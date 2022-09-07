const std = @import("std");
const ri = @import("ri.zig");
const noise = @import("noise.zig");

pub export fn Subdivide2(
    ctx: *anyopaque,
    detail: ri.Float,
    n: ri.Int,
    toks: [*]ri.Token,
    vals: [*]ri.Pointer,
) void {
    _ = ctx;
    _ = detail;

    var prng = std.rand.DefaultPrng.init(42);
    const rand = prng.random();

    var num_points: i32 = 5000;

    for (toks[0..@intCast(usize, n)]) |_, i| {
        var tok = toks[i] orelse continue;
        var val = vals[i] orelse continue;
        var iter = std.mem.split(u8, std.mem.span(tok), " ");
        var token_type = iter.next() orelse continue;
        var token_name = iter.next() orelse continue;
        if (std.mem.eql(u8, token_type, "int") and
            std.mem.eql(u8, token_name, "num_points"))
        {
            num_points = @ptrCast(*i32, @alignCast(@alignOf(i32), val)).*;
        }
    }

    const P_token: ri.Token = "P";
    const falloff_token: ri.Token = "constant float falloffpower";
    const width_token: ri.Token = "varying float width";
    const ids_token: ri.Token = "varying float id";

    var tokens = [4]ri.Token{ P_token, width_token, falloff_token, ids_token };
    var values: [4]ri.Pointer = .{null} ** 4;
    var falloff: ri.Float = 1.0;

    const allocator = std.heap.page_allocator;
    var pts = allocator.alloc(ri.Point, @intCast(usize, num_points)) catch return;
    defer allocator.free(pts);
    var ids = allocator.alloc(f32, @intCast(usize, num_points)) catch return;
    defer allocator.free(ids);
    var widths = allocator.alloc(f32, @intCast(usize, num_points)) catch return;
    defer allocator.free(widths);

    for (pts) |*pt, x| {
        var x_pos: ri.Float = (rand.float(ri.Float) - 0.5) * 10;
        var y_pos: ri.Float = rand.float(ri.Float);
        var z_pos: ri.Float = (rand.float(ri.Float) - 0.5) * 10;
        pt.* = ri.Point{
            x_pos,
            //(@cos(x_pos * std.math.pi) + y_pos) * 0.2,
            @floatCast(f32, (noise.improvedPerlin(x_pos, 0.5, z_pos) + y_pos) * 0.225),
            z_pos,
        };
        ids[x] = @intToFloat(f32, x);
        widths[x] = rand.float(ri.Float) * 0.0025 + 0.005;
    }
    values[0] = @as(ri.Pointer, pts.ptr);
    values[1] = @as(ri.Pointer, widths.ptr);
    values[2] = @as(ri.Pointer, &falloff);
    values[3] = @as(ri.Pointer, ids.ptr);
    ri.RiPointsV(num_points, tokens.len, &tokens, &values);
}
