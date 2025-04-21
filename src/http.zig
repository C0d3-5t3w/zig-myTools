const std = @import("std");
const http = std.http;
const net = std.net;
const uri = std.Uri;
const testing = std.testing;
const Allocator = std.mem.Allocator;

/// Represents an HTTP Client.
pub const Client = struct {
    allocator: Allocator,
    // TODO: Add configuration options like timeout, proxy, etc.

    pub fn init(allocator: Allocator) Client {
        return .{ .allocator = allocator };
    }

    /// Performs an HTTP GET request to the specified URL.
    /// The caller owns the memory of the returned Response body.
    pub fn Get(self: Client, url_str: []const u8) !Response {
        var client = http.Client{ .allocator = self.allocator };
        defer client.deinit();

        const parsed_uri = try uri.parse(url_str);

        var req = try client.request(.GET, parsed_uri, .{ .allocator = self.allocator });
        defer req.deinit();

        try req.start();
        try req.wait();

        // TODO: Handle redirects, response headers, etc.
        var response_body = std.ArrayList(u8).init(self.allocator);
        errdefer response_body.deinit();

        const body_reader = req.reader();
        try response_body.readAll(body_reader, std.math.maxInt(usize));

        return Response{
            .status_code = req.response.status,
            .body = try response_body.toOwnedSlice(),
            // TODO: Populate headers
        };
    }
};

/// Represents an HTTP Response (simplified).
pub const Response = struct {
    status_code: http.Status,
    body: []u8,
    // TODO: Add headers field: std.http.Headers
};

// Note: Running HTTP tests requires network access and can be flaky.
// Using a reliable test endpoint like httpbin.org.
// These tests might be skipped in environments without network access.
test "HTTP Client Get" {
    // This test requires network access.
    if (std.testing.skip_networking) return error.SkipZigTest;

    const allocator = testing.allocator;
    var client = Client.init(allocator);

    // Test basic GET
    var response = try client.Get("http://httpbin.org/get");
    defer allocator.free(response.body);

    try testing.expect(response.status_code == .ok);
    // Check if the body contains expected JSON structure (basic check)
    try testing.expect(std.mem.containsAtLeast(u8, response.body, 1, "\"url\": \"http://httpbin.org/get\""));

    // Test non-existent URL (expecting 404)
    response = try client.Get("http://httpbin.org/status/404");
    defer allocator.free(response.body);
    try testing.expect(response.status_code == .not_found);

    // Test invalid URL format (parsing error)
    try testing.expectError(uri.ParseError.InvalidUri, client.Get("invalid-url"));

    // Test connection error (using a non-routable address)
    // Note: This might time out depending on network configuration.
    // Consider adding a timeout to the client later.
    // try testing.expectError(std.os.SocketError.NetworkUnreachable, client.Get("http://10.255.255.1/"));
}
