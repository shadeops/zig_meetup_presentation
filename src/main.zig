const std = @import("std");
const hapi = @import("hapi.zig");

pub fn main() !void {
    var session = try hapi.createInProcessSession();

    var cook_options = hapi.CookOptions.create();
    try hapi.initialize(&session, &cook_options, false, -1, null, null, null, null, null);
    defer {
        if (hapi.isInitialized(session)) {
            hapi.cleanup(session) catch std.debug.print("cleanup failed\n", .{});
            hapi.shutdown(session) catch std.debug.print("shutdown failed\n", .{});
            hapi.closeSession(&session) catch std.debug.print("closeSession failed\n", .{});
        }
    }

    var asset_library_id = try hapi.loadAssetLibraryFromFile(session, "otls/test_asset.hdalc", false);
    var num_assets = try hapi.getAvailableAssetCount(session, asset_library_id);

    var handle_buf = [_]hapi.StringHandle{0} ** 16;
    var string_buf = [_]u8{0} ** 256;
    var handles: []hapi.StringHandle = undefined;
    var string: []u8 = undefined;

    handles = handle_buf[0..num_assets];

    try hapi.getAvailableAssets(session, asset_library_id, handles);
    var string_len = try hapi.getStringBufLength(session, handles[0]);
    string = string_buf[0..string_len];
    try hapi.getString(session, handles[0], string);

    var node_id = try hapi.createNode(session, -1, string, null, false);

    var parm_info = try hapi.getParmInfoFromName(session, node_id, "str_parm");
    try hapi.setParmStringValue(session, node_id, "hello", parm_info.id, 0);
    try hapi.setParmIntValue(session, node_id, "int_parm", 0, 42);
    try hapi.setParmFloatValue(session, node_id, "flt_parm", 0, 42.0);
    try hapi.setParmFloatValue(session, node_id, "clr_parm", 2, 42.0);

    try hapi.cookNode(session, node_id, null);

    // DEMO
    //while (!@intToEnum(hapi.State, hapi.getStatus(session, .cook_result) catch return).isReady()) {
    while (!(hapi.getStatus(session, .cook_state) catch return).cook_state.isReady()) {
        std.time.sleep(30 * std.time.ns_per_ms);
    }

    var geo_info = try hapi.getDisplayGeoInfo(session, node_id);
    _ = geo_info;
    var part_id: hapi.PartId = 0;
    var part_info = try hapi.getPartInfo(session, node_id, part_id);
    _ = part_info;
    var attr_info = try hapi.getAttributeInfo(session, node_id, part_id, "P", .point);
    var fbuffer = [_]f32{0.0} ** 3;
    var fdata: []f32 = &fbuffer;
    try hapi.getAttributeFloatData(session, node_id, part_id, "P", &attr_info, -1, fdata, 0, attr_info.count);

    std.debug.print("{any}\n", .{fdata});
}
