const getty = @import("../../../lib.zig");
const std = @import("std");

pub fn Visitor(comptime Slice: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace getty.de.Visitor(
            Self,
            Value,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            visitSeq,
            undefined,
            visitString,
            undefined,
            undefined,
        );

        const Value = Slice;

        fn visitSeq(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            var list = std.ArrayList(Child).init(allocator.?);
            errdefer getty.de.free(allocator.?, list);

            while (try seq.nextElement(allocator, Child)) |elem| {
                try list.append(elem);
            }

            return list.toOwnedSlice();
        }

        fn visitString(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
            if (Child != u8) return error.InvalidType;

            const sentinel = @typeInfo(Value).Pointer.sentinel;

            const output = try allocator.?.alloc(u8, input.len + @boolToInt(sentinel != null));
            std.mem.copy(u8, output, input);

            if (sentinel) |s| {
                const sentinel_char = @ptrCast(*const u8, s).*;
                output[input.len] = sentinel_char;
                return output[0..input.len :sentinel_char];
            }

            return output;
        }

        const Child = std.meta.Child(Value);
    };
}
