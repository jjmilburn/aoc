const std = @import("std");

const PassportError = error{ PassportFieldAlreadyExists, PassportFieldValueInvalid, PassportFileParsing };

const Passport = struct {
    byr: u32 = 0, // birth year
    iyr: u32 = 0, // issue year
    eyr: u32 = 0, // expiration year
    hgt: [20]u8 = [_]u8{0} ** 20, // height in cm ('183cm')
    hcl: [20]u8 = [_]u8{0} ** 20, // hair color ('#fffffd')
    ecl: [20]u8 = [_]u8{0} ** 20, // eye color ('amb')
    pid: u32 = 0, // passport ID
    cid: u32 = 0, // country ID

    // valid passport has all 8 fields defined
    pub fn is_valid(self: *Passport) bool {
        const valid = (self.byr != 0 and
            self.iyr != 0 and
            self.eyr != 0 and
            self.hgt[0] != 0 and
            self.hcl[0] != 0 and
            self.ecl[0] != 0 and
            self.pid != 0);

        std.debug.print("passport {} valid? {}\n", .{ self, valid });

        return valid;
        // we ignore cid when determining validity
    }

    pub fn add_field(self: *Passport, key: []const u8, value: []const u8) PassportError!void {
        const key_str = key[0..3];
        switch (key_str[0]) {
            'b' => {
                if (self.byr != 0) {
                    return PassportError.PassportFieldAlreadyExists;
                }
                const val = std.fmt.parseInt(u32, value, 10) catch return PassportError.PassportFieldValueInvalid;
                if (1920 <= val and val <= 2002) {
                    self.byr = val;
                } else {
                    return PassportError.PassportFieldValueInvalid;
                }
            },
            'i' => {
                if (self.iyr != 0) {
                    return PassportError.PassportFieldAlreadyExists;
                }
                const val = std.fmt.parseInt(u32, value, 10) catch return PassportError.PassportFieldValueInvalid;
                if (2010 <= val and val <= 2020) {
                    self.iyr = val;
                } else {
                    return PassportError.PassportFieldValueInvalid;
                }
            },
            'e' => {
                if (key_str[1] == 'y' and key_str[2] == 'r') {
                    if (self.eyr != 0) {
                        return PassportError.PassportFieldAlreadyExists;
                    }
                    const val = std.fmt.parseInt(u32, value, 10) catch return PassportError.PassportFieldValueInvalid;
                    if (2020 <= val and val <= 2030) {
                        self.eyr = val;
                    } else {
                        return PassportError.PassportFieldValueInvalid;
                    }
                }
                if (key_str[1] == 'c' and key_str[2] == 'l') {
                    if (self.ecl[0] != 0) {
                        return PassportError.PassportFieldAlreadyExists;
                    }
                    const valid_ecls = [_][]const u8{
                        "amb",
                        "blu",
                        "brn",
                        "gry",
                        "grn",
                        "hzl",
                        "oth",
                    };
                    var ecl_valid = false;
                    for (valid_ecls) |ecl| {
                        if (std.mem.eql(u8, value[0..3], ecl[0..])) {
                            std.mem.copy(u8, self.ecl[0..], value);
                            ecl_valid = true;
                            break;
                        }
                    }
                    if (!ecl_valid) {
                        return PassportError.PassportFieldValueInvalid;
                    }
                }
            },
            'h' => {
                if (key_str[1] == 'g' and key_str[2] == 't') {
                    if (self.hgt[0] != 0) {
                        return PassportError.PassportFieldAlreadyExists;
                    }
                    if (value.len < 3) {
                        return PassportError.PassportFieldValueInvalid;
                    }
                    // get last 2 characters of slice
                    const hgt_units = value[value.len - 2 .. value.len];
                    std.debug.print("hgtunit {}\n", .{hgt_units});
                    var hgt_val: usize = 0;
                    if (std.mem.eql(u8, hgt_units, "in") and value.len == 4) {
                        hgt_val = std.fmt.parseInt(u32, value[0..2], 10) catch return PassportError.PassportFieldValueInvalid;
                        if (59 > hgt_val or 76 < hgt_val) {
                            return PassportError.PassportFieldValueInvalid;
                        }
                    } else if (std.mem.eql(u8, hgt_units, "cm") and value.len == 5) {
                        hgt_val = std.fmt.parseInt(u32, value[0..3], 10) catch return PassportError.PassportFieldValueInvalid;
                        if (150 > hgt_val or 193 < hgt_val) {
                            return PassportError.PassportFieldValueInvalid;
                        }
                    } else {
                        return PassportError.PassportFieldValueInvalid;
                    }
                    std.mem.copy(u8, self.hgt[0..], value);
                } else if (key_str[1] == 'c' and key_str[2] == 'l') {
                    if (self.hcl[0] != 0) {
                        return PassportError.PassportFieldAlreadyExists;
                    }
                    var hcl_valid = false;
                    if (value[0] == '#' and value.len == 7) {
                        hcl_valid = true;
                        for (value[1..]) |char| {
                            // 0-9 or a-f ASCII
                            if (!((48 <= char and char <= 57) or (char >= 97 and char <= 102))) {
                                hcl_valid = false;
                            }
                        }
                    }
                    if (!hcl_valid) {
                        return PassportError.PassportFieldValueInvalid;
                    }
                    std.mem.copy(u8, self.hcl[0..], value);
                } else {
                    std.debug.print("Key str {}\n", .{key_str});
                    unreachable;
                }
            },
            'p' => {
                if (self.pid != 0) {
                    return PassportError.PassportFieldAlreadyExists;
                }
                if (value.len != 9) {
                    return PassportError.PassportFieldValueInvalid;
                }
                self.pid = std.fmt.parseInt(u32, value, 10) catch return PassportError.PassportFieldValueInvalid;
            },
            'c' => {
                if (self.cid != 0) {
                    // ignore `cid`, entirely.
                    //return PassportError.PassportFieldAlreadyExists;
                }
                //self.cid = std.fmt.parseInt(u32, value, 10) catch return PassportError.PassportFieldValueInvalid;
            },
            // for debugging, as we know the input filed cannot have any other keys in this case
            else => unreachable,
        }
    }
};

pub fn main() anyerror!void {
    std.io.getStdOut().writeAll("Running AOC2020 Day 4\n") catch unreachable;
    // runtime error occurs if too small (FixedBufferAllocator)
    var buffer: [36000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    var allocator = &fba.allocator;
    const input = try std.fs.cwd().readFileAlloc(&fba.allocator, "input.txt", std.math.maxInt(usize));
    defer fba.allocator.free(input);

    // Each passport entry is separated by newlines or spaces
    // XXX can only take a single character for tokenization...
    var passport_fields = std.mem.tokenize(input, std.ascii.spaces[0..]);

    // passports with all fields defined
    var valid_passports: u8 = 0;

    var current_passport = Passport{};

    while (passport_fields.next()) |field| {
        // removes all whitespace (newline, spaces, tabs, etc)
        const trimmed_kv = std.mem.trim(u8, field, std.ascii.spaces[0..]);
        var kv_pair = std.mem.split(trimmed_kv, ":");

        var current_key = kv_pair.next() orelse return PassportError.PassportFileParsing;
        var current_value = kv_pair.next() orelse return PassportError.PassportFileParsing;
        std.debug.assert(kv_pair.next() == null);

        std.debug.print("key is {}, value is {}\n", .{ current_key, current_value });

        // if we've come across a field that already exists in the current
        // passport, we must have come to the end of an invalid passport and are
        // beginning a new one.
        current_passport.add_field(current_key, current_value) catch |err| {
            std.debug.print("Error {} received\n", .{err});
            if (current_passport.is_valid()) {
                valid_passports += 1;
                //std.debug.print("Found valid passport: {}\n", .{current_passport});
            }
            // reset and prepare to add field to a new passport
            current_passport = Passport{};
            current_passport.add_field(current_key, current_value) catch |second_err| {
                std.debug.print("Error {}. Attempted to add invalid field/value pair {}:{}, skipping.\n", .{ second_err, current_key, current_value });
            };
        };
    }
    // final check - is the last passport we were operating on valid?
    if (current_passport.is_valid()) {
        valid_passports += 1;
    }

    std.debug.print("{} valid passports.", .{valid_passports});
}
