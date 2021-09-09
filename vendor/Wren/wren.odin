package wren

// TODO: import on Linux
when ODIN_OS == "windows" do foreign import "lib/wren.lib"

import c "core:c"

WREN_VERSION_MAJOR :: 0;
WREN_VERSION_MINOR :: 4;
WREN_VERSION_PATCH :: 0;
WREN_VERSION_STRING :: "0.4.0";
WREN_VERSION_NUMBER :: 4000;

ReallocateFn         :: #type proc "c" (memory: rawptr, newSize: u64, userData: rawptr) -> rawptr;
ForeignMethodFn      :: #type proc "c" (vm: ^VM);
FinalizerFn          :: #type proc "c" (data: rawptr);
ResolveModuleFn      :: #type proc "c" (vm: VM, importer: cstring, name: cstring) -> cstring;
LoadModuleCompleteFn :: #type proc "c" (vm: ^VM, name: cstring, result: LoadModuleResult);
LoadModuleFn         :: #type proc "c" (vm: ^VM, name: cstring) -> LoadModuleResult;
BindForeignMethodFn  :: #type proc "c" (vm: ^VM, module: cstring, className: cstring, isStatic: bool, signature: cstring) -> ForeignMethodFn;
WriteFn              :: #type proc "c" (vm: ^VM, text: cstring);
ErrorFn              :: #type proc "c" (vm: ^VM, type: ErrorType, module: cstring, line: c.int, message: cstring);
BindForeignClassFn   :: #type proc "c" (vm: ^VM, module: cstring, className: cstring) -> ForeignClassMethods;

ErrorType :: enum i32 {
    WREN_ERROR_COMPILE,
    WREN_ERROR_RUNTIME,
    WREN_ERROR_STACK_TRACE,
}

InterpretResult :: enum i32 {
    WREN_RESULT_SUCCESS,
    WREN_RESULT_COMPILE_ERROR,
    WREN_RESULT_RUNTIME_ERROR,
}

Type :: enum i32 {
    WREN_TYPE_BOOL,
    WREN_TYPE_NUM,
    WREN_TYPE_FOREIGN,
    WREN_TYPE_LIST,
    WREN_TYPE_MAP,
    WREN_TYPE_NULL,
    WREN_TYPE_STRING,
    WREN_TYPE_UNKNOWN,
}

VM :: struct {}

Handle :: struct {}

LoadModuleResult :: struct {
    source : cstring,
    onComplete : LoadModuleCompleteFn,
    userData : rawptr,
}

ForeignClassMethods :: struct {
    allocate : ForeignMethodFn,
    finalize : FinalizerFn,
}

Configuration :: struct {
    reallocateFn : ReallocateFn,
    resolveModuleFn : ResolveModuleFn,
    loadModuleFn : LoadModuleFn,
    bindForeignMethodFn : BindForeignMethodFn,
    bindForeignClassFn : BindForeignClassFn,
    writeFn : WriteFn,
    errorFn : ErrorFn,
    initialHeapSize : c.size_t,
    minHeapSize : c.size_t,
    heapGrowthPercent : c.int,
    userData : rawptr,
}

@(default_calling_convention="c")
foreign wren {

    @(link_name="wrenInitConfiguration")
    InitConfiguration :: proc(configuration : ^Configuration) ---;

    @(link_name="wrenNewVM")
    NewVM :: proc(configuration : ^Configuration) -> ^VM ---;

    @(link_name="wrenFreeVM")
    FreeVM :: proc(vm : ^VM) ---;

    @(link_name="wrenCollectGarbage")
    CollectGarbage :: proc(vm : ^VM) ---;

    @(link_name="wrenInterpret")
    Interpret :: proc(vm : ^VM, module : cstring, source : cstring) -> InterpretResult ---;

    @(link_name="wrenMakeCallHandle")
    MakeCallHandle :: proc(vm : ^VM, signature : cstring) -> ^Handle ---;

    @(link_name="wrenCall")
    Call :: proc(vm : ^VM, method : ^Handle) -> InterpretResult ---;

    @(link_name="wrenReleaseHandle")
    ReleaseHandle :: proc(vm : ^VM, handle : ^Handle) ---;

    @(link_name="wrenGetSlotCount")
    GetSlotCount :: proc(vm : ^VM) -> c.int ---;

    @(link_name="wrenEnsureSlots")
    EnsureSlots :: proc(vm : ^VM, numSlots : c.int) ---;

    @(link_name="wrenGetSlotType")
    GetSlotType :: proc(vm : ^VM, slot : c.int) -> Type ---;

    @(link_name="wrenGetSlotBool")
    GetSlotBool :: proc(vm : ^VM, slot : c.int) -> bool ---;

    @(link_name="wrenGetSlotBytes")
    GetSlotBytes :: proc(vm : ^VM, slot : c.int, length : ^c.int) -> cstring ---;

    @(link_name="wrenGetSlotDouble")
    GetSlotDouble :: proc(vm : ^VM, slot : c.int) -> c.double ---;

    @(link_name="wrenGetSlotForeign")
    GetSlotForeign :: proc(vm : ^VM, slot : c.int) -> rawptr ---;

    @(link_name="wrenGetSlotString")
    GetSlotString :: proc(vm : ^VM, slot : c.int) -> cstring ---;

    @(link_name="wrenGetSlotHandle")
    GetSlotHandle :: proc(vm : ^VM, slot : c.int) -> ^Handle ---;

    @(link_name="wrenSetSlotBool")
    SetSlotBool :: proc(vm : ^VM, slot : c.int, value : bool) ---;

    @(link_name="wrenSetSlotBytes")
    SetSlotBytes :: proc(vm : ^VM, slot : c.int, bytes : cstring, length : c.size_t) ---;

    @(link_name="wrenSetSlotDouble")
    SetSlotDouble :: proc(vm : ^VM, slot : c.int, value : c.double) ---;

    @(link_name="wrenSetSlotNewForeign")
    SetSlotNewForeign :: proc(vm : ^VM, slot : c.int, classSlot : c.int, size : c.size_t) -> rawptr ---;

    @(link_name="wrenSetSlotNewList")
    SetSlotNewList :: proc(vm : ^VM, slot : c.int) ---;

    @(link_name="wrenSetSlotNewMap")
    SetSlotNewMap :: proc(vm : ^VM, slot : c.int) ---;

    @(link_name="wrenSetSlotNull")
    SetSlotNull :: proc(vm : ^VM, slot : c.int) ---;

    @(link_name="wrenSetSlotString")
    SetSlotString :: proc(vm : ^VM, slot : c.int, text : cstring) ---;

    @(link_name="wrenSetSlotHandle")
    SetSlotHandle :: proc(vm : ^VM, slot : c.int, handle : ^Handle) ---;

    @(link_name="wrenGetListCount")
    GetListCount :: proc(vm : ^VM, slot : c.int) -> c.int ---;

    @(link_name="wrenGetListElement")
    GetListElement :: proc(vm : ^VM, listSlot : c.int, index : c.int, elementSlot : c.int) ---;

    @(link_name="wrenSetListElement")
    SetListElement :: proc(vm : ^VM, listSlot : c.int, index : c.int, elementSlot : c.int) ---;

    @(link_name="wrenInsertInList")
    InsertInList :: proc(vm : ^VM, listSlot : c.int, index : c.int, elementSlot : c.int) ---;

    @(link_name="wrenGetMapCount")
    GetMapCount :: proc(vm : ^VM, slot : c.int) -> c.int ---;

    @(link_name="wrenGetMapContainsKey")
    GetMapContainsKey :: proc(vm : ^VM, mapSlot : c.int, keySlot : c.int) -> bool ---;

    @(link_name="wrenGetMapValue")
    GetMapValue :: proc(vm : ^VM, mapSlot : c.int, keySlot : c.int, valueSlot : c.int) ---;

    @(link_name="wrenSetMapValue")
    SetMapValue :: proc(vm : ^VM, mapSlot : c.int, keySlot : c.int, valueSlot : c.int) ---;

    @(link_name="wrenRemoveMapValue")
    RemoveMapValue :: proc(vm : ^VM, mapSlot : c.int, keySlot : c.int, removedValueSlot : c.int) ---;

    @(link_name="wrenGetVariable")
    GetVariable :: proc(vm : ^VM, module : cstring, name : cstring, slot : c.int) ---;

    @(link_name="wrenHasVariable")
    HasVariable :: proc(vm : ^VM, module : cstring, name : cstring) -> bool ---;

    @(link_name="wrenHasModule")
    HasModule :: proc(vm : ^VM, module : cstring) -> bool ---;

    @(link_name="wrenAbortFiber")
    AbortFiber :: proc(vm : ^VM, slot : c.int) ---;

    @(link_name="wrenGetUserData")
    GetUserData :: proc(vm : ^VM) -> rawptr ---;

    @(link_name="wrenSetUserData")
    SetUserData :: proc(vm : ^VM, userData : rawptr) ---;

}
