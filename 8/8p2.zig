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

// an error is raised when we get the
// desired result? sure, why not
const AccumError = error{CorruptedInstructionFound};

// will execute the provided program with accumulator initialized to zero
// and modify accumulator until any operation is executed a second time.
// Then, will return the value of accumulator *before* the second operation
// was performed.
fn execute_until_unterminating(program: []Operation) AccumError!i32 {
    var global_acc: i32 = 0;
    // pc shouldnt be negative
    var pc: usize = 0;

    // pointer to op struct
    var cur_op: *Operation = &program[pc];

    // continue executing the program until we find an already visited
    // instruction
    while (!cur_op.*.visited and pc < program.len) {
        //std.debug.print("PC {} Op {}\n", .{ pc, cur_op.* });
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
        std.debug.assert(pc >= 0);
        // if PC jumps beyond end, we'll exit the while. Play with returning errors...
        if (pc >= program.len) {
            std.debug.print("Found corrupted instruction, accumulator is {}\n", .{global_acc});
            return AccumError.CorruptedInstructionFound;
        }

        cur_op = &program[pc];
    }
    std.debug.print("final pc {}\n", .{pc});
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
    // vary instructions in the program until a modification causes
    // the program to terminate
    std.debug.print("Executing instructions from input file...\n", .{});

    var found = false;
    // change each nop to jmp and vice versa, run, wait for 'error' to raise
    var variant_count: u16 = 613;
    // create 613 variants - we will have fewer (as not all
    // instructions are nop and jmp) but this guarantees enough
    // space even if all instructions were nop and jmp
    var op_variant: [613][613]Operation = undefined;
    while (variant_count > 0) {
        const index = variant_count - 1;
        std.debug.assert(operations.items.len == 613);
        std.mem.copy(Operation, op_variant[index][0..], operations.items[0..]);
        // for each variant, change 0 or 1 instructions from nop to jmp or vice versa
        const op = op_variant[index][index];
        const new_inst = switch (op.inst) {
            .jmp => Instruction.nop,
            .nop => Instruction.jmp,
            .acc => Instruction.acc,
        };
        op_variant[index][index].inst = new_inst;

        variant_count -= 1;
    }
    std.debug.assert(variant_count == 0);

    while (!found and variant_count < 613) {
        const op = op_variant[variant_count];
        std.debug.print("Trying variant {} (operation: {})", .{ variant_count, op });
        const final_acc = execute_until_unterminating(op_variant[variant_count][0..]) catch |err| {
            std.debug.print("Corrupt instruction found", .{});
            return err;
        };

        variant_count += 1;
    }
}
