const std = @import("std");
const sort = std.sort;

fn password_valid(policy: []const u8, password: []const u8) bool {
    // extract character to count (last index of policy slice)
    var char_and_counts = std.mem.split(policy, " ");
    const policy_counts_string = char_and_counts.next().?;
    const policy_char = char_and_counts.next().?;
    std.debug.assert(char_and_counts.next() == null);

    var min_max_counts = std.mem.split(policy_counts_string, "-");
    const min_string = min_max_counts.next().?;
    const max_string = min_max_counts.next().?;
    std.debug.assert(min_max_counts.next() == null);

    const min: u8 = std.fmt.parseInt(u8, min_string, 10) catch unreachable;
    const max: u8 = std.fmt.parseInt(u8, max_string, 10) catch unreachable;

    //std.debug.print("{} {} and pol char {}\n", .{ min, max, policy_char });

    var matchcount: u8 = 0;
    for (password) |letter| {
        if (letter == policy_char[0]) {
            matchcount += 1;
        }
    }

    return (min <= matchcount) and (matchcount <= max);
}

pub fn main() anyerror!void {
    std.io.getStdOut().writeAll("Running AOC2020 #2p1") catch unreachable;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const input = try std.fs.cwd().readFileAlloc(&gpa.allocator, "2p1.txt", std.math.maxInt(usize));
    defer _ = gpa.deinit();
    defer gpa.allocator.free(input);

    // First, we'll get lines of password policy and password
    // lines is an iterator
    var lines = std.mem.tokenize(input, "\n");

    // Count of valid passwords
    var valid_passwords: usize = 0;

    while (lines.next()) |line| {
        var line_elements = std.mem.split(line, ":");
        var policy: ?[]const u8 = undefined;
        var password: ?[]const u8 = undefined;

        policy = line_elements.next();
        password = line_elements.next();

        // should only contain 2 elements
        std.debug.assert(line_elements.next() == null);

        // assume non-null and unwrap policy/password.
        // Would crash if either were null
        if (password_valid(policy.?, password.?)) {
            std.debug.print("{} is valid (Policy '{}')\n", .{ password, policy });
            valid_passwords += 1;
        }
    }
    std.debug.print("{} valid passwords found.", .{valid_passwords});
}
