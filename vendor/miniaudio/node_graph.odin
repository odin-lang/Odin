package miniaudio

import "core:c"

when ODIN_OS == .Windows {
	foreign import lib "lib/miniaudio.lib"
} else {
	foreign import lib "lib/miniaudio.a"
}

/************************************************************************************************************************************************************

Node Graph

************************************************************************************************************************************************************/

/* Must never exceed 254. */
MAX_NODE_BUS_COUNT :: 254

/* Used internally by miniaudio for memory management. Must never exceed MA_MAX_NODE_BUS_COUNT. */
MAX_NODE_LOCAL_BUS_COUNT :: 2

/* Use this when the bus count is determined by the node instance rather than the vtable. */
NODE_BUS_COUNT_UNKNOWN :: 255

node :: struct {}

/* Node flags. */
node_flags :: enum c.int {
	PASSTHROUGH                = 0x00000001,
	CONTINUOUS_PROCESSING      = 0x00000002,
	ALLOW_NULL_INPUT           = 0x00000004,
	DIFFERENT_PROCESSING_RATES = 0x00000008,
	SILENT_OUTPUT              = 0x00000010,
}

/* The playback state of a node. Either started or stopped. */
node_state :: enum c.int {
	started = 0,
	stopped = 1,
}

node_vtable :: struct {
	/*
	Extended processing callback. This callback is used for effects that process input and output
	at different rates (i.e. they perform resampling). This is similar to the simple version, only
	they take two separate frame counts: one for input, and one for output.

	On input, `pFrameCountOut` is equal to the capacity of the output buffer for each bus, whereas
	`pFrameCountIn` will be equal to the number of PCM frames in each of the buffers in `ppFramesIn`.

	On output, set `pFrameCountOut` to the number of PCM frames that were actually output and set
	`pFrameCountIn` to the number of input frames that were consumed.
	*/
	onProcess: proc "c" (pNode: ^node, ppFramesIn: ^[^]f32, pFrameCountIn: ^u32, ppFramesOut: ^[^]f32, pFrameCountOut: ^u32),

	/*
	A callback for retrieving the number of a input frames that are required to output the
	specified number of output frames. You would only want to implement this when the node performs
	resampling. This is optional, even for nodes that perform resampling, but it does offer a
	small reduction in latency as it allows miniaudio to calculate the exact number of input frames
	to read at a time instead of having to estimate.
	*/
	onGetRequiredInputFrameCount: proc "c" (pNode: ^node, outputFrameCount: u32, pInputFrameCount: ^u32) -> result,

	/*
	The number of input buses. This is how many sub-buffers will be contained in the `ppFramesIn`
	parameters of the callbacks above.
	*/
	inputBusCount: u8,

	/*
	The number of output buses. This is how many sub-buffers will be contained in the `ppFramesOut`
	parameters of the callbacks above.
	*/
	outputBusCount: u8,

	/*
	Flags describing characteristics of the node. This is currently just a placeholder for some
	ideas for later on.
	*/
	flags: u32,
}

node_config :: struct {
	vtable:          ^node_vtable,  /* Should never be null. Initialization of the node will fail if so. */
	initialState:    node_state,    /* Defaults to ma_node_state_started. */
	inputBusCount:   u32,           /* Only used if the vtable specifies an input bus count of `MA_NODE_BUS_COUNT_UNKNOWN`, otherwise must be set to `MA_NODE_BUS_COUNT_UNKNOWN` (default). */
	outputBusCount:  u32,           /* Only used if the vtable specifies an output bus count of `MA_NODE_BUS_COUNT_UNKNOWN`, otherwise  be set to `MA_NODE_BUS_COUNT_UNKNOWN` (default). */
	pInputChannels:  ^u32,          /* The number of elements are determined by the input bus count as determined by the vtable, or `inputBusCount` if the vtable specifies `MA_NODE_BUS_COUNT_UNKNOWN`. */
	pOutputChannels: ^u32,          /* The number of elements are determined by the output bus count as determined by the vtable, or `outputBusCount` if the vtable specifies `MA_NODE_BUS_COUNT_UNKNOWN`. */
}

/*
A node has multiple output buses. An output bus is attached to an input bus as an item in a linked
list. Think of the input bus as a linked list, with the output bus being an item in that list.
*/
node_output_bus :: struct {
	/* Immutable. */
	pNode:          ^node,                  /* The node that owns this output bus. The input node. Will be null for dummy head and tail nodes. */
	outputBusIndex: u8,                     /* The index of the output bus on pNode that this output bus represents. */
	channels:       u8,                     /* The number of channels in the audio stream for this bus. */

	/* Mutable via multiple threads. Must be used atomically. The weird ordering here is for packing reasons. */
	inputNodeInputBusIndex: u8,                             /* The index of the input bus on the input. Required for detaching. Will only be used in the spinlock so does not need to be atomic. */
	flags:                  u32, /*atomic*/                 /* Some state flags for tracking the read state of the output buffer. A combination of MA_NODE_OUTPUT_BUS_FLAG_*. */
	refCount:               u32, /*atomic*/                 /* Reference count for some thread-safety when detaching. */
	isAttached:             b32, /*atomic*/                 /* This is used to prevent iteration of nodes that are in the middle of being detached. Used for thread safety. */
	lock:                   spinlock, /*atomic*/            /* Unfortunate lock, but significantly simplifies the implementation. Required for thread-safe attaching and detaching. */
	volume:                 f32, /*atomic*/                 /* Linear. */
	pNext:                  ^node_output_bus, /*atomic*/    /* If null, it's the tail node or detached. */
	pPrev:                  ^node_output_bus, /*atomic*/    /* If null, it's the head node or detached. */
	pInputNode:             ^node, /*atomic*/               /* The node that this output bus is attached to. Required for detaching. */
}

/*
A node has multiple input buses. The output buses of a node are connecting to the input busses of
another. An input bus is essentially just a linked list of output buses.
*/
node_input_bus :: struct {
	/* Mutable via multiple threads. */
	head:        node_output_bus,             /* Dummy head node for simplifying some lock-free thread-safety stuff. */
	nextCounter: u32, /*atomic*/              /* This is used to determine whether or not the input bus is finding the next node in the list. Used for thread safety when detaching output buses. */
	lock:        spinlock, /*atomic*/         /* Unfortunate lock, but significantly simplifies the implementation. Required for thread-safe attaching and detaching. */

	/* Set once at startup. */
	channels: u8,                             /* The number of channels in the audio stream for this bus. */
}


node_base :: struct {
	/* These variables are set once at startup. */
	pNodeGraph:                  ^node_graph,     /* The graph this node belongs to. */
	vtable:                      ^node_vtable,
	pCachedData:                 [^]f32,            /* Allocated on the heap. Fixed size. Needs to be stored on the heap because reading from output buses is done in separate function calls. */
	cachedDataCapInFramesPerBus: u16,               /* The capacity of the input data cache in frames, per bus. */

	/* These variables are read and written only from the audio thread. */
	cachedFrameCountOut:  u16,
	cachedFrameCountIn:   u16,
	consumedFrameCountIn: u16,

	/* These variables are read and written between different threads. */
	state:          node_state, /*atomic*/      /* When set to stopped, nothing will be read, regardless of the times in stateTimes. */
	stateTimes:     [2]u64, /*atomic*/          /* Indexed by ma_node_state. Specifies the time based on the global clock that a node should be considered to be in the relevant state. */
	localTime:      u64, /*atomic*/             /* The node's local clock. This is just a running sum of the number of output frames that have been processed. Can be modified by any thread with `ma_node_set_time()`. */
	inputBusCount:  u32,
	outputBusCount: u32,
	pInputBuses:    [^]node_input_bus,
	pOutputBuses:   [^]node_output_bus,

	/* Memory management. */
	_inputBuses:  [MAX_NODE_LOCAL_BUS_COUNT]node_input_bus,
	_outputBuses: [MAX_NODE_LOCAL_BUS_COUNT]node_output_bus,
	_pHeap:       rawptr,   /* A heap allocation for internal use only. pInputBuses and/or pOutputBuses will point to this if the bus count exceeds MA_MAX_NODE_LOCAL_BUS_COUNT. */
	_ownsHeap:    b32,      /* If set to true, the node owns the heap allocation and _pHeap will be freed in ma_node_uninit(). */
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	node_config_init :: proc() -> node_config ---

	node_get_heap_size           :: proc(pNodeGraph: ^node_graph, pConfig: ^node_config, pHeapSizeInBytes: ^c.size_t) -> result ---
	node_init_preallocated       :: proc(pNodeGraph: ^node_graph, pConfig: ^node_config, pHeap: rawptr, pNode: ^node) -> result ---
	node_init                    :: proc(pNodeGraph: ^node_graph, pConfig: ^node_config, pAllocationCallbacks: ^allocation_callbacks, pNode: ^node) -> result ---
	node_uninit                  :: proc(pNode: ^node, pAllocationCallbacks: ^allocation_callbacks) ---
	node_get_node_graph          :: proc(pNode: ^node) -> ^node_graph ---
	node_get_input_bus_count     :: proc(pNode: ^node) -> u32 ---
	node_get_output_bus_count    :: proc(pNode: ^node) -> u32 ---
	node_get_input_channels      :: proc(pNode: ^node, inputBusIndex: u32) -> u32 ---
	node_get_output_channels     :: proc(pNode: ^node, outputBusIndex: u32) -> u32 ---
	node_attach_output_bus       :: proc(pNode: ^node, outputBusIndex: u32, pOtherNode: ^node, otherNodeInputBusIndex: u32) -> result ---
	node_detach_output_bus       :: proc(pNode: ^node, outputBusIndex: u32) -> result ---
	node_detach_all_output_buses :: proc(pNode: ^node) -> result ---
	node_set_output_bus_volume   :: proc(pNode: ^node, outputBusIndex: u32, volume: f32) -> result ---
	node_get_output_bus_volume   :: proc(pNode: ^node, outputBusIndex: u32) -> f32 ---
	node_set_state               :: proc(pNode: ^node, state: node_state) -> result ---
	node_get_state               :: proc(pNode: ^node) -> node_state ---
	node_set_state_time          :: proc(pNode: ^node, state: node_state, globalTime: u64) -> result ---
	node_get_state_time          :: proc(pNode: ^node, state: node_state) -> u64 ---
	node_get_state_by_time       :: proc(pNode: ^node, globalTime: u64) -> node_state ---
	node_get_state_by_time_range :: proc(pNode: ^node, globalTimeBeg: u64, globalTimeEnd: u64) -> node_state ---
	node_get_time                :: proc(pNode: ^node) -> u64 ---
	node_set_time                :: proc(pNode: ^node, localTime: u64) -> result ---
}

node_graph_config :: struct {
	channels:             u32,
	nodeCacheCapInFrames: u16,
}

node_graph :: struct {
	/* Immutable. */
	base:                 node_base,       /* The node graph itself is a node so it can be connected as an input to different node graph. This has zero inputs and calls ma_node_graph_read_pcm_frames() to generate it's output. */
	endpoint:             node_base,       /* Special node that all nodes eventually connect to. Data is read from this node in ma_node_graph_read_pcm_frames(). */
	nodeCacheCapInFrames: u16,

	/* Read and written by multiple threads. */
	isReading:            b32, /*atomic*/
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	node_graph_config_init :: proc(channels: u32) -> node_graph_config ---

	node_graph_init            :: proc(pConfig: ^node_graph_config, pAllocationCallbacks: ^allocation_callbacks, pNodeGraph: ^node_graph) -> result ---
	node_graph_uninit          :: proc(pNodeGraph: ^node_graph, pAllocationCallbacks: ^allocation_callbacks) ---
	node_graph_get_endpoint    :: proc(pNodeGraph: ^node_graph) -> ^node ---
	node_graph_read_pcm_frames :: proc(pNodeGraph: ^node_graph, pFramesOut: rawptr, frameCount: u64, pFramesRead: ^u64) -> result ---
	node_graph_get_channels    :: proc(pNodeGraph: ^node_graph) -> u32 ---
	node_graph_get_time        :: proc(pNodeGraph: ^node_graph) -> u64 ---
	node_graph_set_time        :: proc(pNodeGraph: ^node_graph, globalTime: u64) -> result ---
}



/* Data source node. 0 input buses, 1 output bus. Used for reading from a data source. */
data_source_node_config :: struct {
	nodeConfig:  node_config,
	pDataSource: ^data_source,
}

data_source_node :: struct {
	base:        node_base,
	pDataSource: ^data_source,
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	data_source_node_config_init :: proc(pDataSource: ^data_source) -> data_source_node_config ---

	data_source_node_init        :: proc(pNodeGraph: ^node_graph, pConfig: ^data_source_node_config, pAllocationCallbacks: ^allocation_callbacks, pDataSourceNode: ^data_source_node) -> result ---
	data_source_node_uninit      :: proc(pDataSourceNode: ^data_source_node, pAllocationCallbacks: ^allocation_callbacks) ---
	data_source_node_set_looping :: proc(pDataSourceNode: ^data_source_node, isLooping: b32) -> result ---
	data_source_node_is_looping  :: proc(pDataSourceNode: ^data_source_node) -> b32 ---
}


/* Splitter Node. 1 input, many outputs. Used for splitting/copying a stream so it can be as input into two separate output nodes. */
splitter_node_config :: struct {
	nodeConfig:     node_config,
	channels:       u32,
	outputBusCount: u32,
}

splitter_node :: struct {
	base: node_base,
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	splitter_node_config_init :: proc(channels: u32) -> splitter_node_config ---

	splitter_node_init   :: proc(pNodeGraph: ^node_graph, pConfig: ^splitter_node_config, pAllocationCallbacks: ^allocation_callbacks, pSplitterNode: ^splitter_node) -> result ---
	splitter_node_uninit :: proc(pSplitterNode: ^splitter_node, pAllocationCallbacks: ^allocation_callbacks) ---
}


/*
Biquad Node
*/
biquad_node_config :: struct {
	nodeConfig: node_config,
	biquad:     biquad_config,
}

biquad_node :: struct {
	baseNode: node_base,
	biquad:   biquad,
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	biquad_node_config_init :: proc(channels: u32, b0, b1, b2, a0, a1, a2: f32) -> biquad_node_config ---

	biquad_node_init   :: proc(pNodeGraph: ^node_graph, pConfig: ^biquad_node_config, pAllocationCallbacks: ^allocation_callbacks, pNode: ^biquad_node) -> result ---
	biquad_node_reinit :: proc(pConfig: ^biquad_config, pNode: ^biquad_node) -> result ---
	biquad_node_uninit :: proc(pNode: ^biquad_node, pAllocationCallbacks: ^allocation_callbacks) ---
}


/*
Low Pass Filter Node
*/
lpf_node_config :: struct {
	nodeConfig: node_config,
	lpf:        lpf_config,
}

lpf_node :: struct {
	baseNode: node_base,
	lpf:      lpf,
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	lpf_node_config_init :: proc(channels, sampleRate: u32, cutoffFrequency: f64, order: u32) -> lpf_node_config ---

	lpf_node_init   :: proc(pNodeGraph: ^node_graph, pConfig: ^lpf_node_config, pAllocationCallbacks: ^allocation_callbacks, pNode: ^lpf_node) -> result ---
	lpf_node_reinit :: proc(pConfig: ^lpf_config, pNode: ^lpf_node) -> result ---
	lpf_node_uninit :: proc(pNode: ^lpf_node, pAllocationCallbacks: ^allocation_callbacks) ---
}


/*
High Pass Filter Node
*/
hpf_node_config :: struct {
	nodeConfig: node_config,
	hpf:        hpf_config,
}

hpf_node :: struct {
	baseNode: node_base,
	hpf:      hpf,
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	hpf_node_config_init :: proc(channels, sampleRate: u32, cutoffFrequency: f64, order: u32) -> hpf_node_config ---

	hpf_node_init   :: proc(pNodeGraph: ^node_graph, pConfig: ^hpf_node_config, pAllocationCallbacks: ^allocation_callbacks, pNode: ^hpf_node) -> result ---
	hpf_node_reinit :: proc(pConfig: ^hpf_config, pNode: ^hpf_node) -> result ---
	hpf_node_uninit :: proc(pNode: ^hpf_node, pAllocationCallbacks: ^allocation_callbacks) ---
}


/*
Band Pass Filter Node
*/
bpf_node_config :: struct {
	nodeConfig: node_config,
	bpf:        bpf_config,
}

bpf_node :: struct {
	baseNode: node_base,
	bpf:      bpf,
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	bpf_node_config_init :: proc(channels, sampleRate: u32, cutoffFrequency: f64, order: u32) -> bpf_node_config ---

	bpf_node_init   :: proc(pNodeGraph: ^node_graph, pConfig: ^bpf_node_config, pAllocationCallbacks: ^allocation_callbacks, pNode: ^bpf_node) -> result ---
	bpf_node_reinit :: proc(pConfig: ^bpf_config, pNode: ^bpf_node) -> result ---
	bpf_node_uninit :: proc(pNode: ^bpf_node, pAllocationCallbacks: ^allocation_callbacks) ---
}


/*
Notching Filter Node
*/
notch_node_config :: struct {
	nodeConfig: node_config,
	notch:      notch_config,
}

notch_node :: struct {
	baseNode: node_base,
	notch:    notch2,
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	notch_node_config_init :: proc(channels, sampleRate: u32, q, frequency: f64) -> notch_node_config ---

	notch_node_init   :: proc(pNodeGraph: ^node_graph, pConfig: ^notch_node_config, pAllocationCallbacks: ^allocation_callbacks, pNode: ^notch_node) -> result ---
	notch_node_reinit :: proc(pConfig: ^notch_config, pNode: ^notch_node) -> result ---
	notch_node_uninit :: proc(pNode: ^notch_node, pAllocationCallbacks: ^allocation_callbacks) ---
}


/*
Peaking Filter Node
*/
peak_node_config :: struct {
	nodeConfig: node_config,
	peak:       peak_config,
}

peak_node :: struct {
	baseNode: node_base,
	peak:     peak2,
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	peak_node_config_init :: proc(channels, sampleRate: u32, gainDB, q, frequency: f64) -> peak_node_config ---

	peak_node_init   :: proc(pNodeGraph: ^node_graph, pConfig: ^peak_node_config, pAllocationCallbacks: ^allocation_callbacks, pNode: ^peak_node) -> result ---
	peak_node_reinit :: proc(pConfig: ^peak_config, pNode: ^peak_node) -> result ---
	peak_node_uninit :: proc(pNode: ^peak_node, pAllocationCallbacks: ^allocation_callbacks) ---
}


/*
Low Shelf Filter Node
*/
loshelf_node_config :: struct {
	nodeConfig: node_config,
	loshelf:    loshelf_config,
}

loshelf_node :: struct {
	baseNode: node_base,
	loshelf:  loshelf2,
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	loshelf_node_config_init :: proc(channels, sampleRate: u32, gainDB, q, frequency: f64) -> loshelf_node_config ---

	loshelf_node_init   :: proc(pNodeGraph: ^node_graph, pConfig: ^loshelf_node_config, pAllocationCallbacks: ^allocation_callbacks, pNode: ^loshelf_node) -> result ---
	loshelf_node_reinit :: proc(pConfig: ^loshelf_config, pNode: ^loshelf_node) -> result ---
	loshelf_node_uninit :: proc(pNode: ^loshelf_node, pAllocationCallbacks: ^allocation_callbacks) ---
}


/*
High Shelf Filter Node
*/
hishelf_node_config :: struct {
	nodeConfig: node_config,
	hishelf:    hishelf_config,
}

hishelf_node :: struct {
	baseNode: node_base,
	hishelf:  hishelf2,
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	hishelf_node_config_init :: proc(channels, sampleRate: u32, gainDB, q, frequency: f64) -> hishelf_node_config ---

	hishelf_node_init   :: proc(pNodeGraph: ^node_graph, pConfig: ^hishelf_node_config, pAllocationCallbacks: ^allocation_callbacks, pNode: ^hishelf_node) -> result ---
	hishelf_node_reinit :: proc(pConfig: ^hishelf_config, pNode: ^hishelf_node) -> result ---
	hishelf_node_uninit :: proc(pNode: ^hishelf_node, pAllocationCallbacks: ^allocation_callbacks) ---
}


/*
Delay Filter Node
*/
delay_node_config :: struct {
	nodeConfig: node_config,
	delay:      delay_config,
}

delay_node :: struct {
	baseNode: node_base,
	delay:    delay,
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	delay_node_config_init :: proc(channels, sampleRate, delayInFrames: u32, decay: f32) -> delay_node_config ---

	delay_node_init      :: proc(pNodeGraph: ^node_graph, pConfig: ^delay_node_config, pAllocationCallbacks: ^allocation_callbacks, pDelayNode: ^delay_node) -> result ---
	delay_node_uninit    :: proc(pDelayNode: ^delay_node, pAllocationCallbacks: ^allocation_callbacks) ---
	delay_node_set_wet   :: proc(pDelayNode: ^delay_node, value: f32) ---
	delay_node_get_wet   :: proc(pDelayNode: ^delay_node) -> f32 ---
	delay_node_set_dry   :: proc(pDelayNode: ^delay_node, value: f32) ---
	delay_node_get_dry   :: proc(pDelayNode: ^delay_node) -> f32 ---
	delay_node_set_decay :: proc(pDelayNode: ^delay_node, value: f32) ---
	delay_node_get_decay :: proc(pDelayNode: ^delay_node) -> f32 ---
}
