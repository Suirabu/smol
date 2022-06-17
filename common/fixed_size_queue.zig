pub const QueueError = error {
    Overflow,
    Underflow,
    InvalidIndex,
};

pub fn FixedSizeQueue(comptime T: type, comptime size: usize) type {
    return struct {
        const Self = @This();
        const capacity = size;

        len: usize,
        elements: [size]T,

        pub fn new() Self {
            return Self{
                .len = 0,
                .elements = undefined,
            };
        }

        pub fn push(self: *Self, val: T) QueueError!void {
            if (self.len == capacity) {
                return QueueError.Overflow;
            }

            self.elements[self.len] = val;
            self.len += 1;
        }

        pub fn pop(self: *Self) QueueError!T {
            if (self.len == 0) {
                return QueueError.Underflow;
            }

            self.len -= 1;
            return self.elements[self.len];
        }

        pub fn peek(self: Self) QueueError!T {
            if (self.len == 0) {
                return QueueError.Underflow;
            }

            return self.elements[self.len - 1];
        }

        pub fn peekNth(self: Self, index: isize) QueueError!T {
            const true_index = if(index >= 0) index else @intCast(isize, self.len) + index;
            if(true_index < 0 or true_index >= self.len) {
                return QueueError.InvalidIndex;
            }

            return self.elements[@intCast(usize, true_index)];
        }
    };
}

const std = @import("std");
const expect = std.testing.expect;
const expectError = std.testing.expectError;

test "FixedSizeQueue.push()" {
    var queue = FixedSizeQueue(u8, 2).new();
    try queue.push(1);
    try queue.push(2);
    try expectError(QueueError.Overflow, queue.push(3));
}

test "FixedSizeQueue.pop()" {
    var queue = FixedSizeQueue(u8, 2).new();
    try queue.push(1);
    try queue.push(2);

    try expect((try queue.pop()) == 2);
    try expect((try queue.pop()) == 1);
    try expectError(QueueError.Underflow, queue.pop());
}

test "FixedSizeQueue.peek()" {
    var queue = FixedSizeQueue(u8, 2).new();

    try queue.push(1);
    try expect((try queue.peek()) == 1);

    try queue.push(2);
    try expect((try queue.peek()) == 2);

    _ = try queue.pop();
    _ = try queue.pop();

    try expectError(QueueError.Underflow, queue.peek());
}

test "FixedSizeQueue.peek_nth()" {
    var queue = FixedSizeQueue(u8, 3).new();

    try queue.push(1);
    try queue.push(2);
    try queue.push(3);  

    try expect((try queue.peekNth(0)) == 1);
    try expect((try queue.peekNth(-2)) == 2);
    try expect((try queue.peekNth(-1)) == 3);

    try expectError(QueueError.InvalidIndex, queue.peekNth(-5));
    try expectError(QueueError.InvalidIndex, queue.peekNth(5));
}
