package sdl3

import "core:c"

Process :: struct {}

ProcessIO :: enum c.int {
	STDIO_INHERITED,    /**< The I/O stream is inherited from the application. */
	STDIO_NULL,         /**< The I/O stream is ignored. */
	STDIO_APP,          /**< The I/O stream is connected to a new SDL_IOStream that the application can read or write */
	STDIO_REDIRECT,     /**< The I/O stream is redirected to an existing SDL_IOStream. */
}

PROP_PROCESS_CREATE_ARGS_POINTER                :: "SDL.process.create.args"
PROP_PROCESS_CREATE_ENVIRONMENT_POINTER         :: "SDL.process.create.environment"
PROP_PROCESS_CREATE_STDIN_NUMBER                :: "SDL.process.create.stdin_option"
PROP_PROCESS_CREATE_STDIN_POINTER               :: "SDL.process.create.stdin_source"
PROP_PROCESS_CREATE_STDOUT_NUMBER               :: "SDL.process.create.stdout_option"
PROP_PROCESS_CREATE_STDOUT_POINTER              :: "SDL.process.create.stdout_source"
PROP_PROCESS_CREATE_STDERR_NUMBER               :: "SDL.process.create.stderr_option"
PROP_PROCESS_CREATE_STDERR_POINTER              :: "SDL.process.create.stderr_source"
PROP_PROCESS_CREATE_STDERR_TO_STDOUT_BOOLEAN    :: "SDL.process.create.stderr_to_stdout"
PROP_PROCESS_CREATE_BACKGROUND_BOOLEAN          :: "SDL.process.create.background"

PROP_PROCESS_PID_NUMBER         :: "SDL.process.pid"
PROP_PROCESS_STDIN_POINTER      :: "SDL.process.stdin"
PROP_PROCESS_STDOUT_POINTER     :: "SDL.process.stdout"
PROP_PROCESS_STDERR_POINTER     :: "SDL.process.stderr"
PROP_PROCESS_BACKGROUND_BOOLEAN :: "SDL.process.background"

@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	CreateProcess               :: proc(args: [^]cstring, pipe_stdio: bool) -> ^Process ---
	CreateProcessWithProperties :: proc(props: PropertiesID) -> ^Process ---
	GetProcessProperties        :: proc(process: ^Process) -> PropertiesID ---
	ReadProcess                 :: proc(process: ^Process, datasize: ^uint, exitcode: ^c.int) -> rawptr ---
	GetProcessInput             :: proc(process: ^Process) -> ^IOStream ---
	GetProcessOutput            :: proc(process: ^Process) -> ^IOStream ---
	KillProcess                 :: proc(process: ^Process, force: bool) -> bool ---
	WaitProcess                 :: proc(process: ^Process, block: bool, exitcode: ^c.int) -> bool ---
	DestroyProcess              :: proc(process: ^Process) ---
}