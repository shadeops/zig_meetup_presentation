const std = @import("std");
const ri = @import("ri.zig");

const c = @cImport({
    @cInclude("HAPI/HAPI.h");
});

const pipe_name = "zig_engine";

fn hasAsset(
    allocator: std.mem.Allocator,
    session: *const c.HAPI_Session,
    library_id: c.HAPI_AssetLibraryId,
    asset_name: [:0]const u8,
) bool {
    var result: c.HAPI_Result = undefined;
    var asset_count: i32 = undefined;

    result = c.HAPI_GetAvailableAssetCount(session, library_id, &asset_count);

    if (result > c.HAPI_RESULT_SUCCESS or asset_count == 0) return false;

    var name_handles = allocator.alloc(
        c.HAPI_StringHandle,
        @intCast(usize, asset_count),
    ) catch return false;

    result = c.HAPI_GetAvailableAssets(session, library_id, name_handles.ptr, asset_count);
    // Assume our asset names (including \0) will be less than 128 chars
    var buffer: [128]u8 = undefined;

    for (name_handles) |handle| {
        var name_len: i32 = undefined;
        result = c.HAPI_GetStringBufLength(session, handle, &name_len);
        std.debug.assert(name_len <= buffer.len);
        result = c.HAPI_GetString(session, handle, &buffer, name_len);

        // name_len includes \0
        var name = buffer[0 .. @intCast(usize, name_len) - 1 :0];
        if (std.mem.eql(u8, name, asset_name)) return true;
    }
    return false;
}

pub export fn Subdivide2(
    ctx: *anyopaque,
    detail: ri.Float,
    num_tokens: ri.Int,
    toks: [*]ri.Token,
    vals: [*]ri.Pointer,
) void {
    _ = ctx;
    _ = detail;

    var otl_path: [:0]const u8 = "";
    var asset_name: [:0]const u8 = "";

    for (toks[0..@intCast(usize, num_tokens)]) |_, tok_i| {
        var tok = toks[tok_i] orelse continue;
        var val = vals[tok_i] orelse continue;
        var iter = std.mem.split(u8, std.mem.span(tok), " ");
        var token_type = iter.next() orelse continue;
        var token_name = iter.next() orelse continue;
        if (std.mem.eql(u8, token_type, "string") and
            std.mem.eql(u8, token_name, "otl_path"))
        {
            var ptr = @ptrCast(?*const ri.Token, @alignCast(@alignOf(ri.Token), val)) orelse continue;
            otl_path = std.mem.span(ptr.*) orelse continue;
        } else if (std.mem.eql(u8, token_type, "string") and
            std.mem.eql(u8, token_name, "asset_name"))
        {
            var ptr = @ptrCast(?*const ri.Token, @alignCast(@alignOf(ri.Token), val)) orelse continue;
            asset_name = std.mem.span(ptr.*) orelse continue;
        }
    }

    if (otl_path.len == 0) {
        std.debug.print("Missing otl_path\n", .{});
        return;
    }

    if (asset_name.len == 0) {
        std.debug.print("Missing asset_name\n", .{});
        return;
    }

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var session: c.HAPI_Session = undefined;
    var result: c.HAPI_Result = undefined;

    const in_process = true;

    if (in_process) {
        // In Houdini 19.0 there is an issue where an In Process Session will crash if not Shutdown()
        // (which was added in 19.0.507).
        // However there is still a lingering bug (fixed in 19.5) where the Shutdown method will crash
        // if linked against HAPIL. Linking against HAPI is fine.
        result = c.HAPI_CreateInProcessSession(&session);
    } else {
        const thrift_options = c.HAPI_ThriftServerOptions{ .autoClose = 1, .timeoutMs = 3000.0 };
        result = c.HAPI_StartThriftNamedPipeServer(&thrift_options, pipe_name, null);
        result = c.HAPI_CreateThriftNamedPipeSession(&session, pipe_name);
    }

    var cook_options = c.HAPI_CookOptions_Create();
    result = c.HAPI_Initialize(&session, &cook_options, 1, -1, null, null, null, null, null);
    defer {
        result = c.HAPI_Cleanup(&session);
        if (in_process) result = c.HAPI_Shutdown(&session);
        result = c.HAPI_CloseSession(&session);
    }

    var library_id: c.HAPI_AssetLibraryId = undefined;
    result = c.HAPI_LoadAssetLibraryFromFile(&session, otl_path.ptr, 1, &library_id);
    if (!hasAsset(allocator, &session, library_id, asset_name)) {
        std.debug.print("Asset does not exist\n", .{});
        return;
    }

    var node_id: c.HAPI_NodeId = undefined;
    result = c.HAPI_CreateNode(&session, -1, asset_name.ptr, null, 0, &node_id);
    std.debug.print("result: {}\n", .{result});

    // Apply parameters
    for (toks[0..@intCast(usize, num_tokens)]) |_, tok_i| {
        var tok = toks[tok_i] orelse continue;
        var val = vals[tok_i] orelse continue;
        var iter = std.mem.split(u8, std.mem.span(tok), " ");
        var token_type = iter.next() orelse continue;
        var token_name = iter.next() orelse continue;

        var parm_info: c.HAPI_ParmInfo = undefined;
        result = c.HAPI_GetParmInfoFromName(&session, node_id, token_name.ptr, &parm_info);
        if (result > c.HAPI_RESULT_SUCCESS) continue;

        std.debug.print("{s}: ", .{token_name});
        if (std.mem.eql(u8, token_type, "string")) {
            std.debug.print("string\n", .{});
            var ptr = @ptrCast(?*const ri.Token, @alignCast(@alignOf(ri.Token), val)) orelse continue;
            if (parm_info.type >= c.HAPI_PARMTYPE_STRING_START and parm_info.type <= c.HAPI_PARMTYPE_STRING_END and parm_info.size == 1) {
                result = c.HAPI_SetParmStringValue(&session, node_id, ptr.*, parm_info.id, 0);
            }
        } else if (std.mem.eql(u8, token_type, "int")) {
            std.debug.print("int\n", .{});
            var ptr = @ptrCast(?*const i32, @alignCast(@alignOf(i32), val)) orelse continue;
            if (parm_info.type >= c.HAPI_PARMTYPE_INT_START and parm_info.type <= c.HAPI_PARMTYPE_INT_END and parm_info.size == 1) {
                result = c.HAPI_SetParmIntValue(&session, node_id, token_name.ptr, 0, ptr.*);
            }
        } else if (std.mem.eql(u8, token_type, "float")) {
            std.debug.print("float\n", .{});
            var ptr = @ptrCast(?*const f32, @alignCast(@alignOf(f32), val)) orelse continue;
            if (parm_info.type == c.HAPI_PARMTYPE_FLOAT and parm_info.size == 1) {
                result = c.HAPI_SetParmFloatValue(&session, node_id, token_name.ptr, 0, ptr.*);
            }
        } else if (std.mem.eql(u8, token_type, "point") or
            std.mem.eql(u8, token_type, "vector") or
            std.mem.eql(u8, token_type, "normal") or
            std.mem.eql(u8, token_type, "color"))
        {
            std.debug.print("float[3]\n", .{});
            var ptr = @ptrCast(?*const [3]f32, @alignCast(@alignOf(f32), val)) orelse continue;
            if (parm_info.type >= c.HAPI_PARMTYPE_FLOAT_START and parm_info.type <= c.HAPI_PARMTYPE_FLOAT_END and parm_info.size == 3) {
                for (ptr.*) |v, i| {
                    result = c.HAPI_SetParmFloatValue(&session, node_id, token_name.ptr, @intCast(i32, i), v);
                }
            }
        } else {
            std.debug.print("unknown\n", .{});
            continue;
        }
    }

    result = c.HAPI_CookNode(&session, node_id, &cook_options);

    var cook_result: c.HAPI_Result = c.HAPI_RESULT_SUCCESS;
    var cook_status = c.HAPI_STATE_MAX;
    while (cook_status > c.HAPI_STATE_MAX_READY_STATE and cook_result == c.HAPI_RESULT_SUCCESS) {
        // In the HAPI examples there is no sleep but instead of repeatedly checking we can
        // wait for what is considered a "fast" cook.
        std.time.sleep(30 * std.time.ns_per_ms);
        cook_result = c.HAPI_GetStatus(
            &session,
            c.HAPI_STATUS_COOK_STATE,
            &cook_status,
        );
    }

    var part_id: c.HAPI_PartId = 0;

    var geo_info: c.HAPI_GeoInfo = undefined;
    result = c.HAPI_GetDisplayGeoInfo(&session, node_id, &geo_info);
    std.debug.print("Part count: {}\n", .{geo_info.partCount});

    var part_info: c.HAPI_PartInfo = undefined;
    result = c.HAPI_GetPartInfo(&session, node_id, part_id, &part_info);

    if (part_info.pointCount == 0) {
        std.debug.print("Warning no points in geometry\n", .{});
        return;
    }
    std.debug.print("Point count: {}\n", .{part_info.pointCount});

    var attrib_names = allocator.alloc(
        c.HAPI_StringHandle,
        @intCast(usize, part_info.attributeCounts[c.HAPI_ATTROWNER_POINT]),
    ) catch return;

    result = c.HAPI_GetAttributeNames(
        &session,
        node_id,
        part_id,
        c.HAPI_ATTROWNER_POINT,
        attrib_names.ptr,
        part_info.attributeCounts[c.HAPI_ATTROWNER_POINT],
    );

    var tokens = std.ArrayList(ri.Token).init(allocator);
    var values = std.ArrayList(ri.Pointer).init(allocator);

    for (attrib_names) |handle| {
        var buf_len: i32 = undefined;

        result = c.HAPI_GetStringBufLength(&session, handle, &buf_len);
        var name = allocator.allocSentinel(
            u8,
            @intCast(usize, buf_len - 1),
            0,
        ) catch continue;

        result = c.HAPI_GetString(&session, handle, name.ptr, buf_len);

        if (std.mem.startsWith(u8, name, "__")) continue;

        var attrib_info: c.HAPI_AttributeInfo = undefined;
        result = c.HAPI_GetAttributeInfo(
            &session,
            node_id,
            part_id,
            name.ptr,
            c.HAPI_ATTROWNER_POINT,
            &attrib_info,
        );
        // Skip array attributes (f[]@name vs v@name)
        if (attrib_info.totalArrayElements > 0)
            continue;
        // Only support float PODs for now
        if (attrib_info.storage != c.HAPI_STORAGETYPE_FLOAT)
            continue;

        var rtype: [:0]const u8 = undefined;
        const qualifier = "varying";

        switch (attrib_info.typeInfo) {
            c.HAPI_ATTRIBUTE_TYPE_NONE => rtype = "float",
            c.HAPI_ATTRIBUTE_TYPE_POINT => rtype = "point",
            c.HAPI_ATTRIBUTE_TYPE_VECTOR => rtype = "vector",
            c.HAPI_ATTRIBUTE_TYPE_NORMAL => rtype = "normal",
            c.HAPI_ATTRIBUTE_TYPE_COLOR => rtype = "color",
            else => continue,
        }

        var fdata = allocator.alloc(
            f32,
            @intCast(usize, attrib_info.count * attrib_info.tupleSize),
        ) catch continue;

        result = c.HAPI_GetAttributeFloatData(
            &session,
            node_id,
            part_id,
            name.ptr,
            &attrib_info,
            -1,
            fdata.ptr,
            0,
            attrib_info.count,
        );

        var rtoken: [:0]const u8 = undefined;
        if (std.mem.eql(u8, name, "P")) {
            // We set it to P instead of using name, since the name handle will expire next time
            // HAPI_GetAttributeNames is called.
            rtoken = "P";
        } else {
            rtoken = std.mem.joinZ(
                allocator,
                " ",
                &[_][:0]const u8{ qualifier, rtype, name },
            ) catch continue;
        }
        tokens.append(rtoken) catch continue;
        values.append(@ptrCast(ri.Pointer, fdata.ptr)) catch continue;
        std.debug.print("\t{s}\n", .{rtoken});
        std.debug.print("\tsize: {}\n", .{attrib_info.tupleSize});
    }

    ri.RiPointsV(
        part_info.pointCount,
        @intCast(i32, tokens.items.len),
        tokens.items.ptr,
        values.items.ptr,
    );
}
