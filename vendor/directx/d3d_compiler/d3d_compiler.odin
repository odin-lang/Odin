package directx_d3d_compiler

foreign import d3dcompiler "d3dcompiler_47.lib"

D3DCOMPILER_DLL_A :: "d3dcompiler_47.dll"
COMPILER_VERSION :: 47


import "../dxgi"

BOOL            :: dxgi.BOOL
IID             :: dxgi.IID
SIZE_T          :: dxgi.SIZE_T
HRESULT         :: dxgi.HRESULT
IUnknown        :: dxgi.IUnknown
IUnknown_VTable :: dxgi.IUnknown_VTable

@(default_calling_convention="system", link_prefix="D3D")
foreign d3dcompiler {
	ReadFileToBlob                 :: proc(pFileName: [^]u16, ppContents: ^^ID3DBlob) -> HRESULT ---
	WriteBlobToFile                :: proc(pBlob: ^ID3DBlob, pFileName: [^]u16, bOverwrite: BOOL) -> HRESULT ---
	Compile                        :: proc(pSrcData: rawptr, SrcDataSize: SIZE_T, pSourceName: cstring, pDefines: ^SHADER_MACRO, pInclude: ^ID3DInclude, pEntrypoint: cstring, pTarget: cstring, Flags1: u32, Flags2: u32, ppCode: ^^ID3DBlob, ppErrorMsgs: ^^ID3DBlob) -> HRESULT ---
	Compile2                       :: proc(pSrcData: rawptr, SrcDataSize: SIZE_T, pSourceName: cstring, pDefines: ^SHADER_MACRO, pInclude: ^ID3DInclude, pEntrypoint: cstring, pTarget: cstring, Flags1: u32, Flags2: u32, SecondaryDataFlags: u32, pSecondaryData: rawptr, SecondaryDataSize: SIZE_T, ppCode: ^^ID3DBlob, ppErrorMsgs: ^^ID3DBlob) -> HRESULT ---
	CompileFromFile                :: proc(pFileName: [^]u16, pDefines: ^SHADER_MACRO, pInclude: ^ID3DInclude, pEntrypoint: cstring, pTarget: cstring, Flags1: u32, Flags2: u32, ppCode: ^^ID3DBlob, ppErrorMsgs: ^^ID3DBlob) -> HRESULT ---
	Preprocess                     :: proc(pSrcData: rawptr, SrcDataSize: SIZE_T, pSourceName: cstring, pDefines: ^SHADER_MACRO, pInclude: ^ID3DInclude, ppCodeText: ^^ID3DBlob, ppErrorMsgs: ^^ID3DBlob) -> HRESULT ---
	GetDebugInfo                   :: proc(pSrcData: rawptr, SrcDataSize: SIZE_T, ppDebugInfo: ^^ID3DBlob) -> HRESULT ---
	Reflect                        :: proc(pSrcData: rawptr, SrcDataSize: SIZE_T, pInterface: ^IID, ppReflector: ^rawptr) -> HRESULT ---
	ReflectLibrary                 :: proc(pSrcData: rawptr, SrcDataSize: SIZE_T, riid: ^IID, ppReflector: ^rawptr) -> HRESULT ---
	Disassemble                    :: proc(pSrcData: rawptr, SrcDataSize: SIZE_T, Flags: u32, szComments: cstring, ppDisassembly: ^^ID3DBlob) -> HRESULT ---
	DisassembleRegion              :: proc(pSrcData: rawptr, SrcDataSize: SIZE_T, Flags: u32, szComments: cstring, StartByteOffset: SIZE_T, NumInsts: SIZE_T, pFinishByteOffset: ^SIZE_T, ppDisassembly: ^^ID3DBlob) -> HRESULT ---
	CreateLinker                   :: proc(ppLinker: ^^ID3D11Linker) -> HRESULT ---
	LoadModule                     :: proc(pSrcData: rawptr, cbSrcDataSize: SIZE_T, ppModule: ^^ID3D11Module) -> HRESULT ---
	GetTraceInstructionOffsets     :: proc(pSrcData: rawptr, SrcDataSize: SIZE_T, Flags: u32, StartInstIndex: SIZE_T, NumInsts: SIZE_T, pOffsets: ^SIZE_T, pTotalInsts: ^SIZE_T) -> HRESULT ---
	GetInputSignatureBlob          :: proc(pSrcData: rawptr, SrcDataSize: SIZE_T, ppSignatureBlob: ^^ID3DBlob) -> HRESULT ---
	GetOutputSignatureBlob         :: proc(pSrcData: rawptr, SrcDataSize: SIZE_T, ppSignatureBlob: ^^ID3DBlob) -> HRESULT ---
	GetInputAndOutputSignatureBlob :: proc(pSrcData: rawptr, SrcDataSize: SIZE_T, ppSignatureBlob: ^^ID3DBlob) -> HRESULT ---
	StripShader                    :: proc(pShaderBytecode: rawptr, BytecodeLength: SIZE_T, uStripFlags: u32, ppStrippedBlob: ^^ID3DBlob) -> HRESULT ---
	GetBlobPart                    :: proc(pSrcData: rawptr, SrcDataSize: SIZE_T, Part: BLOB_PART, Flags: u32, ppPart: ^^ID3DBlob) -> HRESULT ---
	SetBlobPart                    :: proc(pSrcData: rawptr, SrcDataSize: SIZE_T, Part: BLOB_PART, Flags: u32, pPart: rawptr, PartSize: SIZE_T, ppNewShader: ^^ID3DBlob) -> HRESULT ---
	CreateBlob                     :: proc(Size: SIZE_T, ppBlob: ^^ID3DBlob) -> HRESULT ---
	CompressShaders                :: proc(uNumShaders: u32, pShaderData: ^SHADER_DATA, uFlags: u32, ppCompressedData: ^^ID3DBlob) -> HRESULT ---
	DecompressShaders              :: proc(pSrcData: rawptr, SrcDataSize: SIZE_T, uNumShaders: u32, uStartIndex: u32, pIndices: ^u32, uFlags: u32, ppShaders: [^]^ID3DBlob, pTotalShaders: ^u32) -> HRESULT ---
	Disassemble10Effect            :: proc(pEffect: ^ID3D10Effect, Flags: u32, ppDisassembly: ^^ID3DBlob) -> HRESULT ---
}



D3DCOMPILE :: distinct bit_set[D3DCOMPILE_FLAG; u32]
D3DCOMPILE_FLAG :: enum u32 {
	DEBUG                              = 0,
	SKIP_VALIDATION                    = 1,
	SKIP_OPTIMIZATION                  = 2,
	PACK_MATRIX_ROW_MAJOR              = 3,
	PACK_MATRIX_COLUMN_MAJOR           = 4,
	PARTIAL_PRECISION                  = 5,
	FORCE_VS_SOFTWARE_NO_OPT           = 6,
	FORCE_PS_SOFTWARE_NO_OPT           = 7,
	NO_PRESHADER                       = 8,
	AVOID_FLOW_CONTROL                 = 9,
	PREFER_FLOW_CONTROL                = 10,
	ENABLE_STRICTNESS                  = 11,
	ENABLE_BACKWARDS_COMPATIBILITY     = 12,
	IEEE_STRICTNESS                    = 13,
	OPTIMIZATION_LEVEL0                = 14,
	OPTIMIZATION_LEVEL3                = 15,
	RESERVED16                         = 16,
	RESERVED17                         = 17,
	WARNINGS_ARE_ERRORS                = 18,
	RESOURCES_MAY_ALIAS                = 19,
	ENABLE_UNBOUNDED_DESCRIPTOR_TABLES = 20,
	ALL_RESOURCES_BOUND                = 21,
	DEBUG_NAME_FOR_SOURCE              = 22,
	DEBUG_NAME_FOR_BINARY              = 23,
}

D3DCOMPILE_OPTIMIZATION_LEVEL0 :: D3DCOMPILE{.OPTIMIZATION_LEVEL0}
D3DCOMPILE_OPTIMIZATION_LEVEL1 :: D3DCOMPILE{}
D3DCOMPILE_OPTIMIZATION_LEVEL2 :: D3DCOMPILE{.IEEE_STRICTNESS, .OPTIMIZATION_LEVEL3}
D3DCOMPILE_OPTIMIZATION_LEVEL3 :: D3DCOMPILE{.OPTIMIZATION_LEVEL3}


EFFECT :: distinct bit_set[EFFECT_FLAG; u32]
EFFECT_FLAG :: enum u32 {
	CHILD_EFFECT   = 0,
	ALLOW_SLOW_OPS = 1,
}

FLAGS2 :: enum u32 {
	FORCE_ROOT_SIGNATURE_LATEST = 0,
	FORCE_ROOT_SIGNATURE_1_0    = 1 << 4,
	FORCE_ROOT_SIGNATURE_1_1    = 1 << 5,
}

SECDATA :: distinct bit_set[SECDATA_FLAG; u32]
SECDATA_FLAG :: enum u32 {
	MERGE_UAV_SLOTS         = 0,
	PRESERVE_TEMPLATE_SLOTS = 1,
	REQUIRE_TEMPLATE_MATCH  = 2,
}

DISASM_ENABLE_COLOR_CODE            :: 0x00000001
DISASM_ENABLE_DEFAULT_VALUE_PRINTS  :: 0x00000002
DISASM_ENABLE_INSTRUCTION_NUMBERING :: 0x00000004
DISASM_ENABLE_INSTRUCTION_CYCLE     :: 0x00000008
DISASM_DISABLE_DEBUG_INFO           :: 0x00000010
DISASM_ENABLE_INSTRUCTION_OFFSET    :: 0x00000020
DISASM_INSTRUCTION_ONLY             :: 0x00000040
DISASM_PRINT_HEX_LITERALS           :: 0x00000080

GET_INST_OFFSETS_INCLUDE_NON_EXECUTABLE :: 0x00000001

COMPRESS_SHADER_KEEP_ALL_PARTS :: 0x00000001

SHADER_MACRO :: struct {
	Name:       cstring,
	Definition: cstring,
}

ID3D10Blob_UUID_STRING :: "8BA5FB08-5195-40E2-AC58-0D989C3A0102"
ID3D10Blob_UUID := &IID{0x8BA5FB08, 0x5195, 0x40E2, {0xAC, 0x58, 0x0D, 0x98, 0x9C, 0x3A, 0x01, 0x02}}
ID3D10Blob :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using id3d10blob_vtable: ^ID3D10Blob_VTable,
}
ID3D10Blob_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	GetBufferPointer: proc "system" (this: ^ID3D10Blob) -> rawptr,
	GetBufferSize:    proc "system" (this: ^ID3D10Blob) -> SIZE_T,
}


ID3DBlob :: ID3D10Blob
ID3DBlob_VTable :: ID3D10Blob_VTable


INCLUDE_TYPE :: enum i32 {
	INCLUDE_LOCAL       = 0,
	INCLUDE_SYSTEM      = 1,
	_10_INCLUDE_LOCAL   = 0,
	_10_INCLUDE_SYSTEM  = 1,
	INCLUDE_FORCE_DWORD = 2147483647,
}

ID3DInclude :: struct {
	vtable: ^ID3DInclude_VTable,
}
ID3DInclude_VTable :: struct {
	Open:  proc "system" (this: ^ID3DInclude, IncludeType: INCLUDE_TYPE, pFileName: cstring, pParentData: rawptr, ppData: ^rawptr, pBytes: ^u32) -> HRESULT,
	Close: proc "system" (this: ^ID3DInclude, pData: rawptr) -> HRESULT,
}

// Default file includer
D3DCOMPILE_STANDARD_FILE_INCLUDE :: (^ID3DInclude)(uintptr(1))


ID3D11Module :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using id3d11module_vtable: ^ID3D11Module_VTable,
}
ID3D11Module_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	CreateInstance: proc "system" (this: ^ID3D11Module, pNamespace: cstring, ppModuleInstance: ^^ID3D11ModuleInstance) -> HRESULT,
}


ID3D11ModuleInstance :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using id3d11moduleinstance_vtable: ^ID3D11ModuleInstance_VTable,
}
ID3D11ModuleInstance_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	BindConstantBuffer:                      proc "system" (this: ^ID3D11ModuleInstance, uSrcSlot: u32, uDstSlot: u32, cbDstOffset: u32) -> HRESULT,
	BindConstantBufferByName:                proc "system" (this: ^ID3D11ModuleInstance, pName: cstring, uDstSlot: u32, cbDstOffset: u32) -> HRESULT,
	BindResource:                            proc "system" (this: ^ID3D11ModuleInstance, uSrcSlot: u32, uDstSlot: u32, uCount: u32) -> HRESULT,
	BindResourceByName:                      proc "system" (this: ^ID3D11ModuleInstance, pName: cstring, uDstSlot: u32, uCount: u32) -> HRESULT,
	BindSampler:                             proc "system" (this: ^ID3D11ModuleInstance, uSrcSlot: u32, uDstSlot: u32, uCount: u32) -> HRESULT,
	BindSamplerByName:                       proc "system" (this: ^ID3D11ModuleInstance, pName: cstring, uDstSlot: u32, uCount: u32) -> HRESULT,
	BindUnorderedAccessView:                 proc "system" (this: ^ID3D11ModuleInstance, uSrcSlot: u32, uDstSlot: u32, uCount: u32) -> HRESULT,
	BindUnorderedAccessViewByName:           proc "system" (this: ^ID3D11ModuleInstance, pName: cstring, uDstSlot: u32, uCount: u32) -> HRESULT,
	BindResourceAsUnorderedAccessView:       proc "system" (this: ^ID3D11ModuleInstance, uSrcSrvSlot: u32, uDstUavSlot: u32, uCount: u32) -> HRESULT,
	BindResourceAsUnorderedAccessViewByName: proc "system" (this: ^ID3D11ModuleInstance, pSrvName: cstring, uDstUavSlot: u32, uCount: u32) -> HRESULT,
}


ID3D11Linker :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using id3d11linker_vtable: ^ID3D11Linker_VTable,
}
ID3D11Linker_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	Link:                    proc "system" (this: ^ID3D11Linker, pEntry: ^ID3D11ModuleInstance, pEntryName: cstring, pTargetName: cstring, uFlags: u32, ppShaderBlob: ^^ID3DBlob, ppErrorBuffer: ^^ID3DBlob) -> HRESULT,
	UseLibrary:              proc "system" (this: ^ID3D11Linker, pLibraryMI: ^ID3D11ModuleInstance) -> HRESULT,
	AddClipPlaneFromCBuffer: proc "system" (this: ^ID3D11Linker, uCBufferSlot: u32, uCBufferEntry: u32) -> HRESULT,
}


pD3DCompile     :: #type proc "c" (a0: rawptr, a1: SIZE_T, a2: cstring, a3: ^SHADER_MACRO, a4: ^ID3DInclude, a5: cstring, a6: cstring, a7: u32, a8: u32, a9: ^^ID3DBlob, a10: ^^ID3DBlob) -> HRESULT
pD3DPreprocess  :: #type proc "c" (a0: rawptr, a1: SIZE_T, a2: cstring, a3: ^SHADER_MACRO, a4: ^ID3DInclude, a5: ^^ID3DBlob, a6: ^^ID3DBlob) -> HRESULT
pD3DDisassemble :: #type proc "c" (a0: rawptr, a1: SIZE_T, a2: u32, a3: cstring, a4: ^^ID3DBlob) -> HRESULT

D3DCOMPILER_STRIP_FLAGS :: distinct bit_set[D3DCOMPILER_STRIP_FLAG; u32]
D3DCOMPILER_STRIP_FLAG :: enum u32 {
	REFLECTION_DATA = 0,
	DEBUG_INFO      = 1,
	TEST_BLOBS      = 2,
	PRIVATE_DATA    = 3,
	ROOT_SIGNATURE  = 4,
}

BLOB_PART :: enum i32 {
	INPUT_SIGNATURE_BLOB            = 0,
	OUTPUT_SIGNATURE_BLOB           = 1,
	INPUT_AND_OUTPUT_SIGNATURE_BLOB = 2,
	PATCH_CONSTANT_SIGNATURE_BLOB   = 3,
	ALL_SIGNATURE_BLOB              = 4,
	DEBUG_INFO                      = 5,
	LEGACY_SHADER                   = 6,
	XNA_PREPASS_SHADER              = 7,
	XNA_SHADER                      = 8,
	PDB                             = 9,
	PRIVATE_DATA                    = 10,
	ROOT_SIGNATURE                  = 11,
	DEBUG_NAME                      = 12,

	TEST_ALTERNATE_SHADER           = 32768,
	TEST_COMPILE_DETAILS            = 32769,
	TEST_COMPILE_PERF               = 32770,
	TEST_COMPILE_REPORT             = 32771,
}

SHADER_DATA :: struct {
	pBytecode:      rawptr,
	BytecodeLength: SIZE_T,
}

ID3D10Effect :: struct {
	// ????
}
