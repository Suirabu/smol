const std = @import("std");

const common = @import("common");

const FixedSizeQueue = common.FixedSizeQueue;
const InsTag = common.InstructionTag;

pub const Cpu = struct {
    const Self = @This();

    const memory_size = 0xA000;     // 40KiB
    const program_offset = 0x3000;
    const max_program_size = memory_size - program_offset;
    const value_stack_capacity = 256;
    const call_stack_capacity = 16;
    
    const cmp_equal     = 0b001;
    const cmp_greater   = 0b010;
    const cmp_less      = 0b100;

    const ValueStackType = FixedSizeQueue(u16, value_stack_capacity);
    const CallStackType = FixedSizeQueue(u16, call_stack_capacity);

    memory: [memory_size]u8,
    pc: u16,

    value_stack: ValueStackType,
    call_stack: CallStackType,

    pub fn new() Self {
        return Self {
            .memory = undefined,
            .pc = program_offset,
            .value_stack = ValueStackType.new(),
            .call_stack = CallStackType.new(),
        };
    }

    pub fn loadProgram(self: *Self, program: []const u8) !void {
        if(program.len > max_program_size) {
            return error.NotEnoughMemory;
        }
        std.mem.copy(u8, self.memory[program_offset..], program);
    }

    fn isInBounds(addr: usize) bool {
        return addr < memory_size;
    }

    fn getWord(self: Self, addr: usize) !u8 {
        if(!isInBounds(addr)) {
            return error.OutOfBounds;
        }
        return self.memory[addr];
    }
    
    fn getDword(self: Self, addr: usize) !u16 {
        if(!isInBounds(addr)) {
            return error.OutOfBounds;
        }

        const msb: u16 = self.memory[addr];
        const lsb: u16 = self.memory[addr + 1];
        return (msb << 8) + lsb;
    }
    
    pub fn tick(self: *Self) anyerror!void {
        const opcode = self.memory[self.pc];
        self.pc += 1;
        const instruction = @intToEnum(InsTag, opcode);

        switch(instruction) {
            // Meta operations
            InsTag.nop => {},
            
            // Stack operations
            InsTag.push8 => {
                try self.value_stack.push(try self.getWord(self.pc));
                self.pc += 1;
            },
            InsTag.push16 => {
                try self.value_stack.push(try self.getDword(self.pc));
                self.pc += 2;
            },
            InsTag.drop => {
                _ = try self.value_stack.pop();
            },
            InsTag.dup => {
                const val = try self.value_stack.peek();
                try self.value_stack.push(val);
            },
            InsTag.swap => {
                const b = try self.value_stack.pop();
                const a = try self.value_stack.pop();
                try self.value_stack.push(b);
                try self.value_stack.push(a);
            },
            InsTag.over => {               
                try self.value_stack.push(try self.value_stack.peekNth(-2));
            },
            InsTag.rot => {
                const c = try self.value_stack.pop();
                const b = try self.value_stack.pop();
                const a = try self.value_stack.pop();
                try self.value_stack.push(b);
                try self.value_stack.push(c);
                try self.value_stack.push(a);
            },
            InsTag.store8 => {
                const addr = try self.value_stack.pop();
                const a = try self.value_stack.pop();
                if(!isInBounds(addr)) {
                    return error.OutOfBounds;
                }
                self.memory[addr] = @intCast(u8, a);
            },
            InsTag.store16 => {
                const addr = try self.value_stack.pop();
                const a = try self.value_stack.pop();
                if(!isInBounds(addr + 1)) {
                    return error.OutOfBounds;
                }
                self.memory[addr] = @intCast(u8, a >> 8);
                self.memory[addr + 1] = @intCast(u8, a);
            },
            InsTag.load8 => {
                const addr = try self.value_stack.pop();
                try self.value_stack.push(try self.getWord(addr));
            },
            InsTag.load16 => {
                const addr = try self.value_stack.pop();
                try self.value_stack.push(try self.getDword(addr));
            },

            // Arithmetic operations
            InsTag.add => {
                const b = try self.value_stack.pop();
                const a = try self.value_stack.pop();
                try self.value_stack.push(a + b);
            },
            InsTag.sub => {
                const b = try self.value_stack.pop();
                const a = try self.value_stack.pop();
                try self.value_stack.push(a - b);
            },
            InsTag.mult => {
                const b = try self.value_stack.pop();
                const a = try self.value_stack.pop();
                try self.value_stack.push(a * b);
            },
            InsTag.div => {
                const b = try self.value_stack.pop();
                const a = try self.value_stack.pop();
                try self.value_stack.push(a / b);
            },
            InsTag.mod => {
                const b = try self.value_stack.pop();
                const a = try self.value_stack.pop();
                try self.value_stack.push(a % b);
            },

            // Bitwise operations
            InsTag.b_and => {
                const b = try self.value_stack.pop();
                const a = try self.value_stack.pop();
                try self.value_stack.push(a & b);
            },
            InsTag.b_or => {
                const b = try self.value_stack.pop();
                const a = try self.value_stack.pop();
                try self.value_stack.push(a | b);
            },
            InsTag.b_not => {
                const a = try self.value_stack.pop();
                try self.value_stack.push(~a);
            },
            InsTag.xor => {
                const b = try self.value_stack.pop();
                const a = try self.value_stack.pop();
                try self.value_stack.push(a ^ b);
            },
            InsTag.shiftl => {
                const b = try self.value_stack.pop();
                const a = try self.value_stack.pop();
                try self.value_stack.push(a << @intCast(u4, b));
            },
            InsTag.shiftr => {
                const b = try self.value_stack.pop();
                const a = try self.value_stack.pop();
                try self.value_stack.push(a >> @intCast(u4, b));
            },

            // Comparison/Branching Operations
            InsTag.cmp => {
                const b = try self.value_stack.pop();
                const a = try self.value_stack.pop();
                var cond: u16 = 0;
                
                // There's probably some cleaner way to express this, but I
                // keep getting compile time errors when usinf if-expressions.
                if(a == b) {
                    cond = cmp_equal;
                } else if(a < b) {
                    cond = cmp_less;
                } else {
                    cond = cmp_greater;
                }

                try self.value_stack.push(cond);
            },
            InsTag.jmp => {
                const addr = try self.getDword(self.pc);
                if(!isInBounds(addr)) {
                    return error.OutOfBounds;
                }
                self.pc = addr;
            },
            InsTag.jeq => {
                const cond = try self.value_stack.pop();
                const addr = try self.getDword(self.pc);
                self.pc += 2;
                
                if(!isInBounds(addr)) {
                    return error.OutOfBounds;
                } else if(cond == cmp_equal) {
                    self.pc = addr;
                }
            },
            InsTag.jne => {
                const cond = try self.value_stack.pop();
                const addr = try self.getDword(self.pc);
                self.pc += 2;
                
                if(!isInBounds(addr)) {
                    return error.OutOfBounds;
                } else if(cond != cmp_equal) {
                    self.pc = addr;
                }
            },
            InsTag.jlt => {
                const cond = try self.value_stack.pop();
                const addr = try self.getDword(self.pc);
                self.pc += 2;
                
                if(!isInBounds(addr)) {
                    return error.OutOfBounds;
                } else if(cond == cmp_less) {
                    self.pc = addr;
                }
            },
            InsTag.jle => {
                const cond = try self.value_stack.pop();
                const addr = try self.getDword(self.pc);
                self.pc += 2;
                
                if(!isInBounds(addr)) {
                    return error.OutOfBounds;
                } else if(cond == cmp_less or cond == cmp_equal) {
                    self.pc = addr;
                }
            },
            InsTag.jgt => {
                const cond = try self.value_stack.pop();
                const addr = try self.getDword(self.pc);
                self.pc += 2;
                
                if(!isInBounds(addr)) {
                    return error.OutOfBounds;
                } else if(cond == cmp_greater) {
                    self.pc = addr;
                }
            },
            InsTag.jge => {
                const cond = try self.value_stack.pop();
                const addr = try self.getDword(self.pc);
                self.pc += 2;
                
                if(!isInBounds(addr)) {
                    return error.OutOfBounds;
                } else if(cond == cmp_greater or cond == cmp_equal) {
                    self.pc = addr;
                }
            },
            InsTag.jsr => {
                const addr = try self.getDword(self.pc);
                self.pc += 2;
                if(!isInBounds(addr)) {
                    return error.OutOfBounds;
                }
                try self.call_stack.push(self.pc);
                self.pc = addr;
            },
            InsTag.ret => {
                self.pc = try self.call_stack.pop();
            },
        }
    }
};

const expect = std.testing.expect;

test "Stack operations" {
    var cpu = Cpu.new();
    const program = [_]u8 {
        0x10, 42,   // push8 42
        0x11, 1, 0, // push16 256
        0x15,       // over
        0x13,       // dup
        0x16,       // rot
        0x14,       // swap
        0x10, 0,    // push8 0
        0x17,       // store16
        0x10, 0,    // push8 0
        0x19,       // load16
    };
    try cpu.loadProgram(program[0..]);

    try cpu.tick(); // push8 42
    try expect((try cpu.value_stack.peek()) == 42);

    try cpu.tick(); // push16 256
    try expect((try cpu.value_stack.peek()) == 256);
    
    try cpu.tick(); // over
    try expect((try cpu.value_stack.peek()) == 42);
    
    try cpu.tick(); // dup
    try expect((try cpu.value_stack.peek()) == 42);

    try cpu.tick(); // rot
    try expect((try cpu.value_stack.peek()) == 256);

    try cpu.tick(); // swap
    try expect((try cpu.value_stack.peek()) == 42);

    try cpu.tick(); // push8 0
    try expect((try cpu.value_stack.peek()) == 0);

    try cpu.tick(); // store16
    try expect((try cpu.value_stack.peek()) == 256);

    try cpu.tick(); // push8 0
    try expect((try cpu.value_stack.peek()) == 0);

    try cpu.tick(); // load16
    try expect((try cpu.value_stack.peek()) == 42);
}

test "Arithmetic operations" {
    var cpu = Cpu.new();
    const program = [_]u8 {
        0x10, 3,    // push8 3
        0x10, 4,    // push8 4
        0x20,       // add
        0x10, 2,    // push8 2
        0x21,       // sub
        0x10, 3,    // push8 3
        0x22,       // mult
        0x10, 2,    // push8 2
        0x23,       // div
        0x10, 4,    // push8 4
        0x24,       // mod
    };
    try cpu.loadProgram(program[0..]);

    try cpu.tick(); // push8 3
    try cpu.tick(); // push8 4
    try cpu.tick(); // add
    try expect((try cpu.value_stack.peek()) == 7);
    
    try cpu.tick(); // push8 2
    try cpu.tick(); // sub
    try expect((try cpu.value_stack.peek()) == 5);
    
    try cpu.tick(); // push8 3
    try cpu.tick(); // mult
    try expect((try cpu.value_stack.peek()) == 15);
    
    try cpu.tick(); // push8 2
    try cpu.tick(); // div
    try expect((try cpu.value_stack.peek()) == 7);
    
    try cpu.tick(); // push8 4
    try cpu.tick(); // mod
    try expect((try cpu.value_stack.peek()) == 3);
}

test "Bitwise operations" {
    var cpu = Cpu.new();
    const program = [_]u8 {
        0x10, 0b11011011,   // push8 0b11011011
        0x32,               // not
        0x10, 0b11001010,   // push8 0b11001010
        0x31,               // or
        0x10, 0b10110110,   // push8 0b10110110
        0x30,               // and
        0x10, 0b11001011,   // push8 0b11001011
        0x33,               // xor
        0x10, 4,            // push8 4
        0x34,               // shiftl
        0x10, 2,            // push8 4
        0x35,               // shiftr
    };
    try cpu.loadProgram(program[0..]);

    try cpu.tick(); // push8 0b11011011
    try cpu.tick(); // not
    try expect((try cpu.value_stack.peek()) & 0xFF == 0b00100100);
    
    try cpu.tick(); // push8 0b11001010
    try cpu.tick(); // or
    try expect((try cpu.value_stack.peek()) & 0xFF == 0b11101110);
    
    try cpu.tick(); // push8 0b10110110
    try cpu.tick(); // and
    try expect((try cpu.value_stack.peek()) & 0xFF == 0b10100110);
    
    try cpu.tick(); // push8 0b11001011
    try cpu.tick(); // xor
    try expect((try cpu.value_stack.peek()) & 0xFF == 0b01101101);
    
    try cpu.tick(); // push8 4
    try cpu.tick(); // shiftl
    try expect((try cpu.value_stack.peek()) & 0xFFF == 0b011011010000);
    
    try cpu.tick(); // push8 2
    try cpu.tick(); // shiftr
    try expect((try cpu.value_stack.peek()) & 0x7FF == 0b0110110100);
}

test "Comparison operations" {
    var cpu = Cpu.new();
    const program = [_]u8 {
        0x10, 5,    // push8 5
        0x10, 5,    // push8 5
        0x40,       // cmp
        0x10, 5,    // push8 5
        0x10, 3,    // push8 3
        0x40,       // cmp
        0x10, 5,    // push8 5
        0x10, 7,    // push8 7
        0x40,       // cmp
    };
    try cpu.loadProgram(program[0..]);

    try cpu.tick(); // push8 5
    try cpu.tick(); // push8 5
    try cpu.tick(); // cmp
    try expect((try cpu.value_stack.peek()) == Cpu.cmp_equal);
    
    try cpu.tick(); // push8 5
    try cpu.tick(); // push8 3
    try cpu.tick(); // cmp
    try expect((try cpu.value_stack.peek()) == Cpu.cmp_greater);
    
    try cpu.tick(); // push8 5
    try cpu.tick(); // push8 7
    try cpu.tick(); // cmp
    try expect((try cpu.value_stack.peek()) == Cpu.cmp_less);
}

test "Branching operations" {
    var cpu = Cpu.new();
    const program = [_]u8 {
        // 0x3000
        0x41, 0x30, 0x05,   // jmp 0x3005
        0xAA, 0xAA,
        // 0x3005
        0x48, 0x30, 0x0A,   // jsr 0x300A
        0x10, 2,            // push8 2
        // 0x300A
        0x10, 5,            // push8 5
        0x49                // ret
    };
    try cpu.loadProgram(program[0..]);

    try cpu.tick(); // jmp 0x3005
    try cpu.tick(); // jsr 0x300A
    try cpu.tick(); // push8 5
    try expect((try cpu.value_stack.peek()) == 5);
    try cpu.tick(); // ret
    try cpu.tick(); // push8 2
    try expect((try cpu.value_stack.peek()) == 2);
}
