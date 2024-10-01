package lua_5_3

import "base:intrinsics"
import "base:builtin"

import c "core:c/libc"

#assert(size_of(c.int) == size_of(b32))

LUA_SHARED :: #config(LUA_SHARED, false)

when LUA_SHARED {
	when ODIN_OS == .Windows {
		// Does nothing special on windows
		foreign import lib "windows/lua53dll.lib"
	} else when ODIN_OS == .Linux {
		foreign import lib "linux/liblua53.so"
	} else {
		foreign import lib "system:lua5.3"
	}
} else {
	when ODIN_OS == .Windows {
		foreign import lib "windows/lua53dll.lib"
	} else when ODIN_OS == .Linux {
		foreign import lib "linux/liblua53.a"
	} else {
		foreign import lib "system:lua5.3"
	}
}

VERSION_MAJOR       :: "5"
VERSION_MINOR       :: "3"
VERSION_NUM         :: 503
VERSION_RELEASE     :: "6"

VERSION             :: "Lua " + VERSION_MAJOR + "." + VERSION_MINOR
RELEASE             :: VERSION + "." + VERSION_RELEASE
COPYRIGHT           :: RELEASE + "  Copyright (C) 1994-2020 Lua.org, PUC-Rio"
AUTHORS             :: "R. Ierusalimschy, L. H. de Figueiredo, W. Celes"


/* mark for precompiled code ('<esc>Lua') */
SIGNATURE :: "\x1bLua"

/* option for multiple returns in 'lua_pcall' and 'lua_call' */
MULTRET :: -1

REGISTRYINDEX :: -MAXSTACK - 1000


/*
@@ LUAI_MAXSTACK limits the size of the Lua stack.
** CHANGE it if you need a different limit. This limit is arbitrary;
** its only purpose is to stop Lua from consuming unlimited stack
** space (and to reserve some numbers for pseudo-indices).
** (It must fit into max(size_t)/32.)
*/
MAXSTACK :: 1000000


/*
@@ LUA_EXTRASPACE defines the size of a raw memory area associated with
** a Lua state with very fast access.
** CHANGE it if you need a different size.
*/
EXTRASPACE :: size_of(rawptr)



/*
@@ LUA_IDSIZE gives the maximum size for the description of the source
@@ of a function in debug information.
** CHANGE it if you want a different size.
*/
IDSIZE :: 60


/*
@@ LUAL_BUFFERSIZE is the buffer size used by the lauxlib buffer system.
*/
L_BUFFERSIZE :: c.int(16 * size_of(rawptr) * size_of(Number))


MAXALIGNVAL :: max(align_of(Number), align_of(f64), align_of(rawptr), align_of(Integer), align_of(c.long))


Status :: enum c.int {
	OK        = 0,
	YIELD     = 1,
	ERRRUN    = 2,
	ERRSYNTAX = 3,
	ERRMEM    = 4,
	ERRERR    = 5,
	ERRGCMM   = 6,
	ERRFILE   = 7,
}

/* thread status */
OK        :: Status.OK
YIELD     :: Status.YIELD
ERRRUN    :: Status.ERRRUN
ERRSYNTAX :: Status.ERRSYNTAX
ERRMEM    :: Status.ERRMEM
ERRERR    :: Status.ERRERR
ERRFILE   :: Status.ERRFILE

/*
** basic types
*/


Type :: enum c.int {
	NONE          = -1,

	NIL           = 0,
	BOOLEAN       = 1,
	LIGHTUSERDATA = 2,
	NUMBER        = 3,
	STRING        = 4,
	TABLE         = 5,
	FUNCTION      = 6,
	USERDATA      = 7,
	THREAD        = 8,
}

TNONE          :: Type.NONE
TNIL           :: Type.NIL
TBOOLEAN       :: Type.BOOLEAN
TLIGHTUSERDATA :: Type.LIGHTUSERDATA
TNUMBER        :: Type.NUMBER
TSTRING        :: Type.STRING
TTABLE         :: Type.TABLE
TFUNCTION      :: Type.FUNCTION
TUSERDATA      :: Type.USERDATA
TTHREAD        :: Type.THREAD
NUMTYPES :: 9



ArithOp :: enum c.int {
	ADD  = 0,	/* ORDER TM, ORDER OP */
	SUB  = 1,
	MUL  = 2,
	MOD  = 3,
	POW  = 4,
	DIV  = 5,
	IDIV = 6,
	BAND = 7,
	BOR  = 8,
	BXOR = 9,
	SHL  = 10,
	SHR  = 11,
	UNM  = 12,
	BNOT = 13,
}

CompareOp :: enum c.int {
	EQ = 0,
	LT = 1,
	LE = 2,
}

OPADD  :: ArithOp.ADD
OPSUB  :: ArithOp.SUB
OPMUL  :: ArithOp.MUL
OPMOD  :: ArithOp.MOD
OPPOW  :: ArithOp.POW
OPDIV  :: ArithOp.DIV
OPIDIV :: ArithOp.IDIV
OPBAND :: ArithOp.BAND
OPBOR  :: ArithOp.BOR
OPBXOR :: ArithOp.BXOR
OPSHL  :: ArithOp.SHL
OPSHR  :: ArithOp.SHR
OPUNM  :: ArithOp.UNM
OPBNOT :: ArithOp.BNOT

OPEQ :: CompareOp.EQ
OPLT :: CompareOp.LT
OPLE :: CompareOp.LE


/* minimum Lua stack available to a C function */
MINSTACK :: 20


/* predefined values in the registry */
RIDX_MAINTHREAD :: 1
RIDX_GLOBALS    :: 2
RIDX_LAST       :: RIDX_GLOBALS


/* type of numbers in Lua */
Number :: distinct (f32 when size_of(uintptr) == 4 else f64)


/* type for integer functions */
Integer :: distinct (i32 when size_of(uintptr) == 4 else i64)

/* unsigned integer type */
Unsigned :: distinct (u32 when size_of(uintptr) == 4 else u64)

/* type for continuation-function contexts */
KContext :: distinct int


/*
** Type for C functions registered with Lua
*/
CFunction :: #type proc "c" (L: ^State) -> c.int

/*
** Type for continuation functions
*/
KFunction :: #type proc "c" (L: ^State, status: c.int, ctx: KContext) -> c.int


/*
** Type for functions that read/write blocks when loading/dumping Lua chunks
*/
Reader :: #type proc "c" (L: ^State, ud: rawptr, sz: ^c.size_t) -> cstring
Writer :: #type proc "c" (L: ^State, p: rawptr, sz: ^c.size_t, ud: rawptr) -> c.int


/*
** Type for memory-allocation functions
*/
Alloc :: #type proc "c" (ud: rawptr, ptr: rawptr, osize, nsize: c.size_t) -> rawptr


GCWhat :: enum c.int {
	STOP       = 0,
	RESTART    = 1,
	COLLECT    = 2,
	COUNT      = 3,
	COUNTB     = 4,
	STEP       = 5,
	SETPAUSE   = 6,
	SETSTEPMUL = 7,
	ISRUNNING  = 9,
}
GCSTOP       :: GCWhat.STOP
GCRESTART    :: GCWhat.RESTART
GCCOLLECT    :: GCWhat.COLLECT
GCCOUNT      :: GCWhat.COUNT
GCCOUNTB     :: GCWhat.COUNTB
GCSTEP       :: GCWhat.STEP
GCSETPAUSE   :: GCWhat.SETPAUSE
GCSETSTEPMUL :: GCWhat.SETSTEPMUL
GCISRUNNING  :: GCWhat.ISRUNNING



/*
** Event codes
*/

HookEvent :: enum c.int {
	CALL     = 0,
	RET      = 1,
	LINE     = 2,
	COUNT    = 3,
	TAILCALL = 4,
}
HOOKCALL     :: HookEvent.CALL
HOOKRET      :: HookEvent.RET
HOOKLINE     :: HookEvent.LINE
HOOKCOUNT    :: HookEvent.COUNT
HOOKTAILCALL :: HookEvent.TAILCALL


/*
** Event masks
*/
HookMask :: distinct bit_set[HookEvent; c.int]
MASKCALL  :: HookMask{.CALL}
MASKRET   :: HookMask{.RET}
MASKLINE  :: HookMask{.LINE}
MASKCOUNT :: HookMask{.COUNT}

/* activation record */
Debug :: struct {
	event:           HookEvent,
	name:            cstring,                  /* (n) */
	namewhat:        cstring,                  /* (n) 'global', 'local', 'field', 'method' */
	what:            cstring,                  /* (S) 'Lua', 'C', 'main', 'tail' */
	source:          cstring,                  /* (S) */
	currentline:     c.int,                    /* (l) */
	linedefined:     c.int,                    /* (S) */
	lastlinedefined: c.int,                    /* (S) */
	nups:            u8,                       /* (u) number of upvalues */
	nparams:         u8,                       /* (u) number of parameters */
	isvararg:        bool,                     /* (u) */
	istailcall:      bool,                     /* (t) */
	short_src:       [IDSIZE]u8 `fmt:"s"`, /* (S) */
	/* private part */
	i_ci:            rawptr,                   /* active function */
}


/* Functions to be called by the debugger in specific events */
Hook :: #type proc "c" (L: ^State, ar: ^Debug)


State :: struct {} // opaque data type


@(link_prefix="lua_")
@(default_calling_convention="c")
foreign lib {
	/*
	** RCS ident string
	*/

	ident: [^]u8 // TODO(bill): is this correct?


	/*
	** state manipulation
	*/

	newstate  :: proc(f: Alloc, ud: rawptr) -> ^State ---
	close     :: proc(L: ^State) ---
	newthread :: proc(L: ^State) -> ^State ---

	atpanic :: proc(L: ^State, panicf: CFunction) -> CFunction ---

	version :: proc(L: ^State) -> ^Number ---


	/*
	** basic stack manipulation
	*/

	absindex   :: proc (L: ^State, idx: c.int) -> c.int ---
	gettop     :: proc (L: ^State) -> c.int ---
	settop     :: proc (L: ^State, idx: c.int) ---
	pushvalue  :: proc (L: ^State, idx: c.int) ---
	rotate     :: proc (L: ^State, idx: c.int, n: c.int) ---
	copy       :: proc (L: ^State, fromidx, toidx: c.int) ---
	checkstack :: proc (L: ^State, n: c.int) -> c.int ---

	xmove :: proc(from, to: ^State, n: c.int) ---


	/*
	** access functions (stack -> C)
	*/

	isnumber    :: proc(L: ^State, idx: c.int) -> b32 ---
	isstring    :: proc(L: ^State, idx: c.int) -> b32 ---
	iscfunction :: proc(L: ^State, idx: c.int) -> b32 ---
	isinteger   :: proc(L: ^State, idx: c.int) -> b32 ---
	isuserdata  :: proc(L: ^State, idx: c.int) -> b32 ---
	type        :: proc(L: ^State, idx: c.int) -> Type ---
	typename    :: proc(L: ^State, tp: Type) -> cstring ---

	@(link_name="lua_tonumberx")
	tonumber    :: proc(L: ^State, idx: c.int, isnum: ^b32 = nil) -> Number ---
	@(link_name="lua_tointegerx")
	tointeger   :: proc(L: ^State, idx: c.int, isnum: ^b32 = nil) -> Integer ---
	toboolean   :: proc(L: ^State, idx: c.int) -> b32 ---
	tolstring   :: proc(L: ^State, idx: c.int, len: ^c.size_t) -> cstring ---
	rawlen      :: proc(L: ^State, idx: c.int) -> c.size_t ---
	tocfunction :: proc(L: ^State, idx: c.int) -> CFunction ---
	touserdata  :: proc(L: ^State, idx: c.int) -> rawptr ---
	tothread    :: proc(L: ^State, idx: c.int) -> ^State ---
	topointer   :: proc(L: ^State, idx: c.int) -> rawptr ---

	/*
	** Comparison and arithmetic functions
	*/

	arith    :: proc(L: ^State, op: ArithOp) ---
	rawequal :: proc(L: ^State, idx1, idx2: c.int) -> b32 ---
	compare  :: proc(L: ^State, idx1, idx2: c.int, op: CompareOp) -> b32 ---

	/*
	** push functions (C -> stack)
	*/

	pushnil      :: proc(L: ^State) ---
	pushnumber   :: proc(L: ^State, n: Number) ---
	pushinteger  :: proc(L: ^State, n: Integer) ---
	pushlstring  :: proc(L: ^State, s: cstring, len: c.size_t) -> cstring ---
	pushstring   :: proc(L: ^State, s: cstring) -> cstring ---
	pushvfstring :: proc(L: ^State, fmt: cstring, argp: c.va_list) -> cstring ---
	pushfstring       :: proc(L: ^State, fmt: cstring, #c_vararg args: ..any) -> cstring ---
	pushcclosure      :: proc(L: ^State, fn: CFunction, n: c.int) ---
	pushboolean       :: proc(L: ^State, b: b32) ---
	pushlightuserdata :: proc(L: ^State, p: rawptr) ---
	pushthread        :: proc(L: ^State) -> Status ---

	/*
	** get functions (Lua -> stack)
	*/

	getglobal :: proc(L: ^State, name: cstring) -> c.int ---
	gettable  :: proc(L: ^State, idx: c.int) -> c.int ---
	getfield  :: proc(L: ^State, idx: c.int, k: cstring) -> c.int ---
	geti      :: proc(L: ^State, idx: c.int, n: Integer) -> c.int ---
	rawget    :: proc(L: ^State, idx: c.int) -> c.int ---
	rawgeti   :: proc(L: ^State, idx: c.int, n: Integer) -> c.int ---
	rawgetp   :: proc(L: ^State, idx: c.int, p: rawptr) -> c.int ---

	createtable  :: proc(L: ^State, narr, nrec: c.int) ---
	newuserdata  :: proc(L: ^State, sz: c.size_t) -> rawptr ---
	getmetatable :: proc(L: ^State, objindex: c.int) -> c.int ---
	getuservalue :: proc(L: ^State, idx: c.int) -> c.int ---


	/*
	** set functions (stack -> Lua)
	*/

	setglobal    :: proc(L: ^State, name: cstring) ---
	settable     :: proc(L: ^State, idx: c.int) ---
	setfield     :: proc(L: ^State, idx: c.int, k: cstring) ---
	seti         :: proc(L: ^State, idx: c.int, n: Integer) ---
	rawset       :: proc(L: ^State, idx: c.int) ---
	rawseti      :: proc(L: ^State, idx: c.int, n: Integer) ---
	rawsetp      :: proc(L: ^State, idx: c.int, p: rawptr) ---
	setmetatable :: proc(L: ^State, objindex: c.int) -> c.int ---
	setuservalue :: proc(L: ^State, idx: c.int) -> c.int ---


	/*
	** 'load' and 'call' functions (load and run Lua code)
	*/

	@(link_name="lua_callk")
	call :: proc(L: ^State, nargs, nresults: c.int,
	             ctx: KContext = 0, k: KFunction = nil) ---

	@(link_name="lua_pcallk")
	pcall :: proc(L: ^State, nargs, nresults: c.int, errfunc: c.int,
	              ctx: KContext = 0, k: KFunction = nil) -> c.int ---

	load :: proc(L: ^State, reader: Reader, dt: rawptr,
	             chunkname, mode: cstring) -> Status ---

	dump :: proc(L: ^State, writer: Writer, data: rawptr, strip: b32) -> Status ---


	/*
	** coroutine functions
	*/

	@(link_name="lua_yieldk")
	yield       :: proc(L: ^State, nresults: c.int, ctx: KContext = 0, k: KFunction = nil) -> Status ---
	resume      :: proc(L: ^State, from: ^State, narg: c.int) -> Status ---
	status      :: proc(L: ^State) -> Status ---
	isyieldable :: proc(L: ^State) -> b32 ---


	/*
	** garbage-collection function and options
	*/



	gc :: proc(L: ^State, what: GCWhat, data: c.int) -> c.int ---


	/*
	** miscellaneous functions
	*/

	error :: proc(L: ^State) -> Status ---

	next :: proc(L: ^State, idx: c.int) -> c.int ---

	concat :: proc(L: ^State, n: c.int) ---
	len    :: proc(L: ^State, idx: c.int) ---

	stringtonumber :: proc(L: ^State, s: cstring) -> c.size_t ---

	getallocf :: proc(L: State, ud: ^rawptr) -> Alloc ---
	setallocf :: proc(L: ^State, f: Alloc, ud: rawptr) ---

	/*
	** {======================================================================
	** Debug API
	** =======================================================================
	*/

	getstack   :: proc(L: ^State, level: c.int, ar: ^Debug) -> c.int ---
	getinfo    :: proc(L: ^State, what: cstring, ar: ^Debug) -> c.int ---
	getlocal   :: proc(L: ^State, ar: ^Debug, n: c.int) -> cstring ---
	setlocal   :: proc(L: ^State, ar: ^Debug, n: c.int) -> cstring ---
	getupvalue :: proc(L: ^State, funcindex: c.int, n: c.int) -> cstring ---
	setupvalue :: proc(L: ^State, funcindex: c.int, n: c.int) -> cstring ---

	upvalueid   :: proc(L: ^State, fidx, n: c.int) -> rawptr ---
	upvaluejoin :: proc(L: ^State, fidx1, n1, fidx2, n2: c.int) ---

	sethook :: proc(L: ^State, func: Hook, mask: HookMask, count: c.int) ---
	gethook :: proc(L: ^State) -> Hook ---
	gethookmask  :: proc(L: ^State) -> HookMask ---
	gethookcount :: proc(L: ^State) -> c.int ---

	/* }============================================================== */
}



/* version suffix for environment variable names */
VERSUFFIX :: "_" + VERSION_MAJOR + "_" + VERSION_MINOR

COLIBNAME   :: "coroutine"
TABLIBNAME  :: "table"
IOLIBNAME   :: "io"
OSLIBNAME   :: "os"
STRLIBNAME  :: "string"
UTF8LIBNAME :: "utf8"
BITLIBNAME  :: "bit32"
MATHLIBNAME :: "math"
DBLIBNAME   :: "debug"
LOADLIBNAME :: "package"

@(link_prefix="lua")
@(default_calling_convention="c")
foreign lib {
	open_base      :: proc(L: ^State) -> c.int ---
	open_coroutine :: proc(L: ^State) -> c.int ---
	open_table     :: proc(L: ^State) -> c.int ---
	open_io        :: proc(L: ^State) -> c.int ---
	open_os        :: proc(L: ^State) -> c.int ---
	open_string    :: proc(L: ^State) -> c.int ---
	open_utf8      :: proc(L: ^State) -> c.int ---
	open_bit32     :: proc(L: ^State) -> c.int ---
	open_math      :: proc(L: ^State) -> c.int ---
	open_debug     :: proc(L: ^State) -> c.int ---
	open_package   :: proc(L: ^State) -> c.int ---

	/* open all previous libraries */

	L_openlibs :: proc(L: ^State) ---
}



GNAME :: "_G"

/* key, in the registry, for table of loaded modules */
LOADED_TABLE :: "_LOADED"


/* key, in the registry, for table of preloaded loaders */
PRELOAD_TABLE :: "_PRELOAD"

L_Reg :: struct {
	name: cstring,
  	func: CFunction,
}

L_NUMSIZES :: size_of(Integer)*16 + size_of(Number)


/* predefined references */
NOREF  :: -2
REFNIL :: -1


@(link_prefix="lua")
@(default_calling_convention="c")
foreign lib {
	@(link_name="luaL_checkversion_")
	L_checkversion :: proc(L: ^State, ver: Number = VERSION_NUM, sz: c.size_t = L_NUMSIZES) ---


	L_getmetafield :: proc(L: ^State, obj: c.int, e: cstring) -> c.int ---
	L_callmeta     :: proc(L: ^State, obj: c.int, e: cstring) -> c.int ---
	@(link_name="luaL_tolstring")
	L_tostring     :: proc(L: ^State, idx: c.int, len: ^c.size_t = nil) -> cstring ---
	L_argerror     :: proc(L: ^State, arg: c.int, extramsg: cstring) -> c.int ---
	@(link_name="luaL_checklstring")
	L_checkstring  :: proc(L: ^State, arg: c.int, l: ^c.size_t = nil) -> cstring ---
	@(link_name="luaL_optlstring")
	L_optstring    :: proc(L: ^State, arg: c.int, def: cstring, l: ^c.size_t = nil) -> cstring ---
	L_checknumber  :: proc(L: ^State, arg: c.int) -> Number ---
	L_optnumber    :: proc(L: ^State, arg: c.int, def: Number) -> Number ---

	L_checkinteger :: proc(L: ^State, arg: c.int) -> Integer ---
	L_optinteger   :: proc(L: ^State, arg: c.int, def: Integer) -> Integer ---

	L_checkstack :: proc(L: ^State, sz: c.int, msg: cstring) ---
	L_checktype  :: proc(L: ^State, arg: c.int, t: c.int) ---
	L_checkany   :: proc(L: ^State, arg: c.int) ---

	L_newmetatable :: proc(L: ^State, tname: cstring) -> c.int ---
	L_setmetatable :: proc(L: ^State, tname: cstring) ---
	L_testudata    :: proc(L: ^State, ud: c.int, tname: cstring) -> rawptr ---
	L_checkudata   :: proc(L: ^State, ud: c.int, tname: cstring) -> rawptr ---

	L_where :: proc(L: ^State, lvl: c.int) ---
	L_error :: proc(L: ^State, fmt: cstring, #c_vararg args: ..any) -> Status ---

	L_checkoption :: proc(L: ^State, arg: c.int, def: cstring, lst: [^]cstring) -> c.int ---

	L_fileresult :: proc(L: ^State, stat: c.int, fname: cstring) -> c.int ---
	L_execresult :: proc(L: ^State, stat: c.int) -> c.int ---


	L_ref   :: proc(L: ^State, t: c.int) -> c.int ---
	L_unref :: proc(L: ^State, t: c.int, ref: c.int) ---

	@(link_name="luaL_loadfilex")
	L_loadfile :: proc (L: ^State, filename: cstring, mode: cstring = nil) -> Status ---

	@(link_name="luaL_loadbufferx")
	L_loadbuffer :: proc(L: ^State, buff: [^]byte, sz: c.size_t, name: cstring, mode: cstring = nil) -> Status ---
	L_loadstring  :: proc(L: ^State, s: cstring) -> Status ---

	L_newstate :: proc() -> ^State ---

	L_len :: proc(L: ^State, idx: c.int) -> Integer ---

	L_gsub :: proc(L: ^State, s, p, r: cstring) -> cstring ---

	L_setfuncs :: proc(L: ^State, l: [^]L_Reg, nup: c.int) ---

	L_getsubtable :: proc(L: ^State, idx: c.int, fname: cstring) -> c.int ---

	L_traceback   :: proc(L: ^State, L1: ^State, msg: cstring, level: c.int) ---

	L_requiref    :: proc(L: ^State, modname: cstring, openf: CFunction, glb: c.int) ---

}
/*
** {======================================================
** Generic Buffer manipulation
** =======================================================
*/


L_Buffer :: struct {
	b:    [^]byte,  /* buffer address */
	size: c.size_t, /* buffer size */
	n:    c.size_t, /* number of characters in buffer */
	L:    ^State,
	initb: [L_BUFFERSIZE]byte,  /* initial buffer */
}

L_addchar :: #force_inline proc "c" (B: ^L_Buffer, c: byte) {
	if B.n < B.size {
		L_prepbuffsize(B, 1)
	}
	B.b[B.n] = c
	B.n += 1
}

L_addsize :: #force_inline proc "c" (B: ^L_Buffer, s: c.size_t) -> c.size_t {
	B.n += s
	return B.n
}

L_prepbuffer :: #force_inline proc "c" (B: ^L_Buffer) -> [^]byte {
	return L_prepbuffsize(B, c.size_t(L_BUFFERSIZE))
}


@(link_prefix="lua")
@(default_calling_convention="c")
foreign lib {
	L_buffinit       :: proc(L: ^State, B: ^L_Buffer) ---
	L_prepbuffsize   :: proc(B: ^L_Buffer, sz: c.size_t) -> [^]byte ---
	L_addlstring     :: proc(B: ^L_Buffer, s: cstring, l: c.size_t) ---
	L_addstring      :: proc(B: ^L_Buffer, s: cstring) ---
	L_addvalue       :: proc(B: ^L_Buffer) ---
	L_pushresult     :: proc(B: ^L_Buffer) ---
	L_pushresultsize :: proc(B: ^L_Buffer, sz: c.size_t) ---
	L_buffinitsize   :: proc(L: ^State, B: ^L_Buffer, sz: c.size_t) -> [^]byte ---
}


/* }====================================================== */




/*
** {==============================================================
** some useful macros
** ===============================================================
*/

getextraspace :: #force_inline proc "c" (L: ^State) -> rawptr {
	return rawptr(([^]byte)(L)[-EXTRASPACE:])
}
pop :: #force_inline proc "c" (L: ^State, n: c.int) {
	settop(L, -n-1)
}
newtable :: #force_inline proc "c" (L: ^State) {
	createtable(L, 0, 0)
}
register :: #force_inline proc "c" (L: ^State, n: cstring, f: CFunction) {
	pushcfunction(L, f)
	setglobal(L, n)
}

pushcfunction :: #force_inline proc "c" (L: ^State, f: CFunction) {
	pushcclosure(L, f, 0)
}


isfunction      :: #force_inline proc "c" (L: ^State, n: c.int) -> bool { return type(L, n) == .FUNCTION      }
istable         :: #force_inline proc "c" (L: ^State, n: c.int) -> bool { return type(L, n) == .TABLE         }
islightuserdata :: #force_inline proc "c" (L: ^State, n: c.int) -> bool { return type(L, n) == .LIGHTUSERDATA }
isnil           :: #force_inline proc "c" (L: ^State, n: c.int) -> bool { return type(L, n) == .NIL           }
isboolean       :: #force_inline proc "c" (L: ^State, n: c.int) -> bool { return type(L, n) == .BOOLEAN       }
isthread        :: #force_inline proc "c" (L: ^State, n: c.int) -> bool { return type(L, n) == .THREAD        }
isnone          :: #force_inline proc "c" (L: ^State, n: c.int) -> bool { return type(L, n) == .NONE          }
isnoneornil     :: #force_inline proc "c" (L: ^State, n: c.int) -> bool { return type(L, n) <= .NIL           }


pushliteral :: pushstring
pushglobaltable :: #force_inline proc "c" (L: ^State) {
	rawgeti(L, REGISTRYINDEX, RIDX_GLOBALS)
}
tostring :: #force_inline proc "c" (L: ^State, i: c.int) -> cstring {
	return tolstring(L, i, nil)
}
insert :: #force_inline proc "c" (L: ^State, idx: c.int) {
	rotate(L, idx, 1)
}
remove :: #force_inline proc "c" (L: ^State, idx: c.int) {
	rotate(L, idx, -1)
	pop(L, 1)
}
replace :: #force_inline proc "c" (L: ^State, idx: c.int) {
	copy(L, -1, idx)
	pop(L, 1)
}

L_newlibtable :: #force_inline proc "c" (L: ^State, l: []L_Reg) {
	createtable(L, 0, c.int(builtin.len(l) - 1))
}

L_newlib :: proc(L: ^State, l: []L_Reg) {
	L_checkversion(L)
	L_newlibtable(L, l)
	L_setfuncs(L, raw_data(l), 0)
}

L_argcheck :: #force_inline proc "c" (L: ^State, cond: bool, arg: c.int, extramsg: cstring) {
	if cond {
		L_argerror(L, arg, extramsg)
	}
}

L_typename :: #force_inline proc "c" (L: ^State, i: c.int) -> cstring {
	return typename(L, type(L, i))
}
L_dofile :: #force_inline proc "c" (L: ^State, s: cstring) -> c.int {
	err := L_loadfile(L, s)
	return pcall(L, 0, MULTRET, 0) if err == nil else c.int(err)
}
L_dostring :: #force_inline proc "c" (L: ^State, s: cstring) -> c.int {
	err := L_loadstring(L, s)
	return pcall(L, 0, MULTRET, 0) if err == nil else c.int(err)
}
L_getmetatable :: #force_inline proc "c" (L: ^State, n: cstring) -> c.int {
	return getfield(L, REGISTRYINDEX, n)
}
L_opt :: #force_inline proc "c" (L: ^State, f: $F, n: c.int, d: $T) -> T where intrinsics.type_is_proc(F) {
	return d if isnoneornil(L, n) else f(L, n)
}



/* }============================================================== */
