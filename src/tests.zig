const std = @import("std");
const testing = std.testing;

test "allocated sentinel" {
    const src = "test";
    const dest = try testing.allocator.allocSentinel(u8, src.len, 0);
    defer testing.allocator.free(dest);
    const fromC = try testing.allocator.alloc(u8, src.len + 1);
    defer testing.allocator.free(fromC);

    //const cptr: [*]u8 = fromC.ptr;
    //var cptr_slice = cptr[0..src.len :0];
    //std.mem.copy(u8, cptr_slice, src);

    try testing.expect(dest.len == 4);
    try testing.expect(fromC.len == 5);
    std.mem.copy(u8, dest, src);
    try testing.expect(src.len == 4);
    try testing.expect(dest.len == 4);
    try testing.expect(src[4] == 0);
    try testing.expect(dest[4] == 0);
}

test "Stage2 [*c] coerce" {
    const slice0: [:0]const u8 = "hello there";
    try testing.expect(@TypeOf(slice0) == [:0]const u8);

    // STAGE1 vs STAGE2
    // This worked in stage1, but is now a compile error in stage2
    // const cptr: [*c]const u8 = slice0;
    // try testing.expect(@TypeOf(cptr) == [*c]const u8);

    // This works in either
    const cptr: [*c]const u8 = slice0.ptr;
    try testing.expect(@TypeOf(cptr) == [*c]const u8);
}
