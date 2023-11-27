const Gui = @import("../Gui.zig");

const Point = @Vector(2, i32);
const Size = Point;

const Rect = @import("Rect.zig");
const Alignment = @import("Alignment.zig");

const Text = @This();
pos: Point,
size: Size,
alignment: Alignment,

pub const InitInfo = struct {
    data: []const u16,
    pos: Point = .{ 0, 0 },
    alignment: Alignment = .{},
    usage: enum { static, dynamic } = .static,
};

pub fn init(gui: Gui, info: InitInfo) !Text {
    var width: i32 = 0;
    for (info.data) |c| {
        width = width + gui.font.chars[c].width + 1;
    }
    width -= 1;

    return .{
        .pos = info.pos,
        .size = info.pos + Point{ width, 8 },
        .alignment = info.alignment,
    };
}

//pub fn deinit(self: Text) void {
//    self.vertices.deinit();
//}
//
//pub fn subdata(self: *Text, state: State, data: []const u16) !void {
//    const vertices = try initVertices(state, data);
//    self.size[0] = vertices.width;
//    try self.vertices.subdata(vertices.data);
//}
//
//pub fn initVertices(state: State, data: []const u16) !struct { data: []const f32, width: i32 } {
//    var width: i32 = 0;
//    if (data.len > 512) return error.TextSizeOverflow;
//    var i: usize = 0;
//    for (data) |c| {
//        if (c == ' ') {
//            width += 3;
//            continue;
//        }
//
//        const widthf = @as(f32, @floatFromInt(width));
//        const cposf = @as(f32, @floatFromInt(state.render.text.positions[c]));
//        const cwidthf = @as(f32, @floatFromInt(state.render.text.widths[c]));
//        const texwidthf = @as(f32, @floatFromInt(state.render.text.texture.size[0]));
//        const rect = Vec{ widthf, 0.0, widthf + cwidthf, -8.0 };
//        const uvrect = Vec{ cposf / texwidthf, 0.0, (cposf + cwidthf) / texwidthf, 1.0 };
//
//        vertices_data[i * 24 + (4 * 0) + 0] = rect[0];
//        vertices_data[i * 24 + (4 * 0) + 1] = rect[1];
//        vertices_data[i * 24 + (4 * 0) + 2] = uvrect[0];
//        vertices_data[i * 24 + (4 * 0) + 3] = uvrect[1];
//
//        vertices_data[i * 24 + (4 * 1) + 0] = rect[0];
//        vertices_data[i * 24 + (4 * 1) + 1] = rect[3];
//        vertices_data[i * 24 + (4 * 1) + 2] = uvrect[0];
//        vertices_data[i * 24 + (4 * 1) + 3] = uvrect[3];
//
//        vertices_data[i * 24 + (4 * 2) + 0] = rect[2];
//        vertices_data[i * 24 + (4 * 2) + 1] = rect[3];
//        vertices_data[i * 24 + (4 * 2) + 2] = uvrect[2];
//        vertices_data[i * 24 + (4 * 2) + 3] = uvrect[3];
//
//        vertices_data[i * 24 + (4 * 3) + 0] = rect[2];
//        vertices_data[i * 24 + (4 * 3) + 1] = rect[3];
//        vertices_data[i * 24 + (4 * 3) + 2] = uvrect[2];
//        vertices_data[i * 24 + (4 * 3) + 3] = uvrect[3];
//
//        vertices_data[i * 24 + (4 * 4) + 0] = rect[2];
//        vertices_data[i * 24 + (4 * 4) + 1] = rect[1];
//        vertices_data[i * 24 + (4 * 4) + 2] = uvrect[2];
//        vertices_data[i * 24 + (4 * 4) + 3] = uvrect[1];
//
//        vertices_data[i * 24 + (4 * 5) + 0] = rect[0];
//        vertices_data[i * 24 + (4 * 5) + 1] = rect[1];
//        vertices_data[i * 24 + (4 * 5) + 2] = uvrect[0];
//        vertices_data[i * 24 + (4 * 5) + 3] = uvrect[1];
//
//        width += state.render.text.widths[c] + 1;
//        i += 1;
//    }
//
//    return .{
//        .data = vertices_data[0..(i * 24)],
//        .width = width,
//    };
//}
//
//var vertices_data: [12288]f32 = [1]f32{0.0} ** 12288;
