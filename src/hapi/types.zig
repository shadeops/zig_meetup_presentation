const funcs = @import("funcs.zig");

pub const SessionId = i64;
pub const StringHandle = i32;
pub const AssetLibraryId = i32;
pub const NodeId = i32;
pub const ParmId = i32;
pub const PartId = i32;

pub const StatusType = enum(u32) {
    call_result,
    cook_result,
    cook_state,
    max,
};

pub const Status = union(StatusType) {
    call_result: Result,
    cook_state: State,
    cook_result: Result,
    max: void,
};

pub const SessionType = enum(u32) {
    inprocess,
    thrift,
    custom1,
    custom2,
    custom3,
    max,
};

pub const State = enum(u32) {
    ready,
    ready_with_fatal_errors,
    ready_with_cook_errors,
    starting_cook,
    cooking,
    starting_load,
    loading,
    max,

    pub fn isReady(e: State) bool {
        switch (e) {
            .ready, .ready_with_fatal_errors, .ready_with_cook_errors => return true,
            else => return false,
        }
    }
};

pub const PackedPrimInstancingMode = enum(i32) {
    invalid = -1,
    disabled,
    hierarchy,
    flat,
    max,
};

pub const Result = enum(u32) {
    success = 0,
    failure = 1,
    already_initialized = 2,
    not_initialized = 3,
    cant_loadfile = 4,
    parm_set_failed = 5,
    invalid_argument = 6,
    cant_load_geo = 7,
    cant_generate_preset = 8,
    cant_load_preset = 9,
    asset_def_already_loaded = 10,

    no_license_found = 110,
    disallowed_nc_license_found = 120,
    disallowed_nc_asset_with_c_license_found = 130,
    disallowed_nc_asset_with_lc_license_found = 140,
    disallowed_lc_asset_with_c_license_found = 150,
    disallowed_hengine_indie_w_3party_plugin = 160,

    asset_invalid = 200,
    node_invalid = 210,
    user_interrupted = 300,
    invalid_session = 400,
};

pub const Permissions = enum(u32) {
    non_applicable,
    read_write,
    read_only,
    write_only,
    max,
};

pub const RampType = enum(i32) {
    invalid = -1,
    float,
    color,
    max,
};

pub const ParmType = enum(u32) {
    int = 0,
    multiparmlist,
    toggle,
    button,
    float,
    color,
    string,
    path_file,
    path_file_geo,
    path_file_image,
    node,
    folderlist,
    folderlist_radio,
    folder,
    label,
    separator,
    path_file_dir,
    max,

    // HAPI 4.2 has "helpers" in the form of
    // int_start = int
    // int_end = button
    // we'll duplicate the spirit of that using functions on the enum.

    // DEMO

    pub fn isInt(e: ParmType) bool {
        switch (e) {
            .int, .multiparmlist, .toggle, .button => return true,
            else => return false,
        }
    }

    pub fn isFloat(e: ParmType) bool {
        switch (e) {
            .float, .color => return true,
            else => return false,
        }
    }

    pub fn isString(e: ParmType) bool {
        // in HAPI 4.2, path_file_dir isn't considered a string (wrongly)
        switch (e) {
            .string, .path_file, .path_file_geo, .path_file_image, .path_file_dir => return true,
            else => return false,
        }
    }

    pub fn isPath(e: ParmType) bool {
        switch (e) {
            .node => return true,
            else => return false,
        }
    }

    pub fn isContainer(e: ParmType) bool {
        switch (e) {
            .folderlist, .folderlist_radio => return true,
            else => return false,
        }
    }

    pub fn isNonValue(e: ParmType) bool {
        switch (e) {
            .folder, .label, .separator => return true,
            else => return false,
        }
    }
};

pub const PrmScriptType = enum(u32) {
    int = 0,
    float,
    angle,
    string,
    file,
    directory,
    image,
    geometry,
    toggle,
    button,
    vector2,
    vector3,
    vector4,
    intvector2,
    intvector3,
    intvector4,
    uv,
    uvw,
    dir,
    color,
    color4,
    oppath,
    oplist,
    object,
    objectlist,
    render,
    separator,
    geometry_data,
    key_value_dict,
    label,
    rgbamask,
    ordinal,
    ramp_flt,
    ramp_rgb,
    float_log,
    int_log,
    data,
    float_minmax,
    int_minmax,
    int_startend,
    buttonstrip,
    iconstrip,
    groupradio = 1000,
    groupcollapsible,
    groupsimple,
    group,
};

pub const ChoiceListType = enum(u32) {
    none,
    normal,
    mini,
    replace,
    toggle,
};

// While this looks like a bit mask it isn't used as one
pub const NodeType = enum(i32) {
    // zig fmt: off
    any     = -1,
    none    = 0,
    obj     = 1 << 0,
    sop     = 1 << 1,
    chop    = 1 << 2,
    rop     = 1 << 3,
    shop    = 1 << 4,
    cop     = 1 << 5,
    vop     = 1 << 6,
    dop     = 1 << 7,
    top     = 1 << 8,
    // zig fmt: on
};

pub const NodeTypeBits = packed struct(u32) {
    obj: bool = false,
    sop: bool = false,
    chop: bool = false,
    rop: bool = false,
    shop: bool = false,
    cop: bool = false,
    vop: bool = false,
    dop: bool = false,
    top: bool = false,
};

pub const NodeFlags = enum(i32) {
    // zig fmt: off
    any                 = -1,
    none                = 0,
    display             = 1 << 0,
    render              = 1 << 1,
    templated           = 1 << 2,
    locked              = 1 << 3,
    editable            = 1 << 4,
    bypass              = 1 << 5,
    network             = 1 << 6,
    obj_geometry        = 1 << 7,
    obj_camera          = 1 << 8,
    obj_light           = 1 << 9,
    obj_subnet          = 1 << 10,
    sop_curve           = 1 << 11,
    sop_guide           = 1 << 12,
    top_nonscheduler    = 1 << 13,
    non_bypass          = 1 << 14,
    // zig fmt: on
};

pub const NodeFlagsBits = packed struct(u32) {
    any: bool = false,
    none: bool = false,
    display: bool = false,
    render: bool = false,
    templated: bool = false,
    locked: bool = false,
    editable: bool = false,
    bypass: bool = false,
    network: bool = false,
    obj_geometry: bool = false,
    obj_camera: bool = false,
    obj_light: bool = false,
    obj_subnet: bool = false,
    sop_curve: bool = false,
    sop_guide: bool = false,
    top_nonscheduler: bool = false,
    non_bypass: bool = false,
};

pub const AttributeOwner = enum(i32) {
    invalid = -1,
    vertex,
    point,
    prim,
    detail,
    max,
};

pub const StorageType = enum(i32) {
    invalid = -1,
    int,
    int64,
    float,
    float64,
    string,
    uint8,
    int8,
    int16,
    int_array,
    int64_array,
    float_array,
    float64_array,
    string_array,
    uint8_array,
    int8_array,
    int16_array,
    max,
};
pub const AttributeTypeInfo = enum(i32) {
    invalid = -1,
    none,
    point,
    hpoint,
    vector,
    normal,
    color,
    quaternion,
    matrix3,
    matrix,
    st,
    hidden,
    box2,
    box,
    texture,
    max,
};

pub const GeoType = enum(i32) {
    invalid = -1,
    default,
    intermediate,
    input,
    curve,
    max,
};

pub const PartType = enum(i32) {
    invalid = -1,
    mesh,
    curve,
    volume,
    instancer,
    box,
    sphere,
    max,
};

pub const CookOptions = extern struct {
    split_geos_by_group: bool,
    split_group_sh: StringHandle,
    split_geo_by_attribute: bool,
    split_attr_sh: StringHandle,
    max_vertices_per_primitive: i32,
    refine_curve_to_linear: bool,
    curve_refine_lod: f32,
    clear_errors_and_warnings: bool,
    cook_templated_geos: bool,
    split_points_by_vertex_attributes: bool,
    pack_prim_instancing_mode: PackedPrimInstancingMode,
    handle_box_part_types: bool,
    handle_sphere_part_types: bool,
    check_part_changes: bool,
    cache_mesh_topology: bool,
    extra_flags: i32,

    pub const create = funcs.cookOptionsCreate;
    pub const init = funcs.cookOptionsInit;
    pub const isEqual = funcs.cookOptionsAreEqual;
};

pub const Session = extern struct {
    type: SessionType,
    id: SessionId,

    pub const isInitialized = funcs.isInitialized;
};

pub const ParmInfo = extern struct {
    id: ParmId,
    parent_id: ParmId,
    child_index: i32,
    type: ParmType,
    script_type: PrmScriptType,
    type_info_sh: StringHandle,
    permissions: Permissions,
    tag_count: i32,
    size: i32,
    choice_list_type: ChoiceListType,
    choice_count: i32,
    name_sh: StringHandle,
    label_sh: StringHandle,
    template_name_sh: StringHandle,
    help_sh: StringHandle,
    has_min: bool,
    has_max: bool,
    has_uimin: bool,
    has_uimax: bool,
    min: f32,
    max: f32,
    ui_min: f32,
    ui_max: f32,
    invisible: bool,
    disabled: bool,
    spare: bool,
    join_next: bool,
    label_none: bool,
    int_values_index: i32,
    float_values_index: i32,
    string_values_index: i32,
    choice_index: i32,
    input_node_type: NodeType,
    input_node_flag: NodeFlags,
    is_child_of_multi_parm: bool,
    instance_num: i32,
    instance_length: i32,
    instance_count: i32,
    instance_start_offset: i32,
    ramp_type: RampType,
    visibility_condition_sh: StringHandle,
    disabled_condition_sh: StringHandle,
    use_menu_item_token_as_value: bool,
};

pub const GeoInfo = extern struct {
    type: GeoType,
    name_sh: StringHandle,
    node_id: NodeId,
    is_editable: bool,
    is_templated: bool,
    is_display_geo: bool,
    has_geo_changed: bool,
    has_material_changed: bool,
    point_group_count: i32,
    primitive_group_count: i32,
    edge_group_count: i32,
    part_count: i32,
};

pub const PartInfo = extern struct {
    id: PartId,
    name_sh: StringHandle,
    type: PartType,
    face_count: i32,
    vertex_count: i32,
    point_count: i32,
    attribute_counts: [@enumToInt(AttributeOwner.max)]i32,
    is_instanced: bool,
    instanced_part_count: i32,
    instance_count: i32,
    has_changed: bool,
};

pub const AttributeInfo = extern struct {
    exists: bool,
    owner: AttributeOwner,
    storage: StorageType,
    original_owner: AttributeOwner,
    count: i32,
    tuple_size: i32,
    total_array_elements: i64,
    type_info: AttributeTypeInfo,
};
