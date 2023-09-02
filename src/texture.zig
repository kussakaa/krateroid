const Texture = struct {
    pub fn init() !Texture {}
    pub fn deinit(self: Texture) void {}
    pub fn use(self: Texture) void {}
};
