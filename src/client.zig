const std = @import("std");
const net = std.net;
const os = std.posix;

const Client = struct {
    socket: os.socket_t,
    server_address: net.Address,
    connected: bool,
    client_id: u64,

    fn init(server_ip: []const u8, port: u16) !Client {
        const address = try std.net.Address.parseIp(server_ip, port);
        const sock = try os.socket(address.any.family, os.SOCK.STREAM, os.IPPROTO.TCP);
        errdefer os.close(sock);

        return Client{
            .socket = sock,
            .server_address = address,
            .connected = false,
            .client_id = 0,
        };
    }

    fn connect(self: *Client, nickname: []const u8) !void {
        try os.connect(self.socket, &self.server_address.any, self.server_address.getOsSockLen());
        _ = try os.send(self.socket, nickname, 0);
    }
};

pub fn main() !void {
    _ = std.heap.page_allocator;
    var client = try Client.init("127.0.0.1", 3001);
    try client.connect("client1");
}
