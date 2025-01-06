package lua_5_1

import "base:intrinsics"
import "base:builtin"

import c "core:c/libc"

#assert(size_of(c.int) == size_of(b32))

LUA_SHARED :: #config(LUA_SHARED, false)

when LUA_SHARED {
	when ODIN_OS == .Windows {
		// Does nothing special on windows
		foreign import lib "windows/lua5.1.dll.lib"
	} else when ODIN_OS == .Linux {
		foreign import lib "linux/liblua5.1.so"
	} else {
		foreign import lib "system:lua5.1"
	}
} else {
	when ODIN_OS == .Windows {
		foreign import lib "windows/lua5.1.dll.lib"
	} else when ODIN_OS == .Linux {
		foreign import lib "linux/liblua5.1.a"
	} else {
		foreign import lib "system:lua5.1"
	}
}

VERSION	        :: "Lua 5.1"
RELEASE	        :: "Lua 5.1.5"
VERSION_NUM	:: 501
COPYRIGHT	:: "Copyright (C) 1994-2012 Lua.org, PUC-Rio"
AUTHORS         :: "R. Ierusalimschy, L. H. de Figueiredo & W. Celes"

/* mark for precompiled code ('<esc>Lua') */
SIGNATURE :: "\x1bLua"

/* option for multiple returns in 'lua_pcall' and 'lua_call' */
MULTRET :: -1

REGISTRYINDEX :: -10000
ENVIRONINDEX  :: -10001
GLOBALSINDEX  :: -10002

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
	ERRFILE   = 6,
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


CompareOp :: enum c.int {
	EQ = 0,
	LT = 1,
	LE = 2,
}

OPEQ :: CompareOp.EQ
OPLT :: CompareOp.LT
OPLE :: CompareOp.LE


/* minimum Lua stack available to a C function */
MINSTACK :: 20


/* type of numbers in Lua */
Number :: distinct (f32 when size_of(uintptr) == 4 else f64)


/* type for integer functions */
Integer :: distinct (i32 when size_of(uintptr) == 4 else i64)


/*
** Type for C functions registered with Lua
*/
CFunction :: #type proc "c" (L: ^State) -> c.int



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
	STOP        = 0,
	RESTART     = 1,
	COLLECT     = 2,
	COUNT       = 3,
	COUNTB      = 4,
	STEP        = 5,
	SETPAUSE    = 6,
	SETSTEPMUL  = 7,
}
GCSTOP        :: GCWhat.STOP
GCRESTART     :: GCWhat.RESTART
GCCOLLECT     :: GCWhat.COLLECT
GCCOUNT       :: GCWhat.COUNT
GCCOUNTB      :: GCWhat.COUNTB
GCSTEP        :: GCWhat.STEP
GCSETPAUSE    :: GCWhat.SETPAUSE
GCSETSTEPMUL  :: GCWhat.SETSTEPMUL


/*
** Event codes
*/

HookEvent :: enum c.int {
	CALL     = 0,
	RET      = 1,
	LINE     = 2,
	COUNT    = 3,
	TAILRET  = 4,
}
HOOKCALL    :: HookEvent.CALL
HOOKRET     :: HookEvent.RET
HOOKLINE    :: HookEvent.LINE
HOOKCOUNT   :: HookEvent.COUNT
HOOKTAILRET :: HookEvent.TAILRET


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
	name:            cstring,              /* (n) */
	namewhat:        cstring,              /* (n) 'global', 'local', 'field', 'method' */
	what:            cstring,              /* (S) 'Lua', 'C', 'main', 'tail' */
	source:          cstring,              /* (S) */
	currentline:     c.int,                /* (l) */
	nups:            c.int,                /* (u) number of upvalues */
	linedefined:     c.int,                /* (S) */
	lastlinedefined: c.int,                /* (S) */
	short_src:       [IDSIZE]u8 `fmt:"s"`, /* (S) */
	/* private part */
	i_ci:            c.int,                /* active function */
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


	/*
	** basic stack manipulation
	*/

	gettop     :: proc (L: ^State) -> c.int ---
	settop     :: proc (L: ^State, idx: c.int) ---
	pushvalue  :: proc (L: ^State, idx: c.int) ---
	remove     :: proc (L: ^State, idx: c.int) ---
	insert     :: proc (L: ^State, idx: c.int) ---
	replace    :: proc (L: ^State, idx: c.int) ---
	checkstack :: proc (L: ^State, sz: c.int) -> c.int ---

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

	equal    :: proc(L: ^State, idx1, idx2: c.int) -> b32 ---
	rawequal :: proc(L: ^State, idx1, idx2: c.int) -> b32 ---
	lessthan :: proc(L: ^State, idx1, idx2: c.int) -> b32 ---

	toboolean   :: proc(L: ^State, idx: c.int) -> b32 ---
	tolstring   :: proc(L: ^State, idx: c.int, len: ^c.size_t) -> cstring ---
	objlen      :: proc(L: ^State, idx: c.int) -> c.size_t ---
	tocfunction :: proc(L: ^State, idx: c.int) -> CFunction ---
	touserdata  :: proc(L: ^State, idx: c.int) -> rawptr ---
	tothread    :: proc(L: ^State, idx: c.int) -> ^State ---
	topointer   :: proc(L: ^State, idx: c.int) -> rawptr ---

	/*
	** push functions (C -> stack)
	*/

	pushnil      :: proc(L: ^State) ---
	pushnumber   :: proc(L: ^State, n: Number) ---
	pushinteger  :: proc(L: ^State, n: Integer) ---
	pushlstring  :: proc(L: ^State, s: cstring, l: c.size_t) ---
	pushstring   :: proc(L: ^State, s: cstring) ---
	pushvfstring :: proc(L: ^State, fmt: cstring, argp: c.va_list) -> cstring ---
	pushfstring       :: proc(L: ^State, fmt: cstring, #c_vararg args: ..any) -> cstring ---
	pushcclosure      :: proc(L: ^State, fn: CFunction, n: c.int) ---
	pushboolean       :: proc(L: ^State, b: b32) ---
	pushlightuserdata :: proc(L: ^State, p: rawptr) ---
	pushthread        :: proc(L: ^State) -> Status ---

	/*
	** get functions (Lua -> stack)
	*/

	gettable  :: proc(L: ^State, idx: c.int) ---
	getfield  :: proc(L: ^State, idx: c.int, k: cstring) ---
	geti      :: proc(L: ^State, idx: c.int, n: Integer) ---
	rawget    :: proc(L: ^State, idx: c.int) ---
	rawgeti   :: proc(L: ^State, idx: c.int, n: Integer) ---
	rawgetp   :: proc(L: ^State, idx: c.int, p: rawptr) ---

	createtable  :: proc(L: ^State, narr, nrec: c.int) ---
	newuserdata  :: proc(L: ^State, sz: c.size_t) -> rawptr ---
	getmetatable :: proc(L: ^State, objindex: c.int) -> c.int ---
	getfenv      :: proc(L: ^State, idx: c.int) ---


	/*
	** set functions (stack -> Lua)
	*/

	settable     :: proc(L: ^State, idx: c.int) ---
	setfield     :: proc(L: ^State, idx: c.int, k: cstring) ---
	rawset       :: proc(L: ^State, idx: c.int) ---
	rawseti      :: proc(L: ^State, idx: c.int, n: c.int) ---
	rawsetp      :: proc(L: ^State, idx: c.int, p: rawptr) ---
	setmetatable :: proc(L: ^State, objindex: c.int) -> c.int ---
	setfenv      :: proc(L: ^State, idx: c.int) -> c.int ---


	/*
	** 'load' and 'call' functions (load and run Lua code)
	*/

	call :: proc(L: ^State, nargs, nresults: c.int) ---

	getctx :: proc(L: ^State, ctx: ^c.int) -> c.int ---

	pcall :: proc(L: ^State, nargs, nresults: c.int, errfunc: c.int) -> c.int ---
	cpcall :: proc(L: ^State, func: CFunction, ud: rawptr) -> c.int ---

	load :: proc(L: ^State, reader: Reader, dt: rawptr,
	             chunkname: cstring) -> Status ---

	dump :: proc(L: ^State, writer: Writer, data: rawptr) -> Status ---


	/*
	** coroutine functions
	*/

	yield       :: proc(L: ^State, nresults: c.int) -> Status ---
	resume      :: proc(L: ^State, narg: c.int) -> Status ---
	status      :: proc(L: ^State) -> Status ---


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

	sethook :: proc(L: ^State, func: Hook, mask: HookMask, count: c.int) -> c.int ---
	gethook :: proc(L: ^State) -> Hook ---
	gethookmask  :: proc(L: ^State) -> HookMask ---
	gethookcount :: proc(L: ^State) -> c.int ---

	/* }============================================================== */
}



COLIBNAME   :: "coroutine"
TABLIBNAME  :: "table"
IOLIBNAME   :: "io"
OSLIBNAME   :: "os"
STRLIBNAME  :: "string"
UTF8LIBNAME :: "utf8"
MATHLIBNAME :: "math"
DBLIBNAME   :: "debug"
LOADLIBNAME :: "package"

@(link_prefix="lua")
@(default_calling_convention="c")
foreign lib {
	open_base      :: proc(L: ^State) -> c.int ---
	open_table     :: proc(L: ^State) -> c.int ---
	open_io        :: proc(L: ^State) -> c.int ---
	open_os        :: proc(L: ^State) -> c.int ---
	open_string    :: proc(L: ^State) -> c.int ---
	open_utf8      :: proc(L: ^State) -> c.int ---
	open_math      :: proc(L: ^State) -> c.int ---
	open_debug     :: proc(L: ^State) -> c.int ---
	open_package   :: proc(L: ^State) -> c.int ---

	/* open all previous libraries */

	L_openlibs :: proc(L: ^State) ---
}



GNAME :: "_G"

L_Reg :: struct {
	name: cstring,
  	func: CFunction,
}

/* predefined references */
NOREF  :: -2
REFNIL :: -1

@(link_prefix="lua")
@(default_calling_convention="c")
foreign lib {
	L_openlib      :: proc(L: ^State, libname: cstring, l: [^]L_Reg, nup: c.int) ---
	L_register     :: proc(L: ^State, libname: cstring, l: ^L_Reg) ---
	L_getmetafield :: proc(L: ^State, obj: c.int, e: cstring) -> c.int ---
	L_callmeta     :: proc(L: ^State, obj: c.int, e: cstring) -> c.int ---
	L_typeerror    :: proc(L: ^State, narg: c.int, tname: cstring) -> c.int ---
	L_argerror     :: proc(L: ^State, numarg: c.int, extramsg: cstring) -> c.int ---
	@(link_name="luaL_checklstring")
	L_checkstring  :: proc(L: ^State, numArg: c.int, l: ^c.size_t = nil) -> cstring ---
	@(link_name="luaL_optlstring")
	L_optstring    :: proc(L: ^State, numArg: c.int, def: cstring, l: ^c.size_t = nil) -> cstring ---
	L_checknumber  :: proc(L: ^State, numArg: c.int) -> Number ---
	L_optnumber    :: proc(L: ^State, nArg: c.int, def: Number) -> Number ---

	L_checkinteger  :: proc(L: ^State, numArg: c.int) -> Integer ---
	L_optinteger    :: proc(L: ^State, nArg: c.int, def: Integer) -> Integer ---


	L_checkstack :: proc(L: ^State, sz: c.int, msg: cstring) ---
	L_checktype  :: proc(L: ^State, narg: c.int, t: c.int) ---
	L_checkany   :: proc(L: ^State, narg: c.int) ---

	L_newmetatable :: proc(L: ^State, tname: cstring) -> c.int ---
	L_checkudata   :: proc(L: ^State, ud: c.int, tname: cstring) -> rawptr ---

	L_where :: proc(L: ^State, lvl: c.int) ---
	L_error :: proc(L: ^State, fmt: cstring, #c_vararg args: ..any) -> Status ---

	L_checkoption :: proc(L: ^State, narg: c.int, def: cstring, lst: [^]cstring) -> c.int ---


	L_ref   :: proc(L: ^State, t: c.int) -> c.int ---
	L_unref :: proc(L: ^State, t: c.int, ref: c.int) ---

	L_loadfile :: proc (L: ^State, filename: cstring) -> Status ---

	L_loadbuffer :: proc(L: ^State, buff: [^]byte, sz: c.size_t, name: cstring) -> Status ---
	L_loadstring  :: proc(L: ^State, s: cstring) -> Status ---

	L_newstate :: proc() -> ^State ---

	L_gsub :: proc(L: ^State, s, p, r: cstring) -> cstring ---

	L_findtable :: proc(L: ^State, idx: c.int, fname: cstring, szhint: c.int) -> cstring ---
}
/*
** {======================================================
** Generic Buffer manipulation
** =======================================================
*/


L_Buffer :: struct {
	p:    [^]byte,  /* buffer address */
	lvl:  c.int,    /* number of strings in the stack (level) */
	L:    ^State,
	buffer: [L_BUFFERSIZE]byte,  /* initial buffer */
}

L_addchar :: #force_inline proc "c" (B: ^L_Buffer, c: byte) {
	end := ([^]byte)(&B.buffer)[L_BUFFERSIZE:]
	if B.p < end {
		L_prepbuffer(B)
	}
	B.p[0] = c
	B.p = B.p[1:]
}
L_putchar :: L_addchar

L_addsize :: #force_inline proc "c" (B: ^L_Buffer, s: c.size_t) -> [^]byte {
	B.p = B.p[s:]
	return B.p
}


@(link_prefix="lua")
@(default_calling_convention="c")
foreign lib {
	L_buffinit       :: proc(L: ^State, B: ^L_Buffer) ---
	L_prepbuffer     :: proc(B: ^L_Buffer) -> [^]byte ---
	L_addlstring     :: proc(B: ^L_Buffer, s: cstring, l: c.size_t) ---
	L_addstring      :: proc(B: ^L_Buffer, s: cstring) ---
	L_addvalue       :: proc(B: ^L_Buffer) ---
	L_pushresult     :: proc(B: ^L_Buffer) ---
	L_pushresultsize :: proc(B: ^L_Buffer, sz: c.size_t) ---
	L_buffinitsize   :: proc(L: ^State, B: ^L_Buffer, sz: c.size_t) -> [^]byte ---
}

@(link_prefix="lua_")
@(default_calling_convention="c")
foreign lib {
	/* hack */
	setlevel :: proc(from, to: ^State) ---
}


/* }====================================================== */




/*
** {==============================================================
** some useful macros
** ===============================================================
*/

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

strlen :: #force_inline proc "c" (L: ^State, i: c.int) -> c.size_t {
	return objlen(L, i)
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
setglobal :: #force_inline proc "c" (L: ^State, s: cstring) {
	setfield(L, GLOBALSINDEX, s)
}
getglobal :: #force_inline proc "c" (L: ^State, s: cstring) {
	getfield(L, GLOBALSINDEX, s)
}
tostring :: #force_inline proc "c" (L: ^State, i: c.int) -> cstring {
	return tolstring(L, i, nil)
}

open :: newstate
getregistry :: #force_inline proc "c" (L: ^State) {
	pushvalue(L, REGISTRYINDEX)
}

getgccount :: #force_inline proc "c" (L: ^State) -> c.int {
	return gc(L, .COUNT, 0)
}

Chunkreader :: Reader
Chunkwriter :: Writer


L_argcheck :: #force_inline proc "c" (L: ^State, cond: bool, numarg: c.int, extramsg: cstring) {
	if cond {
		L_argerror(L, numarg, extramsg)
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
L_getmetatable :: #force_inline proc "c" (L: ^State, n: cstring) {
	getfield(L, REGISTRYINDEX, n)
}
L_opt :: #force_inline proc "c" (L: ^State, f: $F, n: c.int, d: $T) -> T where intrinsics.type_is_proc(F) {
	return d if isnoneornil(L, n) else f(L, n)
}



ref :: #force_inline proc "c" (L: ^State, lock: bool) -> c.int {
	if lock {
		return L_ref(L, REGISTRYINDEX)
	}
	pushstring(L, "unlocked references are obsolete")
	error(L)
	return 0
}
unref :: #force_inline proc "c" (L: ^State, ref: c.int) {
	L_unref(L,REGISTRYINDEX, ref)
}
getref :: #force_inline proc "c" (L: ^State, ref: Integer) {
	rawgeti(L, REGISTRYINDEX, ref)
}


/* }============================================================== */
