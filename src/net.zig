const std = @import("std");
const net = std.net;
const testing = std.testing;
const Allocator = std.mem.Allocator;

/// Represents an IP address.
pub const IPAddress = net.Address;

/// Errors related to IP parsing.
pub const IPParseError = net.Address.ParseError;

/// Parses an IP address string (IPv4 or IPv6) into an IPAddress.
pub fn parseIP(s: []const u8) IPParseError!IPAddress {
    return net.Address.parseIp(s, 0); // Port 0 is ignored for IP parsing
}

test "parseIP" {
    // Valid IPv4
    const ip4 = try parseIP("192.168.1.1");
    try testing.expect(ip4.isIp4());
    try testing.expectEqual(@as(u32, 0xc0a80101), ip4.ip4AddressInt());

    // Valid IPv6
    const ip6 = try parseIP("::1");
    try testing.expect(ip6.isIp6());
    const expected_ip6: [16]u8 = .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 };
    try testing.expectEqualSlices(u8, &expected_ip6, &ip6.ip6AddressBytes());

    // Valid IPv6 Full
    const ip6_full = try parseIP("2001:0db8:85a3:0000:0000:8a2e:0370:7334");
    try testing.expect(ip6_full.isIp6());

    // Invalid IP
    try testing.expectError(IPParseError.InvalidCharacter, parseIP("invalid-ip"));
    try testing.expectError(IPParseError.InvalidIp4Octet, parseIP("192.168.1.256"));
    try testing.expectError(IPParseError.InvalidCharacter, parseIP("::1:"));
}
