// Declarations shared between D3D versions.
// Based on d3dcommon.h
package d3d_common

import "core:sys/windows"

IID             :: windows.IID
SIZE_T          :: windows.SIZE_T
IUnknown        :: windows.IUnknown
IUnknown_VTable :: windows.IUnknown_VTable

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
