const Char = packed struct { pos: u16 = 0, width: u16 = 3 };
const Font = @This();

chars: [2048]Char,

pub fn init() Font {
    var chars: [2048]Char = undefined;

    for (chars, 0..) |_, i| {
        chars[i] = .{ .pos = 0, .width = 3 };
    }

    chars['!'] = .{ .pos = 3, .width = 1 };
    chars['"'] = .{ .pos = 4 };
    chars['#'] = .{ .pos = 7, .width = 5 };
    chars['$'] = .{ .pos = 12 };
    chars['\''] = .{ .pos = 15, .width = 1 };
    chars['('] = .{ .pos = 16, .width = 1 };
    chars[')'] = .{ .pos = 18, .width = 1 };
    chars['*'] = .{ .pos = 20 };
    chars['+'] = .{ .pos = 23 };
    chars[','] = .{ .pos = 26, .width = 1 };
    chars['-'] = .{ .pos = 27, .width = 2 };
    chars['.'] = .{ .pos = 29, .width = 1 };
    chars['/'] = .{ .pos = 30 };
    chars['0'] = .{ .pos = 33 };
    chars['1'] = .{ .pos = 36, .width = 1 };
    chars['2'] = .{ .pos = 37 };
    chars['3'] = .{ .pos = 40 };
    chars['4'] = .{ .pos = 43 };
    chars['5'] = .{ .pos = 46 };
    chars['6'] = .{ .pos = 49 };
    chars['7'] = .{ .pos = 52 };
    chars['8'] = .{ .pos = 55 };
    chars['9'] = .{ .pos = 58 };
    chars[':'] = .{ .pos = 61, .width = 1 };
    chars[';'] = .{ .pos = 62, .width = 1 };
    chars['<'] = .{ .pos = 63 };
    chars['='] = .{ .pos = 66 };
    chars['>'] = .{ .pos = 69 };
    chars['?'] = .{ .pos = 72 };
    chars['@'] = .{ .pos = 75, .width = 5 };
    chars['a'] = .{ .pos = 80 };
    chars['b'] = .{ .pos = 83 };
    chars['c'] = .{ .pos = 86 };
    chars['d'] = .{ .pos = 89 };
    chars['e'] = .{ .pos = 92 };
    chars['f'] = .{ .pos = 95 };
    chars['g'] = .{ .pos = 98 };
    chars['h'] = .{ .pos = 101 };
    chars['i'] = .{ .pos = 104, .width = 1 };
    chars['j'] = .{ .pos = 105 };
    chars['k'] = .{ .pos = 108 };
    chars['l'] = .{ .pos = 111 };
    chars['m'] = .{ .pos = 114 };
    chars['n'] = .{ .pos = 119 };
    chars['o'] = .{ .pos = 123 };
    chars['p'] = .{ .pos = 126 };
    chars['q'] = .{ .pos = 129 };
    chars['r'] = .{ .pos = 132 };
    chars['s'] = .{ .pos = 135 };
    chars['t'] = .{ .pos = 138 };
    chars['u'] = .{ .pos = 141 };
    chars['v'] = .{ .pos = 144 };
    chars['w'] = .{ .pos = 147 };
    chars['x'] = .{ .pos = 152 };
    chars['y'] = .{ .pos = 155 };
    chars['z'] = .{ .pos = 158 };
    chars['['] = .{ .pos = 161, .width = 2 };
    chars['\\'] = .{ .pos = 163, .width = 3 };
    chars[']'] = .{ .pos = 166, .width = 2 };
    chars['^'] = .{ .pos = 168 };
    chars['_'] = .{ .pos = 171 };
    chars['а'] = .{ .pos = 174 };
    chars['б'] = .{ .pos = 177 };
    chars['в'] = .{ .pos = 180 };
    chars['г'] = .{ .pos = 183 };
    chars['д'] = .{ .pos = 186, .width = 5 };
    chars['е'] = .{ .pos = 191 };
    chars['ё'] = .{ .pos = 194 };
    chars['ж'] = .{ .pos = 197, .width = 5 };
    chars['з'] = .{ .pos = 202 };
    chars['и'] = .{ .pos = 205, .width = 4 };
    chars['й'] = .{ .pos = 209, .width = 4 };
    chars['к'] = .{ .pos = 213 };
    chars['л'] = .{ .pos = 216 };
    chars['м'] = .{ .pos = 219, .width = 5 };
    chars['н'] = .{ .pos = 224 };
    chars['о'] = .{ .pos = 227 };
    chars['п'] = .{ .pos = 230 };
    chars['р'] = .{ .pos = 233 };
    chars['с'] = .{ .pos = 236 };
    chars['т'] = .{ .pos = 239 };
    chars['у'] = .{ .pos = 242 };
    chars['ф'] = .{ .pos = 245, .width = 5 };
    chars['х'] = .{ .pos = 250 };
    chars['ц'] = .{ .pos = 253 };
    chars['ч'] = .{ .pos = 256 };
    chars['ш'] = .{ .pos = 259, .width = 5 };
    chars['щ'] = .{ .pos = 264, .width = 5 };
    chars['ъ'] = .{ .pos = 269, .width = 4 };
    chars['ы'] = .{ .pos = 273, .width = 5 };
    chars['ь'] = .{ .pos = 278 };
    chars['э'] = .{ .pos = 281, .width = 4 };
    chars['ю'] = .{ .pos = 285, .width = 5 };
    chars['я'] = .{ .pos = 290 };

    return .{
        .chars = chars,
    };
}
