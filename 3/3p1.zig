const std = @import("std");
const sort = std.sort;

// does a slope at particular elevator have a tree at offset x?
fn tree_exists(traverse_profile: []const u8, x_coord: usize) bool {
    // slope pattern repeats, every element along 'len'
    // get the matching index in the base pattern
    std.debug.print("checking {} ({})i, found? {} (len is {}, value {})\n", .{
        x_coord,
        x_coord % traverse_profile.len,
        traverse_profile[x_coord % traverse_profile.len] == 35,
        traverse_profile.len,
        traverse_profile[x_coord % traverse_profile.len],
    });
    // 35 decimal = 'X' ascii
    return traverse_profile[x_coord % traverse_profile.len] == 35;
}

pub fn main() anyerror!void {
    std.io.getStdOut().writeAll("Running AOC2020 Day 3\n") catch unreachable;
    // runtime error occurs if too small (FixedBufferAllocator)
    var buffer: [18000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    var allocator = &fba.allocator;
    const input = try std.fs.cwd().readFileAlloc(&fba.allocator, "input.txt", std.math.maxInt(usize));
    defer fba.allocator.free(input);

    // Get elevation profiles (0 = highest, .len is bottom of profile)
    var traverse_profiles = std.mem.tokenize(input, "\n");

    var trees_hit: usize = 0;

    // skip the first/'highest' row as we don't mark any trees
    // in that row
    const firstrow = traverse_profiles.next();
    // columns from left
    var x_pos: usize = 3;
    var y_pos: usize = 1;

    while (traverse_profiles.next()) |profile| {
        std.debug.print("profile is {}\n", .{profile});
        if (tree_exists(profile, x_pos)) {
            trees_hit += 1;
            std.debug.print("Hit tree on row {}\n", .{y_pos});
        }
        x_pos += 3;
        y_pos += 1;
    }
    std.debug.print("{} trees hit.", .{trees_hit});
}
