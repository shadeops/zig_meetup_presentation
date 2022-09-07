pub const Float = f32;
pub const Point = [3]Float;
pub const Color = [3]Float;
pub const Int = i32;
pub const Token = ?[*:0]const u8;
pub const Pointer = ?*anyopaque;

pub const NULL: Pointer = null;

pub extern fn RiPoints(nverts: Int, ...) callconv(.C) void;
pub extern fn RiPointsV(nverts: Int, n: Int, nms: [*]Token, vals: [*]Pointer) callconv(.C) void;
pub extern fn RiSphere(radius: Float, zmin: Float, zmax: Float, tmax: Float, ...) callconv(.C) void;
