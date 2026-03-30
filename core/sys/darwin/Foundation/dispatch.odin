package objc_Foundation

import "core:c"
import "core:sys/darwin"

@(require)
foreign import "system:System"

@(default_calling_convention="c")
foreign System {
    @(link_name="dispatch_get_global_queue")
    dispatch_get_global_queue_by_intptr :: proc(
        identifier: c.intptr_t,
        flags:      c.uintptr_t,
    ) -> dispatch_queue_global_t ---

    dispatch_queue_create :: proc(
        label: cstring,
        attr:  dispatch_queue_attr_t,
    ) -> dispatch_queue_t ---

    dispatch_queue_create_with_target :: proc(
        label:  cstring,
        attr:   dispatch_queue_attr_t,
        target: dispatch_queue_t,
    ) -> dispatch_queue_t ---

    dispatch_queue_attr_make_with_qos_class :: proc(
        attr:              dispatch_queue_attr_t,
        qos_class:         dispatch_qos_class_t,
        relative_priority: c.int,
    ) -> dispatch_queue_attr_t ---

    dispatch_queue_get_qos_class :: proc(
        queue:                 dispatch_queue_t,
        relative_priority_ptr: ^c.int,
    ) -> dispatch_qos_class_t ---

    dispatch_queue_attr_make_initially_inactive :: proc(
        attr: dispatch_queue_attr_t,
    ) -> dispatch_queue_attr_t ---

    dispatch_queue_attr_make_with_autorelease_frequency :: proc(
        attr:      dispatch_queue_attr_t,
        frequency: dispatch_autorelease_frequency_t,
    ) -> dispatch_queue_attr_t ---

    dispatch_async :: proc(
        queue: dispatch_queue_t,
        block: dispatch_block_t,
    ) ---

    dispatch_async_f :: proc(
        queue:    dispatch_queue_t,
        _context: rawptr,
        work:     dispatch_function_t,
    ) ---

    dispatch_after :: proc(
        _when: dispatch_time_t,
        queue: dispatch_queue_t,
        block: dispatch_block_t,
    ) ---

    dispatch_after_f :: proc(
        _when:    dispatch_time_t,
        queue:    dispatch_queue_t,
        _context: rawptr,
        work:     dispatch_function_t,
    ) ---

    dispatch_sync :: proc(
        queue: dispatch_queue_t,
        block: dispatch_block_t,
    ) ---

    dispatch_sync_f :: proc(
        queue:    dispatch_queue_t,
        _context: rawptr,
        work:     dispatch_function_t,
    ) ---

    dispatch_async_and_wait :: proc(
        queue: dispatch_queue_t,
        block: dispatch_block_t,
    ) ---

    dispatch_async_and_wait_f :: proc(
        queue:    dispatch_queue_t,
        _context: rawptr,
        work:     dispatch_function_t,
    ) ---

    dispatch_barrier_async_and_wait :: proc(
        queue: dispatch_queue_t,
        block: dispatch_block_t,
    ) ---

    dispatch_barrier_async_and_wait_f :: proc(
        queue:    dispatch_queue_t,
        _context: rawptr,
        work:     dispatch_function_t,
    ) ---

    dispatch_once :: proc(
        predicate: ^dispatch_once_t,
        block:     dispatch_block_t,
    ) ---

    dispatch_once_f :: proc(
        predicate: ^dispatch_once_t,
        _context:  rawptr,
        function:  dispatch_function_t,
    ) ---

    dispatch_apply :: proc(
        iterations: c.size_t,
        queue:      dispatch_queue_t,
        block:      ^Objc_Block(proc "c" (iteration: c.size_t)),
    ) ---

    dispatch_apply_f :: proc(
        iterations: c.size_t,
        queue:      dispatch_queue_t,
        _context:   rawptr,
        work:       proc "c" (rawptr, c.ulong),
    ) ---

    dispatch_barrier_async :: proc(
        queue: dispatch_queue_t,
        block: dispatch_block_t,
    ) ---

    dispatch_barrier_async_f :: proc(
        queue:    dispatch_queue_t,
        _context: rawptr,
        work:     dispatch_function_t,
    ) ---

    dispatch_barrier_sync :: proc(
        queue: dispatch_queue_t,
        block: dispatch_block_t,
    ) ---

    dispatch_barrier_sync_f :: proc(
        queue:    dispatch_queue_t,
        _context: rawptr,
        work:     dispatch_function_t,
    ) ---

    dispatch_queue_get_label :: proc(
        queue: dispatch_queue_t,
    ) -> cstring ---

    dispatch_set_target_queue :: proc(
        object: dispatch_object_t,
        queue:  dispatch_queue_t,
    ) ---

    dispatch_get_specific :: proc(
        key: rawptr,
    ) -> rawptr ---

    dispatch_queue_set_specific :: proc(
        queue:      dispatch_queue_t,
        key:        rawptr,
        _context:   rawptr,
        destructor: dispatch_function_t,
    ) ---

    dispatch_queue_get_specific :: proc(
        queue: dispatch_queue_t,
        key: rawptr,
    ) -> rawptr ---

    dispatch_main :: proc() ---

    dispatch_assert_queue :: proc(
        queue: dispatch_queue_t,
    ) ---

    dispatch_assert_queue_barrier :: proc(
        queue: dispatch_queue_t,
    ) ---

    dispatch_assert_queue_not :: proc(
        queue: dispatch_queue_t,
    ) ---

    dispatch_block_create :: proc(
        flags: dispatch_block_flags_t,
        block: dispatch_block_t,
    ) -> dispatch_block_t ---

    dispatch_block_create_with_qos_class :: proc(
        flags:             dispatch_block_flags_t,
        qos_class:         dispatch_qos_class_t,
        relative_priority: c.int,
        block:             dispatch_block_t,
    ) -> dispatch_block_t ---

    dispatch_block_perform :: proc(
        flags: dispatch_block_flags_t,
        block: dispatch_block_t,
    ) ---

    dispatch_block_notify :: proc(
        block:              dispatch_block_t,
        queue:              dispatch_queue_t,
        notification_block: dispatch_block_t,
    ) ---

    dispatch_block_wait :: proc(
        block:   dispatch_block_t,
        timeout: dispatch_time_t,
    ) -> c.intptr_t ---

    dispatch_block_cancel :: proc(
        block: dispatch_block_t,
    ) ---

    dispatch_block_testcancel :: proc(
        block: dispatch_block_t,
    ) -> c.intptr_t ---

    dispatch_group_create :: proc() -> dispatch_group_t ---

    dispatch_group_async :: proc(
        group: dispatch_group_t,
        queue: dispatch_queue_t,
        block: dispatch_block_t,
    ) ---

    dispatch_group_async_f :: proc(
        group:    dispatch_group_t,
        queue:    dispatch_queue_t,
        _context: rawptr,
        work:     dispatch_function_t,
    ) ---

    dispatch_group_notify :: proc(
        group: dispatch_group_t,
        queue: dispatch_queue_t,
        block: dispatch_block_t,
    ) ---

    dispatch_group_notify_f :: proc(
        group:    dispatch_group_t,
        queue:    dispatch_queue_t,
        _context: rawptr,
        work:     dispatch_function_t,
    ) ---

    dispatch_group_wait :: proc(
        group:   dispatch_group_t,
        timeout: dispatch_time_t,
    ) -> c.intptr_t ---

    dispatch_group_enter :: proc(
        group: dispatch_group_t,
    ) ---

    dispatch_group_leave :: proc(
        group: dispatch_group_t,
    ) ---

    dispatch_workloop_create :: proc(
        label: cstring,
    ) -> dispatch_workloop_t ---

    dispatch_workloop_create_inactive :: proc(
        label: cstring,
    ) -> dispatch_workloop_t ---

    dispatch_workloop_set_autorelease_frequency :: proc(
        workloop:  dispatch_workloop_t,
        frequency: dispatch_autorelease_frequency_t,
    ) ---

    dispatch_set_qos_class_floor :: proc(
        object:            dispatch_object_t,
        qos_class:         dispatch_qos_class_t,
        relative_priority: c.int,
    ) ---

    dispatch_source_create :: proc(
        type:   dispatch_source_type_t,
        handle: c.uintptr_t,
        mask:   c.uintptr_t,
        queue:  dispatch_queue_t,
    ) -> dispatch_source_t ---

    dispatch_source_set_registration_handler_f :: proc(
        source:  dispatch_source_t,
        handler: dispatch_function_t,
    ) ---

    dispatch_source_set_registration_handler :: proc(
        source:  dispatch_source_t,
        handler: dispatch_block_t,
    ) ---

    dispatch_source_set_event_handler_f :: proc(
        source:  dispatch_source_t,
        handler: dispatch_function_t,
    ) ---

    dispatch_source_set_event_handler :: proc(
        source:  dispatch_source_t,
        handler: dispatch_block_t,
    ) ---

    dispatch_source_set_cancel_handler_f :: proc(
        source:  dispatch_source_t,
        handler: dispatch_function_t,
    ) ---

    dispatch_source_set_cancel_handler :: proc(
        source:  dispatch_source_t,
        handler: dispatch_block_t,
    ) ---

    dispatch_source_get_data :: proc(
        source: dispatch_source_t,
    ) -> c.uintptr_t ---

    dispatch_source_get_mask :: proc(
        source: dispatch_source_t,
    ) -> c.uintptr_t ---

    dispatch_source_get_handle :: proc(
        source: dispatch_source_t,
    ) -> c.uintptr_t ---

    dispatch_source_merge_data :: proc(
        source: dispatch_source_t,
        value: c.uintptr_t,
    ) ---

    dispatch_source_set_timer :: proc(
        source:   dispatch_source_t,
        start:    dispatch_time_t,
        interval: c.uint64_t,
        leeway:   c.uint64_t,
    ) ---

    dispatch_source_cancel :: proc(
        source: dispatch_source_t,
    ) ---

    dispatch_source_testcancel :: proc(
        source: dispatch_source_t,
    ) -> c.intptr_t ---

    dispatch_io_create :: proc(
        type:            dispatch_io_type_t,
        fd:              dispatch_fd_t,
        queue:           dispatch_queue_t,
        cleanup_handler: ^Objc_Block(proc "c" (error: c.int)),
    ) -> dispatch_io_t ---

    dispatch_io_create_with_io :: proc(
        type:            dispatch_io_type_t,
        io:              dispatch_io_t,
        queue:           dispatch_queue_t,
        cleanup_handler: ^Objc_Block(proc "c" (error: c.int)),
    ) -> dispatch_io_t ---

    dispatch_io_create_with_path :: proc(
        type:            dispatch_io_type_t,
        path:            cstring,
        oflag:           c.int,
        mode:            darwin.mode_t,
        queue:           dispatch_queue_t,
        cleanup_handler: ^Objc_Block(proc "c" (error: c.int)),
    ) -> dispatch_io_t ---

    dispatch_read :: proc(
        fd:      dispatch_fd_t,
        length:  c.size_t,
        queue:   dispatch_queue_t,
        handler: ^Objc_Block(proc "c" (data: dispatch_data_t, error: c.int)),
    ) ---

    dispatch_io_read :: proc(
        channel:    dispatch_io_t,
        offset:     darwin.off_t,
        length:     c.size_t,
        queue:      dispatch_queue_t,
        io_handler: dispatch_io_handler_t,
    ) ---

    dispatch_write :: proc(
        fd:      dispatch_fd_t,
        data:    dispatch_data_t,
        queue:   dispatch_queue_t,
        handler: ^Objc_Block(proc "c" (data: dispatch_data_t, error: c.int)),
    ) ---

    dispatch_io_write :: proc(
        channel:    dispatch_io_t,
        offset:     darwin.off_t,
        data:       dispatch_data_t,
        queue:      dispatch_queue_t,
        io_handler: dispatch_io_handler_t,
    ) ---

    dispatch_io_close :: proc(
        channel: dispatch_io_t,
        flags:   dispatch_io_close_flags_t,
    ) ---

    dispatch_io_get_descriptor :: proc(
        channel: dispatch_io_t,
    ) -> dispatch_fd_t ---

    dispatch_io_set_interval :: proc(
        channel:  dispatch_io_t,
        interval: c.uint64_t,
        flags:    dispatch_io_interval_flags_t,
    ) ---

    dispatch_io_set_low_water :: proc(
        channel:   dispatch_io_t,
        low_water: c.size_t,
    ) ---

    dispatch_io_set_high_water :: proc(
        channel:    dispatch_io_t,
        high_water: c.size_t,
    ) ---

    dispatch_io_barrier :: proc(
        channel: dispatch_io_t,
        barrier: dispatch_block_t,
    ) ---

    dispatch_data_create :: proc(
        buffer:     rawptr,
        size:       c.size_t,
        queue:      dispatch_queue_t,
        destructor: dispatch_block_t,
    ) -> dispatch_data_t ---

    dispatch_data_create_map :: proc(
        data:       dispatch_data_t,
        buffer_ptr: ^rawptr,
        size_ptr:   ^c.size_t,
    ) -> dispatch_data_t ---

    dispatch_data_create_concat :: proc(
        data1: dispatch_data_t,
        data2: dispatch_data_t,
    ) -> dispatch_data_t ---

    dispatch_data_create_subrange :: proc(
        data:   dispatch_data_t,
        offset: c.size_t,
        length: c.size_t,
    ) -> dispatch_data_t ---

    dispatch_data_copy_region :: proc(
        data:       dispatch_data_t,
        location:   c.size_t,
        offset_ptr: ^c.size_t,
    ) -> dispatch_data_t ---

    dispatch_data_get_size :: proc(
        data: dispatch_data_t,
    ) -> c.size_t ---

    dispatch_data_apply :: proc(
        data:    dispatch_data_t,
        applier: dispatch_data_applier_t,
    ) -> c.bool ---

    dispatch_semaphore_create :: proc(
        value: c.intptr_t,
    ) -> dispatch_semaphore_t ---

    dispatch_semaphore_signal :: proc(
        dsema: dispatch_semaphore_t,
    ) -> c.intptr_t ---

    dispatch_semaphore_wait :: proc(
        dsema:   dispatch_semaphore_t,
        timeout: dispatch_time_t,
    ) -> c.intptr_t ---

    dispatch_time :: proc(
        _when: dispatch_time_t,
        delta: c.int64_t,
    ) -> dispatch_time_t ---

    dispatch_walltime :: proc(
        _when: ^darwin.timespec,
        delta: c.int64_t,
    ) -> dispatch_time_t ---

    dispatch_activate :: proc(
        object: dispatch_object_t,
    ) ---

    dispatch_suspend :: proc(
        object: dispatch_object_t,
    ) ---

    dispatch_resume :: proc(
        object: dispatch_object_t,
    ) ---

    dispatch_get_context :: proc(
        object: dispatch_object_t,
    ) -> rawptr ---

    dispatch_set_context :: proc(
        object:   dispatch_object_t,
        _context: rawptr,
    ) ---

    dispatch_retain :: proc(
        object: dispatch_object_t,
    ) ---

    dispatch_release :: proc(
        object: dispatch_object_t,
    ) ---

    dispatch_set_finalizer_f :: proc(
        object:    dispatch_object_t,
        finalizer: dispatch_function_t,
    ) ---

    dispatch_allow_send_signals :: proc(
        preserve_signum: c.int,
    ) -> c.int ---

    dispatch_workloop_set_os_workgroup :: proc(
        workloop:  dispatch_workloop_t,
        workgroup: os_workgroup_t,
    ) ---

    _dispatch_main_q: dispatch_queue_s

    _dispatch_source_type_data_add:       dispatch_source_type_s
    _dispatch_source_type_data_or:        dispatch_source_type_s
    _dispatch_source_type_data_replace:   dispatch_source_type_s
    _dispatch_source_type_mach_send:      dispatch_source_type_s
    _dispatch_source_type_mach_recv:      dispatch_source_type_s
    _dispatch_source_type_memorypressure: dispatch_source_type_s
    _dispatch_source_type_proc:           dispatch_source_type_s
    _dispatch_source_type_read:           dispatch_source_type_s
    _dispatch_source_type_signal:         dispatch_source_type_s
    _dispatch_source_type_timer:          dispatch_source_type_s
    _dispatch_source_type_vnode:          dispatch_source_type_s
    _dispatch_source_type_write:          dispatch_source_type_s

    _dispatch_data_empty: dispatch_data_s;

    _dispatch_data_destructor_free: dispatch_block_t

    _dispatch_queue_attr_concurrent: dispatch_queue_attr_s
}

dispatch_get_main_queue :: proc "contextless" () -> dispatch_queue_main_t {
    return dispatch_queue_main_t(&_dispatch_main_q)
}

dispatch_get_global_queue :: proc{
    dispatch_get_global_queue_by_intptr,
    dispatch_get_global_queue_by_priority,
    dispatch_get_global_queue_by_qos,
}
dispatch_get_global_queue_by_priority :: proc "contextless" (
    priority: dispatch_queue_priority_t,
) -> dispatch_queue_global_t {
    return dispatch_get_global_queue_by_intptr(c.intptr_t(priority), 0)
}
dispatch_get_global_queue_by_qos :: proc "contextless" (
    qos: darwin.qos_class_t,
) -> dispatch_queue_global_t {
    return dispatch_get_global_queue_by_intptr(c.intptr_t(qos), 0)
}

DISPATCH_SOURCE_TYPE_DATA_ADD       :: proc "contextless" () -> dispatch_source_type_t {
    return &_dispatch_source_type_data_add
}
DISPATCH_SOURCE_TYPE_DATA_OR        :: proc "contextless" () -> dispatch_source_type_t {
    return &_dispatch_source_type_data_or
}
DISPATCH_SOURCE_TYPE_DATA_REPLACE   :: proc "contextless" () -> dispatch_source_type_t {
    return &_dispatch_source_type_data_replace
}
DISPATCH_SOURCE_TYPE_MACH_SEND      :: proc "contextless" () -> dispatch_source_type_t {
    return &_dispatch_source_type_mach_send
}
DISPATCH_SOURCE_TYPE_MACH_RECV      :: proc "contextless" () -> dispatch_source_type_t {
    return &_dispatch_source_type_mach_recv
}
DISPATCH_SOURCE_TYPE_MEMORYPRESSURE :: proc "contextless" () -> dispatch_source_type_t {
    return &_dispatch_source_type_memorypressure
}
DISPATCH_SOURCE_TYPE_PROC           :: proc "contextless" () -> dispatch_source_type_t {
    return &_dispatch_source_type_proc
}
DISPATCH_SOURCE_TYPE_READ           :: proc "contextless" () -> dispatch_source_type_t {
    return &_dispatch_source_type_read
}
DISPATCH_SOURCE_TYPE_SIGNAL         :: proc "contextless" () -> dispatch_source_type_t {
    return &_dispatch_source_type_signal
}
DISPATCH_SOURCE_TYPE_TIMER          :: proc "contextless" () -> dispatch_source_type_t {
    return &_dispatch_source_type_timer
}
DISPATCH_SOURCE_TYPE_VNODE          :: proc "contextless" () -> dispatch_source_type_t {
    return &_dispatch_source_type_vnode
}
DISPATCH_SOURCE_TYPE_WRITE          :: proc "contextless" () -> dispatch_source_type_t {
    return &_dispatch_source_type_write
}

dispatch_data_empty :: proc "contextless" () -> dispatch_data_t {
    return &_dispatch_data_empty
}

DISPATCH_DATA_DESTRUCTOR_DEFAULT :: proc "contextless" () -> dispatch_block_t {
    return nil
}
DISPATCH_DATA_DESTRUCTOR_FREE    :: proc "contextless" () -> dispatch_block_t {
    return _dispatch_data_destructor_free
}

DISPATCH_QUEUE_SERIAL :: proc "contextless" () -> dispatch_queue_attr_t {
    return nil
}
DISPATCH_QUEUE_SERIAL_INACTIVE :: proc "contextless" () -> dispatch_queue_attr_t {
    return dispatch_queue_attr_make_initially_inactive(DISPATCH_QUEUE_SERIAL())
}
DISPATCH_QUEUE_SERIAL_WITH_AUTORELEASE_POOL :: proc "contextless" () -> dispatch_queue_attr_t {
    return dispatch_queue_attr_make_with_autorelease_frequency(
        DISPATCH_QUEUE_SERIAL(), dispatch_autorelease_frequency_t.WORK_ITEM)
}
DISPATCH_QUEUE_CONCURRENT :: proc "contextless" () -> dispatch_queue_attr_t {
    return dispatch_queue_attr_t(&_dispatch_queue_attr_concurrent)
}
DISPATCH_QUEUE_CONCURRENT_INACTIVE :: proc "contextless" () -> dispatch_queue_attr_t {
    return dispatch_queue_attr_make_initially_inactive(DISPATCH_QUEUE_CONCURRENT())
}
DISPATCH_QUEUE_CONCURRENT_WITH_AUTORELEASE_POOL :: proc "contextless" () -> dispatch_queue_attr_t {
    return dispatch_queue_attr_make_with_autorelease_frequency(
        DISPATCH_QUEUE_CONCURRENT(), dispatch_autorelease_frequency_t.WORK_ITEM)
}

dispatch_cancel :: proc{
    dispatch_block_cancel,
    dispatch_source_cancel,
}

dispatch_notify :: proc{
    dispatch_block_notify,
    dispatch_group_notify,
}

dispatch_testcancel :: proc{
    dispatch_block_testcancel,
    dispatch_source_testcancel,
}

dispatch_wait :: proc{
    dispatch_block_wait,
    dispatch_group_wait,
    dispatch_semaphore_wait,
}

dispatch_object_t  :: ^OS_dispatch_object
OS_dispatch_object :: struct{using _: ObjectProtocol}
dispatch_object_s  :: OS_dispatch_object

dispatch_queue_t  :: ^OS_dispatch_queue
OS_dispatch_queue :: struct{using _: OS_dispatch_object}
dispatch_queue_s  :: OS_dispatch_queue

dispatch_queue_main_t  :: ^OS_dispatch_queue_main
OS_dispatch_queue_main :: struct{using _: OS_dispatch_queue_serial}
dispatch_queue_main_s  :: OS_dispatch_queue_main

dispatch_queue_global_t  :: ^OS_dispatch_queue_global
OS_dispatch_queue_global :: struct{using _: OS_dispatch_queue}
dispatch_queue_global_s  :: OS_dispatch_queue_global

dispatch_queue_serial_t  :: ^OS_dispatch_queue_serial
OS_dispatch_queue_serial :: struct{using _: OS_dispatch_queue}
dispatch_queue_serial_s  :: OS_dispatch_queue_serial

dispatch_queue_concurrent_t  :: ^OS_dispatch_queue_concurrent
OS_dispatch_queue_concurrent :: struct{using _: OS_dispatch_queue}
dispatch_queue_concurrent_s  :: OS_dispatch_queue_concurrent

dispatch_queue_attr_t  :: ^OS_dispatch_queue_attr
OS_dispatch_queue_attr :: struct{using _: OS_dispatch_object}
dispatch_queue_attr_s  :: OS_dispatch_queue_attr

dispatch_qos_class_t :: darwin.qos_class_t

dispatch_autorelease_frequency_t :: enum c.ulong {
    INHERIT   = 0,
    WORK_ITEM = 1,
    NEVER     = 2,
}

dispatch_function_t :: proc "c" (rawptr)

dispatch_block_t :: ^Objc_Block(proc "c" ())

dispatch_block_flags_t :: bit_set[enum{
    BARRIER           = 0,
    DETACHED          = 1,
    ASSIGN_CURRENT    = 2,
    NO_QOS_CLASS      = 3,
    INHERIT_QOS_CLASS = 4,
    ENFORCE_QOS_CLASS = 5,
}; c.ulong]

dispatch_once_t :: c.intptr_t

DISPATCH_APPLY_AUTO :: dispatch_queue_t(uintptr(0))

DISPATCH_CURRENT_QUEUE_LABEL :: dispatch_queue_t(uintptr(0))

dispatch_group_t  :: ^OS_dispatch_group
OS_dispatch_group :: struct{using _: OS_dispatch_object}
dispatch_group_s  :: OS_dispatch_group

dispatch_workloop_t  :: ^OS_dispatch_workloop
OS_dispatch_workloop :: struct{using _: OS_dispatch_queue}
dispatch_workloop_s  :: OS_dispatch_workloop

dispatch_queue_priority_t :: enum c.long {
    HIGH       = 2,
    DEFAULT    = 0,
    LOW        = -2,
    BACKGROUND = auto_cast c.INT16_MIN,
}
DISPATCH_QUEUE_PRIORITY_HIGH       :: dispatch_queue_priority_t.HIGH
DISPATCH_QUEUE_PRIORITY_DEFAULT    :: dispatch_queue_priority_t.DEFAULT
DISPATCH_QUEUE_PRIORITY_LOW        :: dispatch_queue_priority_t.LOW
DISPATCH_QUEUE_PRIORITY_BACKGROUND :: dispatch_queue_priority_t.BACKGROUND

dispatch_source_t  :: ^OS_dispatch_source
OS_dispatch_source :: struct{using _: OS_dispatch_object}
dispatch_source_s  :: OS_dispatch_source

dispatch_source_type_t :: ^dispatch_source_type_s
dispatch_source_type_s :: struct{} // opaque type

dispatch_source_proc_flags_t :: bit_set[enum{
    EXIT   = 31,
    FORK   = 30,
    EXEC   = 29,
    SIGNAL = 27,
}; c.ulong]
DISPATCH_PROC_EXIT   :: 0x80000000
DISPATCH_PROC_FORK   :: 0x40000000
DISPATCH_PROC_EXEC   :: 0x20000000
DISPATCH_PROC_SIGNAL :: 0x08000000

dispatch_source_vnode_flags_t :: bit_set[enum{
    DELETE  = 0,
    WRITE   = 1,
    EXTEND  = 2,
    ATTRIB  = 3,
    LINK    = 4,
    RENAME  = 5,
    REVOKE  = 6,
    FUNLOCK = 8,
}; c.ulong]
DISPATCH_VNODE_DELETE  :: 0x1
DISPATCH_VNODE_WRITE   :: 0x2
DISPATCH_VNODE_EXTEND  :: 0x4
DISPATCH_VNODE_ATTRIB  :: 0x8
DISPATCH_VNODE_LINK    :: 0x10
DISPATCH_VNODE_RENAME  :: 0x20
DISPATCH_VNODE_REVOKE  :: 0x40
DISPATCH_VNODE_FUNLOCK :: 0x100

dispatch_source_mach_recv_flags_t :: bit_set[enum{}; c.ulong]

dispatch_source_mach_send_flags_t :: bit_set[enum{
    DEAD = 0,
}; c.ulong]
DISPATCH_MACH_SEND_DEAD :: 0x1

dispatch_source_memorypressure_flags_t :: bit_set[enum{
    NORMAL   = 0,
    WARN     = 1,
    CRITICAL = 2,
}; c.ulong]
DISPATCH_MEMORYPRESSURE_NORMAL   :: 0x01
DISPATCH_MEMORYPRESSURE_WARN     :: 0x02
DISPATCH_MEMORYPRESSURE_CRITICAL :: 0x04

dispatch_source_timer_flags_t :: bit_set[enum{
    STRICT = 0,
}; c.ulong]
DISPATCH_TIMER_STRICT :: 0x1

dispatch_io_t  :: ^OS_dispatch_io
OS_dispatch_io :: struct{using _: OS_dispatch_object}
dispatch_io_s  :: OS_dispatch_io

dispatch_fd_t :: c.int

dispatch_io_type_t :: enum c.ulong {
    STREAM = 0,
    RANDOM = 1,
}
DISPATCH_IO_STREAM :: dispatch_io_type_t.STREAM
DISPATCH_IO_RANDOM :: dispatch_io_type_t.RANDOM

dispatch_io_handler_t :: ^Objc_Block(proc "c" (c.bool, ^OS_dispatch_data, c.int))

dispatch_io_close_flags_t :: bit_set[enum{
    STOP = 0,
}; c.ulong]
DISPATCH_IO_STOP :: 0x1

dispatch_io_interval_flags_t :: bit_set[enum{
    STRICT_INTERVAL = 0,
}; c.ulong]
DISPATCH_IO_STRICT_INTERVAL :: 0x1

dispatch_data_t  :: ^OS_dispatch_data
OS_dispatch_data :: struct{using _: OS_dispatch_object}
dispatch_data_s  :: OS_dispatch_data

dispatch_data_applier_t :: ^Objc_Block(proc "c" (^OS_dispatch_data, c.ulong, rawptr, c.ulong) -> c.bool)

dispatch_semaphore_t  :: ^OS_dispatch_semaphore
OS_dispatch_semaphore :: struct{using _: OS_dispatch_object}
dispatch_semaphore_s  :: OS_dispatch_semaphore

dispatch_time_t :: c.uint64_t
DISPATCH_TIME_NOW     :: c.ulonglong(0)
DISPATCH_TIME_FOREVER :: ~c.ulonglong(0)

MSEC_PER_SEC  :: c.ulonglong(1_000)
NSEC_PER_SEC  :: c.ulonglong(1_000_000_000)
NSEC_PER_MSEC :: c.ulonglong(1_000_000)
USEC_PER_SEC  :: c.ulonglong(1_000_000)
NSEC_PER_USEC :: c.ulonglong(1_000)

DISPATCH_WALLTIME_NOW :: ~c.ulonglong(1)

dispatch_queue_serial_executor_t  :: ^OS_dispatch_queue_serial_executor
OS_dispatch_queue_serial_executor :: struct{using _: OS_dispatch_queue}
dispatch_queue_serial_executor_s  :: OS_dispatch_queue_serial_executor

DISPATCH_TARGET_QUEUE_DEFAULT :: dispatch_queue_t(uintptr(0))
