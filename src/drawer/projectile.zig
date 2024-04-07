const _data = struct {
    pub var vertex_buffer: gfx.Buffer = undefined;
    pub var mesh: gfx.Mesh = undefined;
    pub var program: gfx.Program = undefined;
    pub const uniform = struct {
        pub var model: gfx.Uniform = undefined;
        pub var view: gfx.Uniform = undefined;
        pub var proj: gfx.Uniform = undefined;
    };
};

pub fn init() !void {
    const bytes = @import("../world.zig").getProjectilesPosBytes();
    const cnt = @import("../world.zig").getProjectilesMaxCnt();

    world.projectile.vertex_buffer = try gfx.Buffer.init(.{
        .name = "world projectile vertex",
        .target = .vbo,
        .datatype = .f32,
        .vertsize = 4,
        .usage = .dynamic_draw,
    });
    world.projectile.vertex_buffer.data(bytes);

    world.projectile.mesh = try gfx.Mesh.init(.{
        .name = "world projectile mesh",
        .buffers = &.{world.projectile.vertex_buffer},
        .vertcnt = cnt,
        .drawmode = .points,
    });

    world.projectile.program = try gfx.Program.init(_allocator, "world/projectile");
    world.projectile.uniform.model = try gfx.Uniform.init(world.projectile.program, "model");
    world.projectile.uniform.view = try gfx.Uniform.init(world.projectile.program, "view");
    world.projectile.uniform.proj = try gfx.Uniform.init(world.projectile.program, "proj");
}

pub fn draw() void {
    const bytes = projectile.getProjectilesPosBytes();
    _data.vertex_buffer.subdata(0, bytes);
    _data.program.use();
    _data.uniform.model.set(zm.identity());
    _data.uniform.view.set(camera.view);
    _data.uniform.proj.set(camera.proj);
    _data.mesh.draw();
}
