const Id = usize;

const Event = union(enum) {
    none,
    button: union(enum) {
        focused: Id,
        unfocused: Id,
        pressed: Id,
        unpressed: Id,
    },
    switcher: union(enum) {
        focused: Id,
        unfocused: Id,
        pressed: Id,
        unpressed: Id,
        switched: struct {
            id: Id,
            data: bool,
        },
    },
    slider: union(enum) {
        focused: Id,
        unfocused: Id,
        pressed: Id,
        unpressed: Id,
        scrolled: struct {
            id: Id,
            data: f32,
        },
    },
};

var items: [16]Event = undefined;
var current: usize = 0;
var current_event: usize = 0;

fn push(event: Event) void {
    items[current_event] = event;
    if (current_event < items.len - 1) {
        current_event += 1;
    } else {
        current_event = 0;
    }
}

fn pop() Event {
    if (current != current_event) {
        const e = items[current];
        if (current < items.len - 1) {
            current += 1;
        } else {
            current = 0;
        }
        return e;
    } else {
        return .none;
    }
}
