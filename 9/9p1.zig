const std = @import("std");

const preamble_len: usize = 25;

const XmasMessage = struct {
    // preamble length to examine
    preamble_len: usize = preamble_len,
    contents: std.ArrayList(usize) = undefined,

    valid_pairs: usize = 0,

    pub fn init(contents: std.ArrayList(usize)) XmasMessage {
        return XmasMessage{
            .contents = contents,
            // valid_pairs has default value
        };
    }

    pub fn preambleIsPopulated(self: *XmasMessage) bool {
        if (self.contents.items.len < self.preamble_len) {
            return false;
        }
        std.debug.assert(self.contents.items.len == self.preamble_len);
        return true;
    }

    pub fn newValIsValid(self: *XmasMessage, new_val: usize) bool {
        // iterate through the preamble, which is windowed as we move
        // through the message
        const preamble_start_idx = self.contents.items.len - self.preamble_len;
        var i: usize = 0;

        // get first value to compare
        while (i < self.preamble_len) {
            //std.debug.print(" iterating i = {}\n", .{i});
            const preamble_compare_a = self.contents.items[preamble_start_idx + i];

            var j: usize = 0;
            while (j < self.preamble_len) {
                //std.debug.print(" iterating j = {}\n", .{j});
                const preamble_compare_b = self.contents.items[preamble_start_idx + j];
                if (i == j) {
                    // no-op
                    // skip adding same number to itself in preamble
                } else if (preamble_compare_a + preamble_compare_b == new_val) {
                    //std.debug.print("Adding {} and {}...\n", .{ preamble_compare_a, preamble_compare_b });
                    return true;
                }
                j += 1;
            }
            i += 1;
        }
        return false;
    }

    pub fn incrementMessage(self: *XmasMessage, new_val: usize) !void {
        try self.contents.append(new_val);
    }
};

pub fn main() anyerror!void {
    std.io.getStdOut().writeAll("Running AOC2020 Day 9\n") catch unreachable;
    // runtime error occurs if too small (FixedBufferAllocator)
    var buffer: [32000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    var allocator = &fba.allocator;
    const input = try std.fs.cwd().readFileAlloc(&fba.allocator, "input.txt", std.math.maxInt(usize));
    defer fba.allocator.free(input);

    // Read first
    var in_vals = std.mem.tokenize(input, "\n");
    var message_arraylist = std.ArrayList(usize).init(allocator);
    defer message_arraylist.deinit();

    var parsed_message = XmasMessage.init(message_arraylist);

    // fill the message preamble
    while (!parsed_message.preambleIsPopulated()) {
        // assert the input is longer than the expected preamble
        const new_val_str = in_vals.next().?;
        const new_val: usize = try std.fmt.parseInt(usize, new_val_str[0..], 10);
        std.debug.print("Building initial preamble with {}\n", .{new_val});
        try parsed_message.incrementMessage(new_val);
    }

    // begin validating new values until finding an invalid one
    while (in_vals.next()) |val| {
        const new_val_str = val;
        const new_val: usize = try std.fmt.parseInt(usize, new_val_str[0..], 10);
        std.debug.print("Adding {} to message\n", .{new_val});
        if (!parsed_message.newValIsValid(new_val)) {
            std.debug.print("\n\n\nValue {} is invalid!!!\n\n\n", .{new_val});
        }
        try parsed_message.incrementMessage(new_val);
    }
}
