const std = @import("std");
const net = std.net;
const http = std.http;
const crypto = std.crypto;
const base64 = std.base64;
const mem = std.mem;
const io = std.io;
const fmt = std.fmt;
const testing = std.testing;
const Allocator = mem.Allocator;

// WebSocket opcodes
pub const OpcodeText = 1;
pub const OpcodeBinary = 2;
pub const OpcodeClose = 8;
pub const OpcodePing = 9;
pub const OpcodePong = 10;

// Message types (matching opcodes for simplicity here)
pub const MessageTypeText = OpcodeText;
pub const MessageTypeBinary = OpcodeBinary;
pub const MessageTypeClose = OpcodeClose;
pub const MessageTypePing = OpcodePing;
pub const MessageTypePong = OpcodePong;

const websocket_guid = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";

/// Conn represents a WebSocket connection.
pub const Conn = struct {
    conn: net.StreamConn,
    allocator: Allocator,
    is_server: bool,
    read_buffer: std.ArrayList(u8),
    write_buffer: std.ArrayList(u8),

    // TODO: Add fields for read/write state, fragmentation, etc.

    pub fn init(conn: net.StreamConn, allocator: Allocator, is_server: bool, read_buf_size: usize, write_buf_size: usize) !Conn {
        var read_buffer = std.ArrayList(u8).initCapacity(allocator, read_buf_size);
        errdefer read_buffer.deinit();
        var write_buffer = std.ArrayList(u8).initCapacity(allocator, write_buf_size);
        errdefer write_buffer.deinit();

        return Conn{
            .conn = conn,
            .allocator = allocator,
            .is_server = is_server,
            .read_buffer = read_buffer,
            .write_buffer = write_buffer,
        };
    }

    pub fn deinit(self: *Conn) void {
        self.read_buffer.deinit();
        self.write_buffer.deinit();
        self.conn.close(); // Close the underlying connection
    }

    /// Reads a single message from the connection.
    /// Returns the message type and the payload data.
    /// The returned slice is owned by the Conn's internal buffer and valid until the next read.
    /// NOTE: This is a placeholder. Full implementation requires frame parsing.
    pub fn ReadMessage(self: *Conn) !struct { message_type: u8, data: []u8 } {
        // Placeholder: Reads some data but doesn't parse frames.
        // A real implementation needs to parse FIN, RSV, opcode, mask, payload length,
        // handle masking/unmasking, control frames (Close, Ping, Pong), and fragmentation.
        self.read_buffer.clearRetainingCapacity();
        const n = try self.conn.read(self.read_buffer.items); // Simplified read
        if (n == 0) return error.ConnectionClosed;

        // Pretend we read a text message with the raw data
        return .{ .message_type = MessageTypeText, .data = self.read_buffer.items[0..n] };
    }

    /// Writes a single message to the connection.
    /// NOTE: This is a placeholder. Full implementation requires frame generation.
    pub fn WriteMessage(self: *Conn, message_type: u8, data: []const u8) !void {
        // Placeholder: Writes raw data without framing.
        // A real implementation needs to construct frames with FIN, RSV, opcode,
        // payload length, and mask the payload if is_server is false.
        _ = message_type; // unused in placeholder
        _ = try self.conn.write(data);
    }
};

/// Upgrader specifies parameters for upgrading an HTTP connection to a
/// WebSocket connection.
pub const Upgrader = struct {
    read_buffer_size: usize = 4096,
    write_buffer_size: usize = 4096,
    // Optional: Function to check the origin of the request. Return true to allow.
    check_origin: ?fn (req: *const http.Server.Request) bool = null,
    // TODO: Add options for subprotocols, compression, error handling func.

    /// Upgrades the HTTP server connection to the WebSocket protocol.
    /// The response parameter is used to inform the client about the failure
    /// when the upgrade fails. It's the responsibility of the caller to
    /// finish the response using `resp.finish()`.
    /// The `conn` parameter is the underlying network connection obtained after
    /// hijacking the HTTP request. If nil, it assumes the response writer
    /// can provide the connection (e.g., via `resp.hijack()`).
    pub fn Upgrade(self: Upgrader, resp: *http.Server.Response, req: *const http.Server.Request, underlying_conn: ?net.StreamConn) !Conn {
        const allocator = req.allocator; // Use allocator from the request

        if (req.method != .GET) {
            resp.status = .method_not_allowed;
            try resp.headers.append("Allow", "GET");
            return error.HttpMethodNotAllowed;
        }

        if (!req.headers.contains("Sec-WebSocket-Key")) {
            resp.status = .bad_request;
            return error.WebSocketKeyMissing;
        }

        if (!http.tokenListContains(req.headers.get("Upgrade"), "websocket")) {
            resp.status = .bad_request;
            return error.WebSocketUpgradeRequired;
        }

        if (!http.tokenListContains(req.headers.get("Connection"), "Upgrade")) {
            resp.status = .bad_request;
            return error.WebSocketConnectionUpgradeRequired;
        }

        if (!std.mem.eql(u8, req.headers.get("Sec-WebSocket-Version") orelse "", "13")) {
            resp.status = .bad_request;
            try resp.headers.append("Sec-WebSocket-Version", "13");
            return error.WebSocketVersionNotSupported;
        }

        if (self.check_origin) |check| {
            if (!check(req)) {
                resp.status = .forbidden;
                return error.WebSocketOriginNotAllowed;
            }
        }

        const key = req.headers.get("Sec-WebSocket-Key").?;
        const accept_key = try computeAcceptKey(allocator, key);
        defer allocator.free(accept_key);

        resp.status = .switching_protocols;
        try resp.headers.append("Upgrade", "websocket");
        try resp.headers.append("Connection", "Upgrade");
        try resp.headers.append("Sec-WebSocket-Accept", accept_key);
        // TODO: Handle Sec-WebSocket-Protocol

        // Send the response headers immediately
        try resp.sendHeader();

        // Obtain the underlying connection
        const stream_conn = underlying_conn orelse (try resp.hijack());

        // Create the WebSocket connection object
        return Conn.init(stream_conn, allocator, true, self.read_buffer_size, self.write_buffer_size);
    }
};

fn computeAcceptKey(allocator: Allocator, key: []const u8) ![]u8 {
    const combined_len = key.len + websocket_guid.len;
    var combined = try allocator.alloc(u8, combined_len);
    defer allocator.free(combined);

    @memcpy(combined[0..key.len], key);
    @memcpy(combined[key.len..combined_len], websocket_guid);

    const sha1_hasher = crypto.hash.Sha1.init(.{});
    sha1_hasher.update(combined);
    var hash_result: [crypto.hash.Sha1.digest_length]u8 = undefined;
    sha1_hasher.final(&hash_result);

    const b64_len = base64.standard.calcEncodedLen(hash_result.len);
    const b64_buf = try allocator.alloc(u8, b64_len);
    // errdefer allocator.free(b64_buf); // Freed by caller

    base64.standard.encode(b64_buf, &hash_result);
    return b64_buf;
}

test "computeAcceptKey" {
    const allocator = testing.allocator;
    // Example from RFC 6455
    const key = "dGhlIHNhbXBsZSBub25jZQ==";
    const expected_accept = "s3pPLMBiTxaQ9kYGzzhZRbK+xOo=";

    const accept = try computeAcceptKey(allocator, key);
    defer allocator.free(accept);

    try testing.expectEqualStrings(expected_accept, accept);
}

// TODO: Add tests for Upgrader (requires mocking http request/response)
// TODO: Add tests for Conn Read/Write (requires implementing framing and mocking connection)
