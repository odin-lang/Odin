#+build windows
package directx_dxc
import win32 "core:sys/windows"
import dxgi "vendor:directx/dxgi"

BOOL            :: dxgi.BOOL
SIZE_T          :: dxgi.SIZE_T
ULONG           :: dxgi.ULONG
CLSID           :: dxgi.GUID
IID             :: dxgi.IID
HRESULT         :: dxgi.HRESULT
IUnknown        :: dxgi.IUnknown
IUnknown_VTable :: dxgi.IUnknown_VTable
wstring         :: win32.wstring
FILETIME        :: win32.FILETIME
BSTR            :: wstring
