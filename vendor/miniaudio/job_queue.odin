package miniaudio

import "core:c"

foreign import lib { LIB }

/*
Slot Allocator
--------------
The idea of the slot allocator is for it to be used in conjunction with a fixed sized buffer. You use the slot allocator to allocator an index that can be used
as the insertion point for an object.

Slots are reference counted to help mitigate the ABA problem in the lock-free queue we use for tracking jobs.

The slot index is stored in the low 32 bits. The reference counter is stored in the high 32 bits:

		+-----------------+-----------------+
		| 32 Bits         | 32 Bits         |
		+-----------------+-----------------+
		| Reference Count | Slot Index      |
		+-----------------+-----------------+
*/
slot_allocator_config :: struct {
	capacity: u32,    /* The number of slots to make available. */
}

slot_allocator_group :: struct {
	bitfield: u32, /*atomic*/   /* Must be used atomically because the allocation and freeing routines need to make copies of this which must never be optimized away by the compiler. */
}

slot_allocator :: struct {
	pGroups:  [^]slot_allocator_group,   /* Slots are grouped in chunks of 32. */
	pSlots:   [^]u32,                    /* 32 bits for reference counting for ABA mitigation. */
	count:    u32,                       /* Allocation count. */
	capacity: u32,

	/* Memory management. */
	_ownsHeap: b32,
	_pHeap:    rawptr,
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	slot_allocator_config_init :: proc(capacity: u32) -> slot_allocator_config ---

	slot_allocator_get_heap_size     :: proc(pConfig: ^slot_allocator_config, pHeapSizeInBytes: ^c.size_t) -> result ---
	slot_allocator_init_preallocated :: proc(pConfig: ^slot_allocator_config, pHeap: rawptr, pAllocator: ^slot_allocator) -> result ---
	slot_allocator_init              :: proc(pConfig: ^slot_allocator_config, pAllocationCallbacks: ^allocation_callbacks, pAllocator: ^slot_allocator) -> result ---
	slot_allocator_uninit            :: proc(pAllocator: ^slot_allocator, pAllocationCallbacks: ^allocation_callbacks) ---
	slot_allocator_alloc             :: proc(pAllocator: ^slot_allocator, pSlot: ^u64) -> result ---
	slot_allocator_free              :: proc(pAllocator: ^slot_allocator, slot: u64) -> result ---
}

/*
Callback for processing a job. Each job type will have their own processing callback which will be
called by ma_job_process().
*/
job_proc :: proc "c" (pJob: ^job)

/* When a job type is added here an callback needs to be added go "g_jobVTable" in the implementation section. */
job_type :: enum c.int {
	/* Miscellaneous. */
	QUIT = 0,
	CUSTOM,

	/* Resource Manager. */
	RESOURCE_MANAGER_LOAD_DATA_BUFFER_NODE,
	RESOURCE_MANAGER_FREE_DATA_BUFFER_NODE,
	RESOURCE_MANAGER_PAGE_DATA_BUFFER_NODE,
	RESOURCE_MANAGER_LOAD_DATA_BUFFER,
	RESOURCE_MANAGER_FREE_DATA_BUFFER,
	RESOURCE_MANAGER_LOAD_DATA_STREAM,
	RESOURCE_MANAGER_FREE_DATA_STREAM,
	RESOURCE_MANAGER_PAGE_DATA_STREAM,
	RESOURCE_MANAGER_SEEK_DATA_STREAM,

	/* Device. */
	DEVICE_AAUDIO_REROUTE,

	/* Count. Must always be last. */
	COUNT,
}

job :: struct {
	toc: struct #raw_union {   /* 8 bytes. We encode the job code into the slot allocation data to save space. */
		breakup: struct {
			code:     u16,         /* Job type. */
			slot:     u16,         /* Index into a ma_slot_allocator. */
			refcount: u32,
		},
		allocation: u64,
	},
	next:  u64, /*atomic*/    /* refcount + slot for the next item. Does not include the job code. */
	order: u32,               /* Execution order. Used to create a data dependency and ensure a job is executed in order. Usage is contextual depending on the job type. */

	data: struct #raw_union {
		/* Miscellaneous. */
		custom: struct {
			proc_: job_proc,
			data0: uintptr,
			data1: uintptr,
		},

		/* Resource Manager */
		resourceManager: struct #raw_union {
			loadDataBufferNode: struct {
				pResourceManager:  rawptr /*ma_resource_manager**/,
				pDataBufferNode:   rawptr /*ma_resource_manager_data_buffer_node**/,
				pFilePath:         cstring,
				pFilePathW:        [^]c.wchar_t,
				flags:             u32,                       /* Resource manager data source flags that were used when initializing the data buffer. */
				pInitNotification: ^async_notification,       /* Signalled when the data buffer has been initialized and the format/channels/rate can be retrieved. */
				pDoneNotification: ^async_notification,       /* Signalled when the data buffer has been fully decoded. Will be passed through to MA_JOB_TYPE_RESOURCE_MANAGER_PAGE_DATA_BUFFER_NODE when decoding. */
				pInitFence:        ^fence,                    /* Released when initialization of the decoder is complete. */
				pDoneFence:        ^fence,                    /* Released if initialization of the decoder fails. Passed through to PAGE_DATA_BUFFER_NODE untouched if init is successful. */
			},
			freeDataBufferNode: struct {
				pResourceManager:  rawptr /*ma_resource_manager**/,
				pDataBufferNode:   rawptr /*ma_resource_manager_data_buffer_node**/,
				pDoneNotification: ^async_notification,
				pDoneFence:        ^fence,
			},
			pageDataBufferNode: struct {
				pResourceManager:  rawptr /*ma_resource_manager**/,
				pDataBufferNode:   rawptr /*ma_resource_manager_data_buffer_node**/,
				pDecoder:          rawptr /*ma_decoder**/,
				pDoneNotification: ^async_notification,       /* Signalled when the data buffer has been fully decoded. */
				pDoneFence:        ^fence,                    /* Passed through from LOAD_DATA_BUFFER_NODE and released when the data buffer completes decoding or an error occurs. */
			},

			loadDataBuffer: struct {
				pDataBuffer:             rawptr /*ma_resource_manager_data_buffer**/,
				pInitNotification:       ^async_notification,       /* Signalled when the data buffer has been initialized and the format/channels/rate can be retrieved. */
				pDoneNotification:       ^async_notification,       /* Signalled when the data buffer has been fully decoded. */
				pInitFence:              ^fence,                    /* Released when the data buffer has been initialized and the format/channels/rate can be retrieved. */
				pDoneFence:              ^fence,                    /* Released when the data buffer has been fully decoded. */
				rangeBegInPCMFrames:     u64,
				rangeEndInPCMFrames:     u64,
				loopPointBegInPCMFrames: u64,
				loopPointEndInPCMFrames: u64,
				isLooping:               u32,
			},
			freeDataBuffer: struct {
				pDataBuffer:       rawptr /*ma_resource_manager_data_buffer**/,
				pDoneNotification: ^async_notification,
				pDoneFence:        ^fence,
			},

			loadDataStream: struct {
				pDataStream:       rawptr /*ma_resource_manager_data_stream**/,
				pFilePath:         cstring,               /* Allocated when the job is posted, freed by the job thread after loading. */
				pFilePathW:        [^]c.wchar_t,          /* ^ As above ^. Only used if pFilePath is NULL. */
				initialSeekPoint:  u64,
				pInitNotification: ^async_notification,   /* Signalled after the first two pages have been decoded and frames can be read from the stream. */
				pInitFence:        ^fence,
			},
			freeDataStream: struct {
				pDataStream:       rawptr /*ma_resource_manager_data_stream**/,
				pDoneNotification: ^async_notification,
				pDoneFence:        ^fence,
			},
			pageDataStream: struct {
				pDataStream: rawptr /*ma_resource_manager_data_stream**/,
				pageIndex:   u32,   /* The index of the page to decode into. */
			},
			seekDataStream: struct {
				pDataStream: rawptr /*ma_resource_manager_data_stream**/,
				frameIndex:  u64,
			},
		},

		/* Device. */
		device: struct #raw_union {
			aaudio: struct #raw_union {
				reroute: struct {
					pDevice:    rawptr /*ma_device**/,
					deviceType: u32 /*ma_device_type*/,
				},
			},
		},
	},
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	job_init    :: proc(code: u16) -> job ---
	job_process :: proc(pJob: ^job) -> result ---
}


/*
When set, ma_job_queue_next() will not wait and no semaphore will be signaled in
ma_job_queue_post(). ma_job_queue_next() will return MA_NO_DATA_AVAILABLE if nothing is available.

This flag should always be used for platforms that do not support multithreading.
*/
job_queue_flags :: enum c.int {
	NON_BLOCKING = 0x00000001,
}

job_queue_config :: struct {
	flags:    u32,
	capacity: u32, /* The maximum number of jobs that can fit in the queue at a time. */
}

USE_EXPERIMENTAL_LOCK_FREE_JOB_QUEUE :: false

job_queue :: struct {
	flags:     u32,                                          /* Flags passed in at initialization time. */
	capacity:  u32,                                          /* The maximum number of jobs that can fit in the queue at a time. Set by the config. */
	head:      u64, /*atomic*/                               /* The first item in the list. Required for removing from the top of the list. */
	tail:      u64, /*atomic*/                               /* The last item in the list. Required for appending to the end of the list. */
	sem:       (struct {} when NO_THREADING else semaphore), /* Only used when MA_JOB_QUEUE_FLAG_NON_BLOCKING is unset. */
	allocator: slot_allocator,
	pJobs:     [^]job,
	lock:      (struct {} when USE_EXPERIMENTAL_LOCK_FREE_JOB_QUEUE else spinlock),

	/* Memory management. */
	_pHeap:    rawptr,
	_ownsHeap: b32,
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	job_queue_config_init :: proc(flags, capacity: u32) -> job_queue_config ---

	job_queue_get_heap_size     :: proc(pConfig: ^job_queue_config, pHeapSizeInBytes: ^c.size_t) -> result ---
	job_queue_init_preallocated :: proc(pConfig: ^job_queue_config, pHeap: rawptr, pQueue: ^job_queue) -> result ---
	job_queue_init              :: proc(pConfig: ^job_queue_config, pAllocationCallbacks: ^allocation_callbacks, pQueue: ^job_queue) -> result ---
	job_queue_uninit            :: proc(pQueue: ^job_queue, pAllocationCallbacks: ^allocation_callbacks) ---
	job_queue_post              :: proc(pQueue: ^job_queue, pJob: ^job) -> result ---
	job_queue_next              :: proc(pQueue: ^job_queue, pJob: ^job) -> result --- /* Returns MA_CANCELLED if the next job is a quit job. */
}
