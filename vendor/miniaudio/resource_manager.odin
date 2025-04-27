package miniaudio

import "core:c"

foreign import lib { LIB }

/************************************************************************************************************************************************************

Resource Manager

************************************************************************************************************************************************************/

resource_manager_data_source_flag :: enum c.int {
	STREAM         = 0,   /* When set, does not load the entire data source in memory. Disk I/O will happen on job threads. */
	DECODE         = 1,   /* Decode data before storing in memory. When set, decoding is done at the resource manager level rather than the mixing thread. Results in faster mixing, but higher memory usage. */
	ASYNC          = 2,   /* When set, the resource manager will load the data source asynchronously. */
	WAIT_INIT      = 3,   /* When set, waits for initialization of the underlying data source before returning from ma_resource_manager_data_source_init(). */
	UNKNOWN_LENGTH = 4,   /* Gives the resource manager a hint that the length of the data source is unknown and calling `ma_data_source_get_length_in_pcm_frames()` should be avoided. */
}

resource_manager_data_source_flags :: bit_set[resource_manager_data_source_flag; u32]

/*
Pipeline notifications used by the resource manager. Made up of both an async notification and a fence, both of which are optional.
*/
resource_manager_pipeline_stage_notification :: struct {
	pNotification: ^async_notification,
	pFence:        ^fence,
}

resource_manager_pipeline_notifications :: struct {
	init: resource_manager_pipeline_stage_notification,    /* Initialization of the decoder. */
	done: resource_manager_pipeline_stage_notification,    /* Decoding fully completed. */
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	resource_manager_pipeline_notifications_init :: proc() -> resource_manager_pipeline_notifications ---
}


/* BEGIN BACKWARDS COMPATIBILITY */
/* TODO: Remove this block in version 0.12. */
resource_manager_job                              :: job
resource_manager_job_init                         :: job_init
JOB_TYPE_RESOURCE_MANAGER_QUEUE_FLAG_NON_BLOCKING :: job_queue_flags.NON_BLOCKING
resource_manager_job_queue_config                 :: job_queue_config
resource_manager_job_queue_config_init            :: job_queue_config_init
resource_manager_job_queue                        :: job_queue
resource_manager_job_queue_get_heap_size          :: job_queue_get_heap_size
resource_manager_job_queue_init_preallocated      :: job_queue_init_preallocated
resource_manager_job_queue_init                   :: job_queue_init
resource_manager_job_queue_uninit                 :: job_queue_uninit
resource_manager_job_queue_post                   :: job_queue_post
resource_manager_job_queue_next                   :: job_queue_next
/* END BACKWARDS COMPATIBILITY */



/* Maximum job thread count will be restricted to this, but this may be removed later and replaced with a heap allocation thereby removing any limitation. */
RESOURCE_MANAGER_MAX_JOB_THREAD_COUNT :: 64

resource_manager_flag :: enum c.int {
	/* Indicates ma_resource_manager_next_job() should not block. Only valid when the job thread count is 0. */
	NON_BLOCKING = 0,

	/* Disables any kind of multithreading. Implicitly enables MA_RESOURCE_MANAGER_FLAG_NON_BLOCKING. */
	NO_THREADING = 1,
}

resource_manager_flags :: bit_set[resource_manager_flag; u32]

resource_manager_data_source_config :: struct {
	pFilePath:                   cstring,
	pFilePathW:                  [^]c.wchar_t,
	pNotifications:              ^resource_manager_pipeline_notifications,
	initialSeekPointInPCMFrames: u64,
	rangeBegInPCMFrames:         u64,
	rangeEndInPCMFrames:         u64,
	loopPointBegInPCMFrames:     u64,
	loopPointEndInPCMFrames:     u64,
	isLooping:                   b32,
	flags:                       u32,
}

resource_manager_data_supply_type :: enum c.int {
	unknown = 0,   /* Used for determining whether or the data supply has been initialized. */
	encoded,       /* Data supply is an encoded buffer. Connector is ma_decoder. */
	decoded,       /* Data supply is a decoded buffer. Connector is ma_audio_buffer. */
	decoded_paged, /* Data supply is a linked list of decoded buffers. Connector is ma_paged_audio_buffer. */
}

resource_manager_data_supply :: struct {
	type: resource_manager_data_supply_type, /*atomic*/    /* Read and written from different threads so needs to be accessed atomically. */
	backend: struct #raw_union {
		encoded: struct {
			pData:       rawptr,
			sizeInBytes: c.size_t,
		},
		decoded: struct {
			pData:             rawptr,
			totalFrameCount:   u64,
			decodedFrameCount: u64,
			format:            format,
			channels:          u32,
			sampleRate:        u32,
		},
		decodedPaged: struct {
			data:              paged_audio_buffer_data,
			decodedFrameCount: u64,
			sampleRate:        u32,
		},
	},
}

resource_manager_data_buffer_node :: struct {
	hashedName32:                 u32,                  /* The hashed name. This is the key. */
	refCount:                     u32,
	result:                       result, /*atomic*/    /* Result from asynchronous loading. When loading set to MA_BUSY. When fully loaded set to MA_SUCCESS. When deleting set to MA_UNAVAILABLE. */
	executionCounter:             u32, /*atomic*/       /* For allocating execution orders for jobs. */
	executionPointer:             u32, /*atomic*/       /* For managing the order of execution for asynchronous jobs relating to this object. Incremented as jobs complete processing. */
	isDataOwnedByResourceManager: b32,                  /* Set to true when the underlying data buffer was allocated the resource manager. Set to false if it is owned by the application (via ma_resource_manager_register_*()). */
	data:                         resource_manager_data_supply,
	pParent:                      ^resource_manager_data_buffer_node,
	pChildLo:                     ^resource_manager_data_buffer_node,
	pChildHi:                     ^resource_manager_data_buffer_node,
}

resource_manager_data_buffer :: struct {
	ds:                     data_source_base,                      /* Base data source. A data buffer is a data source. */
	pResourceManager:       ^resource_manager,                     /* A pointer to the resource manager that owns this buffer. */
	pNode:                  ^resource_manager_data_buffer_node,    /* The data node. This is reference counted and is what supplies the data. */
	flags:                  resource_manager_flags,                /* The flags that were passed used to initialize the buffer. */
	executionCounter:       u32, /*atomic*/                        /* For allocating execution orders for jobs. */
	executionPointer:       u32, /*atomic*/                        /* For managing the order of execution for asynchronous jobs relating to this object. Incremented as jobs complete processing. */
	seekTargetInPCMFrames:  u64,                                   /* Only updated by the public API. Never written nor read from the job thread. */
	seekToCursorOnNextRead: b32,                                   /* On the next read we need to seek to the frame cursor. */
	result:                 result, /*atomic*/                     /* Keeps track of a result of decoding. Set to MA_BUSY while the buffer is still loading. Set to MA_SUCCESS when loading is finished successfully. Otherwise set to some other code. */
	isLooping:              b32, /*atomic*/                        /* Can be read and written by different threads at the same time. Must be used atomically. */
	isConnectorInitialized: b32,                                   /* Used for asynchronous loading to ensure we don't try to initialize the connector multiple times while waiting for the node to fully load. */
	connector: struct #raw_union {
		decoder:     decoder,             /* Supply type is ma_resource_manager_data_supply_type_encoded */
		buffer:      audio_buffer,        /* Supply type is ma_resource_manager_data_supply_type_decoded */
		pagedBuffer: paged_audio_buffer,  /* Supply type is ma_resource_manager_data_supply_type_decoded_paged */
	},  /* Connects this object to the node's data supply. */
}

resource_manager_data_stream :: struct {
	ds:                     data_source_base,     /* Base data source. A data stream is a data source. */
	pResourceManager:       ^resource_manager,    /* A pointer to the resource manager that owns this data stream. */
	flags:                  u32,                  /* The flags that were passed used to initialize the stream. */
	decoder:                decoder,              /* Used for filling pages with data. This is only ever accessed by the job thread. The public API should never touch this. */
	isDecoderInitialized:   b32,                  /* Required for determining whether or not the decoder should be uninitialized in MA_JOB_TYPE_RESOURCE_MANAGER_FREE_DATA_STREAM. */
	totalLengthInPCMFrames: u64,                  /* This is calculated when first loaded by the MA_JOB_TYPE_RESOURCE_MANAGER_LOAD_DATA_STREAM. */
	relativeCursor:         u32,                  /* The playback cursor, relative to the current page. Only ever accessed by the public API. Never accessed by the job thread. */
	absoluteCursor:         u64, /*atomic*/       /* The playback cursor, in absolute position starting from the start of the file. */
	currentPageIndex:       u32,                  /* Toggles between 0 and 1. Index 0 is the first half of pPageData. Index 1 is the second half. Only ever accessed by the public API. Never accessed by the job thread. */
	executionCounter:       u32, /*atomic*/       /* For allocating execution orders for jobs. */
	executionPointer:       u32, /*atomic*/       /* For managing the order of execution for asynchronous jobs relating to this object. Incremented as jobs complete processing. */

	/* Written by the public API, read by the job thread. */
	isLooping:              b32, /*atomic*/       /* Whether or not the stream is looping. It's important to set the looping flag at the data stream level for smooth loop transitions. */

	/* Written by the job thread, read by the public API. */
	pPageData:              rawptr,               /* Buffer containing the decoded data of each page. Allocated once at initialization time. */
	pageFrameCount:         [2]u32, /*atomic*/    /* The number of valid PCM frames in each page. Used to determine the last valid frame. */

	/* Written and read by both the public API and the job thread. These must be atomic. */
	result:                 result, /*atomic*/    /* Result from asynchronous loading. When loading set to MA_BUSY. When initialized set to MA_SUCCESS. When deleting set to MA_UNAVAILABLE. If an error occurs when loading, set to an error code. */
	isDecoderAtEnd:         b32, /*atomic*/       /* Whether or not the decoder has reached the end. */
	isPageValid:            [2]b32, /*atomic*/    /* Booleans to indicate whether or not a page is valid. Set to false by the public API, set to true by the job thread. Set to false as the pages are consumed, true when they are filled. */
	seekCounter:            b32, /*atomic*/       /* When 0, no seeking is being performed. When > 0, a seek is being performed and reading should be delayed with MA_BUSY. */
}

resource_manager_data_source :: struct {
	backend: struct #raw_union {
		buffer: resource_manager_data_buffer,
		stream: resource_manager_data_stream,
	},  /* Must be the first item because we need the first item to be the data source callbacks for the buffer or stream. */

	flags:            u32,                /* The flags that were passed in to ma_resource_manager_data_source_init(). */
	executionCounter: u32, /*atomic*/     /* For allocating execution orders for jobs. */
	executionPointer: u32, /*atomic*/     /* For managing the order of execution for asynchronous jobs relating to this object. Incremented as jobs complete processing. */
}

resource_manager_config :: struct {
	allocationCallbacks:            allocation_callbacks,
	pLog:                           ^log,
	decodedFormat:                  format,    /* The decoded format to use. Set to ma_format_unknown (default) to use the file's native format. */
	decodedChannels:                u32,       /* The decoded channel count to use. Set to 0 (default) to use the file's native channel count. */
	decodedSampleRate:              u32,       /* the decoded sample rate to use. Set to 0 (default) to use the file's native sample rate. */
	jobThreadCount:                 u32,       /* Set to 0 if you want to self-manage your job threads. Defaults to 1. */
	jobThreadStackSize:             uint,
	jobQueueCapacity:               u32,       /* The maximum number of jobs that can fit in the queue at a time. Defaults to MA_JOB_TYPE_RESOURCE_MANAGER_QUEUE_CAPACITY. Cannot be zero. */
	flags:                          u32,
	pVFS:                           ^vfs,      /* Can be NULL in which case defaults will be used. */
	ppCustomDecodingBackendVTables: ^[^]decoding_backend_vtable,
	customDecodingBackendCount:     u32,
	pCustomDecodingBackendUserData: rawptr,
}

resource_manager :: struct {
	config:              resource_manager_config,
	pRootDataBufferNode: ^resource_manager_data_buffer_node,                                               /* The root buffer in the binary tree. */
	dataBufferBSTLock:   (struct {} when NO_THREADING else mutex),                                         /* For synchronizing access to the data buffer binary tree. */
	jobThreads:          (struct {} when NO_THREADING else [RESOURCE_MANAGER_MAX_JOB_THREAD_COUNT]thread), /* The threads for executing jobs. */
	jobQueue:            job_queue,                                                                        /* Multi-consumer, multi-producer job queue for managing jobs for asynchronous decoding and streaming. */
	defaultVFS:          default_vfs,                                                                      /* Only used if a custom VFS is not specified. */
	log:                 log,                                                                              /* Only used if no log was specified in the config. */
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	resource_manager_data_source_config_init :: proc() -> resource_manager_data_source_config ---
	resource_manager_config_init             :: proc() -> resource_manager_config ---

	/* Init. */
	resource_manager_init    :: proc(pConfig: ^resource_manager_config, pResourceManager: ^resource_manager) -> result ---
	resource_manager_uninit  :: proc(pResourceManager: ^resource_manager) ---
	resource_manager_get_log :: proc(pResourceManager: ^resource_manager) -> ^log ---

	/* Registration. */
	resource_manager_register_file           :: proc(pResourceManager: ^resource_manager, pFilePath: cstring, flags: u32) -> result ---
	resource_manager_register_file_w         :: proc(pResourceManager: ^resource_manager, pFilePath: [^]c.wchar_t, flags: u32) -> result ---
	resource_manager_register_decoded_data   :: proc(pResourceManager: ^resource_manager, pName: cstring, pData: rawptr, frameCount: u64, format: format, channels: u32, sampleRate: u32) -> result ---  /* Does not copy. Increments the reference count if already exists and returns MA_SUCCESS. */
	resource_manager_register_decoded_data_w :: proc(pResourceManager: ^resource_manager, pName: [^]c.wchar_t, pData: rawptr, frameCount: u64, format: format, channels: u32, sampleRate: u32) -> result ---
	resource_manager_register_encoded_data   :: proc(pResourceManager: ^resource_manager, pName: cstring, pData: rawptr, sizeInBytes: c.size_t) -> result ---    /* Does not copy. Increments the reference count if already exists and returns MA_SUCCESS. */
	resource_manager_register_encoded_data_w :: proc(pResourceManager: ^resource_manager, pName: [^]c.wchar_t, pData: rawptr, sizeInBytes: c.size_t) -> result ---
	resource_manager_unregister_file         :: proc(pResourceManager: ^resource_manager, pFilePath: cstring) -> result ---
	resource_manager_unregister_file_w       :: proc(pResourceManager: ^resource_manager, pFilePath: [^]c.wchar_t) -> result ---
	resource_manager_unregister_data         :: proc(pResourceManager: ^resource_manager, pName: cstring) -> result ---
	resource_manager_unregister_data_w       :: proc(pResourceManager: ^resource_manager, pName: [^]c.wchar_t) -> result ---

	/* Data Buffers. */
	resource_manager_data_buffer_init_ex                  :: proc(pResourceManager: ^resource_manager, pConfig: ^resource_manager_data_source_config, pDataBuffer: ^resource_manager_data_buffer) -> result ---
	resource_manager_data_buffer_init                     :: proc(pResourceManager: ^resource_manager, pFilePath: cstring, flags: u32, pNotifications: ^resource_manager_pipeline_notifications, pDataBuffer: ^resource_manager_data_buffer) -> result ---
	resource_manager_data_buffer_init_w                   :: proc(pResourceManager: ^resource_manager, pFilePath: [^]c.wchar_t, flags: u32, pNotifications: ^resource_manager_pipeline_notifications, pDataBuffer: ^resource_manager_data_buffer) -> result ---
	resource_manager_data_buffer_init_copy                :: proc(pResourceManager: ^resource_manager, pExistingDataBuffer, pDataBuffer: ^resource_manager_data_buffer) -> result ---
	resource_manager_data_buffer_uninit                   :: proc(pDataBuffer: ^resource_manager_data_buffer) -> result ---
	resource_manager_data_buffer_read_pcm_frames          :: proc(pDataBuffer: ^resource_manager_data_buffer, pFramesOut: rawptr, frameCount: u64, pFramesRead: ^u64) -> result ---
	resource_manager_data_buffer_seek_to_pcm_frame        :: proc(pDataBuffer: ^resource_manager_data_buffer, frameIndex: u64) -> result ---
	resource_manager_data_buffer_get_data_format          :: proc(pDataBuffer: ^resource_manager_data_buffer, pFormat: ^format, pChannels: ^u32, pSampleRate: ^u32, pChannelMap: [^]channel, channelMapCap: c.size_t) -> result ---
	resource_manager_data_buffer_get_cursor_in_pcm_frames :: proc(pDataBuffer: ^resource_manager_data_buffer, pCursor: ^u64) -> result ---
	resource_manager_data_buffer_get_length_in_pcm_frames :: proc(pDataBuffer: ^resource_manager_data_buffer, pLength: ^u64) -> result ---
	resource_manager_data_buffer_result                   :: proc(pDataBuffer: ^resource_manager_data_buffer) -> result ---
	resource_manager_data_buffer_set_looping              :: proc(pDataBuffer: ^resource_manager_data_buffer, isLooping: b32) -> result ---
	resource_manager_data_buffer_is_looping               :: proc(pDataBuffer: ^resource_manager_data_buffer) -> b32 ---
	resource_manager_data_buffer_get_available_frames     :: proc(pDataBuffer: ^resource_manager_data_buffer, pAvailableFrames: ^u64) -> result ---

	/* Data Streams. */
	resource_manager_data_stream_init_ex                  :: proc(pResourceManager: ^resource_manager, pConfig: ^resource_manager_data_source_config, pDataStream: ^resource_manager_data_stream) -> result ---
	resource_manager_data_stream_init                     :: proc(pResourceManager: ^resource_manager, pFilePath: cstring, flags: u32, pNotifications: ^resource_manager_pipeline_notifications, pDataStream: ^resource_manager_data_stream) -> result ---
	resource_manager_data_stream_init_w                   :: proc(pResourceManager: ^resource_manager, pFilePath: [^]c.wchar_t, flags: u32, pNotifications: ^resource_manager_pipeline_notifications, pDataStream: ^resource_manager_data_stream) -> result ---
	resource_manager_data_stream_uninit                   :: proc(pDataStream: ^resource_manager_data_stream) -> result ---
	resource_manager_data_stream_read_pcm_frames          :: proc(pDataStream: ^resource_manager_data_stream, pFramesOut: rawptr, frameCount: u64, pFramesRead: ^u64) -> result ---
	resource_manager_data_stream_seek_to_pcm_frame        :: proc(pDataStream: ^resource_manager_data_stream, frameIndex: u64) -> result ---
	resource_manager_data_stream_get_data_format          :: proc(pDataStream: ^resource_manager_data_stream, pFormat: ^format, pChannels, pSampleRate: ^u32, pChannelMap: [^]channel, channelMapCap: c.size_t) -> result ---
	resource_manager_data_stream_get_cursor_in_pcm_frames :: proc(pDataStream: ^resource_manager_data_stream, pCursor: ^u64) -> result ---
	resource_manager_data_stream_get_length_in_pcm_frames :: proc(pDataStream: ^resource_manager_data_stream, pLength: ^u64) -> result ---
	resource_manager_data_stream_result                   :: proc(pDataStream: ^resource_manager_data_stream) -> result ---
	resource_manager_data_stream_set_looping              :: proc(pDataStream: ^resource_manager_data_stream, isLooping: b32) -> result ---
	resource_manager_data_stream_is_looping               :: proc(pDataStream: ^resource_manager_data_stream) -> b32 ---
	resource_manager_data_stream_get_available_frames     :: proc(pDataStream: ^resource_manager_data_stream, pAvailableFrames: ^u64) -> result ---

	/* Data Sources. */
	resource_manager_data_source_init_ex                  :: proc(pResourceManager: ^resource_manager, pConfig: ^resource_manager_data_source_config, pDataSource: ^resource_manager_data_source) -> result ---
	resource_manager_data_source_init                     :: proc(pResourceManager: ^resource_manager, pName: cstring, flags: u32, pNotifications: ^resource_manager_pipeline_notifications, pDataSource: ^resource_manager_data_source) -> result ---
	resource_manager_data_source_init_w                   :: proc(pResourceManager: ^resource_manager, pName: [^]c.wchar_t, flags: u32, pNotifications: ^resource_manager_pipeline_notifications, pDataSource: ^resource_manager_data_source) -> result ---
	resource_manager_data_source_init_copy                :: proc(pResourceManager: ^resource_manager, pExistingDataSource, pDataSource: ^resource_manager_data_source) -> result ---
	resource_manager_data_source_uninit                   :: proc(pDataSource: ^resource_manager_data_source) -> result ---
	resource_manager_data_source_read_pcm_frames          :: proc(pDataSource: ^resource_manager_data_source, pFramesOut: rawptr, frameCount: u64, pFramesRead: ^u64) -> result ---
	resource_manager_data_source_seek_to_pcm_frame        :: proc(pDataSource: ^resource_manager_data_source, frameIndex: u64) -> result ---
	resource_manager_data_source_get_data_format          :: proc(pDataSource: ^resource_manager_data_source, pFormat: ^format, pChannels, pSampleRate: ^u32, pChannelMap: [^]channel, channelMapCap: c.size_t) -> result ---
	resource_manager_data_source_get_cursor_in_pcm_frames :: proc(pDataSource: ^resource_manager_data_source, pCursor: ^u64) -> result ---
	resource_manager_data_source_get_length_in_pcm_frames :: proc(pDataSource: ^resource_manager_data_source, pLength: ^u64) -> result ---
	resource_manager_data_source_result                   :: proc(pDataSource: ^resource_manager_data_source) -> result ---
	resource_manager_data_source_set_looping              :: proc(pDataSource: ^resource_manager_data_source, isLooping: b32) -> result ---
	resource_manager_data_source_is_looping               :: proc(pDataSource: ^resource_manager_data_source) -> b32 ---
	resource_manager_data_source_get_available_frames     :: proc(pDataSource: ^resource_manager_data_source, pAvailableFrames: ^u64) -> result ---

	/* Job management. */
	resource_manager_post_job         :: proc(pResourceManager: ^resource_manager, pJob: ^job) -> result ---
	resource_manager_post_job_quit    :: proc(pResourceManager: ^resource_manager) -> result ---  /* Helper for posting a quit job. */
	resource_manager_next_job         :: proc(pResourceManager: ^resource_manager, pJob: ^job) -> result ---
	resource_manager_process_job      :: proc(pResourceManager: ^resource_manager, pJob: ^job) -> result ---  /* DEPRECATED. Use ma_job_process(). Will be removed in version 0.12. */
	resource_manager_process_next_job :: proc(pResourceManager: ^resource_manager) -> result ---   /* Returns MA_CANCELLED if a MA_JOB_TYPE_QUIT job is found. In non-blocking mode, returns MA_NO_DATA_AVAILABLE if no jobs are available. */
}
