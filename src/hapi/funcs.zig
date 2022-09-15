const types = @import("types.zig");

pub const ResultError = error{
    Failure,
    AlreadyInitialized,
    NotInitialized,
    CantLoadFile,
    ParmSetFailed,
    InvalidArgument,
    CantLoadGeo,
    CantGeneratePreset,
    CantLoadPreset,
    AssetDefAlreadyLoaded,
    NoLicenseFound,
    DisallowedNCLicenseFound,
    DisallowedNCAssetWithCLicenseFound,
    DisallowedNCAssetWithLCLicenseFound,
    DisallowedLCAssetWithCLicenseFound,
    DisallowedHEngineIndieW3PartyPlugin,
    AssetInvalid,
    NodeInvalid,
    UserInterrupted,
    InvalidSession,
};

inline fn resultToError(result: types.Result) ResultError {
    switch (result) {
        .failure => return ResultError.Failure,
        .already_initialized => return ResultError.AlreadyInitialized,
        .not_initialized => return ResultError.NotInitialized,
        .cant_loadfile => return ResultError.CantLoadFile,
        .parm_set_failed => return ResultError.ParmSetFailed,
        .invalid_argument => return ResultError.InvalidArgument,
        .cant_load_geo => return ResultError.CantLoadGeo,
        .cant_generate_preset => return ResultError.CantGeneratePreset,
        .cant_load_preset => return ResultError.CantLoadPreset,
        .asset_def_already_loaded => return ResultError.AssetDefAlreadyLoaded,
        .no_license_found => return ResultError.NoLicenseFound,
        .disallowed_nc_license_found => return ResultError.DisallowedNCLicenseFound,
        .disallowed_nc_asset_with_c_license_found => return ResultError.DisallowedNCAssetWithCLicenseFound,
        .disallowed_nc_asset_with_lc_license_found => return ResultError.DisallowedNCAssetWithLCLicenseFound,
        .disallowed_lc_asset_with_c_license_found => return ResultError.DisallowedLCAssetWithCLicenseFound,
        .disallowed_hengine_indie_w_3party_plugin => return ResultError.DisallowedHEngineIndieW3PartyPlugin,
        .asset_invalid => return ResultError.AssetInvalid,
        .node_invalid => return ResultError.NodeInvalid,
        .user_interrupted => return ResultError.UserInterrupted,
        .invalid_session => return ResultError.InvalidSession,
        else => unreachable,
    }
}

extern fn HAPI_CreateInProcessSession(session: *types.Session) types.Result;
pub fn createInProcessSession() ResultError!types.Session {
    var session: types.Session = undefined;
    var result = HAPI_CreateInProcessSession(&session);
    switch (result) {
        .success => return session,
        else => return resultToError(result),
    }
}

extern fn HAPI_IsInitialized(session: *const types.Session) types.Result;
pub fn isInitialized(session: types.Session) bool {
    switch (HAPI_IsInitialized(&session)) {
        .success => return true,
        .not_initialized => return false,
        else => unreachable,
    }
}

extern fn HAPI_Initialize(
    session: *types.Session,
    cook_options: *types.CookOptions,
    use_cooking_thread: bool,
    cooking_stack_size: i32,
    houdini_environment_files: ?[*]const u8,
    otl_search_path: ?[*]const u8,
    dso_search_path: ?[*]const u8,
    image_dso_search_path: ?[*]const u8,
    audio_dso_search_path: ?[*]const u8,
) types.Result;

pub fn initialize(
    session: *types.Session,
    cook_options: *types.CookOptions,
    use_cooking_thread: bool,
    cooking_stack_size: i32,
    houdini_environment_files: ?[:0]const u8,
    otl_search_path: ?[:0]const u8,
    dso_search_path: ?[:0]const u8,
    image_dso_search_path: ?[:0]const u8,
    audio_dso_search_path: ?[:0]const u8,
) ResultError!void {
    switch (HAPI_Initialize(
        session,
        cook_options,
        use_cooking_thread,
        cooking_stack_size,
        // This is ick
        if (houdini_environment_files) |v| v.ptr else null,
        if (otl_search_path) |v| v.ptr else null,
        if (dso_search_path) |v| v.ptr else null,
        if (image_dso_search_path) |v| v.ptr else null,
        if (audio_dso_search_path) |v| v.ptr else null,
    )) {
        .success => return,
        else => unreachable,
    }
}

extern fn HAPI_Cleanup(session: *const types.Session) types.Result;

pub fn cleanup(session: types.Session) ResultError!void {
    switch (HAPI_Cleanup(&session)) {
        .success => return,
        else => |result| return resultToError(result),
    }
}

extern fn HAPI_Shutdown(session: *const types.Session) types.Result;

pub fn shutdown(session: types.Session) ResultError!void {
    switch (HAPI_Shutdown(&session)) {
        .success => return,
        else => |result| return resultToError(result),
    }
}

extern fn HAPI_CloseSession(session: *types.Session) types.Result;

pub fn closeSession(session: *types.Session) ResultError!void {
    switch (HAPI_CloseSession(session)) {
        .success => return,
        else => |result| return resultToError(result),
    }
}

extern fn HAPI_LoadAssetLibraryFromFile(
    session: *const types.Session,
    file_path: [*]const u8,
    allow_overwrite: bool,
    library_id: *types.AssetLibraryId,
) types.Result;

pub fn loadAssetLibraryFromFile(
    session: types.Session,
    file_path: [:0]const u8,
    allow_overwrite: bool,
) ResultError!types.AssetLibraryId {
    var asset_library_id: types.AssetLibraryId = undefined;
    switch (HAPI_LoadAssetLibraryFromFile(&session, file_path.ptr, allow_overwrite, &asset_library_id)) {
        .success => return asset_library_id,
        else => |result| return resultToError(result),
    }
}

extern fn HAPI_GetAvailableAssetCount(
    session: *const types.Session,
    library_id: types.AssetLibraryId,
    asset_count: *i32,
) types.Result;

pub fn getAvailableAssetCount(
    session: types.Session,
    library_id: types.AssetLibraryId,
) ResultError!usize {
    var asset_count: i32 = undefined;
    switch (HAPI_GetAvailableAssetCount(&session, library_id, &asset_count)) {
        .success => return @intCast(usize, asset_count),
        else => |result| return resultToError(result),
    }
}

extern fn HAPI_GetAvailableAssets(
    session: *const types.Session,
    library_id: types.AssetLibraryId,
    asset_names_array: [*]types.StringHandle,
    asset_count: i32,
) types.Result;

pub fn getAvailableAssets(
    session: types.Session,
    library_id: types.AssetLibraryId,
    asset_name_handles: []types.StringHandle,
) ResultError!void {
    // do we assert that asset_name_handles.len <= GetAvailableAssetCount ?
    switch (HAPI_GetAvailableAssets(
        &session,
        library_id,
        asset_name_handles.ptr,
        @intCast(i32, asset_name_handles.len),
    )) {
        .success => return,
        else => |result| return resultToError(result),
    }
}

extern fn HAPI_GetStringBufLength(
    session: *const types.Session,
    string_handle: types.StringHandle,
    buffer_length: *i32,
) types.Result;

pub fn getStringBufLength(
    session: types.Session,
    string_handle: types.StringHandle,
) ResultError!usize {
    var buffer_length: i32 = undefined;
    switch (HAPI_GetStringBufLength(&session, string_handle, &buffer_length)) {
        .success => return @intCast(usize, buffer_length),
        else => |result| return resultToError(result),
    }
}

extern fn HAPI_GetString(
    session: *const types.Session,
    string_handle: types.StringHandle,
    string_value: [*]u8,
    len: i32,
) types.Result;

pub fn getString(
    session: types.Session,
    string_handle: types.StringHandle,
    string_value: []u8,
) ResultError!void {
    switch (HAPI_GetString(&session, string_handle, string_value.ptr, @intCast(i32, string_value.len))) {
        .success => return,
        else => |result| return resultToError(result),
    }
}

extern fn HAPI_CreateNode(
    session: *const types.Session,
    parent_node_id: types.NodeId,
    operator_name: [*]const u8,
    node_label: ?[*]const u8,
    cook_on_creation: bool,
    new_node_id: *types.NodeId,
) types.Result;
pub fn createNode(
    session: types.Session,
    parent_node_id: types.NodeId,
    operator_name: []const u8,
    node_label: ?[]const u8,
    cook_on_creation: bool,
) ResultError!types.NodeId {
    var new_node_id: types.NodeId = undefined;
    switch (HAPI_CreateNode(
        &session,
        parent_node_id,
        operator_name.ptr,
        if (node_label) |v| v.ptr else null,
        cook_on_creation,
        &new_node_id,
    )) {
        .success => return new_node_id,
        else => |result| return resultToError(result),
    }
}

extern fn HAPI_GetParmInfoFromName(
    session: *const types.Session,
    node_id: types.NodeId,
    parm_name: [*]const u8,
    parm_info: *types.ParmInfo,
) types.Result;

pub fn getParmInfoFromName(
    session: types.Session,
    node_id: types.NodeId,
    parm_name: []const u8,
) ResultError!types.ParmInfo {
    var parm_info: types.ParmInfo = undefined;
    switch (HAPI_GetParmInfoFromName(
        &session,
        node_id,
        parm_name.ptr,
        &parm_info,
    )) {
        .success => return parm_info,
        else => |result| return resultToError(result),
    }
}

extern fn HAPI_SetParmStringValue(
    session: *const types.Session,
    node_id: types.NodeId,
    value: [*]const u8,
    parm_id: types.ParmId,
    index: i32,
) types.Result;

pub fn setParmStringValue(
    session: types.Session,
    node_id: types.NodeId,
    value: []const u8,
    parm_id: types.ParmId,
    index: i32,
) ResultError!void {
    switch (HAPI_SetParmStringValue(
        &session,
        node_id,
        value.ptr,
        parm_id,
        index,
    )) {
        .success => return,
        else => |result| return resultToError(result),
    }
}

extern fn HAPI_SetParmIntValue(
    session: *const types.Session,
    node_id: types.NodeId,
    parm_name: [*]const u8,
    index: i32,
    value: i32,
) types.Result;

pub fn setParmIntValue(
    session: types.Session,
    node_id: types.NodeId,
    parm_name: []const u8,
    index: i32,
    value: i32,
) ResultError!void {
    switch (HAPI_SetParmIntValue(
        &session,
        node_id,
        parm_name.ptr,
        index,
        value,
    )) {
        .success => return,
        else => |result| return resultToError(result),
    }
}

extern fn HAPI_SetParmFloatValue(
    session: *const types.Session,
    node_id: types.NodeId,
    parm_name: [*]const u8,
    index: i32,
    value: f32,
) types.Result;

pub fn setParmFloatValue(
    session: types.Session,
    node_id: types.NodeId,
    parm_name: []const u8,
    index: i32,
    value: f32,
) ResultError!void {
    switch (HAPI_SetParmFloatValue(
        &session,
        node_id,
        parm_name.ptr,
        index,
        value,
    )) {
        .success => return,
        else => |result| return resultToError(result),
    }
}

extern fn HAPI_CookNode(
    session: *const types.Session,
    node_id: types.NodeId,
    cook_options: ?*const types.CookOptions,
) types.Result;
pub fn cookNode(
    session: types.Session,
    node_id: types.NodeId,
    cook_options: ?types.CookOptions,
) ResultError!void {
    switch (HAPI_CookNode(
        &session,
        node_id,
        if (cook_options) |v| &v else null,
    )) {
        .success => return,
        else => |result| return resultToError(result),
    }
}

extern fn HAPI_GetStatus(
    session: *const types.Session,
    status_type: types.StatusType,
    status: *i32,
) types.Result;
pub fn getStatus(
    session: types.Session,
    status_type: types.StatusType,
) ResultError!types.Status {
    var status: i32 = undefined;
    switch (HAPI_GetStatus(
        &session,
        status_type,
        &status,
    )) {
        .success => {
            return switch (status_type) {
                .call_result => types.Status{ .call_result = @intToEnum(types.Result, status) },
                .cook_result => types.Status{ .cook_result = @intToEnum(types.Result, status) },
                .cook_state => types.Status{ .cook_state = @intToEnum(types.State, status) },
                else => unreachable,
            };
        },
        else => |result| return resultToError(result),
    }
}

extern fn HAPI_GetDisplayGeoInfo(
    session: *const types.Session,
    object_node_id: types.NodeId,
    geo_info: *types.GeoInfo,
) types.Result;
pub fn getDisplayGeoInfo(
    session: types.Session,
    object_node_id: types.NodeId,
) ResultError!types.GeoInfo {
    var geo_info: types.GeoInfo = undefined;
    switch (HAPI_GetDisplayGeoInfo(
        &session,
        object_node_id,
        &geo_info,
    )) {
        .success => return geo_info,
        else => |result| return resultToError(result),
    }
}

extern fn HAPI_GetPartInfo(
    session: *const types.Session,
    node_id: types.NodeId,
    part_id: types.PartId,
    part_info: *types.PartInfo,
) types.Result;
pub fn getPartInfo(
    session: types.Session,
    node_id: types.NodeId,
    part_id: types.PartId,
) ResultError!types.PartInfo {
    var part_info: types.PartInfo = undefined;
    switch (HAPI_GetPartInfo(
        &session,
        node_id,
        part_id,
        &part_info,
    )) {
        .success => return part_info,
        else => |result| return resultToError(result),
    }
}

extern fn HAPI_GetAttributeInfo(
    session: *const types.Session,
    node_id: types.NodeId,
    part_id: types.PartId,
    name: [*]const u8,
    owner: types.AttributeOwner,
    attr_info: *types.AttributeInfo,
) types.Result;
pub fn getAttributeInfo(
    session: types.Session,
    node_id: types.NodeId,
    part_id: types.PartId,
    name: []const u8,
    owner: types.AttributeOwner,
) ResultError!types.AttributeInfo {
    var attr_info: types.AttributeInfo = undefined;
    switch (HAPI_GetAttributeInfo(
        &session,
        node_id,
        part_id,
        name.ptr,
        owner,
        &attr_info,
    )) {
        .success => return attr_info,
        else => |result| return resultToError(result),
    }
}

extern fn HAPI_GetAttributeFloatData(
    session: *const types.Session,
    node_id: types.NodeId,
    part_id: types.PartId,
    name: [*]const u8,
    attr_info: *types.AttributeInfo,
    stride: i32,
    data_array: [*]f32,
    start: i32,
    length: i32,
) types.Result;
pub fn getAttributeFloatData(
    session: types.Session,
    node_id: types.NodeId,
    part_id: types.PartId,
    name: [*]const u8,
    attr_info: *types.AttributeInfo,
    stride: i32,
    data_array: []f32,
    start: i32,
    length: i32,
) ResultError!void {
    switch (HAPI_GetAttributeFloatData(
        &session,
        node_id,
        part_id,
        name,
        attr_info,
        stride,
        data_array.ptr,
        start,
        length,
    )) {
        .success => return,
        else => |result| return resultToError(result),
    }
}

extern fn HAPI_CookOptions_Init(in: *types.CookOptions) void;
pub const cookOptionsInit = HAPI_CookOptions_Init;
extern fn HAPI_CookOptions_Create() types.CookOptions;
pub const cookOptionsCreate = HAPI_CookOptions_Create;
extern fn HAPI_CookOptions_AreEqual(left: *const types.CookOptions, right: *const types.CookOptions) bool;
pub fn cookOptionsAreEqual(left: types.CookOptions, right: types.CookOptions) bool {
    return HAPI_CookOptions_AreEqual(&left, &right);
}

//    result = c.HAPI_GetAttributeFloatData(&session,node_id,part_id,name.ptr,&attrib_info,-1,fdata.ptr,0,attrib_info.count);
