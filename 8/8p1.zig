const std = @import("std");

// Possible instructions for an operation in the handheld unit boot code
const Instruction = enum {
    nop, acc, jmp
};

// Single operation. 'visited' to track if its been executed or not
const Operation = struct {
    inst: Instruction,
    operand: i32,
    visited: bool = false,
};

// will execute the provided program with accumulator initialized to zero
// and modify accumulator until any operation is executed a second time.
// Then, will return the value of accumulator *before* the second operation
// was performed.
fn execute_until_unterminating(program: []Operation) !i32 {
    var global_acc: i32 = 0;
    // pc shouldnt be negative
    var pc: usize = 0;

    // pointer to op struct
    var cur_op: *Operation = &program[pc];

    // continue executing the program until we find an already visited
    // instruction
    while (!cur_op.*.visited and pc < program.len) {
        std.debug.print("PC {} Op {}\n", .{ pc, cur_op.* });
        cur_op.*.visited = true;
        switch (cur_op.inst) {
            // nice feature: switching with enum literals
            .nop => {
                pc += 1;
            },
            .acc => {
                pc += 1;
                global_acc += cur_op.operand;
            },
            .jmp => {
                if (cur_op.operand > 0) {
                    pc = pc + @intCast(usize, cur_op.operand);
                } else {
                    pc = pc - @intCast(usize, -cur_op.operand);
                }
            },
        }
        // should never reach end of the program or jump earlier...
        std.debug.assert(pc < program.len);
        std.debug.assert(pc >= 0);
        cur_op = &program[pc];
    }

    return global_acc;
}

pub fn main() anyerror!void {
    std.io.getStdOut().writeAll("Running AOC2020 Day 8\n") catch unreachable;
    // runtime error occurs if too small (FixedBufferAllocator)
    var buffer: [18000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    var allocator = &fba.allocator;
    const input = try std.fs.cwd().readFileAlloc(&fba.allocator, "input.txt", std.math.maxInt(usize));
    defer fba.allocator.free(input);

    // "The moment the program tries to run any instruction a second time, you know it will never terminate."
    // each token is '<instruction> <+/-val>', e.g. `nop +456`, `acc +0`, etc
    var operation_lines = std.mem.tokenize(input, "\n");
    var operations = std.ArrayList(Operation).init(allocator);
    defer operations.deinit();

    while (operation_lines.next()) |operation_line| {
        var operation = Operation{
            // first character is a(cc)/n(op)/j(mp)
            .inst = switch (operation_line[0]) {
                'a' => Instruction.acc,
                'n' => Instruction.nop,
                'j' => Instruction.jmp,
                else => unreachable,
            },
            .operand = switch (operation_line[4]) {
                '+' => try std.fmt.parseInt(i32, operation_line[5..], 10),
                '-' => -1 * try std.fmt.parseInt(i32, operation_line[5..], 10),
                else => unreachable,
            },
            // visited is by default false
        };
        //std.debug.print("Parsed Op {}\n", .{operation});

        try operations.append(operation);
    }
    // run the program
    std.debug.print("Executing instructions from input file...\n", .{});
    const final_acc = execute_until_unterminating(operations.toOwnedSlice());
    std.debug.print("Final accumulator value {}\n", .{final_acc});
}
