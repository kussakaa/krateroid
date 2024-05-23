pub fn Queue(comptime len: usize, comptime T: type, comptime zero: T) type {
    return struct {
        const Self = @This();

        begin: usize = 0,
        end: usize = 0,
        items: [len]T = undefined,

        pub fn pull(self: *Self) T {
            if (self.begin == self.end) return zero;
            const item = self.items[self.begin];
            self.begin = next(self.begin);
            return item;
        }

        pub fn push(self: *Self, item: T) void {
            self.items[self.end] = item;
            self.end = next(self.end);
        }

        pub fn next(i: usize) usize {
            return if (i == len - 1) 0 else i + 1;
        }
    };
}
