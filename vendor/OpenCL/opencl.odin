// bindings for [[ OpenCL ; https://registry.khronos.org/OpenCL/ ]].
#+build windows, linux, darwin
package vendor_opencl

import "core:c"

cl_platform_id :: distinct rawptr
cl_device_id :: distinct rawptr
cl_context :: distinct rawptr
cl_command_queue :: distinct rawptr
cl_mem :: distinct rawptr
cl_program :: distinct rawptr
cl_kernel :: distinct rawptr
cl_event :: distinct rawptr
cl_sampler :: distinct rawptr
svm_pointer :: distinct uintptr

cl_char :: i8
cl_uchar :: u8
cl_short :: i16
cl_ushort :: u16
cl_int :: i32
cl_uint :: u32
cl_long :: i64
cl_ulong :: u64

cl_half :: u16
cl_float :: f32
cl_double :: f64

cl_bool :: b32
size_t :: c.size_t
cl_bitfield :: distinct cl_ulong
cl_device_type_bits :: enum cl_bitfield {
    DEFAULT,
    CPU,
    GPU,
    ACCELERATOR,
    CUSTOM,
    _p0, _p1, _p2, _p3, _p4, _p5, _p6, _p7, _p8, _p9,
    _p10, _p11, _p12, _p13, _p14, _p15, _p16, _p17, _p18, _p19,
    _p20, _p21, _p22, _p23, _p24, _p25, _p26, _p27, _p28, _p29,
    _p30, _p31, _p32, _p33, _p34, _p35, _p36, _p37, _p38, _p39,
    _p40, _p41, _p42, _p43, _p44, _p45, _p46, _p47, _p48, _p49,
    _p50, _p51, _p52, _p53, _p54, _p55, _p56, _p57, _p58
}
cl_device_type :: bit_set[cl_device_type_bits; cl_bitfield] 
cl_platform_info :: enum cl_uint {
    PROFILE = 0x0900,
    VERSION = 0x0901,
    NAME = 0x0902,
    VENDOR = 0x0903,
    EXTENSIONS = 0x0904,
    HOST_TIMER_RESOLUTION = 0x0905,
    NUMERIC_VERSION = 0x0906,
    EXTENSIONS_WITH_VERSION = 0x0907,
}
cl_device_info :: enum cl_uint {
    TYPE                                    = 0x1000,
    VENDOR_ID                               = 0x1001,
    MAX_COMPUTE_UNITS                       = 0x1002,
    MAX_WORK_ITEM_DIMENSIONS                = 0x1003,
    MAX_WORK_GROUP_SIZE                     = 0x1004,
    MAX_WORK_ITEM_SIZES                     = 0x1005,
    PREFERRED_VECTOR_WIDTH_CHAR             = 0x1006,
    PREFERRED_VECTOR_WIDTH_SHORT            = 0x1007,
    PREFERRED_VECTOR_WIDTH_INT              = 0x1008,
    PREFERRED_VECTOR_WIDTH_LONG             = 0x1009,
    PREFERRED_VECTOR_WIDTH_FLOAT            = 0x100A,
    PREFERRED_VECTOR_WIDTH_DOUBLE           = 0x100B,
    MAX_CLOCK_FREQUENCY                     = 0x100C,
    ADDRESS_BITS                            = 0x100D,
    MAX_READ_IMAGE_ARGS                     = 0x100E,
    MAX_WRITE_IMAGE_ARGS                    = 0x100F,
    MAX_MEM_ALLOC_SIZE                      = 0x1010,
    IMAGE2D_MAX_WIDTH                       = 0x1011,
    IMAGE2D_MAX_HEIGHT                      = 0x1012,
    IMAGE3D_MAX_WIDTH                       = 0x1013,
    IMAGE3D_MAX_HEIGHT                      = 0x1014,
    IMAGE3D_MAX_DEPTH                       = 0x1015,
    IMAGE_SUPPORT                           = 0x1016,
    MAX_PARAMETER_SIZE                      = 0x1017,
    MAX_SAMPLERS                            = 0x1018,
    MEM_BASE_ADDR_ALIGN                     = 0x1019,
    MIN_DATA_TYPE_ALIGN_SIZE                = 0x101A,
    SINGLE_FP_CONFIG                        = 0x101B,
    GLOBAL_MEM_CACHE_TYPE                   = 0x101C,
    GLOBAL_MEM_CACHELINE_SIZE               = 0x101D,
    GLOBAL_MEM_CACHE_SIZE                   = 0x101E,
    GLOBAL_MEM_SIZE                         = 0x101F,
    MAX_CONSTANT_BUFFER_SIZE                = 0x1020,
    MAX_CONSTANT_ARGS                       = 0x1021,
    LOCAL_MEM_TYPE                          = 0x1022,
    LOCAL_MEM_SIZE                          = 0x1023,
    ERROR_CORRECTION_SUPPORT                = 0x1024,
    PROFILING_TIMER_RESOLUTION              = 0x1025,
    ENDIAN_LITTLE                           = 0x1026,
    AVAILABLE                               = 0x1027,
    COMPILER_AVAILABLE                      = 0x1028,
    EXECUTION_CAPABILITIES                  = 0x1029,
    QUEUE_ON_HOST_PROPERTIES                = 0x102A,
    NAME                                    = 0x102B,
    VENDOR                                  = 0x102C,
    DRIVER_VERSION                          = 0x102D,
    PROFILE                                 = 0x102E,
    VERSION                                 = 0x102F,
    EXTENSIONS                              = 0x1030,
    PLATFORM                                = 0x1031,
    DOUBLE_FP_CONFIG                        = 0x1032,
    PREFERRED_VECTOR_WIDTH_HALF             = 0x1034,
    HOST_UNIFIED_MEMORY                     = 0x1035,
    NATIVE_VECTOR_WIDTH_CHAR                = 0x1036,
    NATIVE_VECTOR_WIDTH_SHORT               = 0x1037,
    NATIVE_VECTOR_WIDTH_INT                 = 0x1038,
    NATIVE_VECTOR_WIDTH_LONG                = 0x1039,
    NATIVE_VECTOR_WIDTH_FLOAT               = 0x103A,
    NATIVE_VECTOR_WIDTH_DOUBLE              = 0x103B,
    NATIVE_VECTOR_WIDTH_HALF                = 0x103C,
    OPENCL_C_VERSION                        = 0x103D,
    LINKER_AVAILABLE                        = 0x103E,
    BUILT_IN_KERNELS                        = 0x103F,
    IMAGE_MAX_BUFFER_SIZE                   = 0x1040,
    IMAGE_MAX_ARRAY_SIZE                    = 0x1041,
    PARENT_DEVICE                           = 0x1042,
    PARTITION_MAX_SUB_DEVICES               = 0x1043,
    PARTITION_PROPERTIES                    = 0x1044,
    PARTITION_AFFINITY_DOMAIN               = 0x1045,
    PARTITION_TYPE                          = 0x1046,
    REFERENCE_COUNT                         = 0x1047,
    PREFERRED_INTEROP_USER_SYNC             = 0x1048,
    PRINTF_BUFFER_SIZE                      = 0x1049,
    IMAGE_PITCH_ALIGNMENT                   = 0x104A,
    IMAGE_BASE_ADDRESS_ALIGNMENT            = 0x104B,
    MAX_READ_WRITE_IMAGE_ARGS               = 0x104C,
    MAX_GLOBAL_VARIABLE_SIZE                = 0x104D,
    QUEUE_ON_DEVICE_PROPERTIES              = 0x104E,
    QUEUE_ON_DEVICE_PREFERRED_SIZE          = 0x104F,
    QUEUE_ON_DEVICE_MAX_SIZE                = 0x1050,
    MAX_ON_DEVICE_QUEUES                    = 0x1051,
    MAX_ON_DEVICE_EVENTS                    = 0x1052,
    SVM_CAPABILITIES                        = 0x1053,
    GLOBAL_VARIABLE_PREFERRED_TOTAL_SIZE    = 0x1054,
    MAX_PIPE_ARGS                           = 0x1055,
    PIPE_MAX_ACTIVE_RESERVATIONS            = 0x1056,
    PIPE_MAX_PACKET_SIZE                    = 0x1057,
    PREFERRED_PLATFORM_ATOMIC_ALIGNMENT     = 0x1058,
    PREFERRED_GLOBAL_ATOMIC_ALIGNMENT       = 0x1059,
    PREFERRED_LOCAL_ATOMIC_ALIGNMENT        = 0x105A,
    IL_VERSION                              = 0x105B,
    MAX_NUM_SUB_GROUPS                      = 0x105C,
    SUB_GROUP_INDEPENDENT_FORWARD_PROGRESS  = 0x105D,
    NUMERIC_VERSION                         = 0x105E,
    EXTENSIONS_WITH_VERSION                 = 0x1060,
    ILS_WITH_VERSION                        = 0x1061,
    BUILT_IN_KERNELS_WITH_VERSION           = 0x1062,
    ATOMIC_MEMORY_CAPABILITIES              = 0x1063,
    ATOMIC_FENCE_CAPABILITIES               = 0x1064,
    NON_UNIFORM_WORK_GROUP_SUPPORT          = 0x1065,
    OPENCL_C_ALL_VERSIONS                   = 0x1066,
    PREFERRED_WORK_GROUP_SIZE_MULTIPLE      = 0x1067,
    WORK_GROUP_COLLECTIVE_FUNCTIONS_SUPPORT = 0x1068,
    GENERIC_ADDRESS_SPACE_SUPPORT           = 0x1069,
    OPENCL_C_FEATURES                       = 0x106F,
    DEVICE_ENQUEUE_CAPABILITIES             = 0x1070,
    PIPE_SUPPORT                            = 0x1071,
    LATEST_CONFORMANCE_VERSION_PASSED       = 0x1072,
}
cl_device_fp_config_bits :: enum cl_bitfield {
    DENORM,
    INF_NAN,
    ROUND_TO_NEAREST,
    ROUND_TO_ZERO,
    ROUND_TO_INF,
    FMA,
    SOFT_FLOAT,
    CORRECTLY_ROUNDED_DIVIDE_SQRT,
}
cl_device_fp_config :: bit_set[cl_device_fp_config_bits; cl_bitfield]
cl_device_mem_cache_type :: enum cl_uint {
    NONE = 0x0,
    READ_ONLY_CACHE = 0x1,
    READ_WRITE_CACHE = 0x2,
}
cl_device_local_mem_type :: enum cl_uint {
    LOCAL = 0x1,
    GLOBAL = 0x2,
}
cl_device_exec_capabilities_bits :: enum cl_bitfield {
    EXEC_KERNEL,
    EXEC_NATIVE_KERNEL,
}
cl_device_exec_capabilities :: bit_set[cl_device_exec_capabilities_bits; cl_bitfield]
cl_command_queue_properties_bits :: enum cl_bitfield {
    OUT_OF_ORDER_EXEC_MODE_ENABLE = 0,
    PROFILING_ENABLE              = 1,
    ON_DEVICE                     = 2,
    ON_DEVICE_DEFAULT             = 3,
}
cl_command_queue_properties :: bit_set[cl_command_queue_properties_bits; cl_bitfield]
cl_context_info :: enum cl_uint {
    REFERENCE_COUNT = 0x1080,
    DEVICES         = 0x1081,
    PROPERTIES      = 0x1082,
    NUM_DEVICES     = 0x1083,
}
cl_context_properties :: enum c.intptr_t {
    PLATFORM          = 0x1084,
    INTEROP_USER_SYNC = 0x1085,
    // cl_gl
    GL_CONTEXT_KHR     = 0x2008,
    EGL_DISPLAY_KHR    = 0x2009,
    GLX_DISPLAY_KHR    = 0x200A,
    WGL_HDC_KHR        = 0x200B,
    CGL_SHAREGROUP_KHR = 0x200C,
}
cl_device_partition_property :: enum c.intptr_t {
    EQUALLY            = 0x1086,
    BY_COUNTS          = 0x1087,
    BY_COUNTS_LIST_END = 0x0,
    BY_AFFINITY_DOMAIN = 0x1088,
}
cl_device_affinity_domain_bits :: enum cl_bitfield {
    NUMA               = 0,
    L4_CACHE           = 1,
    L3_CACHE           = 2,
    L2_CACHE           = 3,
    L1_CACHE           = 4,
    NEXT_PARTITIONABLE = 5,
}
cl_device_affinity_domain :: bit_set[cl_device_affinity_domain_bits; cl_bitfield]
cl_device_svm_capabilities_bits :: enum cl_bitfield {
    COARSE_GRAIN_BUFFER = 0,
    FINE_GRAIN_BUFFER   = 1,
    FINE_GRAIN_SYSTEM   = 2,
    ATOMICS             = 3,
}
cl_device_svm_capabilities :: bit_set[cl_device_svm_capabilities_bits; cl_bitfield]
cl_command_queue_info :: enum cl_uint {
    CONTEXT          = 0x1090,
    DEVICE           = 0x1091,
    REFERENCE_COUNT  = 0x1092,
    PROPERTIES       = 0x1093,
    SIZE             = 0x1094,
    DEVICE_DEFAULT   = 0x1095,
    PROPERTIES_ARRAY = 0x1098,
}
cl_mem_flags_bits :: enum cl_bitfield {
    READ_WRITE            = 0,
    WRITE_ONLY            = 1,
    READ_ONLY             = 2,
    USE_HOST_PTR          = 3,
    ALLOC_HOST_PTR        = 4,
    COPY_HOST_PTR         = 5,
    _reserved             = 6,
    HOST_WRITE_ONLY       = 7,
    HOST_READ_ONLY        = 8,
    HOST_NO_ACCESS        = 9,
    SVM_FINE_GRAIN_BUFFER = 10,   /* used by cl_svm_mem_flags only */
    SVM_ATOMICS           = 11,   /* used by cl_svm_mem_flags only */
    KERNEL_READ_AND_WRITE = 12,
}
cl_mem_flags :: bit_set[cl_mem_flags_bits; cl_bitfield]

cl_properties :: struct #raw_union {
    bool: cl_bool,
    int: cl_int,
    uint: cl_uint,
    long: cl_long,
    ulong: cl_ulong,
    platform_id: cl_platform_id,
    device_id: cl_device_id,
}
cl_generic_property :: struct #raw_union {
    property: cl_properties,
    queue_key: cl_command_queue_info,
    queue_val: cl_command_queue_properties,
    mem_key: cl_mem_info,
    mem_val: cl_mem_flags,
    pipe_key: cl_pipe_info,
    sampler_key: cl_sampler_info,
}
cl_queue_properties :: struct #raw_union {
    key: cl_command_queue_info,
    val: cl_command_queue_properties,
    property: cl_properties,
}
cl_mem_properties :: struct #raw_union {
    key: cl_mem_info,
    val: cl_mem_flags,
    property: cl_properties,
}
cl_pipe_properties :: struct #raw_union {
    key: cl_pipe_info,
    property: cl_properties,
}
cl_sampler_properties :: struct #raw_union {
    key: cl_sampler_info,
    property: cl_properties,
}
cl_partition_properties :: struct #raw_union {
    key: cl_device_partition_property,
    property: cl_properties,
}
cl_create_context_properties :: struct #raw_union {
    key: cl_context_properties,
    property: cl_properties,
}

cl_svm_mem_flags :: cl_mem_flags
cl_mem_migration_flags_bits :: enum cl_bitfield {
    OBJECT_HOST              = 0,
    OBJECT_CONTENT_UNDEFINED = 1,
}
cl_mem_migration_flags :: bit_set[cl_mem_migration_flags_bits; cl_bitfield]
cl_channel_order :: enum cl_uint {
    R             = 0x10B0,
    A             = 0x10B1,
    RG            = 0x10B2,
    RA            = 0x10B3,
    RGB           = 0x10B4,
    RGBA          = 0x10B5,
    BGRA          = 0x10B6,
    ARGB          = 0x10B7,
    INTENSITY     = 0x10B8,
    LUMINANCE     = 0x10B9,
    Rx            = 0x10BA,
    RGx           = 0x10BB,
    RGBx          = 0x10BC,
    DEPTH         = 0x10BD,
    DEPTH_STENCIL = 0x10BE,
    sRGB          = 0x10BF,
    sRGBx         = 0x10C0,
    sRGBA         = 0x10C1,
    sBGRA         = 0x10C2,
    ABGR          = 0x10C3,
}
cl_channel_type :: enum cl_uint {
    SNORM_INT8         = 0x10D0,
    SNORM_INT16        = 0x10D1,
    UNORM_INT8         = 0x10D2,
    UNORM_INT16        = 0x10D3,
    UNORM_SHORT_565    = 0x10D4,
    UNORM_SHORT_555    = 0x10D5,
    UNORM_INT_101010   = 0x10D6,
    SIGNED_INT8        = 0x10D7,
    SIGNED_INT16       = 0x10D8,
    SIGNED_INT32       = 0x10D9,
    UNSIGNED_INT8      = 0x10DA,
    UNSIGNED_INT16     = 0x10DB,
    UNSIGNED_INT32     = 0x10DC,
    HALF_FLOAT         = 0x10DD,
    FLOAT              = 0x10DE,
    UNORM_INT24        = 0x10DF,
    UNORM_INT_101010_2 = 0x10E0,
}
cl_mem_object_type :: enum cl_uint {
    BUFFER         = 0x10F0,
    IMAGE2D        = 0x10F1,
    IMAGE3D        = 0x10F2,
    IMAGE2D_ARRAY  = 0x10F3,
    IMAGE1D        = 0x10F4,
    IMAGE1D_ARRAY  = 0x10F5,
    IMAGE1D_BUFFER = 0x10F6,
    PIPE           = 0x10F7,
}
cl_mem_info :: enum cl_uint {
    TYPE                 = 0x1100,
    FLAGS                = 0x1101,
    SIZE                 = 0x1102,
    HOST_PTR             = 0x1103,
    MAP_COUNT            = 0x1104,
    REFERENCE_COUNT      = 0x1105,
    CONTEXT              = 0x1106,
    ASSOCIATED_MEMOBJECT = 0x1107,
    OFFSET               = 0x1108,
    USES_SVM_POINTER     = 0x1109,
    PROPERTIES           = 0x110A,
}
cl_image_info :: enum cl_uint {
    FORMAT         = 0x1110,
    ELEMENT_SIZE   = 0x1111,
    ROW_PITCH      = 0x1112,
    SLICE_PITCH    = 0x1113,
    WIDTH          = 0x1114,
    HEIGHT         = 0x1115,
    DEPTH          = 0x1116,
    ARRAY_SIZE     = 0x1117,
    BUFFER         = 0x1118,
    NUM_MIP_LEVELS = 0x1119,
    NUM_SAMPLES    = 0x111A,
}
cl_buffer_create_type :: enum cl_uint {
    CREATE_TYPE_REGION = 0x1220,
}
cl_pipe_info :: enum cl_uint {
    PACKET_SIZE = 0x1120,
    MAX_PACKETS = 0x1121,
    PROPERTIES  = 0x1122,
}
cl_addressing_mode :: enum cl_uint {
    NONE            = 0x1130,
    CLAMP_TO_EDGE   = 0x1131,
    CLAMP           = 0x1132,
    REPEAT          = 0x1133,
    MIRRORED_REPEAT = 0x1134,
}
cl_filter_mode :: enum cl_uint {
    NEAREST = 0x1140,
    LINEAR  = 0x1141,
}
cl_sampler_info :: enum cl_uint {
    REFERENCE_COUNT   = 0x1150,
    CONTEXT           = 0x1151,
    NORMALIZED_COORDS = 0x1152,
    ADDRESSING_MODE   = 0x1153,
    FILTER_MODE       = 0x1154,
    MIP_FILTER_MODE   = 0x1155,
    LOD_MIN           = 0x1156,
    LOD_MAX           = 0x1157,
    PROPERTIES        = 0x1158,
}
cl_map_flags_bits :: enum cl_bitfield {
    READ                    = 0,
    WRITE                   = 1,
    WRITE_INVALIDATE_REGION = 2,
}
cl_map_flags :: bit_set[cl_map_flags_bits; cl_bitfield]
cl_program_info :: enum cl_uint {
    REFERENCE_COUNT            = 0x1160,
    CONTEXT                    = 0x1161,
    NUM_DEVICES                = 0x1162,
    DEVICES                    = 0x1163,
    SOURCE                     = 0x1164,
    BINARY_SIZES               = 0x1165,
    BINARIES                   = 0x1166,
    NUM_KERNELS                = 0x1167,
    KERNEL_NAMES               = 0x1168,
    IL                         = 0x1169,
    SCOPE_GLOBAL_CTORS_PRESENT = 0x116A,
    SCOPE_GLOBAL_DTORS_PRESENT = 0x116B,
}
cl_program_build_info :: enum cl_uint {
    BUILD_STATUS                     = 0x1181,
    BUILD_OPTIONS                    = 0x1182,
    BUILD_LOG                        = 0x1183,
    BINARY_TYPE                      = 0x1184,
    BUILD_GLOBAL_VARIABLE_TOTAL_SIZE = 0x1185,
}
cl_program_binary_type :: enum cl_uint {
    NONE            = 0x0,
    COMPILED_OBJECT = 0x1,
    LIBRARY         = 0x2,
    EXECUTABLE      = 0x4,
}
cl_build_status :: enum cl_int {
    SUCCESS     = 0,
    NONE        = -1,
    ERROR       = -2,
    IN_PROGRESS = -3,
}
cl_kernel_info :: enum cl_uint {
    FUNCTION_NAME   = 0x1190,
    NUM_ARGS        = 0x1191,
    REFERENCE_COUNT = 0x1192,
    CONTEXT         = 0x1193,
    PROGRAM         = 0x1194,
    ATTRIBUTES      = 0x1195,
}
cl_kernel_arg_info :: enum cl_uint {
    ADDRESS_QUALIFIER = 0x1196,
    ACCESS_QUALIFIER  = 0x1197,
    TYPE_NAME         = 0x1198,
    TYPE_QUALIFIER    = 0x1199,
    NAME              = 0x119A,
}
cl_kernel_arg_address_qualifier :: enum cl_uint {
    GLOBAL   = 0x119B,
    LOCAL    = 0x119C,
    CONSTANT = 0x119D,
    PRIVATE  = 0x119E,
}
cl_kernel_arg_access_qualifier :: enum cl_uint {
    READ_ONLY  = 0x11A0,
    WRITE_ONLY = 0x11A1,
    READ_WRITE = 0x11A2,
    NONE       = 0x11A3,
}
cl_kernel_arg_type_qualifier_bits :: enum cl_bitfield {
    CONST    = 0,
    RESTRICT = 1,
    VOLATILE = 2,
    PIPE     = 3,
}
cl_kernel_arg_type_qualifier :: bit_set[cl_kernel_arg_type_qualifier_bits; cl_bitfield]
cl_kernel_work_group_info :: enum cl_uint {
    WORK_GROUP_SIZE                    = 0x11B0,
    COMPILE_WORK_GROUP_SIZE            = 0x11B1,
    LOCAL_MEM_SIZE                     = 0x11B2,
    PREFERRED_WORK_GROUP_SIZE_MULTIPLE = 0x11B3,
    PRIVATE_MEM_SIZE                   = 0x11B4,
    GLOBAL_WORK_SIZE                   = 0x11B5,
}
cl_kernel_sub_group_info :: enum cl_uint {
    MAX_SUB_GROUP_SIZE_FOR_NDRANGE = 0x2033,
    SUB_GROUP_COUNT_FOR_NDRANGE    = 0x2034,
    LOCAL_SIZE_FOR_SUB_GROUP_COUNT = 0x11B8,
    MAX_NUM_SUB_GROUPS             = 0x11B9,
    COMPILE_NUM_SUB_GROUPS         = 0x11BA,
}
cl_kernel_exec_info :: enum cl_uint {
    PTRS              = 0x11B6,
    FINE_GRAIN_SYSTEM = 0x11B7,
}
cl_event_info :: enum cl_uint {
    COMMAND_QUEUE            = 0x11D0,
    COMMAND_TYPE             = 0x11D1,
    REFERENCE_COUNT          = 0x11D2,
    COMMAND_EXECUTION_STATUS = 0x11D3,
    CONTEXT                  = 0x11D4,
}
cl_command_type :: enum cl_uint {
    NDRANGE_KERNEL       = 0x11F0,
    TASK                 = 0x11F1,
    NATIVE_KERNEL        = 0x11F2,
    READ_BUFFER          = 0x11F3,
    WRITE_BUFFER         = 0x11F4,
    COPY_BUFFER          = 0x11F5,
    READ_IMAGE           = 0x11F6,
    WRITE_IMAGE          = 0x11F7,
    COPY_IMAGE           = 0x11F8,
    COPY_IMAGE_TO_BUFFER = 0x11F9,
    COPY_BUFFER_TO_IMAGE = 0x11FA,
    MAP_BUFFER           = 0x11FB,
    MAP_IMAGE            = 0x11FC,
    UNMAP_MEM_OBJECT     = 0x11FD,
    MARKER               = 0x11FE,
    ACQUIRE_GL_OBJECTS   = 0x11FF,
    RELEASE_GL_OBJECTS   = 0x1200,
    READ_BUFFER_RECT     = 0x1201,
    WRITE_BUFFER_RECT    = 0x1202,
    COPY_BUFFER_RECT     = 0x1203,
    USER                 = 0x1204,
    BARRIER              = 0x1205,
    MIGRATE_MEM_OBJECTS  = 0x1206,
    FILL_BUFFER          = 0x1207,
    FILL_IMAGE           = 0x1208,
    SVM_FREE             = 0x1209,
    SVM_MEMCPY           = 0x120A,
    SVM_MEMFILL          = 0x120B,
    SVM_MAP              = 0x120C,
    SVM_UNMAP            = 0x120D,
    SVM_MIGRATE_MEM      = 0x120E,
    //cl_egl
    EGL_FENCE_SYNC_OBJECT_KHR = 0x202F,
    ACQUIRE_EGL_OBJECTS_KHR   = 0x202D,
    RELEASE_EGL_OBJECTS_KHR   = 0x202E,
}
// idk if this is the right backing type
cl_command_execution_status :: enum c.int {
    COMPLETE  = 0x0,
    RUNNING   = 0x1,
    SUBMITTED = 0x2,
    QUEUED    = 0x3,
}
cl_profiling_info :: enum cl_uint {
    COMMAND_QUEUED   = 0x1280,
    COMMAND_SUBMIT   = 0x1281,
    COMMAND_START    = 0x1282,
    COMMAND_END      = 0x1283,
    COMMAND_COMPLETE = 0x1284,
}
cl_device_atomic_capabilities_bits :: enum cl_bitfield {
    ATOMIC_ORDER_RELAXED     = 0,
    ATOMIC_ORDER_ACQ_REL     = 1,
    ATOMIC_ORDER_SEQ_CST     = 2,
    ATOMIC_SCOPE_WORK_ITEM   = 3,
    ATOMIC_SCOPE_WORK_GROUP  = 4,
    ATOMIC_SCOPE_DEVICE      = 5,
    ATOMIC_SCOPE_ALL_DEVICES = 6,
}
cl_device_atomic_capabilities :: bit_set[cl_device_atomic_capabilities_bits; cl_bitfield]
cl_device_device_enqueue_capabilities_bits :: enum cl_bitfield {
    SUPPORTED           = 0,
    REPLACEABLE_DEFAULT = 1,
}
cl_device_device_enqueue_capabilities :: distinct cl_bitfield
cl_khronos_vendor_id :: distinct cl_uint
CL_KHRONOS_VENDOR_ID_CODEPLAY : cl_khronos_vendor_id : 0x10004


/* cl_version */
CL_VERSION_MAJOR_BITS :: (10)
CL_VERSION_MINOR_BITS :: (10)
CL_VERSION_PATCH_BITS :: (12)

CL_VERSION_MAJOR_MASK :: ((1 << CL_VERSION_MAJOR_BITS) - 1)
CL_VERSION_MINOR_MASK :: ((1 << CL_VERSION_MINOR_BITS) - 1)
CL_VERSION_PATCH_MASK :: ((1 << CL_VERSION_PATCH_BITS) - 1)

cl_version :: distinct cl_uint
CL_VERSION_MAJOR :: proc(version: cl_version) -> cl_version {
    return ((version) >> (CL_VERSION_MINOR_BITS + CL_VERSION_PATCH_BITS))
}

CL_VERSION_MINOR :: proc(version: cl_version) -> cl_version {
    return (((version) >> CL_VERSION_PATCH_BITS) & CL_VERSION_MINOR_MASK)
}

CL_VERSION_PATCH :: proc(version: cl_version) -> cl_version {
    return ((version) & CL_VERSION_PATCH_MASK)
}

CL_MAKE_VERSION :: proc (major, minor, patch: cl_version) -> cl_version {
    return ((((major) & CL_VERSION_MAJOR_MASK) << (CL_VERSION_MINOR_BITS + CL_VERSION_PATCH_BITS)) | (((minor) & CL_VERSION_MINOR_MASK) << CL_VERSION_PATCH_BITS) | ((patch) & CL_VERSION_PATCH_MASK))
}

cl_image_format :: struct {
    image_channel_order: cl_channel_order,
    image_channel_data_type: cl_channel_type,
}

cl_image_desc :: struct{
    image_type: cl_mem_object_type,
    image_width: size_t,
    image_height: size_t,
    image_depth: size_t,
    image_array_size: size_t,
    image_row_pitch: size_t,
    image_slice_pitch: size_t,
    num_mip_levels: cl_uint,
    num_samples: cl_uint,
    using _: struct #raw_union {
        buffer: cl_mem,
        mem_object: cl_mem,
    },
}
cl_buffer_region :: struct {
    origin : size_t,
    size : size_t,
}

CL_NAME_VERSION_MAX_NAME_SIZE :: 64

cl_name_version :: struct {
    version: cl_version,
    name: [CL_NAME_VERSION_MAX_NAME_SIZE]u8 `fmt:"s"`,
}

cl_error :: enum i32 {
    CL_SUCCESS                                    = 0,
    CL_DEVICE_NOT_FOUND                           = -1,
    CL_DEVICE_NOT_AVAILABLE                       = -2,
    CL_COMPILER_NOT_AVAILABLE                     = -3,
    CL_MEM_OBJECT_ALLOCATION_FAILURE              = -4,
    CL_OUT_OF_RESOURCES                           = -5,
    CL_OUT_OF_HOST_MEMORY                         = -6,
    CL_PROFILING_INFO_NOT_AVAILABLE               = -7,
    CL_MEM_COPY_OVERLAP                           = -8,
    CL_IMAGE_FORMAT_MISMATCH                      = -9,
    CL_IMAGE_FORMAT_NOT_SUPPORTED                 = -10,
    CL_BUILD_PROGRAM_FAILURE                      = -11,
    CL_MAP_FAILURE                                = -12,
    CL_MISALIGNED_SUB_BUFFER_OFFSET               = -13,
    CL_EXEC_STATUS_ERROR_FOR_EVENTS_IN_WAIT_LIST  = -14,
    CL_COMPILE_PROGRAM_FAILURE                    = -15,
    CL_LINKER_NOT_AVAILABLE                       = -16,
    CL_LINK_PROGRAM_FAILURE                       = -17,
    CL_DEVICE_PARTITION_FAILED                    = -18,
    CL_KERNEL_ARG_INFO_NOT_AVAILABLE              = -19,
    CL_INVALID_VALUE                              = -30,
    CL_INVALID_DEVICE_TYPE                        = -31,
    CL_INVALID_PLATFORM                           = -32,
    CL_INVALID_DEVICE                             = -33,
    CL_INVALID_CONTEXT                            = -34,
    CL_INVALID_QUEUE_PROPERTIES                   = -35,
    CL_INVALID_COMMAND_QUEUE                      = -36,
    CL_INVALID_HOST_PTR                           = -37,
    CL_INVALID_MEM_OBJECT                         = -38,
    CL_INVALID_IMAGE_FORMAT_DESCRIPTOR            = -39,
    CL_INVALID_IMAGE_SIZE                         = -40,
    CL_INVALID_SAMPLER                            = -41,
    CL_INVALID_BINARY                             = -42,
    CL_INVALID_BUILD_OPTIONS                      = -43,
    CL_INVALID_PROGRAM                            = -44,
    CL_INVALID_PROGRAM_EXECUTABLE                 = -45,
    CL_INVALID_KERNEL_NAME                        = -46,
    CL_INVALID_KERNEL_DEFINITION                  = -47,
    CL_INVALID_KERNEL                             = -48,
    CL_INVALID_ARG_INDEX                          = -49,
    CL_INVALID_ARG_VALUE                          = -50,
    CL_INVALID_ARG_SIZE                           = -51,
    CL_INVALID_KERNEL_ARGS                        = -52,
    CL_INVALID_WORK_DIMENSION                     = -53,
    CL_INVALID_WORK_GROUP_SIZE                    = -54,
    CL_INVALID_WORK_ITEM_SIZE                     = -55,
    CL_INVALID_GLOBAL_OFFSET                      = -56,
    CL_INVALID_EVENT_WAIT_LIST                    = -57,
    CL_INVALID_EVENT                              = -58,
    CL_INVALID_OPERATION                          = -59,
    CL_INVALID_GL_OBJECT                          = -60,
    CL_INVALID_BUFFER_SIZE                        = -61,
    CL_INVALID_MIP_LEVEL                          = -62,
    CL_INVALID_GLOBAL_WORK_SIZE                   = -63,
    CL_INVALID_PROPERTY                           = -64,
    CL_INVALID_IMAGE_DESCRIPTOR                   = -65,
    CL_INVALID_COMPILER_OPTIONS                   = -66,
    CL_INVALID_LINKER_OPTIONS                     = -67,
    CL_INVALID_DEVICE_PARTITION_COUNT             = -68,
    CL_INVALID_PIPE_SIZE                          = -69,
    CL_INVALID_DEVICE_QUEUE                       = -70,
    CL_INVALID_SPEC_ID                            = -71,
    CL_MAX_SIZE_RESTRICTION_EXCEEDED              = -72,
    //cl_egl
    INVALID_EGL_OBJECT_KHR        = -1093,
    EGL_RESOURCE_NOT_ACQUIRED_KHR = -1092,
    //cl_gl
    INVALID_GL_SHAREGROUP_REFERENCE_KHR = -1000,

}

CL_BLOCKING :: 1
CL_NONBLOCKING :: 0
when ODIN_OS == .Windows {
    foreign import opencl "system:OpenCL.lib"
} else when ODIN_OS == .Linux {
    foreign import opencl "system:libOpenCL.so"
} else {
    foreign import opencl "system:OpenCL.framework"
}
// cl.h
@(default_calling_convention="c")
foreign opencl {
    clGetPlatformIDs :: proc(num_entries: cl_uint, platforms: [^]cl_platform_id, num_platforms: ^cl_uint) -> cl_error ---
    clGetPlatformInfo :: proc(platform: cl_platform_id, param_name: cl_platform_info, param_value_size: size_t, param_value: rawptr, param_value_size_ret: ^size_t) -> cl_error ---
    clGetDeviceIDs :: proc(platform: cl_platform_id, device_type: cl_device_type, num_entries: cl_uint, devices: [^]cl_device_id, num_devices: ^cl_uint) -> cl_error ---
    clGetDeviceInfo :: proc(device: cl_device_id, param_name: cl_device_info, param_value_size: size_t, param_value: rawptr, param_value_size_ret: ^size_t) -> cl_error ---
    clCreateSubDevices :: proc(in_device: cl_device_id, properties: [^]cl_partition_properties, num_devices: cl_uint,out_devices: [^]cl_device_id,num_devices_ret: ^cl_uint) -> cl_error ---
    clRetainDevice :: proc(device: cl_device_id) -> cl_error ---
    clReleaseDevice :: proc(device: cl_device_id) -> cl_error ---
    clSetDefaultDeviceCommandQueue :: proc(ctx: cl_context, device: cl_device_id, command_queue: cl_command_queue) -> cl_error ---
    clGetDeviceAndHostTimer :: proc(device: cl_device_id, device_timestamp: ^cl_ulong, host_timestamp: ^cl_ulong) -> cl_error ---
    clGetHostTimer  :: proc(device: cl_device_id, host_timestamp: ^cl_ulong) -> cl_error ---
    clCreateContext :: proc(properties: [^]cl_create_context_properties, num_devices: cl_uint, devices: [^]cl_device_id, pfn_notify: proc "c"(errinfo: cstring, private_info:rawptr, cb:size_t, user_data:rawptr), user_data:rawptr, errcode_ret: ^cl_error) -> cl_context ---
    clCreateContextFromType :: proc(properties: [^]cl_create_context_properties, device_type: cl_device_type, pfn_notify: proc "c"(errinfo: cstring, private_info:rawptr, cb:size_t, user_data:rawptr), user_data:rawptr, errcode_ret: ^cl_error) -> cl_context ---
    clRetainContext :: proc(device: cl_context) -> cl_error ---
    clReleaseContext :: proc(device: cl_context) -> cl_error ---
    clGetContextInfo :: proc(ctx: cl_context, info: cl_context_info, param_value_size: size_t, param_value: rawptr, param_value_size_ret: ^size_t) -> cl_error ---
    clSetContextDestructorCallback :: proc(ctx:cl_context, pfn_notify: proc "c"(ctx: cl_context, user_data: rawptr), user_data: rawptr) -> cl_error ---

    clCreateProgramWithSource :: proc(ctx: cl_context, strings_count: cl_uint, strings: [^]cstring, lengths: [^]size_t, errcode_ret: ^cl_error) -> cl_program ---
    clCreateProgramWithBinary :: proc(ctx: cl_context, num_devices: cl_uint, device_list: [^]cl_device_id, lengths: [^]size_t, binaries: [^]rawptr, binary_status: [^]cl_error, errcode_ret: ^cl_error) -> cl_program ---
    /* kernel_names is a semi-colon separated list of built-in kernel names. */
    clCreateProgramWithBuiltInKernels :: proc(ctx: cl_context, num_devices: cl_uint, device_list: [^]cl_device_id, kernel_names: cstring, errcode_ret: ^cl_error) -> cl_program ---
    clCreateProgramWithIL :: proc(ctx: cl_context, il: rawptr, length: size_t, errcode_ret: ^cl_error) -> cl_program ---
    clRetainProgram :: proc(program: cl_program) -> cl_error ---
    clReleaseProgram :: proc(program: cl_program) -> cl_error ---
    /* options is a pointer to a null-terminated string of characters that describes the build options to be used for building the program executable. The list of supported options is described in Compiler Options*/
    clBuildProgram :: proc(program: cl_program, num_devices: cl_uint, device_list: [^]cl_device_id, options: cstring, pfn_notify: proc "c"(program: cl_program, user_data: rawptr), user_data: rawptr) -> cl_error ---
    clCompileProgram :: proc(program: cl_program, num_devices: cl_uint, device_list: [^]cl_device_id, options: cstring, num_input_headers: cl_uint,  input_headers: [^]cl_program, header_include_names: [^]cstring, pfn_notify: proc "c"(program: cl_program, user_data: rawptr), user_data: rawptr) -> cl_error ---
    clLinkProgram :: proc(ctx: cl_context, num_devices: cl_uint, device_list: [^]cl_device_id, options: cstring, num_input_programs: cl_uint, input_programs: [^]cl_program, pfn_notify: proc "c"(program: cl_program, user_data: rawptr), user_data: rawptr, errcode_ret: ^cl_error) -> cl_program ---
    clGetProgramInfo :: proc(program: cl_program, param_name: cl_program_info, param_value_size: size_t, param_value: rawptr, param_value_size_ret: ^size_t) -> cl_error ---
    clCreateBuffer :: proc(ctx: cl_context, flags: cl_mem_flags, size: size_t, host_ptr: rawptr, errcode_ret: ^cl_error) -> cl_mem ---
    clCreateSubBuffer :: proc(buffer: cl_mem, flags: cl_mem_flags, buffer_create_type: cl_buffer_create_type, buffer_create_info: rawptr, errcode_ret: ^cl_error) -> cl_mem ---
    clCreateImage :: proc(ctx: cl_context, flags: cl_mem_flags, image_format: ^cl_image_format, image_desc: ^cl_image_desc, host_ptr: rawptr, errcode_ret: ^cl_error) -> cl_mem ---
    clCreatePipe :: proc(ctx: cl_context, flags: cl_mem_flags, pipe_packet_size: cl_uint, pipe_max_packets: cl_uint, properties: [^]cl_pipe_properties, errcode_ret: ^cl_error) -> cl_mem ---
    clCreateBufferWithProperties :: proc(ctx: cl_context, properties: [^]cl_mem_properties, flags: cl_mem_flags, size: size_t, host_ptr: rawptr, errcode_ret: ^cl_error) -> cl_mem ---
    clCreateImageWithProperties :: proc(ctx: cl_context, properties: [^]cl_mem_properties, flags: cl_mem_flags, image_format: ^cl_image_format, image_desc: ^cl_image_desc, host_ptr: rawptr, errcode_ret: ^cl_error) -> cl_mem ---
    clRetainMemObject :: proc(memobj: cl_mem) -> cl_error ---
    clReleaseMemObject :: proc(memobj: cl_mem) -> cl_error ---
    clGetSupportedImageFormats :: proc(ctx: cl_context, flags: cl_mem_flags, image_type: cl_mem_object_type, num_entries: cl_uint, image_formats: [^]cl_image_format, num_image_formats: [^]cl_uint) -> cl_error ---
    clGetMemObjectInfo :: proc(memobj: cl_mem, param_name: cl_mem_info, param_value_size: size_t, param_value: rawptr, param_value_size_ret: ^size_t) -> cl_error ---
    clGetImageInfo :: proc(image: cl_mem, param_name: cl_image_info, param_value_size: size_t, param_value: rawptr, param_value_size_ret: ^size_t) -> cl_error ---
    clGetPipeInfo :: proc(pipe: cl_mem, param_name: cl_pipe_info, param_value_size: size_t, param_value: rawptr, param_value_size_ret: ^size_t) -> cl_error ---
    clSetMemObjectDestructorCallback :: proc(memobj: cl_mem, pfn_notify: proc "c"(memobj: cl_mem, user_data: rawptr), user_data: rawptr) -> cl_error ---
    
    clGetProgramBuildInfo :: proc(program: cl_program, device: cl_device_id, param_name: cl_program_build_info, param_value_size: size_t, param_value: rawptr, param_value_size_ret: ^size_t) -> cl_error ---
    clCreateKernel :: proc(program: cl_program, kernel_name: cstring, errcode_ret: ^cl_error) -> cl_kernel ---
    clCreateKernelsInProgram :: proc(program: cl_program, num_kernels: cl_uint, kernels: [^]cl_kernel, num_kernels_ret: ^cl_uint) -> cl_error ---
    clCloneKernel :: proc(source_kernel: cl_kernel, errcode_ret: ^cl_error) -> cl_kernel ---
    clRetainKernel :: proc(kernel: cl_kernel) -> cl_error ---
    clReleaseKernel :: proc(kernel: cl_kernel) -> cl_error ---
    clSetKernelArg :: proc(kernel: cl_kernel, arg_index: cl_uint, arg_size: size_t, arg_value: rawptr) -> cl_error ---
    clSetKernelArgSVMPointer :: proc(kernel: cl_kernel, arg_index: cl_uint, arg_value: rawptr) -> cl_error ---
    clSetKernelExecInfo :: proc(kernel: cl_kernel, param_name: cl_kernel_exec_info, param_value_size: size_t, param_value: rawptr) -> cl_error ---
    clGetKernelInfo :: proc(kernel: cl_kernel, param_name: cl_kernel_info, param_value_size: size_t, param_value: rawptr, param_value_size_ret: ^size_t) -> cl_error ---
    clGetKernelArgInfo :: proc(kernel: cl_kernel, arg_index: cl_uint, param_name: cl_kernel_arg_info, param_value_size: size_t, param_value: rawptr, param_value_size_ret: ^size_t) -> cl_error ---
    clGetKernelWorkGroupInfo :: proc(kernel: cl_kernel, device: cl_device_id, param_name: cl_kernel_work_group_info, param_value_size: size_t, param_value: rawptr, param_value_size_ret: ^size_t) -> cl_error ---
    clGetKernelSubGroupInfo :: proc(kernel: cl_kernel, device: cl_device_id, param_name: cl_kernel_sub_group_info, input_value_size: size_t, input_value: rawptr, param_value_size: size_t, param_value: rawptr, param_value_size_ret: ^size_t) -> cl_error ---
    
    clCreateCommandQueueWithProperties :: proc(ctx: cl_context, device: cl_device_id, properties: [^]cl_queue_properties, errcode_ret: ^cl_error) -> cl_command_queue ---
    clRetainCommandQueue :: proc(command_queue: cl_command_queue) -> cl_error ---
    clReleaseCommandQueue :: proc(command_queue: cl_command_queue) -> cl_error ---
    clGetCommandQueueInfo :: proc(command_queue: cl_command_queue, param_name: cl_command_queue_info , param_value_size: size_t, param_value: rawptr, param_value_size_ret: ^size_t) -> cl_error ---
    clFlush :: proc(command_queue: cl_command_queue) -> cl_error ---
    clFinish :: proc(command_queue: cl_command_queue) -> cl_error ---
    clWaitForEvents :: proc(num_events: cl_uint, event_list: [^]cl_event) -> cl_error ---
    clRetainEvent :: proc(event: cl_event) -> cl_error ---
    clReleaseEvent :: proc(event: cl_event) -> cl_error ---
    clSVMAlloc :: proc(ctx: cl_context, flags: cl_svm_mem_flags, size: size_t, alignment: cl_uint) -> svm_pointer ---
    clSVMFree :: proc(ctx: cl_context, ptr: svm_pointer) ---
    clCreateCommandQueue :: proc(ctx: cl_context, device: cl_device_id, properties: cl_command_queue_properties, errcode_ret: ^cl_error) -> cl_command_queue ---
    clCreateSampler :: proc(ctx: cl_context, normalized_coords: cl_bool, addressing_mode: cl_addressing_mode, filter_mode: cl_filter_mode, errcode_ret: ^cl_error) -> cl_sampler ---
    clGetEventInfo :: proc(event: cl_event, param_name: cl_event_info, param_value_size: size_t, param_value: rawptr, param_value_size_ret: ^size_t) -> cl_error ---
    clCreateUserEvent :: proc(ctx: cl_context, errorcode_ret: ^cl_error) -> cl_event ---
    clSetUserEventStatus :: proc(event: cl_event, execution_status: cl_command_execution_status) -> cl_error ---
    clSetEventCallback :: proc(event: cl_event, command_exec_callback_type: cl_command_execution_status, pfn_notify: proc "c"(event: cl_event,event_command_status: cl_command_execution_status,user_data: rawptr),user_data: rawptr) -> cl_error ---
    clGetEventProfilingInfo :: proc(event: cl_event, param_name: cl_profiling_info, param_value_size: size_t, param_value: rawptr, param_value_size_ret: ^size_t) -> cl_error ---
    
    clEnqueueNDRangeKernel :: proc(command_queue: cl_command_queue, kernel: cl_kernel, work_dim: cl_uint, global_work_offset: [^]size_t, global_work_size: [^]size_t, local_work_size: [^]size_t, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_error ---
    clEnqueueReadBuffer :: proc(command_queue: cl_command_queue, buffer: cl_mem, blocking_read: cl_bool, offset: size_t, size: size_t, ptr: rawptr, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_error ---
    clEnqueueWriteBuffer :: proc(command_queue: cl_command_queue, buffer: cl_mem, blocking_write: cl_bool, offset: size_t, size: size_t, ptr: rawptr, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_error ---
    clEnqueueTask :: proc(command_queue: cl_command_queue, kernel: cl_kernel, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_error ---
    clEnqueueReadBufferRect :: proc(command_queue: cl_command_queue, buffer: cl_mem, blocking_read: cl_bool, buffer_origin: ^[3]size_t, host_origin: ^[3]size_t, region: ^[3]size_t, buffer_row_pitch: size_t, buffer_slice_pitch: size_t, host_row_pitch: size_t, host_slice_pitch: size_t, ptr: rawptr, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_error ---
    clEnqueueWriteBufferRect :: proc(command_queue: cl_command_queue, buffer: cl_mem, blocking_write: cl_bool, buffer_origin: ^[3]size_t, host_origin: ^[3]size_t, region: ^[3]size_t, buffer_row_pitch: size_t, buffer_slice_pitch: size_t, host_row_pitch: size_t, host_slice_pitch: size_t, ptr: rawptr, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_error ---
    clEnqueueFillBuffer :: proc(command_queue: cl_command_queue, buffer: cl_mem, pattern: rawptr, pattern_size: size_t, offset: size_t, size: size_t, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_error ---
    clEnqueueCopyBuffer :: proc(command_queue: cl_command_queue, src_buffer: cl_mem, dst_buffer: cl_mem, src_offset: size_t, dst_offset: size_t, size: size_t, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_error ---
    clEnqueueCopyBufferRect :: proc(command_queue: cl_command_queue, src_buffer: cl_mem, dst_buffer: cl_mem, src_origin: ^[3]size_t, dst_origin: ^[3]size_t, region: ^[3]size_t, src_row_pitch: size_t, src_slice_pitch: size_t, dst_row_pitch: size_t, dst_slice_pitch: size_t, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_error ---
    clEnqueueReadImage :: proc(command_queue: cl_command_queue, image: cl_mem, blocking_read: cl_bool, origin: ^[3]size_t, region: ^[3]size_t, row_pitch: size_t, slice_pitch: size_t, ptr: rawptr, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_error ---
    clEnqueueWriteImage :: proc(command_queue: cl_command_queue, image: cl_mem, blocking_write: cl_bool, origin: ^[3]size_t, region: ^[3]size_t, input_row_pitch: size_t, input_slice_pitch: size_t, ptr: rawptr, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_error ---
    clEnqueueFillImage :: proc(command_queue: cl_command_queue, image: cl_mem, fill_color: rawptr, origin: ^[3]size_t, region: ^[3]size_t, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_error ---
    clEnqueueCopyImage :: proc(command_queue: cl_command_queue, src_image: cl_mem, dst_image: cl_mem, src_origin: ^[3]size_t, dst_origin: ^[3]size_t, region: ^[3]size_t, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_error ---
    clEnqueueCopyImageToBuffer :: proc(command_queue: cl_command_queue, src_image: cl_mem, dst_buffer: cl_mem, src_origin: ^[3]size_t, region: ^[3]size_t, dst_offset: size_t, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_error ---
    clEnqueueCopyBufferToImage :: proc(command_queue: cl_command_queue, src_buffer: cl_mem, dst_image: cl_mem, src_offset: size_t, dst_origin: ^[3]size_t, region: ^[3]size_t, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_error ---
    clEnqueueMapBuffer :: proc(command_queue: cl_command_queue, buffer: cl_mem, blocking_map: cl_bool, map_flags: cl_map_flags, offset: size_t, size: size_t, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event, event: ^cl_event, errorcode_ret: ^cl_error) -> rawptr ---
    clEnqueueMapImage :: proc(command_queue: cl_command_queue, image: cl_mem, blocking_map: cl_bool, map_flags: cl_map_flags, origin: ^[3]size_t, region: ^[3]size_t, image_row_pitch: ^size_t, image_slice_pitch: ^size_t, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event, event: ^cl_event, errorcode_ret: ^cl_error) -> rawptr ---
    clEnqueueUnmapMemObject :: proc(command_queue: cl_command_queue, memobj: cl_mem, mapped_ptr: rawptr, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_error ---
    clEnqueueMigrateMemObjects :: proc(command_queue: cl_command_queue, num_mem_objects: cl_uint, mem_objects: [^]cl_mem, flags: cl_mem_migration_flags, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_error ---
    clEnqueueNativeKernel :: proc(command_queue: cl_command_queue, user_func : proc "c" (rawptr), args: rawptr, cb_args: size_t, num_mem_objects: cl_uint, mem_list: [^]cl_mem, args_mem_loc: [^]^cl_mem, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_error ---

    clCreateSamplerWithProperties :: proc(ctx: cl_context, sampler_properties: [^]cl_sampler_properties, errcode_ret: ^cl_error) -> cl_sampler ---
    clRetainSampler :: proc(sampler: cl_sampler) -> cl_error ---
    clReleaseSampler :: proc(sampler: cl_sampler) -> cl_error ---
    clGetSamplerInfo :: proc(sampler: cl_sampler, param_name: cl_sampler_info, param_value_size: size_t, param_value: rawptr, param_value_size_ret: ^size_t) -> cl_error ---
    clSetProgramSpecializationConstant :: proc(program: cl_program, spec_id: cl_uint, spec_size: size_t, spec_value: rawptr) -> cl_error ---
    clSetProgramReleaseCallback :: proc(program: cl_program, pfn_notify: proc "c"(program: cl_program, user_data: rawptr), user_data: rawptr) -> cl_error ---
    clUnloadPlatformCompiler :: proc(platform: cl_platform_id) -> cl_error ---
    clEnqueueMarkerWithWaitList :: proc(command_queue: cl_command_queue, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_error ---
    clEnqueueBarrierWithWaitList :: proc(command_queue: cl_command_queue, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_error ---

    clEnqueueSVMFree :: proc(command_queue: cl_command_queue, num_svm_pointers: cl_uint, svm_pointers: [^]svm_pointer, pfn_free_func: proc "c"(queue: cl_command_queue , num_svm_pointers: cl_uint, svm_pointers: [^]svm_pointer, user_data: rawptr), user_data: rawptr, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_error ---
    clEnqueueSVMMemcpy :: proc(command_queue: cl_command_queue, blocking_copy: cl_bool, dst_ptr: struct #raw_union{host: rawptr, svm: svm_pointer}, src_ptr: struct #raw_union{host: rawptr, svm: svm_pointer}, size: size_t, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_error ---
    clEnqueueSVMMemFill :: proc(command_queue: cl_command_queue, svm_ptr: svm_pointer, pattern: rawptr, pattern_size: size_t, size: size_t, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_error ---
    clEnqueueSVMMap :: proc(command_queue: cl_command_queue, blocking_map: cl_bool, flags: cl_map_flags, svm_ptr: svm_pointer, size: size_t, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_error ---
    clEnqueueSVMUnmap :: proc(command_queue: cl_command_queue, svm_ptr: svm_pointer, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_error ---
    clEnqueueSVMMigrateMem :: proc(command_queue: cl_command_queue, num_svm_pointers: cl_uint, svm_pointers: [^]svm_pointer, sizes: [^]size_t, flags: cl_mem_migration_flags, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_error ---
    clGetExtensionFunctionAddressForPlatform :: proc(platform: cl_platform_id, func_name: cstring) -> proc "c"() ---

    /*
     *  WARNING:
     *     This API introduces mutable state into the OpenCL implementation. It has been REMOVED
     *  to better facilitate thread safety.  The 1.0 API is not thread safe. It is not tested by the
     *  OpenCL 1.1 conformance test, and consequently may not work or may not work dependably.
     *  It is likely to be non-performant. Use of this API is not advised. Use at your own risk.
     *
     *  Software developers previously relying on this API are instructed to set the command queue
     *  properties when creating the queue, instead.
     */
    clSetCommandQueueProperty :: proc(command_queue: cl_command_queue, properties: cl_command_queue_properties, enable: cl_bool, old_properties: ^cl_command_queue_properties) -> cl_error ---

    /* Deprecated OpenCL 1.1 APIs */
    clCreateImage2D :: proc(ctx: cl_context, flags: cl_mem_flags, image_format: ^cl_image_format , image_width: size_t, image_height: size_t, image_row_pitch: size_t, host_ptr: rawptr, errcode_ret: ^cl_error) -> cl_mem ---
    clCreateImage3D :: proc(ctx: cl_context, flags: cl_mem_flags, image_format: ^cl_image_format, image_width: size_t, image_height: size_t, image_depth: size_t, image_row_pitch: size_t, image_slice_pitch: size_t, host_ptr: rawptr, errcode_ret: ^cl_error) -> cl_mem ---
    clEnqueueMarker :: proc(command_queue: cl_command_queue, event: ^cl_event) -> cl_error ---
    clEnqueueWaitForEvents :: proc(command_queue: cl_command_queue, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event) -> cl_error ---
    clEnqueueBarrier :: proc(command_queue: cl_command_queue) -> cl_error ---
    clUnloadCompiler :: proc() -> cl_error ---
    clGetExtensionFunctionAddress :: proc(func_name: cstring) -> proc "c"() ---
}

// cl_egl.h

CLeglImageKHR:: distinct rawptr 
CLeglDisplayKHR:: distinct rawptr 
CLeglSyncKHR:: distinct rawptr 
/* properties passed to clCreateFromEGLImageKHR */
cl_egl_image_properties_khr :: cl_properties
cl_khr_egl_image :: 1
cl_khr_egl_event :: 1

clCreateFromEGLImageKHR_fn :: #type proc "c"(ctx: cl_context, egldisplay: CLeglDisplayKHR, eglimage: CLeglImageKHR, flags: cl_mem_flags, properties: [^]cl_egl_image_properties_khr, errcode_ret: ^cl_error) -> cl_mem
clEnqueueAcquireEGLObjectsKHR_fn :: #type proc "c"(command_queue: cl_command_queue, num_objects: cl_uint, mem_objects: [^]cl_mem, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_error
clEnqueueReleaseEGLObjectsKHR_fn :: #type proc "c"(command_queue: cl_command_queue, num_objects: cl_uint, mem_objects: [^]cl_mem, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_error
clCreateEventFromEGLSyncKHR_fn :: #type proc "c"(ctx: cl_context, sync: CLeglSyncKHR, display: CLeglDisplayKHR, errcode_ret: ^cl_error) -> cl_event

getFnClCreateFromEGLImageKHR :: proc "c"(platform: cl_platform_id) -> clCreateFromEGLImageKHR_fn{
    return auto_cast clGetExtensionFunctionAddressForPlatform(platform, "clCreateFromEGLImageKHR")
}
getFnClEnqueueAcquireEGLObjectsKHR :: proc "c"(platform: cl_platform_id) -> clEnqueueAcquireEGLObjectsKHR_fn{
    return auto_cast clGetExtensionFunctionAddressForPlatform(platform, "clEnqueueAcquireEGLObjectsKHR")
}
getFnClEnqueueReleaseEGLObjectsKHR :: proc "c"(platform: cl_platform_id) -> clEnqueueReleaseEGLObjectsKHR_fn{
    return auto_cast clGetExtensionFunctionAddressForPlatform(platform, "clEnqueueReleaseEGLObjectsKHR")
}
getFnClCreateEventFromEGLSyncKHR :: proc "c"(platform: cl_platform_id) -> clCreateEventFromEGLSyncKHR_fn{
    return auto_cast clGetExtensionFunctionAddressForPlatform(platform, "clCreateEventFromEGLSyncKHR")
}

// cl_gl.h
cl_GLuint :: u32
cl_GLenum :: u32
cl_GLint :: i32

cl_gl_object_type :: enum cl_uint {
    BUFFER          = 0x2000,
    TEXTURE2D       = 0x2001,
    TEXTURE3D       = 0x2002,
    RENDERBUFFER    = 0x2003,
    TEXTURE2D_ARRAY = 0x200E,
    TEXTURE1D       = 0x200F,
    TEXTURE1D_ARRAY = 0x2010,
    TEXTURE_BUFFER  = 0x2011,
}
cl_gl_texture_info :: enum cl_uint {
    TEXTURE_TARGET = 0x2004,
    MIPMAP_LEVEL   = 0x2005,
    NUM_SAMPLES    = 0x2012,
}
cl_GLsync:: distinct rawptr


clCreateFromGLBuffer_fn :: #type proc "c"(ctx: cl_context, flags: cl_mem_flags, bufobj: cl_GLuint, errcode_ret: ^cl_error) -> cl_mem
clCreateFromGLTexture_fn :: #type proc "c"(ctx: cl_context, flags: cl_mem_flags, target: cl_GLenum, miplevel: cl_GLint, texture: cl_GLuint, errcode_ret: ^cl_error) -> cl_mem
clCreateFromGLRenderbuffer_fn :: #type proc "c"(ctx: cl_context, flags: cl_mem_flags, renderbuffer: cl_GLuint, errcode_ret: ^cl_error) -> cl_mem
clGetGLObjectInfo_fn :: #type proc "c"(memobj: cl_mem, gl_object_type: ^cl_gl_object_type, gl_object_name: ^cl_GLuint) -> cl_error
clGetGLTextureInfo_fn :: #type proc "c"(memobj: cl_mem, param_name: cl_gl_texture_info, param_value_size: size_t, param_value: rawptr, param_value_size_ret: ^size_t) -> cl_error
clEnqueueAcquireGLObjects_fn :: #type proc "c"(command_queue: cl_command_queue, num_objects: cl_uint, mem_objects: [^]cl_mem, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_error
clEnqueueReleaseGLObjects_fn :: #type proc "c"(command_queue: cl_command_queue, num_objects: cl_uint, mem_objects: [^]cl_mem, num_events_in_wait_list: cl_uint, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_error
clCreateFromGLTexture2D_fn :: #type proc "c"(ctx: cl_context, flags: cl_mem_flags, target: cl_GLenum, miplevel: cl_GLint, texture: cl_GLuint, errcode_ret: ^cl_error) -> cl_mem
clCreateFromGLTexture3D_fn :: #type proc "c"(ctx: cl_context, flags: cl_mem_flags, target: cl_GLenum, miplevel: cl_GLint, texture: cl_GLuint, errcode_ret: ^cl_error) -> cl_mem

getFnClCreateFromGLBuffer :: proc "c"(platform: cl_platform_id) -> clCreateFromGLBuffer_fn {
    return auto_cast clGetExtensionFunctionAddressForPlatform(platform, "clCreateFromGLBuffer")
}
getFnClCreateFromGLTexture :: proc "c"(platform: cl_platform_id) -> clCreateFromGLTexture_fn {
    return auto_cast clGetExtensionFunctionAddressForPlatform(platform, "clCreateFromGLTexture")
}
getFnClCreateFromGLRenderbuffer :: proc "c"(platform: cl_platform_id) -> clCreateFromGLRenderbuffer_fn {
    return auto_cast clGetExtensionFunctionAddressForPlatform(platform, "clCreateFromGLRenderbuffer")
}
getFnClGetGLObjectInfo :: proc "c"(platform: cl_platform_id) -> clGetGLObjectInfo_fn {
    return auto_cast clGetExtensionFunctionAddressForPlatform(platform, "clGetGLObjectInfo")
}
getFnClGetGLTextureInfo :: proc "c"(platform: cl_platform_id) -> clGetGLTextureInfo_fn {
    return auto_cast clGetExtensionFunctionAddressForPlatform(platform, "clGetGLTextureInfo")
}
getFnClEnqueueAcquireGLObjects :: proc "c"(platform: cl_platform_id) -> clEnqueueAcquireGLObjects_fn {
    return auto_cast clGetExtensionFunctionAddressForPlatform(platform, "clEnqueueAcquireGLObjects")
}
getFnClEnqueueReleaseGLObjects :: proc "c"(platform: cl_platform_id) -> clEnqueueReleaseGLObjects_fn {
    return auto_cast clGetExtensionFunctionAddressForPlatform(platform, "clEnqueueReleaseGLObjects")
}
getFnClCreateFromGLTexture2D :: proc "c"(platform: cl_platform_id) -> clCreateFromGLTexture2D_fn {
    return auto_cast clGetExtensionFunctionAddressForPlatform(platform, "clCreateFromGLTexture2D")
}
getFnClCreateFromGLTexture3D :: proc "c"(platform: cl_platform_id) -> clCreateFromGLTexture3D_fn {
    return auto_cast clGetExtensionFunctionAddressForPlatform(platform, "clCreateFromGLTexture3D")
}

/* cl_khr_gl_sharing extension  */

cl_khr_gl_sharing :: 1

cl_gl_context_info :: enum cl_uint {
    CURRENT_DEVICE_FOR_GL_CONTEXT_KHR = 0x2006,
    DEVICES_FOR_GL_CONTEXT_KHR        = 0x2007,
}

clGetGLContextInfoKHR_fn :: #type proc "c"(properties: [^]cl_context_properties, param_name: cl_gl_context_info, param_value_size: size_t, param_value: rawptr, param_value_size_ret: ^size_t) -> cl_error
clCreateEventFromGLsyncKHR_fn :: #type proc "c"(ctx: cl_context, sync: cl_GLsync, errcode_ret: ^cl_error) -> cl_event

// cl_intel_sharing_format_query_gl

cl_intel_sharing_format_query_gl :: 1

/* when cl_khr_gl_sharing is supported */

clGetSupportedGLTextureFormatsINTEL_fn :: #type proc "c"(ctx: cl_context, flags: cl_mem_flags, image_type: cl_mem_object_type, num_entries: cl_uint, gl_formats: [^]cl_GLenum, num_texture_formats: ^cl_uint) -> cl_error

getFnClGetGLContextInfoKHR :: proc "c"(platform: cl_platform_id) -> clGetGLContextInfoKHR_fn {
    return auto_cast clGetExtensionFunctionAddressForPlatform(platform, "clGetGLContextInfoKHR")
}
getFnClCreateEventFromGLsyncKHR :: proc "c"(platform: cl_platform_id) -> clCreateEventFromGLsyncKHR_fn {
    return auto_cast clGetExtensionFunctionAddressForPlatform(platform, "clCreateEventFromGLsyncKHR")
}
getFnClGetSupportedGLTextureFormatsINTEL :: proc "c"(platform: cl_platform_id) -> clGetSupportedGLTextureFormatsINTEL_fn {
    return auto_cast clGetExtensionFunctionAddressForPlatform(platform, "clGetSupportedGLTextureFormatsINTEL")
}