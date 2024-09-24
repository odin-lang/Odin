package directx_dxc

when ODIN_OS == .Windows {
	foreign import dxcompiler "dxcompiler.lib"
} else {
	foreign import dxcompiler "system:dxcompiler"
}

@(default_calling_convention="c", link_prefix="Dxc")
foreign dxcompiler {
	CreateInstance  :: proc (rclsid: ^CLSID, riid: ^IID, ppv: rawptr) -> HRESULT ---
	CreateInstance2 :: proc (pMalloc: ^IMalloc, rclsid: ^CLSID, riid: ^IID, ppv: rawptr) -> HRESULT ---
}

pCreateInstanceProc  :: #type proc "c" (rclsid: ^CLSID, riid: ^IID, ppv: rawptr) -> HRESULT
pCreateInstance2Proc :: #type proc "c" (pMalloc: ^IMalloc, rclsid: ^CLSID, riid: ^IID, ppv: rawptr) -> HRESULT

CreateInstance_ProcName  :: "DxcCreateInstance"
CreateInstance2_ProcName :: "DxcCreateInstance2"

IMalloc :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using imalloc_vtable: ^IMalloc_VTable,
}
IMalloc_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	Alloc:          proc "system" (this: ^IMalloc, cb: SIZE_T) -> rawptr,
	Realloc:        proc "system" (this: ^IMalloc, pv: rawptr, cb: SIZE_T) -> rawptr,
	Free:           proc "system" (this: ^IMalloc, pv: rawptr),
	GetSize:        proc "system" (this: ^IMalloc, pv: rawptr) -> SIZE_T,
	DidAlloc:       proc "system" (this: ^IMalloc, pv: rawptr) -> i32,
	HeapMinimize:   proc "system" (this: ^IMalloc),
}

ISequentialStream :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using isequentialstream_vtable: ^ISequentialStream_VTable,
}
ISequentialStream_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	Read:  proc "system" (this: ^ISequentialStream, pv: rawptr, cb: ULONG, pcbRead: ^ULONG) -> HRESULT,
	Write: proc "system" (this: ^ISequentialStream, pv: rawptr, cb: ULONG, pcbWritten: ^ULONG) -> HRESULT,
}

STATSTG :: struct {
	pwcsName:          wstring,
	type:              u32,
	cbSize:            u64,
	mtime:             FILETIME,
	ctime:             FILETIME,
	atime:             FILETIME,
	grfMode:           u32,
	grfLocksSupported: u32,
	clsid:             CLSID,
	grfStateBits:      u32,
	reserved:          u32,
}

IStream :: struct #raw_union {
	#subtype isequentialstream: ISequentialStream,
	using istream_vtable: ^IStream_VTable,
}
IStream_VTable :: struct {
	using isequentialstream_vtable: ISequentialStream_VTable,
	Seek:         proc "system" (this: ^IStream, dlibMove: i64, dwOrigin: u32, plibNewPosition: ^u64) -> HRESULT,
	SetSize:      proc "system" (this: ^IStream, libNewSize: u64) -> HRESULT,
	CopyTo:       proc "system" (this: ^IStream, pstm: ^IStream, cb: u64, pcbRead: ^u64, pcbWritten: ^u64) -> HRESULT,
	Commit:       proc "system" (this: ^IStream, grfCommitFlags: u32) -> HRESULT,
	Revert:       proc "system" (this: ^IStream) -> HRESULT,
	LockRegion:   proc "system" (this: ^IStream, libOffset: u64, cb: u64, dwLockType: u32) -> HRESULT,
	UnlockRegion: proc "system" (this: ^IStream, libOffset: u64, cb: u64, dwLockType: u32) -> HRESULT,
	Stat:         proc "system" (this: ^IStream, pstatstg: ^STATSTG, grfStatFlag: u32) -> HRESULT,
	Clone:        proc "system" (this: ^IStream, ppstm: ^^IStream) -> HRESULT,
}

IBlob_UUID_STRING :: "8BA5FB08-5195-40E2-AC58-0D989C3A0102"
IBlob_UUID := &IID{0x8BA5FB08, 0x5195, 0x40E2, {0xAC, 0x58, 0x0D, 0x98, 0x9C, 0x3A, 0x01, 0x02}}
IBlob :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using id3d10blob_vtable: ^IBlob_VTable,
}
IBlob_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	GetBufferPointer: proc "system" (this: ^IBlob) -> rawptr,
	GetBufferSize:    proc "system" (this: ^IBlob) -> SIZE_T,
}

IBlobEncoding_UUID_STRRING :: "7241D424-2646-4191-97C0-98E96E42FC68"
IBlobEncoding_UUID := &IID{0x7241D424, 0x2646, 0x4191, {0x97, 0xC0, 0x98, 0xE9, 0x6E, 0x42, 0xFC, 0x68}}
IBlobEncoding :: struct #raw_union {
	#subtype idxcblob: IBlob,
	using idxcblobencoding_vtable: ^IBlobEncoding_VTable,
}
IBlobEncoding_VTable :: struct {
	using idxcblob_vtable: IBlob_VTable,
	GetEncoding: proc "system" (this: ^IBlobEncoding, pKnown: ^BOOL, pCodePage: ^u32) -> HRESULT,
}

IBlobUtf16_UUID_STRING :: "A3F84EAB-0FAA-497E-A39C-EE6ED60B2D84"
IBlobUtf16_UUID := &IID{0xA3F84EAB, 0x0FAA, 0x497E, {0xA3, 0x9C, 0xEE, 0x6E, 0xD6, 0x0B, 0x2D, 0x84}}
IBlobUtf16 :: struct #raw_union {
	#subtype idxcblobencoding: IBlobEncoding,
	using idxcblobutf16_vtable : ^IBlobUtf16_VTable,
}
IBlobUtf16_VTable :: struct {
	using idxcblobencoding_vtable: IBlobEncoding_VTable,
	GetStringPointer: proc "system" (this: ^IBlobUtf16) -> wstring,
	GetStringLength:  proc "system" (this: ^IBlobUtf16) -> SIZE_T,
}

IBlobUtf8_UUID_STRING :: "3DA636C9-BA71-4024-A301-30CBF125305B"
IBlobUtf8_UUID := &IID{0x3DA636C9, 0xBA71, 0x4024, {0xA3, 0x01, 0x30, 0xCB, 0xF1, 0x25, 0x30, 0x5B}}
IBlobUtf8 :: struct #raw_union {
	#subtype idxcblobencoding: IBlobEncoding,
	using idxcblobutf8_vtable : ^IBlobUtf8_VTable,
}
IBlobUtf8_VTable :: struct {
	using idxcblobencoding_vtable: IBlobEncoding_VTable,
	GetStringPointer: proc "system" (this: ^IBlobUtf8) -> cstring,
	GetStringLength:  proc "system" (this: ^IBlobUtf8) -> SIZE_T,
}

IIncludeHandler_UUID_STRING :: "7F61FC7D-950D-467F-B3E3-3C02FB49187C"
IIncludeHandler_UUID := &IID{0x7F61FC7D, 0x950D, 0x467F, {0xB3, 0xE3, 0x3C, 0x02, 0xFB, 0x49, 0x18, 0x7C}}
IIncludeHandler :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using idxcincludehandler_vtable: ^IIncludeHandler_VTable,
}
IIncludeHandler_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	LoadSource: proc "system" (this: ^IIncludeHandler, pFilename: wstring, ppIncludeSource: ^^IBlob) -> HRESULT,
}

Define :: struct {
	Name:  wstring,
	Value: wstring,
}

ICompilerArgs_UUID_STRING :: "73EFFE2A-70DC-45F8-9690-EFF64C02429D"
ICompilerArgs_UUID := &IID{0x73EFFE2A, 0x70DC, 0x45F8, {0x96, 0x90, 0xEF, 0xF6, 0x4C, 0x02, 0x42, 0x9D}}
ICompilerArgs :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using idxccompilerargs_vtable: ^ICompilerArgs_VTable,
}
ICompilerArgs_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	GetArguments:       proc "system" (this: ^ICompilerArgs) -> [^]wstring,
	GetCount:           proc "system" (this: ^ICompilerArgs) -> u32,
	AddArguments:       proc "system" (this: ^ICompilerArgs, pArguments: [^]wstring, argCount: u32) -> HRESULT,
	AddArgumentsUTF8:   proc "system" (this: ^ICompilerArgs, pArguments: [^]cstring, argCount: u32) -> HRESULT,
	AddDefines:         proc "system" (this: ^ICompilerArgs, pDefines: [^]Define, defineCount: u32) -> HRESULT,
}

ILibrary_UUID_STRING :: "E5204DC7-D18C-4C3C-BDFB-851673980FE7"
ILibrary_UUID := &IID{0xE5204DC7, 0xD18C, 0x4C3C, {0xBD, 0xFB, 0x85, 0x16, 0x73, 0x98, 0x0F, 0xE7}}
ILibrary :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using idxclibrary_vtable: ^ILibrary_VTable,
}
ILibrary_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	SetMalloc:                        proc "system" (this: ^ILibrary, pMalloc: ^IMalloc) -> HRESULT,
	CreateBlobFromBlob:               proc "system" (this: ^ILibrary, pBlob: ^IBlob, offset: u32, length: u32, ppResult: ^^IBlob) -> HRESULT,
	CreateBlobFromFile:               proc "system" (this: ^ILibrary, pFileName: wstring, codePage: ^u32, pBlobEncoding: ^^IBlobEncoding) -> HRESULT,
	CreateBlobWithEncodingFromPinned: proc "system" (this: ^ILibrary, pText: rawptr, size: u32, codePage: u32, pBlobEncoding: ^^IBlobEncoding) -> HRESULT,
	CreateBlobWithEncodingOnHeapCopy: proc "system" (this: ^ILibrary, pText: rawptr, size: u32, codePage: u32, pBlobEncoding: ^^IBlobEncoding) -> HRESULT,
	CreateBlobWithEncodingOnMalloc:   proc "system" (this: ^ILibrary, pText: rawptr, pIMalloc: ^IMalloc, size: u32, codePage: u32, pBlobEncoding: ^^IBlobEncoding) -> HRESULT,
	CreateIncludeHandler:             proc "system" (this: ^ILibrary, ppResult: ^^IIncludeHandler) -> HRESULT,
	CreateStreamFromBlobReadOnly:     proc "system" (this: ^ILibrary, pBlob: ^IBlob, ppStream: ^^IStream) -> HRESULT,
	GetBlobAsUtf8:                    proc "system" (this: ^ILibrary, pBlob: ^IBlob, pBlobEncoding: ^^IBlobEncoding) -> HRESULT,
	GetBlobAsUtf16:                   proc "system" (this: ^ILibrary, pBlob: ^IBlob, pBlobEncoding: ^^IBlobEncoding) -> HRESULT,
}

IOperationResult_UUID_STRING :: "CEDB484A-D4E9-445A-B991-CA21CA157DC2"
IOperationResult_UUID := &IID{0xCEDB484A, 0xD4E9, 0x445A, {0xB9, 0x91, 0xCA, 0x21, 0xCA, 0x15, 0x7D, 0xC2}}
IOperationResult :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using idxcoperationresult_vtable: ^IOperationResult_VTable,
}
IOperationResult_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	GetStatus:      proc "system" (this: ^IOperationResult, pStatus: ^HRESULT) -> HRESULT,
	GetResult:      proc "system" (this: ^IOperationResult, ppResult: ^^IBlob) -> HRESULT,
	GetErrorBuffer: proc "system" (this: ^IOperationResult, ppErrors: ^^IBlobEncoding) -> HRESULT,
}

ICompiler_UUID_STRING :: "8C210BF3-011F-4422-8D70-6F9ACB8DB617"
ICompiler_UUID := &IID{0x8C210BF3, 0x011F, 0x4422, {0x8D, 0x70, 0x6F, 0x9A, 0xCB, 0x8D, 0xB6, 0x17}}
ICompiler :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using idxccompiler_vtable: ^ICompiler_VTable,
}
ICompiler_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	Compile: proc "system" (
		this: ^ICompiler, 
		pSource: ^Buffer, 
		pSourceName: wstring,
		pEntryPoint: wstring,
		pTargetProfile: wstring,
		pArguments: [^]wstring,
		argCount: u32,
		pDefines: [^]Define,
		defineCount: u32,
		pIncludeHandler: ^IIncludeHandler,
		ppResult: ^^IOperationResult) -> HRESULT,
	Preprocess: proc "system" (
		this: ^ICompiler, 
		pSource: ^Buffer, 
		pSourceName: wstring,
		pArguments: [^]wstring,
		argCount: u32,
		pDefines: [^]Define,
		defineCount: u32,
		pIncludeHandler: ^IIncludeHandler,
		ppResult: ^^IOperationResult) -> HRESULT,
	Disassemble: proc "system" (this: ^ICompiler, pSource: ^Buffer, ppDisassembly: ^IBlobEncoding) -> HRESULT,
}

ICompiler2_UUID_STRING :: "A005A9D9-B8BB-4594-B5C9-0E633BEC4D37"
ICompiler2_UUID := &IID{0xA005A9D9, 0xB8BB, 0x4594, {0xB5, 0xC9, 0x0E, 0x63, 0x3B, 0xEC, 0x4D, 0x37}}
ICompiler2 :: struct #raw_union {
	#subtype icompiler: ICompiler,
	using idxccompiler2_vtable: ^ICompiler2_VTable,
}
ICompiler2_VTable :: struct {
	using idxccompiler_vtable: ^ICompiler_VTable,
	CompileWithDebug: proc "system" (
		this: ^ICompiler2,
		pSource: ^Buffer, 
		pSourceName: wstring,
		pEntryPoint: wstring,
		pTargetProfile: wstring,
		pArguments: [^]wstring,
		argCount: u32,
		pDefines: [^]Define,
		defineCount: u32,
		pIncludeHandler: ^IIncludeHandler,
		ppResult: ^^IOperationResult,
		ppDebugBlobName: ^wstring,
		ppDebugBlob: ^^IBlob) -> HRESULT,
}

ILinker_UUID_STRING :: "F1B5BE2A-62DD-4327-A1C2-42AC1E1E78E6"
ILinker_UUID := &IID{0xF1B5BE2A, 0x62DD, 0x4327, {0xA1, 0xC2, 0x42, 0xAC, 0x1E, 0x1E, 0x78, 0xE6}}
ILinker :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using idxclinker_vtable: ^ILinker_VTable,
}
ILinker_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	RegisterLibrary: proc "system" (this: ^ILinker, pLibName: ^IBlob) -> HRESULT,
	Link: proc "system" (
		this: ^ILinker,
		pEntryName: wstring,
		pTargetProfile: wstring,
		pLibNames: [^]wstring,
		libCount: u32,
		pArguments: [^]wstring,
		argCount: u32,
		ppResult: ^^IOperationResult) -> HRESULT,
}

Buffer :: struct {
	Ptr:      rawptr,
	Size:     SIZE_T,
	Encoding: u32,
}

IUtils_UUID_STRING :: "4605C4CB-2019-492A-ADA4-65F20BB7D67F"
IUtils_UUID := &IID{0x4605C4CB, 0x2019, 0x492A, {0xAD, 0xA4, 0x65, 0xF2, 0x0B, 0xB7, 0xD6, 0x7F}}
IUtils :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using idxcutils_vtable: ^IUtils_VTable,
}
IUtils_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	CreateBlobFromBlob:           proc "system" (this: ^IUtils, pBlob: ^IBlob, offset: u32, length: u32, ppResult: ^^IBlob) -> HRESULT,
	CreateBlobFromPinned:         proc "system" (this: ^IUtils, pData: rawptr, size: u32, codePage: u32, pBlobEncoding: ^^IBlobEncoding) -> HRESULT,
	MoveToBlob:                   proc "system" (this: ^IUtils, pData: rawptr, pIMalloc: ^IMalloc, size: u32, codePage: u32, pBlobEncoding: ^^IBlobEncoding) -> HRESULT,
	CreateBlob:                   proc "system" (this: ^IUtils, pData: rawptr, size: u32, codePage: u32, pBlobEncoding: ^^IBlobEncoding) -> HRESULT,
	LoadFile:                     proc "system" (this: ^IUtils, pFileName: wstring, pCodePage: ^u32, pBlobEncoding: ^^IBlobEncoding) -> HRESULT,
	CreateReadOnlyStreamFromBlob: proc "system" (this: ^IUtils, pBlob: ^IBlob, ppStream: ^^IStream) -> HRESULT,
	CreateDefaultIncludeHandler:  proc "system" (this: ^IUtils, ppResult: ^^IIncludeHandler) -> HRESULT,
	GetBlobAsUtf8:                proc "system" (this: ^IUtils, pBlob: ^IBlob, pBlobEncoding: ^^IBlobUtf8) -> HRESULT,
	GetBlobAsUtf16:               proc "system" (this: ^IUtils, pBlob: ^IBlob, pBlobEncoding: ^^IBlobUtf16) -> HRESULT,
	GetDxilContainerPart:         proc "system" (this: ^IUtils, pShader: ^Buffer, Part: u32, ppPartData: rawptr, pPartSizeInBytes: ^u32) -> HRESULT,
	CreateReflection:             proc "system" (this: ^IUtils, pData: ^Buffer, iid: ^IID, ppvReflection: rawptr) -> HRESULT,
	BuildArguments:               proc "system" (this: ^IUtils, pSourceName: wstring, pEntryPoint: wstring, pTargetProfile: wstring, pArguments: [^]wstring, argCount: u32, pDefines: [^]Define, defineCount: u32, ppArgs: ^[^]ICompilerArgs) -> HRESULT,
	GetPDBContents:               proc "system" (this: ^IUtils, pPDBBlob: ^IBlob, ppHash: ^^IBlob, ppContainer: ^^IBlob) -> HRESULT,
}

DXC_OUT_KIND :: enum u32 {
	NONE            = 0,
	OBJECT          = 1,
	ERRORS          = 2,
	PDB             = 3,
	SHADER_HASH     = 4,
	DISASSEMBLY     = 5,
	HLSL            = 6,
	TEXT            = 7,
	REFLECTION      = 8,
	ROOT_SIGNATURE  = 9,
	EXTRA_OUTPUTS   = 10,
	FORCE_DWORD     = 0xFFFFFFFF,
}

IResult_UUID_STRING :: "58346CDA-DDE7-4497-9461-6F87AF5E0659"
IResult_UUID := &IID{0x58346CDA, 0xDDE7, 0x4497, {0x94, 0x61, 0x6F, 0x87, 0xAF, 0x5E, 0x06, 0x59}}
IResult :: struct #raw_union {
	#subtype idxcoperationresult: IOperationResult,
	using idxcresult_vtable: ^IResult_VTable,
}
IResult_VTable :: struct {
	using idxcoperationresult_vtable: IOperationResult_VTable,
	HasOutput:        proc "system" (this: ^IResult, dxcOutKind: DXC_OUT_KIND) -> BOOL,
	GetOutput:        proc "system" (this: ^IResult, dxcOutKind: DXC_OUT_KIND, iid: ^IID, ppvObject: rawptr, ppOutputName: ^^IBlobUtf16) -> HRESULT,
	GetNumOutputs:    proc "system" (this: ^IResult) -> u32,
	GetOutputByIndex: proc "system" (this: ^IResult, Index: u32) -> DXC_OUT_KIND,
	PrimaryOutput:    proc "system" (this: ^IResult) -> DXC_OUT_KIND,
}

IExtraOutputs_UUID_STRING :: "319B37A2-A5C2-494A-A5DE-4801B2FAF989"
IExtraOutputs_UUID := &IID{0x319B37A2, 0xA5C2, 0x494A, {0xA5, 0xDE, 0x48, 0x01, 0xB2, 0xFA, 0xF9, 0x89}}
IExtraOutputs :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using idxcextraoutputs_vtable: ^IExtraOutputs_VTable,
}
IExtraOutputs_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	GetOutputCount: proc "system" (this: ^IExtraOutputs) -> u32,
	GetOutput:      proc "system" (this: ^IExtraOutputs, uIndex: u32, iid: ^IID, ppvObject: rawptr, ppOutputType: ^^IBlobUtf16, ppOutputName: ^^IBlobUtf16) -> HRESULT,
}

ICompiler3_UUID_STRING :: "228B4687-5A6A-4730-900C-9702B2203F54"
ICompiler3_UUID := &IID{0x228B4687, 0x5A6A, 0x4730, {0x90, 0x0C, 0x97, 0x02, 0xB2, 0x20, 0x3F, 0x54}}
ICompiler3 :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using idxccompiler3_vtable: ^ICompiler3_VTable,
}
ICompiler3_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	Compile:     proc "system" (this: ^ICompiler3, pSource: ^Buffer, pArguments: [^]wstring, argCount: u32, pIncludeHandler: ^IIncludeHandler, riid: ^IID, ppResult: rawptr) -> HRESULT,
	Disassemble: proc "system" (this: ^ICompiler3, pObject: ^Buffer, riid: ^IID, ppResult: rawptr) -> HRESULT,
}

IValidator_UUID_STRING :: "A6E82BD2-1FD7-4826-9811-2857E797F49A"
IValidator_UUID := &IID{0xA6E82BD2, 0x1FD7, 0x4826, {0x98, 0x11, 0x28, 0x57, 0xE7, 0x97, 0xF4, 0x9A}}
IValidator :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using idxcvalidator_vtable: ^IValidator_VTable,
}
IValidator_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	Validate: proc "system" (this: ^IValidator, pShader: ^IBlob, Flags: u32, ppResult: ^^IOperationResult) -> HRESULT,
}

IValidator2_UUID_STRING :: "458E1FD1-B1B2-4750-A6E1-9C10F03BED92"
IValidator2_UUID := &IID{0x458E1FD1, 0xB1B2, 0x4750, {0xA6, 0xE1, 0x9C, 0x10, 0xF0, 0x3B, 0xED, 0x92}}
IValidator2 :: struct #raw_union {
	#subtype idxcvalidator: IValidator,
	using idxcvalidator2_vtable: ^IValidator2_VTable,
}
IValidator2_VTable :: struct {
	using idxcvalidator_vtable: IValidator_VTable,
	ValidateWithDebug: proc "system" (this: ^IValidator2, pShader: ^IBlob, Flags: u32, pOptDebugBitcode: ^Buffer, ppResult: ^^IOperationResult) -> HRESULT,
}

IContainerBuilder_UUID_STRING :: "334B1F50-2292-4B35-99A1-25588D8C17FE"
IContainerBuilder_UUID := &IID{0x334B1F50, 0x2292, 0x4B35, {0x99, 0xA1, 0x25, 0x58, 0x8D, 0x8C, 0x17, 0xFE}}
IContainerBuilder :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using idxccontainerbuilder_vtable: ^IContainerBuilder_VTable,
}
IContainerBuilder_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	Load:               proc "system" (this: ^IContainerBuilder, pDxilContainerHeader: ^IBlob) -> HRESULT,
	AddPart:            proc "system" (this: ^IContainerBuilder, fourCC: u32, pSource: ^IBlob) -> HRESULT,
	RemovePart:         proc "system" (this: ^IContainerBuilder, fourCC: u32) -> HRESULT,
	SerializeContainer: proc "system" (this: ^IContainerBuilder, ppResult: ^^IOperationResult) -> HRESULT,
}

IAssembler_UUID_STRING :: "091F7A26-1C1F-4948-904B-E6E3A8A771D5"
IAssembler_UUID := &IID{0x091F7A26, 0x1C1F, 0x4948, {0x90, 0x4B, 0xE6, 0xE3, 0xA8, 0xA7, 0x71, 0xD5}}
IAssembler :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using idxcassembler_vtable: ^IAssembler_VTable,
}
IAssembler_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	AssembleToContainer: proc "system" (this: ^IAssembler, pShader: ^IBlob, ppResult: ^^IOperationResult) -> HRESULT,
}

IContainerReflection_UUID_STRING :: "D2C21B26-8350-4BDC-976A-331CE6F4C54C"
IContainerReflection_UUID := &IID{0xD2C21B26, 0x8350, 0x4BDC, {0x97, 0x6A, 0x33, 0x1C, 0xE6, 0xF4, 0xC5, 0x4C}}
IContainerReflection :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using idxccontainerreflection_vtable: ^IContainerReflection_VTable,
}
IContainerReflection_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	Load:              proc "system" (this: ^IContainerReflection, pContainer: ^IBlob) -> HRESULT,
	GetPartCount:      proc "system" (this: ^IContainerReflection, pResult: ^u32) -> HRESULT,
	GetPartKind:       proc "system" (this: ^IContainerReflection, idx: u32, pResult: ^u32) -> HRESULT,
	GetPartContent:    proc "system" (this: ^IContainerReflection, idx: u32, ppResult: ^^IBlob) -> HRESULT,
	FindFirstPartKind: proc "system" (this: ^IContainerReflection, kind: u32, pResult: ^u32) -> HRESULT,
	GetPartReflection: proc "system" (this: ^IContainerReflection, idx: u32, iid: ^IID, ppvObject: rawptr) -> HRESULT,
}

IOptimizerPass_UUID_STRING :: "AE2CD79F-CC22-453F-9B6B-B124E7A5204C"
IOptimizerPass_UUID := &IID{0xAE2CD79F, 0xCC22, 0x453F, {0x9B, 0x6B, 0xB1, 0x24, 0xE7, 0xA5, 0x20, 0x4C}}
IOptimizerPass :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using idxcoptimizerpass_vtable: ^IOptimizerPass_VTable,
}
IOptimizerPass_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	GetOptionName:           proc "system" (this: ^IOptimizerPass, ppResult: ^wstring) -> HRESULT,
	GetDescription:          proc "system" (this: ^IOptimizerPass, ppResult: ^wstring) -> HRESULT,
	GetOptionArgCount:       proc "system" (this: ^IOptimizerPass, pCount: ^u32) -> HRESULT,
	GetOptionArgName:        proc "system" (this: ^IOptimizerPass, argIndex: u32, ppResult: ^wstring) -> HRESULT,
	GetOptionArgDescription: proc "system" (this: ^IOptimizerPass, argIndex: u32, ppResult: ^wstring) -> HRESULT,
}

IOptimizer_UUID_STRING :: "25740E2E-9CBA-401B-9119-4FB42F39F270"
IOptimizer_UUID := &IID{0x25740E2E, 0x9CBA, 0x401B, {0x91, 0x19, 0x4F, 0xB4, 0x2F, 0x39, 0xF2, 0x70}}
IOptimizer :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using idxcoptimizer_vtable: ^IOptimizer_VTable,
}
IOptimizer_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	GetAvailablePassCount: proc "system" (this: ^IOptimizer, pCount: ^u32) -> HRESULT,
	GetAvailablePass:      proc "system" (this: ^IOptimizer, index: u32, ppResult: ^^IOptimizerPass) -> HRESULT,
	RunOptimizer:          proc "system" (this: ^IOptimizer, pBlob: ^IBlob, ppOptions: [^]wstring, optionCount: u32, pOutputModule: ^^IBlob, ppOutputText: ^^IBlobEncoding) -> HRESULT,
}

VersionInfoFlags :: enum u32 {
	None     = 0,
	Debug    = 1,
	Internal = 2,
}

IVersionInfo_UUID_STRING :: "B04F5B50-2059-4F12-A8FF-A1E0CDE1CC7E"
IVersionInfo_UUID := &IID{0xB04F5B50, 0x2059, 0x4F12, {0xA8, 0xFF, 0xA1, 0xE0, 0xCD, 0xE1, 0xCC, 0x7E}}
IVersionInfo :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using idxcversioninfo_vtable: ^IVersionInfo_VTable,
}
IVersionInfo_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	GetVersion: proc "system" (this: ^IVersionInfo, pMajor: ^u32, pMinor: ^u32) -> HRESULT,
	GetFlags:   proc "system" (this: ^IVersionInfo, pFlags: ^VersionInfoFlags) -> HRESULT,
}

IVersionInfo2_UUID_STRING :: "FB6904C4-42F0-4B62-9C46-983AF7DA7C83"
IVersionInfo2_UUID := &IID{0xFB6904C4, 0x42F0, 0x4B62, {0x9C, 0x46, 0x98, 0x3A, 0xF7, 0xDA, 0x7C, 0x83}}
IVersionInfo2 :: struct #raw_union {
	#subtype idxcversioninfo: IVersionInfo,
	using idxcversioninfo2_vtable: ^IVersionInfo2_VTable,
}
IVersionInfo2_VTable :: struct {
	using idxcversioninfo_vtable: IVersionInfo_VTable,
	GetCommitInfo: proc "system" (this: ^IVersionInfo2, pCommitCount: ^u32, pCommitHash: ^[^]byte) -> HRESULT,
}

IVersionInfo3_UUID_STRING :: "5E13E843-9D25-473C-9AD2-03B2D0B44B1E"
IVersionInfo3_UUID := &IID{0x5E13E843, 0x9D25, 0x473C, {0x9A, 0xD2, 0x03, 0xB2, 0xD0, 0xB4, 0x4B, 0x1E}}
IVersionInfo3 :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using idxcversioninfo3_vtable: ^IVersionInfo3_VTable,
}
IVersionInfo3_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	GetCustomVersionString: proc "system" (this: ^IVersionInfo3, pVersionString: ^cstring) -> HRESULT,
}

ArgPair :: struct {
	pName:  wstring,
	pValue: wstring,
}

IPdbUtils_UUID_STRING :: "E6C9647E-9D6A-4C3B-B94C-524B5A6C343D"
IPdbUtils_UUID := &IID{0xE6C9647E, 0x9D6A, 0x4C3B, {0xB9, 0x4C, 0x52, 0x4B, 0x5A, 0x6C, 0x34, 0x3D}}
IPdbUtils :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using idxcpdbutils_vtable: ^IPdbUtils_VTable,
}
IPdbUtils_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	Load:                  proc "system" (this: ^IPdbUtils, pPdbOrDxil: ^IBlob) -> HRESULT,
	GetSourceCount:        proc "system" (this: ^IPdbUtils, pCount: ^u32) -> HRESULT,
	GetSource:             proc "system" (this: ^IPdbUtils, uIndex: u32, ppResult: ^^IBlobEncoding) -> HRESULT,
	GetSourceName:         proc "system" (this: ^IPdbUtils, uIndex: u32, pResult: ^BSTR) -> HRESULT,
	GetFlagCount:          proc "system" (this: ^IPdbUtils, pCount: ^u32) -> HRESULT,
	GetFlag:               proc "system" (this: ^IPdbUtils, uIndex: u32, pResult: ^BSTR) -> HRESULT,
	GetArgCount:           proc "system" (this: ^IPdbUtils, pCount: ^u32) -> HRESULT,
	GetArg:                proc "system" (this: ^IPdbUtils, uIndex: u32, pResult: ^BSTR) -> HRESULT,
	GetArgPairCount:       proc "system" (this: ^IPdbUtils, pCount: ^u32) -> HRESULT,
	GetArgPair:            proc "system" (this: ^IPdbUtils, uIndex: u32, pName: ^BSTR, pValue: ^BSTR) -> HRESULT,
	GetDefineCount:        proc "system" (this: ^IPdbUtils, pCount: ^u32) -> HRESULT,
	GetDefine:             proc "system" (this: ^IPdbUtils, uIndex: u32, pResult: ^BSTR) -> HRESULT,
	GetTargetProfile:      proc "system" (this: ^IPdbUtils, pResult: ^BSTR) -> HRESULT,
	GetEntryPoint:         proc "system" (this: ^IPdbUtils, pResult: ^BSTR) -> HRESULT,
	GetMainFileName:       proc "system" (this: ^IPdbUtils, pResult: ^BSTR) -> HRESULT,
	GetHash:               proc "system" (this: ^IPdbUtils, ppResult: ^^IBlob) -> HRESULT,
	GetName:               proc "system" (this: ^IPdbUtils, pResult: ^BSTR) -> HRESULT,
	IsFullPDB:             proc "system" (this: ^IPdbUtils) -> BOOL,
	GetFullPDB:            proc "system" (this: ^IPdbUtils, ppFullPDB: ^^IBlob) -> HRESULT,
	GetVersionInfo:        proc "system" (this: ^IPdbUtils, ppVersionInfo: ^^IVersionInfo) -> HRESULT,
	SetCompiler:           proc "system" (this: ^IPdbUtils, pCompiler: ^ICompiler3) -> HRESULT,
	CompileForFullPDB:     proc "system" (this: ^IPdbUtils, ppResult: ^^IResult) -> HRESULT,
	OverrideArgs:          proc "system" (this: ^IPdbUtils, pArgPairs: ^ArgPair, uNumArgPairs: u32) -> HRESULT,
	OverrideRootSignature: proc "system" (this: ^IPdbUtils, pRootSignature: wstring) -> HRESULT,
}


Compiler_CLSID_STRING :: "73E22D93-E6CE-47F3-B5BF-F0664F39C1B0"
Compiler_CLSID := &CLSID{0x73E22D93, 0xE6CE, 0x47F3, {0xB5, 0xBF, 0xF0, 0x66, 0x4F, 0x39, 0xC1, 0xB0}}

Linker_CLSID_STRING :: "EF6A8087-B0EA-4D56-9E45-D07E1A8B7806"
Linker_CLSID := &CLSID{0xEF6A8087, 0xB0EA, 0x4D56, {0x9E, 0x45, 0xD0, 0x7E, 0x1A, 0x8B, 0x78, 0x6}}

DiaDataSource_CLSID_STRING :: "CD1F6B73-2AB0-484D-8EDC-EBE7A43CA09F"
DiaDataSource_CLSID := &CLSID{0xCD1F6B73, 0x2AB0, 0x484D, {0x8E, 0xDC, 0xEB, 0xE7, 0xA4, 0x3C, 0xA0, 0x9F}}

CompilerArgs_CLSID_STRING :: "3E56AE82-224D-470F-A1A1-FE3016EE9F9D"
CompilerArgs_CLSID := &CLSID{0x3E56AE82, 0x224D, 0x470F, {0xA1, 0xA1, 0xFE, 0x30, 0x16, 0xEE, 0x9F, 0x9D}}

Library_CLSID_STRING :: "6245D6AF-66E0-48FD-80B4-4D271796748C"
Library_CLSID := &CLSID{0x6245D6AF, 0x66E0, 0x48FD, {0x80, 0xB4, 0x4D, 0x27, 0x17, 0x96, 0x74, 0x8C}}

Utils_CLSID_STRING :: Library_CLSID_STRING
Utils_CLSID := Library_CLSID

Validator_CLSID_STRING :: "8CA3E215-F728-4CF3-8CDD-88AF917587A1"
Validator_CLSID := &CLSID{0x8CA3E215, 0xF728, 0x4CF3, {0x8C, 0xDD, 0x88, 0xAF, 0x91, 0x75, 0x87, 0xA1}}

Assembler_CLSID_STRING :: "D728DB68-F903-4F80-94CD-DCCF76EC7151"
Assembler_CLSID := &CLSID{0xD728DB68, 0xF903, 0x4F80, {0x94, 0xCD, 0xDC, 0xCF, 0x76, 0xEC, 0x71, 0x51}}

ContainerReflection_CLSID_STRING :: "b9f54489-55b8-400c-ba3a-1675e4728b91"
ContainerReflection_CLSID := &CLSID{0xB9F54489, 0x55B8, 0x400C, {0xBA, 0x3A, 0x16, 0x75, 0xE4, 0x72, 0x8B, 0x91}}

Optimizer_CLSID_STRING :: "AE2CD79F-CC22-453F-9B6B-B124E7A5204C"
Optimizer_CLSID := &CLSID{0xAE2CD79F, 0xCC22, 0x453F, {0x9B, 0x6B, 0xB1, 0x24, 0xE7, 0xA5, 0x20, 0x4C}}

ContainerBuilder_CLSID_STRING :: "94134294-411f-4574-b4d0-8741e25240d2"
ContainerBuilder_CLSID := &CLSID{0x94134294, 0x411F, 0x4574, {0xB4, 0xD0, 0x87, 0x41, 0xE2, 0x52, 0x40, 0xD2}}

PdbUtils_CLSID_STRING :: "54621dfb-f2ce-457e-ae8c-ec355faeec7c"
PdbUtils_CLSID := &CLSID{0x54621DFB, 0xF2CE, 0x457E, {0xAE, 0x8C, 0xEC, 0x35, 0x5F, 0xAE, 0xEC, 0x7C}}

CP_UTF8  :: 65001
CP_UTF16 :: 1200
CP_ACP   :: 0

make_fourcc :: proc "contextless" (ch0, ch1, ch2, ch3: u32) -> u32 {
	return ch0 | (ch1 << 8) | (ch2 << 16) | (ch3 << 24)
}

PART_PDB                      :: u32('I') | (u32('L')<<8) | (u32('D')<<16) | (u32('B')<<24)
PART_PDB_NAME                 :: u32('I') | (u32('L')<<8) | (u32('D')<<16) | (u32('N')<<24)
PART_PRIVATE_DATA             :: u32('P') | (u32('R')<<8) | (u32('I')<<16) | (u32('V')<<24)
PART_ROOT_SIGNATURE           :: u32('R') | (u32('T')<<8) | (u32('S')<<16) | (u32('0')<<24)
PART_DXIL                     :: u32('D') | (u32('X')<<8) | (u32('I')<<16) | (u32('L')<<24)
PART_REFLECTION_DATA          :: u32('S') | (u32('T')<<8) | (u32('A')<<16) | (u32('T')<<24)
PART_SHADER_HASH              :: u32('H') | (u32('A')<<8) | (u32('S')<<16) | (u32('H')<<24)
PART_INPUT_SIGNATURE          :: u32('I') | (u32('S')<<8) | (u32('G')<<16) | (u32('1')<<24)
PART_OUTPUT_SIGNATURE         :: u32('O') | (u32('S')<<8) | (u32('G')<<16) | (u32('1')<<24)
PART_PATCH_CONSTANT_SIGNATURE :: u32('P') | (u32('S')<<8) | (u32('G')<<16) | (u32('1')<<24)

ARG_DEBUG                           :: "-Zi"
ARG_SKIP_VALIDATION                 :: "-Vd"
ARG_SKIP_OPTIMIZATIONS              :: "-Od"
ARG_PACK_MATRIX_ROW_MAJOR           :: "-Zpr"
ARG_PACK_MATRIX_COLUMN_MAJOR        :: "-Zpc"
ARG_AVOID_FLOW_CONTROL              :: "-Gfa"
ARG_PREFER_FLOW_CONTROL             :: "-Gfp"
ARG_ENABLE_STRICTNESS               :: "-Ges"
ARG_ENABLE_BACKWARDS_COMPATIBILITY  :: "-Gec"
ARG_IEEE_STRICTNESS                 :: "-Gis"
ARG_OPTIMIZATION_LEVEL0             :: "-O0"
ARG_OPTIMIZATION_LEVEL1             :: "-O1"
ARG_OPTIMIZATION_LEVEL2             :: "-O2"
ARG_OPTIMIZATION_LEVEL3             :: "-O3"
ARG_WARNINGS_ARE_ERRORS             :: "-WX"
ARG_RESOURCES_MAY_ALIAS             :: "-res_may_alias"
ARG_ALL_RESOURCES_BOUND             :: "-all_resources_bound"
ARG_DEBUG_NAME_FOR_SOURCE           :: "-Zss"
ARG_DEBUG_NAME_FOR_BINARY           :: "-Zsb"

EXTRA_OUTPUT_NAME_STDOUT :: "*stdout*"
EXTRA_OUTPUT_NAME_STDERR :: "*stderr*"
