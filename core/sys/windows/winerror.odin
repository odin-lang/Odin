// +build windows
package sys_windows

ERROR_SUCCESS : DWORD : 0
NO_ERROR :: 0
SEC_E_OK : HRESULT : 0x00000000

ERROR_INVALID_FUNCTION       : DWORD : 1
ERROR_FILE_NOT_FOUND         : DWORD : 2
ERROR_PATH_NOT_FOUND         : DWORD : 3
ERROR_ACCESS_DENIED          : DWORD : 5
ERROR_INVALID_HANDLE         : DWORD : 6
ERROR_NOT_ENOUGH_MEMORY      : DWORD : 8
ERROR_INVALID_BLOCK          : DWORD : 9
ERROR_BAD_ENVIRONMENT        : DWORD : 10
ERROR_BAD_FORMAT             : DWORD : 11
ERROR_INVALID_ACCESS         : DWORD : 12
ERROR_INVALID_DATA           : DWORD : 13
ERROR_OUTOFMEMORY            : DWORD : 14
ERROR_INVALID_DRIVE          : DWORD : 15
ERROR_CURRENT_DIRECTORY      : DWORD : 16
ERROR_NO_MORE_FILES          : DWORD : 18
ERROR_SHARING_VIOLATION      : DWORD : 32
ERROR_LOCK_VIOLATION         : DWORD : 33
ERROR_HANDLE_EOF             : DWORD : 38
ERROR_NOT_SUPPORTED          : DWORD : 50
ERROR_FILE_EXISTS            : DWORD : 80
ERROR_INVALID_PARAMETER      : DWORD : 87
ERROR_BROKEN_PIPE            : DWORD : 109
ERROR_CALL_NOT_IMPLEMENTED   : DWORD : 120
ERROR_INSUFFICIENT_BUFFER    : DWORD : 122
ERROR_INVALID_NAME           : DWORD : 123
ERROR_BAD_ARGUMENTS          : DWORD : 160
ERROR_LOCK_FAILED            : DWORD : 167
ERROR_ALREADY_EXISTS         : DWORD : 183
ERROR_NO_DATA                : DWORD : 232
ERROR_ENVVAR_NOT_FOUND       : DWORD : 203
ERROR_OPERATION_ABORTED      : DWORD : 995
ERROR_IO_PENDING             : DWORD : 997
ERROR_NO_UNICODE_TRANSLATION : DWORD : 1113
ERROR_TIMEOUT                : DWORD : 1460
ERROR_DATATYPE_MISMATCH      : DWORD : 1629
ERROR_UNSUPPORTED_TYPE       : DWORD : 1630
ERROR_NOT_SAME_OBJECT        : DWORD : 1656
ERROR_PIPE_CONNECTED         : DWORD : 0x80070217
ERROR_PIPE_BUSY              : DWORD : 231

E_NOTIMPL :: HRESULT(-0x7fff_bfff) // 0x8000_4001

SUCCEEDED :: #force_inline proc "contextless" (#any_int result: int) -> bool { return result >= 0 }


System_Error :: enum DWORD {
	// The operation completed successfully.
	SUCCESS = 0x0,
	// Incorrect function.
	INVALID_FUNCTION = 0x1,
	// The system cannot find the file specified.
	FILE_NOT_FOUND = 0x2,
	// The system cannot find the path specified.
	PATH_NOT_FOUND = 0x3,
	// The system cannot open the file.
	TOO_MANY_OPEN_FILES = 0x4,
	// Access is denied.
	ACCESS_DENIED = 0x5,
	// The handle is invalid.
	INVALID_HANDLE = 0x6,
	// The storage control blocks were destroyed.
	ARENA_TRASHED = 0x7,
	// Not enough memory resources are available to process this command.
	NOT_ENOUGH_MEMORY = 0x8,
	// The storage control block address is invalid.
	INVALID_BLOCK = 0x9,
	// The environment is incorrect.
	BAD_ENVIRONMENT = 0xA,
	// An attempt was made to load a program with an incorrect format.
	BAD_FORMAT = 0xB,
	// The access code is invalid.
	INVALID_ACCESS = 0xC,
	// The data is invalid.
	INVALID_DATA = 0xD,
	// Not enough storage is available to complete this operation.
	OUTOFMEMORY = 0xE,
	// The system cannot find the drive specified.
	INVALID_DRIVE = 0xF,
	// The directory cannot be removed.
	CURRENT_DIRECTORY = 0x10,
	// The system cannot move the file to a different disk drive.
	NOT_SAME_DEVICE = 0x11,
	// There are no more files.
	NO_MORE_FILES = 0x12,
	// The media is write protected.
	WRITE_PROTECT = 0x13,
	// The system cannot find the device specified.
	BAD_UNIT = 0x14,
	// The device is not ready.
	NOT_READY = 0x15,
	// The device does not recognize the command.
	BAD_COMMAND = 0x16,
	// Data error cyclic redundancy check.
	CRC = 0x17,
	// The program issued a command but the command length is incorrect.
	BAD_LENGTH = 0x18,
	// The drive cannot locate a specific area or track on the disk.
	SEEK = 0x19,
	// The specified disk or diskette cannot be accessed.
	NOT_DOS_DISK = 0x1A,
	// The drive cannot find the sector requested.
	SECTOR_NOT_FOUND = 0x1B,
	// The printer is out of paper.
	OUT_OF_PAPER = 0x1C,
	// The system cannot write to the specified device.
	WRITE_FAULT = 0x1D,
	// The system cannot read from the specified device.
	READ_FAULT = 0x1E,
	// A device attached to the system is not functioning.
	GEN_FAILURE = 0x1F,
	// The process cannot access the file because it is being used by another process.
	SHARING_VIOLATION = 0x20,
	// The process cannot access the file because another process has locked a portion of the file.
	LOCK_VIOLATION = 0x21,
	// The wrong diskette is in the drive. Insert %2 Volume Serial Number: %3 into drive %1.
	WRONG_DISK = 0x22,
	// Too many files opened for sharing.
	SHARING_BUFFER_EXCEEDED = 0x24,
	// Reached the end of the file.
	HANDLE_EOF = 0x26,
	// The disk is full.
	HANDLE_DISK_FULL = 0x27,
	// The request is not supported.
	NOT_SUPPORTED = 0x32,
	// Windows cannot find the network path. Verify that the network path is correct and the destination computer is not busy or turned off. If Windows still cannot find the network path, contact your network administrator.
	REM_NOT_LIST = 0x33,
	// You were not connected because a duplicate name exists on the network. If joining a domain, go to System in Control Panel to change the computer name and try again. If joining a workgroup, choose another workgroup name.
	DUP_NAME = 0x34,
	// The network path was not found.
	BAD_NETPATH = 0x35,
	// The network is busy.
	NETWORK_BUSY = 0x36,
	// The specified network resource or device is no longer available.
	DEV_NOT_EXIST = 0x37,
	// The network BIOS command limit has been reached.
	TOO_MANY_CMDS = 0x38,
	// A network adapter hardware error occurred.
	ADAP_HDW_ERR = 0x39,
	// The specified server cannot perform the requested operation.
	BAD_NET_RESP = 0x3A,
	// An unexpected network error occurred.
	UNEXP_NET_ERR = 0x3B,
	// The remote adapter is not compatible.
	BAD_REM_ADAP = 0x3C,
	// The printer queue is full.
	PRINTQ_FULL = 0x3D,
	// Space to store the file waiting to be printed is not available on the server.
	NO_SPOOL_SPACE = 0x3E,
	// Your file waiting to be printed was deleted.
	PRINT_CANCELLED = 0x3F,
	// The specified network name is no longer available.
	NETNAME_DELETED = 0x40,
	// Network access is denied.
	NETWORK_ACCESS_DENIED = 0x41,
	// The network resource type is not correct.
	BAD_DEV_TYPE = 0x42,
	// The network name cannot be found.
	BAD_NET_NAME = 0x43,
	// The name limit for the local computer network adapter card was exceeded.
	TOO_MANY_NAMES = 0x44,
	// The network BIOS session limit was exceeded.
	TOO_MANY_SESS = 0x45,
	// The remote server has been paused or is in the process of being started.
	SHARING_PAUSED = 0x46,
	// No more connections can be made to this remote computer at this time because there are already as many connections as the computer can accept.
	REQ_NOT_ACCEP = 0x47,
	// The specified printer or disk device has been paused.
	REDIR_PAUSED = 0x48,
	// The file exists.
	FILE_EXISTS = 0x50,
	// The directory or file cannot be created.
	CANNOT_MAKE = 0x52,
	// Fail on INT 24.
	FAIL_I24 = 0x53,
	// Storage to process this request is not available.
	OUT_OF_STRUCTURES = 0x54,
	// The local device name is already in use.
	ALREADY_ASSIGNED = 0x55,
	// The specified network password is not correct.
	INVALID_PASSWORD = 0x56,
	// The parameter is incorrect.
	INVALID_PARAMETER = 0x57,
	// A write fault occurred on the network.
	NET_WRITE_FAULT = 0x58,
	// The system cannot start another process at this time.
	NO_PROC_SLOTS = 0x59,
	// Cannot create another system semaphore.
	TOO_MANY_SEMAPHORES = 0x64,
	// The exclusive semaphore is owned by another process.
	EXCL_SEM_ALREADY_OWNED = 0x65,
	// The semaphore is set and cannot be closed.
	SEM_IS_SET = 0x66,
	// The semaphore cannot be set again.
	TOO_MANY_SEM_REQUESTS = 0x67,
	// Cannot request exclusive semaphores at interrupt time.
	INVALID_AT_INTERRUPT_TIME = 0x68,
	// The previous ownership of this semaphore has ended.
	SEM_OWNER_DIED = 0x69,
	// Insert the diskette for drive %1.
	SEM_USER_LIMIT = 0x6A,
	// The program stopped because an alternate diskette was not inserted.
	DISK_CHANGE = 0x6B,
	// The disk is in use or locked by another process.
	DRIVE_LOCKED = 0x6C,
	// The pipe has been ended.
	BROKEN_PIPE = 0x6D,
	// The system cannot open the device or file specified.
	OPEN_FAILED = 0x6E,
	// The file name is too long.
	BUFFER_OVERFLOW = 0x6F,
	// There is not enough space on the disk.
	DISK_FULL = 0x70,
	// No more internal file identifiers available.
	NO_MORE_SEARCH_HANDLES = 0x71,
	// The target internal file identifier is incorrect.
	INVALID_TARGET_HANDLE = 0x72,
	// The IOCTL call made by the application program is not correct.
	INVALID_CATEGORY = 0x75,
	// The verify-on-write switch parameter value is not correct.
	INVALID_VERIFY_SWITCH = 0x76,
	// The system does not support the command requested.
	BAD_DRIVER_LEVEL = 0x77,
	// This function is not supported on this system.
	CALL_NOT_IMPLEMENTED = 0x78,
	// The semaphore timeout period has expired.
	SEM_TIMEOUT = 0x79,
	// The data area passed to a system call is too small.
	INSUFFICIENT_BUFFER = 0x7A,
	// The filename, directory name, or volume label syntax is incorrect.
	INVALID_NAME = 0x7B,
	// The system call level is not correct.
	INVALID_LEVEL = 0x7C,
	// The disk has no volume label.
	NO_VOLUME_LABEL = 0x7D,
	// The specified module could not be found.
	MOD_NOT_FOUND = 0x7E,
	// The specified procedure could not be found.
	PROC_NOT_FOUND = 0x7F,
	// There are no child processes to wait for.
	WAIT_NO_CHILDREN = 0x80,
	// The %1 application cannot be run in Win32 mode.
	CHILD_NOT_COMPLETE = 0x81,
	// Attempt to use a file handle to an open disk partition for an operation other than raw disk I/O.
	DIRECT_ACCESS_HANDLE = 0x82,
	// An attempt was made to move the file pointer before the beginning of the file.
	NEGATIVE_SEEK = 0x83,
	// The file pointer cannot be set on the specified device or file.
	SEEK_ON_DEVICE = 0x84,
	// A JOIN or SUBST command cannot be used for a drive that contains previously joined drives.
	IS_JOIN_TARGET = 0x85,
	// An attempt was made to use a JOIN or SUBST command on a drive that has already been joined.
	IS_JOINED = 0x86,
	// An attempt was made to use a JOIN or SUBST command on a drive that has already been substituted.
	IS_SUBSTED = 0x87,
	// The system tried to delete the JOIN of a drive that is not joined.
	NOT_JOINED = 0x88,
	// The system tried to delete the substitution of a drive that is not substituted.
	NOT_SUBSTED = 0x89,
	// The system tried to join a drive to a directory on a joined drive.
	JOIN_TO_JOIN = 0x8A,
	// The system tried to substitute a drive to a directory on a substituted drive.
	SUBST_TO_SUBST = 0x8B,
	// The system tried to join a drive to a directory on a substituted drive.
	JOIN_TO_SUBST = 0x8C,
	// The system tried to SUBST a drive to a directory on a joined drive.
	SUBST_TO_JOIN = 0x8D,
	// The system cannot perform a JOIN or SUBST at this time.
	BUSY_DRIVE = 0x8E,
	// The system cannot join or substitute a drive to or for a directory on the same drive.
	SAME_DRIVE = 0x8F,
	// The directory is not a subdirectory of the root directory.
	DIR_NOT_ROOT = 0x90,
	// The directory is not empty.
	DIR_NOT_EMPTY = 0x91,
	// The path specified is being used in a substitute.
	IS_SUBST_PATH = 0x92,
	// Not enough resources are available to process this command.
	IS_JOIN_PATH = 0x93,
	// The path specified cannot be used at this time.
	PATH_BUSY = 0x94,
	// An attempt was made to join or substitute a drive for which a directory on the drive is the target of a previous substitute.
	IS_SUBST_TARGET = 0x95,
	// System trace information was not specified in your CONFIG.SYS file, or tracing is disallowed.
	SYSTEM_TRACE = 0x96,
	// The number of specified semaphore events for DosMuxSemWait is not correct.
	INVALID_EVENT_COUNT = 0x97,
	// DosMuxSemWait did not execute; too many semaphores are already set.
	TOO_MANY_MUXWAITERS = 0x98,
	// The DosMuxSemWait list is not correct.
	INVALID_LIST_FORMAT = 0x99,
	// The volume label you entered exceeds the label character limit of the target file system.
	LABEL_TOO_LONG = 0x9A,
	// Cannot create another thread.
	TOO_MANY_TCBS = 0x9B,
	// The recipient process has refused the signal.
	SIGNAL_REFUSED = 0x9C,
	// The segment is already discarded and cannot be locked.
	DISCARDED = 0x9D,
	// The segment is already unlocked.
	NOT_LOCKED = 0x9E,
	// The address for the thread ID is not correct.
	BAD_THREADID_ADDR = 0x9F,
	// One or more arguments are not correct.
	BAD_ARGUMENTS = 0xA0,
	// The specified path is invalid.
	BAD_PATHNAME = 0xA1,
	// A signal is already pending.
	SIGNAL_PENDING = 0xA2,
	// No more threads can be created in the system.
	MAX_THRDS_REACHED = 0xA4,
	// Unable to lock a region of a file.
	LOCK_FAILED = 0xA7,
	// The requested resource is in use.
	BUSY = 0xAA,
	// Device's command support detection is in progress.
	DEVICE_SUPPORT_IN_PROGRESS = 0xAB,
	// A lock request was not outstanding for the supplied cancel region.
	CANCEL_VIOLATION = 0xAD,
	// The file system does not support atomic changes to the lock type.
	ATOMIC_LOCKS_NOT_SUPPORTED = 0xAE,
	// The system detected a segment number that was not correct.
	INVALID_SEGMENT_NUMBER = 0xB4,
	// The operating system cannot run %1.
	INVALID_ORDINAL = 0xB6,
	// Cannot create a file when that file already exists.
	ALREADY_EXISTS = 0xB7,
	// The flag passed is not correct.
	INVALID_FLAG_NUMBER = 0xBA,
	// The specified system semaphore name was not found.
	SEM_NOT_FOUND = 0xBB,
	// The operating system cannot run %1.
	INVALID_STARTING_CODESEG = 0xBC,
	// The operating system cannot run %1.
	INVALID_STACKSEG = 0xBD,
	// The operating system cannot run %1.
	INVALID_MODULETYPE = 0xBE,
	// Cannot run %1 in Win32 mode.
	INVALID_EXE_SIGNATURE = 0xBF,
	// The operating system cannot run %1.
	EXE_MARKED_INVALID = 0xC0,
	// %1 is not a valid Win32 application.
	BAD_EXE_FORMAT = 0xC1,
	// The operating system cannot run %1.
	ITERATED_DATA_EXCEEDS_64k = 0xC2,
	// The operating system cannot run %1.
	INVALID_MINALLOCSIZE = 0xC3,
	// The operating system cannot run this application program.
	DYNLINK_FROM_INVALID_RING = 0xC4,
	// The operating system is not presently configured to run this application.
	IOPL_NOT_ENABLED = 0xC5,
	// The operating system cannot run %1.
	INVALID_SEGDPL = 0xC6,
	// The operating system cannot run this application program.
	AUTODATASEG_EXCEEDS_64k = 0xC7,
	// The code segment cannot be greater than or equal to 64K.
	RING2SEG_MUST_BE_MOVABLE = 0xC8,
	// The operating system cannot run %1.
	RELOC_CHAIN_XEEDS_SEGLIM = 0xC9,
	// The operating system cannot run %1.
	INFLOOP_IN_RELOC_CHAIN = 0xCA,
	// The system could not find the environment option that was entered.
	ENVVAR_NOT_FOUND = 0xCB,
	// No process in the command subtree has a signal handler.
	NO_SIGNAL_SENT = 0xCD,
	// The filename or extension is too long.
	FILENAME_EXCED_RANGE = 0xCE,
	// The ring 2 stack is in use.
	RING2_STACK_IN_USE = 0xCF,
	// The global filename characters, * or ?, are entered incorrectly or too many global filename characters are specified.
	META_EXPANSION_TOO_LONG = 0xD0,
	// The signal being posted is not correct.
	INVALID_SIGNAL_NUMBER = 0xD1,
	// The signal handler cannot be set.
	THREAD_1_INACTIVE = 0xD2,
	// The segment is locked and cannot be reallocated.
	LOCKED = 0xD4,
	// Too many dynamic-link modules are attached to this program or dynamic-link module.
	TOO_MANY_MODULES = 0xD6,
	// Cannot nest calls to LoadModule.
	NESTING_NOT_ALLOWED = 0xD7,
	// This version of %1 is not compatible with the version of Windows you're running. Check your computer's system information and then contact the software publisher.
	EXE_MACHINE_TYPE_MISMATCH = 0xD8,
	// The image file %1 is signed, unable to modify.
	EXE_CANNOT_MODIFY_SIGNED_BINARY = 0xD9,
	// The image file %1 is strong signed, unable to modify.
	EXE_CANNOT_MODIFY_STRONG_SIGNED_BINARY = 0xDA,
	// This file is checked out or locked for editing by another user.
	FILE_CHECKED_OUT = 0xDC,
	// The file must be checked out before saving changes.
	CHECKOUT_REQUIRED = 0xDD,
	// The file type being saved or retrieved has been blocked.
	BAD_FILE_TYPE = 0xDE,
	// The file size exceeds the limit allowed and cannot be saved.
	FILE_TOO_LARGE = 0xDF,
	// Access Denied. Before opening files in this location, you must first add the web site to your trusted sites list, browse to the web site, and select the option to login automatically.
	FORMS_AUTH_REQUIRED = 0xE0,
	// Operation did not complete successfully because the file contains a virus or potentially unwanted software.
	VIRUS_INFECTED = 0xE1,
	// This file contains a virus or potentially unwanted software and cannot be opened. Due to the nature of this virus or potentially unwanted software, the file has been removed from this location.
	VIRUS_DELETED = 0xE2,
	// The pipe is local.
	PIPE_LOCAL = 0xE5,
	// The pipe state is invalid.
	BAD_PIPE = 0xE6,
	// All pipe instances are busy.
	PIPE_BUSY = 0xE7,
	// The pipe is being closed.
	NO_DATA = 0xE8,
	// No process is on the other end of the pipe.
	PIPE_NOT_CONNECTED = 0xE9,
	// More data is available.
	MORE_DATA = 0xEA,
	// The session was canceled.
	VC_DISCONNECTED = 0xF0,
	// The specified extended attribute name was invalid.
	INVALID_EA_NAME = 0xFE,
	// The extended attributes are inconsistent.
	EA_LIST_INCONSISTENT = 0xFF,
	// The wait operation timed out.
	WAIT_TIMEOUT = 0x102,
	// No more data is available.
	NO_MORE_ITEMS = 0x103,
	// The copy functions cannot be used.
	CANNOT_COPY = 0x10A,
	// The directory name is invalid.
	DIRECTORY = 0x10B,
	// The extended attributes did not fit in the buffer.
	EAS_DIDNT_FIT = 0x113,
	// The extended attribute file on the mounted file system is corrupt.
	EA_FILE_CORRUPT = 0x114,
	// The extended attribute table file is full.
	EA_TABLE_FULL = 0x115,
	// The specified extended attribute handle is invalid.
	INVALID_EA_HANDLE = 0x116,
	// The mounted file system does not support extended attributes.
	EAS_NOT_SUPPORTED = 0x11A,
	// Attempt to release mutex not owned by caller.
	NOT_OWNER = 0x120,
	// Too many posts were made to a semaphore.
	TOO_MANY_POSTS = 0x12A,
	// Only part of a ReadProcessMemory or WriteProcessMemory request was completed.
	PARTIAL_COPY = 0x12B,
	// The oplock request is denied.
	OPLOCK_NOT_GRANTED = 0x12C,
	// An invalid oplock acknowledgment was received by the system.
	INVALID_OPLOCK_PROTOCOL = 0x12D,
	// The volume is too fragmented to complete this operation.
	DISK_TOO_FRAGMENTED = 0x12E,
	// The file cannot be opened because it is in the process of being deleted.
	DELETE_PENDING = 0x12F,
	// Short name settings may not be changed on this volume due to the global registry setting.
	INCOMPATIBLE_WITH_GLOBAL_SHORT_NAME_REGISTRY_SETTING = 0x130,
	// Short names are not enabled on this volume.
	SHORT_NAMES_NOT_ENABLED_ON_VOLUME = 0x131,
	// The security stream for the given volume is in an inconsistent state. Please run CHKDSK on the volume.
	SECURITY_STREAM_IS_INCONSISTENT = 0x132,
	// A requested file lock operation cannot be processed due to an invalid byte range.
	INVALID_LOCK_RANGE = 0x133,
	// The subsystem needed to support the image type is not present.
	IMAGE_SUBSYSTEM_NOT_PRESENT = 0x134,
	// The specified file already has a notification GUID associated with it.
	NOTIFICATION_GUID_ALREADY_DEFINED = 0x135,
	// An invalid exception handler routine has been detected.
	INVALID_EXCEPTION_HANDLER = 0x136,
	// Duplicate privileges were specified for the token.
	DUPLICATE_PRIVILEGES = 0x137,
	// No ranges for the specified operation were able to be processed.
	NO_RANGES_PROCESSED = 0x138,
	// Operation is not allowed on a file system internal file.
	NOT_ALLOWED_ON_SYSTEM_FILE = 0x139,
	// The physical resources of this disk have been exhausted.
	DISK_RESOURCES_EXHAUSTED = 0x13A,
	// The token representing the data is invalid.
	INVALID_TOKEN = 0x13B,
	// The device does not support the command feature.
	DEVICE_FEATURE_NOT_SUPPORTED = 0x13C,
	// The system cannot find message text for message number 0x%1 in the message file for %2.
	MR_MID_NOT_FOUND = 0x13D,
	// The scope specified was not found.
	SCOPE_NOT_FOUND = 0x13E,
	// The Central Access Policy specified is not defined on the target machine.
	UNDEFINED_SCOPE = 0x13F,
	// The Central Access Policy obtained from Active Directory is invalid.
	INVALID_CAP = 0x140,
	// The device is unreachable.
	DEVICE_UNREACHABLE = 0x141,
	// The target device has insufficient resources to complete the operation.
	DEVICE_NO_RESOURCES = 0x142,
	// A data integrity checksum error occurred. Data in the file stream is corrupt.
	DATA_CHECKSUM_ERROR = 0x143,
	// An attempt was made to modify both a KERNEL and normal Extended Attribute EA in the same operation.
	INTERMIXED_KERNEL_EA_OPERATION = 0x144,
	// Device does not support file-level TRIM.
	FILE_LEVEL_TRIM_NOT_SUPPORTED = 0x146,
	// The command specified a data offset that does not align to the device's granularity/alignment.
	OFFSET_ALIGNMENT_VIOLATION = 0x147,
	// The command specified an invalid field in its parameter list.
	INVALID_FIELD_IN_PARAMETER_LIST = 0x148,
	// An operation is currently in progress with the device.
	OPERATION_IN_PROGRESS = 0x149,
	// An attempt was made to send down the command via an invalid path to the target device.
	BAD_DEVICE_PATH = 0x14A,
	// The command specified a number of descriptors that exceeded the maximum supported by the device.
	TOO_MANY_DESCRIPTORS = 0x14B,
	// Scrub is disabled on the specified file.
	SCRUB_DATA_DISABLED = 0x14C,
	// The storage device does not provide redundancy.
	NOT_REDUNDANT_STORAGE = 0x14D,
	// An operation is not supported on a resident file.
	RESIDENT_FILE_NOT_SUPPORTED = 0x14E,
	// An operation is not supported on a compressed file.
	COMPRESSED_FILE_NOT_SUPPORTED = 0x14F,
	// An operation is not supported on a directory.
	DIRECTORY_NOT_SUPPORTED = 0x150,
	// The specified copy of the requested data could not be read.
	NOT_READ_FROM_COPY = 0x151,
	// No action was taken as a system reboot is required.
	FAIL_NOACTION_REBOOT = 0x15E,
	// The shutdown operation failed.
	FAIL_SHUTDOWN = 0x15F,
	// The restart operation failed.
	FAIL_RESTART = 0x160,
	// The maximum number of sessions has been reached.
	MAX_SESSIONS_REACHED = 0x161,
	// The thread is already in background processing mode.
	THREAD_MODE_ALREADY_BACKGROUND = 0x190,
	// The thread is not in background processing mode.
	THREAD_MODE_NOT_BACKGROUND = 0x191,
	// The process is already in background processing mode.
	PROCESS_MODE_ALREADY_BACKGROUND = 0x192,
	// The process is not in background processing mode.
	PROCESS_MODE_NOT_BACKGROUND = 0x193,
	// Attempt to access invalid address.
	INVALID_ADDRESS = 0x1E7,

	// User profile cannot be loaded.
	USER_PROFILE_LOAD = 0x1F4,
	// Arithmetic result exceeded 32 bits.
	ARITHMETIC_OVERFLOW = 0x216,
	// There is a process on other end of the pipe.
	PIPE_CONNECTED = 0x217,
	// Waiting for a process to open the other end of the pipe.
	PIPE_LISTENING = 0x218,
	// Application verifier has found an error in the current process.
	VERIFIER_STOP = 0x219,
	// An error occurred in the ABIOS subsystem.
	ABIOS_ERROR = 0x21A,
	// A warning occurred in the WX86 subsystem.
	WX86_WARNING = 0x21B,
	// An error occurred in the WX86 subsystem.
	WX86_ERROR = 0x21C,
	// An attempt was made to cancel or set a timer that has an associated APC and the subject thread is not the thread that originally set the timer with an associated APC routine.
	TIMER_NOT_CANCELED = 0x21D,
	// Unwind exception code.
	UNWIND = 0x21E,
	// An invalid or unaligned stack was encountered during an unwind operation.
	BAD_STACK = 0x21F,
	// An invalid unwind target was encountered during an unwind operation.
	INVALID_UNWIND_TARGET = 0x220,
	// Invalid Object Attributes specified to NtCreatePort or invalid Port Attributes specified to NtConnectPort
	INVALID_PORT_ATTRIBUTES = 0x221,
	// Length of message passed to NtRequestPort or NtRequestWaitReplyPort was longer than the maximum message allowed by the port.
	PORT_MESSAGE_TOO_LONG = 0x222,
	// An attempt was made to lower a quota limit below the current usage.
	INVALID_QUOTA_LOWER = 0x223,
	// An attempt was made to attach to a device that was already attached to another device.
	DEVICE_ALREADY_ATTACHED = 0x224,
	// An attempt was made to execute an instruction at an unaligned address and the host system does not support unaligned instruction references.
	INSTRUCTION_MISALIGNMENT = 0x225,
	// Profiling not started.
	PROFILING_NOT_STARTED = 0x226,
	// Profiling not stopped.
	PROFILING_NOT_STOPPED = 0x227,
	// The passed ACL did not contain the minimum required information.
	COULD_NOT_INTERPRET = 0x228,
	// The number of active profiling objects is at the maximum and no more may be started.
	PROFILING_AT_LIMIT = 0x229,
	// Used to indicate that an operation cannot continue without blocking for I/O.
	CANT_WAIT = 0x22A,
	// Indicates that a thread attempted to terminate itself by default (called NtTerminateThread with NULL) and it was the last thread in the current process.
	CANT_TERMINATE_SELF = 0x22B,
	// If an MM error is returned which is not defined in the standard FsRtl filter, it is converted to one of the following errors which is guaranteed to be in the filter. In this case information is lost, however, the filter correctly handles the exception.
	UNEXPECTED_MM_CREATE_ERR = 0x22C,
	// If an MM error is returned which is not defined in the standard FsRtl filter, it is converted to one of the following errors which is guaranteed to be in the filter. In this case information is lost, however, the filter correctly handles the exception.
	UNEXPECTED_MM_MAP_ERROR = 0x22D,
	// If an MM error is returned which is not defined in the standard FsRtl filter, it is converted to one of the following errors which is guaranteed to be in the filter. In this case information is lost, however, the filter correctly handles the exception.
	UNEXPECTED_MM_EXTEND_ERR = 0x22E,
	// A malformed function table was encountered during an unwind operation.
	BAD_FUNCTION_TABLE = 0x22F,
	// Indicates that an attempt was made to assign protection to a file system file or directory and one of the SIDs in the security descriptor could not be translated into a GUID that could be stored by the file system. This causes the protection attempt to fail, which may cause a file creation attempt to fail.
	NO_GUID_TRANSLATION = 0x230,
	// Indicates that an attempt was made to grow an LDT by setting its size, or that the size was not an even number of selectors.
	INVALID_LDT_SIZE = 0x231,
	// Indicates that the starting value for the LDT information was not an integral multiple of the selector size.
	INVALID_LDT_OFFSET = 0x233,
	// Indicates that the user supplied an invalid descriptor when trying to set up Ldt descriptors.
	INVALID_LDT_DESCRIPTOR = 0x234,
	// Indicates a process has too many threads to perform the requested action. For example, assignment of a primary token may only be performed when a process has zero or one threads.
	TOO_MANY_THREADS = 0x235,
	// An attempt was made to operate on a thread within a specific process, but the thread specified is not in the process specified.
	THREAD_NOT_IN_PROCESS = 0x236,
	// Page file quota was exceeded.
	PAGEFILE_QUOTA_EXCEEDED = 0x237,
	// The Netlogon service cannot start because another Netlogon service running in the domain conflicts with the specified role.
	LOGON_SERVER_CONFLICT = 0x238,
	// The SAM database on a Windows Server is significantly out of synchronization with the copy on the Domain Controller. A complete synchronization is required.
	SYNCHRONIZATION_REQUIRED = 0x239,
	// The NtCreateFile API failed. This error should never be returned to an application, it is a place holder for the Windows Lan Manager Redirector to use in its internal error mapping routines.
	NET_OPEN_FAILED = 0x23A,
	// {Privilege Failed} The I/O permissions for the process could not be changed.
	IO_PRIVILEGE_FAILED = 0x23B,
	// {Application Exit by CTRL+C} The application terminated as a result of a CTRL+C.
	CONTROL_C_EXIT = 0x23C,
	// {Missing System File} The required system file %hs is bad or missing.
	MISSING_SYSTEMFILE = 0x23D,
	// {Application Error} The exception %s (0x%08lx) occurred in the application at location 0x%08lx.
	UNHANDLED_EXCEPTION = 0x23E,
	// {Application Error} The application was unable to start correctly (0x%lx). Click OK to close the application.
	APP_INIT_FAILURE = 0x23F,
	// {Unable to Create Paging File} The creation of the paging file %hs failed (%lx). The requested size was %ld.
	PAGEFILE_CREATE_FAILED = 0x240,
	// Windows cannot verify the digital signature for this file. A recent hardware or software change might have installed a file that is signed incorrectly or damaged, or that might be malicious software from an unknown source.
	INVALID_IMAGE_HASH = 0x241,
	// {No Paging File Specified} No paging file was specified in the system configuration.
	NO_PAGEFILE = 0x242,
	// {EXCEPTION} A real-mode application issued a floating-point instruction and floating-point hardware is not present.
	ILLEGAL_FLOAT_CONTEXT = 0x243,
	// An event pair synchronization operation was performed using the thread specific client/server event pair object, but no event pair object was associated with the thread.
	NO_EVENT_PAIR = 0x244,
	// A Windows Server has an incorrect configuration.
	DOMAIN_CTRLR_CONFIG_ERROR = 0x245,
	// An illegal character was encountered. For a multi-byte character set this includes a lead byte without a succeeding trail byte. For the Unicode character set this includes the characters 0xFFFF and 0xFFFE.
	ILLEGAL_CHARACTER = 0x246,
	// The Unicode character is not defined in the Unicode character set installed on the system.
	UNDEFINED_CHARACTER = 0x247,
	// The paging file cannot be created on a floppy diskette.
	FLOPPY_VOLUME = 0x248,
	// The system BIOS failed to connect a system interrupt to the device or bus for which the device is connected.
	BIOS_FAILED_TO_CONNECT_INTERRUPT = 0x249,
	// This operation is only allowed for the Primary Domain Controller of the domain.
	BACKUP_CONTROLLER = 0x24A,
	// An attempt was made to acquire a mutant such that its maximum count would have been exceeded.
	MUTANT_LIMIT_EXCEEDED = 0x24B,
	// A volume has been accessed for which a file system driver is required that has not yet been loaded.
	FS_DRIVER_REQUIRED = 0x24C,
	// {Registry File Failure} The registry cannot load the hive (file): %hs or its log or alternate. It is corrupt, absent, or not writable.
	CANNOT_LOAD_REGISTRY_FILE = 0x24D,
	// {Unexpected Failure in DebugActiveProcess} An unexpected failure occurred while processing a DebugActiveProcess API request. You may choose OK to terminate the process, or Cancel to ignore the error.
	DEBUG_ATTACH_FAILED = 0x24E,
	// {Fatal System Error} The %hs system process terminated unexpectedly with a status of 0x%08x (0x%08x 0x%08x). The system has been shut down.
	SYSTEM_PROCESS_TERMINATED = 0x24F,
	// {Data Not Accepted} The TDI client could not handle the data received during an indication.
	DATA_NOT_ACCEPTED = 0x250,
	// NTVDM encountered a hard error.
	VDM_HARD_ERROR = 0x251,
	// {Cancel Timeout} The driver %hs failed to complete a cancelled I/O request in the allotted time.
	DRIVER_CANCEL_TIMEOUT = 0x252,
	// {Reply Message Mismatch} An attempt was made to reply to an LPC message, but the thread specified by the client ID in the message was not waiting on that message.
	REPLY_MESSAGE_MISMATCH = 0x253,
	// {Delayed Write Failed} Windows was unable to save all the data for the file %hs. The data has been lost. This error may be caused by a failure of your computer hardware or network connection. Please try to save this file elsewhere.
	LOST_WRITEBEHIND_DATA = 0x254,
	// The parameter(s) passed to the server in the client/server shared memory window were invalid. Too much data may have been put in the shared memory window.
	CLIENT_SERVER_PARAMETERS_INVALID = 0x255,
	// The stream is not a tiny stream.
	NOT_TINY_STREAM = 0x256,
	// The request must be handled by the stack overflow code.
	STACK_OVERFLOW_READ = 0x257,
	// Internal OFS status codes indicating how an allocation operation is handled. Either it is retried after the containing onode is moved or the extent stream is converted to a large stream.
	CONVERT_TO_LARGE = 0x258,
	// The attempt to find the object found an object matching by ID on the volume but it is out of the scope of the handle used for the operation.
	FOUND_OUT_OF_SCOPE = 0x259,
	// The bucket array must be grown. Retry transaction after doing so.
	ALLOCATE_BUCKET = 0x25A,
	// The user/kernel marshalling buffer has overflowed.
	MARSHALL_OVERFLOW = 0x25B,
	// The supplied variant structure contains invalid data.
	INVALID_VARIANT = 0x25C,
	// The specified buffer contains ill-formed data.
	BAD_COMPRESSION_BUFFER = 0x25D,
	// {Audit Failed} An attempt to generate a security audit failed.
	AUDIT_FAILED = 0x25E,
	// The timer resolution was not previously set by the current process.
	TIMER_RESOLUTION_NOT_SET = 0x25F,
	// There is insufficient account information to log you on.
	INSUFFICIENT_LOGON_INFO = 0x260,
	// {Invalid DLL Entrypoint} The dynamic link library %hs is not written correctly. The stack pointer has been left in an inconsistent state. The entrypoint should be declared as WINAPI or STDCALL. Select YES to fail the DLL load. Select NO to continue execution. Selecting NO may cause the application to operate incorrectly.
	BAD_DLL_ENTRYPOINT = 0x261,
	// {Invalid Service Callback Entrypoint} The %hs service is not written correctly. The stack pointer has been left in an inconsistent state. The callback entrypoint should be declared as WINAPI or STDCALL. Selecting OK will cause the service to continue operation. However, the service process may operate incorrectly.
	BAD_SERVICE_ENTRYPOINT = 0x262,
	// There is an IP address conflict with another system on the network.
	IP_ADDRESS_CONFLICT1 = 0x263,
	// There is an IP address conflict with another system on the network.
	IP_ADDRESS_CONFLICT2 = 0x264,
	// {Low On Registry Space} The system has reached the maximum size allowed for the system part of the registry. Additional storage requests will be ignored.
	REGISTRY_QUOTA_LIMIT = 0x265,
	// A callback return system service cannot be executed when no callback is active.
	NO_CALLBACK_ACTIVE = 0x266,
	// The password provided is too short to meet the policy of your user account. Please choose a longer password.
	PWD_TOO_SHORT = 0x267,
	// The policy of your user account does not allow you to change passwords too frequently. This is done to prevent users from changing back to a familiar, but potentially discovered, password. If you feel your password has been compromised then please contact your administrator immediately to have a new one assigned.
	PWD_TOO_RECENT = 0x268,
	// You have attempted to change your password to one that you have used in the past. The policy of your user account does not allow this. Please select a password that you have not previously used.
	PWD_HISTORY_CONFLICT = 0x269,
	// The specified compression format is unsupported.
	UNSUPPORTED_COMPRESSION = 0x26A,
	// The specified hardware profile configuration is invalid.
	INVALID_HW_PROFILE = 0x26B,
	// The specified Plug and Play registry device path is invalid.
	INVALID_PLUGPLAY_DEVICE_PATH = 0x26C,
	// The specified quota list is internally inconsistent with its descriptor.
	QUOTA_LIST_INCONSISTENT = 0x26D,
	// {Windows Evaluation Notification} The evaluation period for this installation of Windows has expired. This system will shutdown in 1 hour. To restore access to this installation of Windows, please upgrade this installation using a licensed distribution of this product.
	EVALUATION_EXPIRATION = 0x26E,
	// {Illegal System DLL Relocation} The system DLL %hs was relocated in memory. The application will not run properly. The relocation occurred because the DLL %hs occupied an address range reserved for Windows system DLLs. The vendor supplying the DLL should be contacted for a new DLL.
	ILLEGAL_DLL_RELOCATION = 0x26F,
	// {DLL Initialization Failed} The application failed to initialize because the window station is shutting down.
	DLL_INIT_FAILED_LOGOFF = 0x270,
	// The validation process needs to continue on to the next step.
	VALIDATE_CONTINUE = 0x271,
	// There are no more matches for the current index enumeration.
	NO_MORE_MATCHES = 0x272,
	// The range could not be added to the range list because of a conflict.
	RANGE_LIST_CONFLICT = 0x273,
	// The server process is running under a SID different than that required by client.
	SERVER_SID_MISMATCH = 0x274,
	// A group marked use for deny only cannot be enabled.
	CANT_ENABLE_DENY_ONLY = 0x275,
	// {EXCEPTION} Multiple floating point faults.
	FLOAT_MULTIPLE_FAULTS = 0x276,
	// {EXCEPTION} Multiple floating point traps.
	FLOAT_MULTIPLE_TRAPS = 0x277,
	// The requested interface is not supported.
	NOINTERFACE = 0x278,
	// {System Standby Failed} The driver %hs does not support standby mode. Updating this driver may allow the system to go to standby mode.
	DRIVER_FAILED_SLEEP = 0x279,
	// The system file %1 has become corrupt and has been replaced.
	CORRUPT_SYSTEM_FILE = 0x27A,
	// {Virtual Memory Minimum Too Low} Your system is low on virtual memory. Windows is increasing the size of your virtual memory paging file. During this process, memory requests for some applications may be denied. For more information, see Help.
	COMMITMENT_MINIMUM = 0x27B,
	// A device was removed so enumeration must be restarted.
	PNP_RESTART_ENUMERATION = 0x27C,
	// {Fatal System Error} The system image %s is not properly signed. The file has been replaced with the signed file. The system has been shut down.
	SYSTEM_IMAGE_BAD_SIGNATURE = 0x27D,
	// Device will not start without a reboot.
	PNP_REBOOT_REQUIRED = 0x27E,
	// There is not enough power to complete the requested operation.
	INSUFFICIENT_POWER = 0x27F,
	// MULTIPLE_FAULT_VIOLATION = , = 0x281,
	MULTIPLE_FAULT_VIOLATION = 0x280, // The system is in the process of shutting down.
 // An attempt to remove a processes DebugPort was made, but a port was not already associated with the process.
	PORT_NOT_SET = 0x282,
	// This version of Windows is not compatible with the behavior version of directory forest, domain or domain controller.
	DS_VERSION_CHECK_FAILURE = 0x283,
	// The specified range could not be found in the range list.
	RANGE_NOT_FOUND = 0x284,
	// The driver was not loaded because the system is booting into safe mode.
	NOT_SAFE_MODE_DRIVER = 0x286,
	// The driver was not loaded because it failed its initialization call.
	FAILED_DRIVER_ENTRY = 0x287,
	// The "%hs" encountered an error while applying power or reading the device configuration. This may be caused by a failure of your hardware or by a poor connection.
	DEVICE_ENUMERATION_ERROR = 0x288,
	// The create operation failed because the name contained at least one mount point which resolves to a volume to which the specified device object is not attached.
	MOUNT_POINT_NOT_RESOLVED = 0x289,
	// The device object parameter is either not a valid device object or is not attached to the volume specified by the file name.
	INVALID_DEVICE_OBJECT_PARAMETER = 0x28A,
	// A Machine Check Error has occurred. Please check the system eventlog for additional information.
	MCA_OCCURED = 0x28B,
	// There was error [%2] processing the driver database.
	DRIVER_DATABASE_ERROR = 0x28C,
	// System hive size has exceeded its limit.
	SYSTEM_HIVE_TOO_LARGE = 0x28D,
	// The driver could not be loaded because a previous version of the driver is still in memory.
	DRIVER_FAILED_PRIOR_UNLOAD = 0x28E,
	// {Volume Shadow Copy Service} Please wait while the Volume Shadow Copy Service prepares volume %hs for hibernation.
	VOLSNAP_PREPARE_HIBERNATE = 0x28F,
	// The system has failed to hibernate (The error code is %hs). Hibernation will be disabled until the system is restarted.
	HIBERNATION_FAILURE = 0x290,
	// The password provided is too long to meet the policy of your user account. Please choose a shorter password.
	PWD_TOO_LONG = 0x291,
	// The requested operation could not be completed due to a file system limitation.
	FILE_SYSTEM_LIMITATION = 0x299,
	// An assertion failure has occurred.
	ASSERTION_FAILURE = 0x29C,
	// An error occurred in the ACPI subsystem.
	ACPI_ERROR = 0x29D,
	// WOW Assertion Error.
	WOW_ASSERTION = 0x29E,
	// A device is missing in the system BIOS MPS table. This device will not be used. Please contact your system vendor for system BIOS update.
	PNP_BAD_MPS_TABLE = 0x29F,
	// A translator failed to translate resources.
	PNP_TRANSLATION_FAILED = 0x2A0,
	// A IRQ translator failed to translate resources.
	PNP_IRQ_TRANSLATION_FAILED = 0x2A1,
	// Driver %2 returned invalid ID for a child device (%3).
	PNP_INVALID_ID = 0x2A2,
	// {Kernel Debugger Awakened} the system debugger was awakened by an interrupt.
	WAKE_SYSTEM_DEBUGGER = 0x2A3,
	// {Handles Closed} Handles to objects have been automatically closed as a result of the requested operation.
	HANDLES_CLOSED = 0x2A4,
	// {Too Much Information} The specified access control list (ACL) contained more information than was expected.
	EXTRANEOUS_INFORMATION = 0x2A5,
	// This warning level status indicates that the transaction state already exists for the registry sub-tree, but that a transaction commit was previously aborted. The commit has NOT been completed, but has not been rolled back either (so it may still be committed if desired).
	RXACT_COMMIT_NECESSARY = 0x2A6,
	// {Media Changed} The media may have changed.
	MEDIA_CHECK = 0x2A7,
	// {GUID Substitution} During the translation of a global identifier (GUID) to a Windows security ID SID, no administratively-defined GUID prefix was found. A substitute prefix was used, which will not compromise system security. However, this may provide a more restrictive access than intended.
	GUID_SUBSTITUTION_MADE = 0x2A8,
	// The create operation stopped after reaching a symbolic link.
	STOPPED_ON_SYMLINK = 0x2A9,
	// A long jump has been executed.
	LONGJUMP = 0x2AA,
	// The Plug and Play query operation was not successful.
	PLUGPLAY_QUERY_VETOED = 0x2AB,
	// A frame consolidation has been executed.
	UNWIND_CONSOLIDATE = 0x2AC,
	// {Registry Hive Recovered} Registry hive (file): %hs was corrupted and it has been recovered. Some data might have been lost.
	REGISTRY_HIVE_RECOVERED = 0x2AD,
	// The application is attempting to run executable code from the module %hs. This may be insecure. An alternative, %hs, is available. Should the application use the secure module %hs?
	DLL_MIGHT_BE_INSECURE = 0x2AE,
	// The application is loading executable code from the module %hs. This is secure, but may be incompatible with previous releases of the operating system. An alternative, %hs, is available. Should the application use the secure module %hs?
	DLL_MIGHT_BE_INCOMPATIBLE = 0x2AF,
	// Debugger did not handle the exception.
	DBG_EXCEPTION_NOT_HANDLED = 0x2B0,
	// Debugger will reply later.
	DBG_REPLY_LATER = 0x2B1,
	// Debugger cannot provide handle.
	DBG_UNABLE_TO_PROVIDE_HANDLE = 0x2B2,
	// Debugger terminated thread.
	DBG_TERMINATE_THREAD = 0x2B3,
	// Debugger terminated process.
	DBG_TERMINATE_PROCESS = 0x2B4,
	// Debugger got control C.
	DBG_CONTROL_C = 0x2B5,
	// Debugger printed exception on control C.
	DBG_PRINTEXCEPTION_C = 0x2B6,
	// Debugger received RIP exception.
	DBG_RIPEXCEPTION = 0x2B7,
	// Debugger received control break.
	DBG_CONTROL_BREAK = 0x2B8,
	// Debugger command communication exception.
	DBG_COMMAND_EXCEPTION = 0x2B9,
	// {Object Exists} An attempt was made to create an object and the object name already existed.
	OBJECT_NAME_EXISTS = 0x2BA,
	// {Thread Suspended} A thread termination occurred while the thread was suspended. The thread was resumed, and termination proceeded.
	THREAD_WAS_SUSPENDED = 0x2BB,
	// {Image Relocated} An image file could not be mapped at the address specified in the image file. Local fixups must be performed on this image.
	IMAGE_NOT_AT_BASE = 0x2BC,
	// This informational level status indicates that a specified registry sub-tree transaction state did not yet exist and had to be created.
	RXACT_STATE_CREATED = 0x2BD,
	// {Segment Load} A virtual DOS machine (VDM) is loading, unloading, or moving an MS-DOS or Win16 program segment image. An exception is raised so a debugger can load, unload or track symbols and breakpoints within these 16-bit segments.
	SEGMENT_NOTIFICATION = 0x2BE,
	// {Invalid Current Directory} The process cannot switch to the startup current directory %hs. Select OK to set current directory to %hs, or select CANCEL to exit.
	BAD_CURRENT_DIRECTORY = 0x2BF,
	// {Redundant Read} To satisfy a read request, the NT fault-tolerant file system successfully read the requested data from a redundant copy. This was done because the file system encountered a failure on a member of the fault-tolerant volume, but was unable to reassign the failing area of the device.
	FT_READ_RECOVERY_FROM_BACKUP = 0x2C0,
	// {Redundant Write} To satisfy a write request, the NT fault-tolerant file system successfully wrote a redundant copy of the information. This was done because the file system encountered a failure on a member of the fault-tolerant volume, but was not able to reassign the failing area of the device.
	FT_WRITE_RECOVERY = 0x2C1,
	// {Machine Type Mismatch} The image file %hs is valid, but is for a machine type other than the current machine. Select OK to continue, or CANCEL to fail the DLL load.
	IMAGE_MACHINE_TYPE_MISMATCH = 0x2C2,
	// {Partial Data Received} The network transport returned partial data to its client. The remaining data will be sent later.
	RECEIVE_PARTIAL = 0x2C3,
	// {Expedited Data Received} The network transport returned data to its client that was marked as expedited by the remote system.
	RECEIVE_EXPEDITED = 0x2C4,
	// {Partial Expedited Data Received} The network transport returned partial data to its client and this data was marked as expedited by the remote system. The remaining data will be sent later.
	RECEIVE_PARTIAL_EXPEDITED = 0x2C5,
	// {TDI Event Done} The TDI indication has completed successfully.
	EVENT_DONE = 0x2C6,
	// {TDI Event Pending} The TDI indication has entered the pending state.
	EVENT_PENDING = 0x2C7,
	// Checking file system on %wZ.
	CHECKING_FILE_SYSTEM = 0x2C8,
	// {Fatal Application Exit} %hs.
	FATAL_APP_EXIT = 0x2C9,
	// The specified registry key is referenced by a predefined handle.
	PREDEFINED_HANDLE = 0x2CA,
	// {Page Unlocked} The page protection of a locked page was changed to 'No Access' and the page was unlocked from memory and from the process.
	WAS_UNLOCKED = 0x2CB,
	// %hs
	SERVICE_NOTIFICATION = 0x2CC,
	// {Page Locked} One of the pages to lock was already locked.
	WAS_LOCKED = 0x2CD,
	// Application popup: %1 : %2
	LOG_HARD_ERROR = 0x2CE,
	// ALREADY_WIN32 = , = 0x2D0,
	ALREADY_WIN32 = 0x2CF, // {Machine Type Mismatch} The image file %hs is valid, but is for a machine type other than the current machine.
 // A yield execution was performed and no thread was available to run.
	NO_YIELD_PERFORMED = 0x2D1,
	// The resumable flag to a timer API was ignored.
	TIMER_RESUME_IGNORED = 0x2D2,
	// The arbiter has deferred arbitration of these resources to its parent.
	ARBITRATION_UNHANDLED = 0x2D3,
	// The inserted CardBus device cannot be started because of a configuration error on "%hs".
	CARDBUS_NOT_SUPPORTED = 0x2D4,
	// The CPUs in this multiprocessor system are not all the same revision level. To use all processors the operating system restricts itself to the features of the least capable processor in the system. Should problems occur with this system, contact the CPU manufacturer to see if this mix of processors is supported.
	MP_PROCESSOR_MISMATCH = 0x2D5,
	// The system was put into hibernation.
	HIBERNATED = 0x2D6,
	// The system was resumed from hibernation.
	RESUME_HIBERNATION = 0x2D7,
	// Windows has detected that the system firmware (BIOS) was updated [previous firmware date = %2, current firmware date %3].
	FIRMWARE_UPDATED = 0x2D8,
	// A device driver is leaking locked I/O pages causing system degradation. The system has automatically enabled tracking code in order to try and catch the culprit.
	DRIVERS_LEAKING_LOCKED_PAGES = 0x2D9,
	// The system has awoken.
	WAKE_SYSTEM = 0x2DA,
	// WAIT_1 = , = 0x2DC,
	WAIT_1 = 0x2DB, // WAIT_2 = , = 0x2DD, // WAIT_3 = , = 0x2DE, // WAIT_63 = , = 0x2DF, // ABANDONED_WAIT_0 = , = 0x2E0, // ABANDONED_WAIT_63 = , = 0x2E1, // USER_APC = , = 0x2E2, // KERNEL_APC = , = 0x2E3, // ALERTED = , = 0x2E4, // The requested operation requires elevation.
 // A reparse should be performed by the Object Manager since the name of the file resulted in a symbolic link.
	REPARSE = 0x2E5,
	// An open/create operation completed while an oplock break is underway.
	OPLOCK_BREAK_IN_PROGRESS = 0x2E6,
	// A new volume has been mounted by a file system.
	VOLUME_MOUNTED = 0x2E7,
	// This success level status indicates that the transaction state already exists for the registry sub-tree, but that a transaction commit was previously aborted. The commit has now been completed.
	RXACT_COMMITTED = 0x2E8,
	// This indicates that a notify change request has been completed due to closing the handle which made the notify change request.
	NOTIFY_CLEANUP = 0x2E9,
	// {Connect Failure on Primary Transport} An attempt was made to connect to the remote server %hs on the primary transport, but the connection failed. The computer WAS able to connect on a secondary transport.
	PRIMARY_TRANSPORT_CONNECT_FAILED = 0x2EA,
	// Page fault was a transition fault.
	PAGE_FAULT_TRANSITION = 0x2EB,
	// Page fault was a demand zero fault.
	PAGE_FAULT_DEMAND_ZERO = 0x2EC,
	// Page fault was a demand zero fault.
	PAGE_FAULT_COPY_ON_WRITE = 0x2ED,
	// Page fault was a demand zero fault.
	PAGE_FAULT_GUARD_PAGE = 0x2EE,
	// Page fault was satisfied by reading from a secondary storage device.
	PAGE_FAULT_PAGING_FILE = 0x2EF,
	// Cached page was locked during operation.
	CACHE_PAGE_LOCKED = 0x2F0,
	// Crash dump exists in paging file.
	CRASH_DUMP = 0x2F1,
	// Specified buffer contains all zeros.
	BUFFER_ALL_ZEROS = 0x2F2,
	// A reparse should be performed by the Object Manager since the name of the file resulted in a symbolic link.
	REPARSE_OBJECT = 0x2F3,
	// The device has succeeded a query-stop and its resource requirements have changed.
	RESOURCE_REQUIREMENTS_CHANGED = 0x2F4,
	// The translator has translated these resources into the global space and no further translations should be performed.
	TRANSLATION_COMPLETE = 0x2F5,
	// A process being terminated has no threads to terminate.
	NOTHING_TO_TERMINATE = 0x2F6,
	// The specified process is not part of a job.
	PROCESS_NOT_IN_JOB = 0x2F7,
	// The specified process is part of a job.
	PROCESS_IN_JOB = 0x2F8,
	// {Volume Shadow Copy Service} The system is now ready for hibernation.
	VOLSNAP_HIBERNATE_READY = 0x2F9,
	// A file system or file system filter driver has successfully completed an FsFilter operation.
	FSFILTER_OP_COMPLETED_SUCCESSFULLY = 0x2FA,
	// The specified interrupt vector was already connected.
	INTERRUPT_VECTOR_ALREADY_CONNECTED = 0x2FB,
	// The specified interrupt vector is still connected.
	INTERRUPT_STILL_CONNECTED = 0x2FC,
	// An operation is blocked waiting for an oplock.
	WAIT_FOR_OPLOCK = 0x2FD,
	// Debugger handled exception.
	DBG_EXCEPTION_HANDLED = 0x2FE,
	// Debugger continued.
	DBG_CONTINUE = 0x2FF,
	// An exception occurred in a user mode callback and the kernel callback frame should be removed.
	CALLBACK_POP_STACK = 0x300,
	// Compression is disabled for this volume.
	COMPRESSION_DISABLED = 0x301,
	// The data provider cannot fetch backwards through a result set.
	CANTFETCHBACKWARDS = 0x302,
	// The data provider cannot scroll backwards through a result set.
	CANTSCROLLBACKWARDS = 0x303,
	// The data provider requires that previously fetched data is released before asking for more data.
	ROWSNOTRELEASED = 0x304,
	// The data provider was not able to interpret the flags set for a column binding in an accessor.
	BAD_ACCESSOR_FLAGS = 0x305,
	// One or more errors occurred while processing the request.
	ERRORS_ENCOUNTERED = 0x306,
	// The implementation is not capable of performing the request.
	NOT_CAPABLE = 0x307,
	// The client of a component requested an operation which is not valid given the state of the component instance.
	REQUEST_OUT_OF_SEQUENCE = 0x308,
	// A version number could not be parsed.
	VERSION_PARSE_ERROR = 0x309,
	// The iterator's start position is invalid.
	BADSTARTPOSITION = 0x30A,
	// The hardware has reported an uncorrectable memory error.
	MEMORY_HARDWARE = 0x30B,
	// The attempted operation required self healing to be enabled.
	DISK_REPAIR_DISABLED = 0x30C,
	// The Desktop heap encountered an error while allocating session memory. There is more information in the system event log.
	INSUFFICIENT_RESOURCE_FOR_SPECIFIED_SHARED_SECTION_SIZE = 0x30D,
	// The system power state is transitioning from %2 to %3.
	SYSTEM_POWERSTATE_TRANSITION = 0x30E,
	// The system power state is transitioning from %2 to %3 but could enter %4.
	SYSTEM_POWERSTATE_COMPLEX_TRANSITION = 0x30F,
	// A thread is getting dispatched with MCA EXCEPTION because of MCA.
	MCA_EXCEPTION = 0x310,
	// Access to %1 is monitored by policy rule %2.
	ACCESS_AUDIT_BY_POLICY = 0x311,
	// Access to %1 has been restricted by your Administrator by policy rule %2.
	ACCESS_DISABLED_NO_SAFER_UI_BY_POLICY = 0x312,
	// A valid hibernation file has been invalidated and should be abandoned.
	ABANDON_HIBERFILE = 0x313,
	// {Delayed Write Failed} Windows was unable to save all the data for the file %hs; the data has been lost. This error may be caused by network connectivity issues. Please try to save this file elsewhere.
	LOST_WRITEBEHIND_DATA_NETWORK_DISCONNECTED = 0x314,
	// {Delayed Write Failed} Windows was unable to save all the data for the file %hs; the data has been lost. This error was returned by the server on which the file exists. Please try to save this file elsewhere.
	LOST_WRITEBEHIND_DATA_NETWORK_SERVER_ERROR = 0x315,
	// {Delayed Write Failed} Windows was unable to save all the data for the file %hs; the data has been lost. This error may be caused if the device has been removed or the media is write-protected.
	LOST_WRITEBEHIND_DATA_LOCAL_DISK_ERROR = 0x316,
	// The resources required for this device conflict with the MCFG table.
	BAD_MCFG_TABLE = 0x317,
	// The volume repair could not be performed while it is online. Please schedule to take the volume offline so that it can be repaired.
	DISK_REPAIR_REDIRECTED = 0x318,
	// The volume repair was not successful.
	DISK_REPAIR_UNSUCCESSFUL = 0x319,
	// One of the volume corruption logs is full. Further corruptions that may be detected won't be logged.
	CORRUPT_LOG_OVERFULL = 0x31A,
	// One of the volume corruption logs is internally corrupted and needs to be recreated. The volume may contain undetected corruptions and must be scanned.
	CORRUPT_LOG_CORRUPTED = 0x31B,
	// One of the volume corruption logs is unavailable for being operated on.
	CORRUPT_LOG_UNAVAILABLE = 0x31C,
	// One of the volume corruption logs was deleted while still having corruption records in them. The volume contains detected corruptions and must be scanned.
	CORRUPT_LOG_DELETED_FULL = 0x31D,
	// One of the volume corruption logs was cleared by chkdsk and no longer contains real corruptions.
	CORRUPT_LOG_CLEARED = 0x31E,
	// Orphaned files exist on the volume but could not be recovered because no more new names could be created in the recovery directory. Files must be moved from the recovery directory.
	ORPHAN_NAME_EXHAUSTED = 0x31F,
	// The oplock that was associated with this handle is now associated with a different handle.
	OPLOCK_SWITCHED_TO_NEW_HANDLE = 0x320,
	// An oplock of the requested level cannot be granted. An oplock of a lower level may be available.
	CANNOT_GRANT_REQUESTED_OPLOCK = 0x321,
	// The operation did not complete successfully because it would cause an oplock to be broken. The caller has requested that existing oplocks not be broken.
	CANNOT_BREAK_OPLOCK = 0x322,
	// The handle with which this oplock was associated has been closed. The oplock is now broken.
	OPLOCK_HANDLE_CLOSED = 0x323,
	// The specified access control entry (ACE) does not contain a condition.
	NO_ACE_CONDITION = 0x324,
	// The specified access control entry (ACE) contains an invalid condition.
	INVALID_ACE_CONDITION = 0x325,
	// Access to the specified file handle has been revoked.
	FILE_HANDLE_REVOKED = 0x326,
	// An image file was mapped at a different address from the one specified in the image file but fixups will still be automatically performed on the image.
	IMAGE_AT_DIFFERENT_BASE = 0x327,
	// Access to the extended attribute was denied.
	EA_ACCESS_DENIED = 0x3E2,
	// The I/O operation has been aborted because of either a thread exit or an application request.
	OPERATION_ABORTED = 0x3E3,
	// Overlapped I/O event is not in a signaled state.
	IO_INCOMPLETE = 0x3E4,
	// Overlapped I/O operation is in progress.
	IO_PENDING = 0x3E5,
	// Invalid access to memory location.
	NOACCESS = 0x3E6,
	// Error performing inpage operation.
	SWAPERROR = 0x3E7,

	// Recursion too deep; the stack overflowed.
	STACK_OVERFLOW = 0x3E9,
	// The window cannot act on the sent message.
	INVALID_MESSAGE = 0x3EA,
	// Cannot complete this function.
	CAN_NOT_COMPLETE = 0x3EB,
	// Invalid flags.
	INVALID_FLAGS = 0x3EC,
	// The volume does not contain a recognized file system. Please make sure that all required file system drivers are loaded and that the volume is not corrupted.
	UNRECOGNIZED_VOLUME = 0x3ED,
	// The volume for a file has been externally altered so that the opened file is no longer valid.
	FILE_INVALID = 0x3EE,
	// The requested operation cannot be performed in full-screen mode.
	FULLSCREEN_MODE = 0x3EF,
	// An attempt was made to reference a token that does not exist.
	NO_TOKEN = 0x3F0,
	// The configuration registry database is corrupt.
	BADDB = 0x3F1,
	// The configuration registry key is invalid.
	BADKEY = 0x3F2,
	// The configuration registry key could not be opened.
	CANTOPEN = 0x3F3,
	// The configuration registry key could not be read.
	CANTREAD = 0x3F4,
	// The configuration registry key could not be written.
	CANTWRITE = 0x3F5,
	// One of the files in the registry database had to be recovered by use of a log or alternate copy. The recovery was successful.
	REGISTRY_RECOVERED = 0x3F6,
	// The registry is corrupted. The structure of one of the files containing registry data is corrupted, or the system's memory image of the file is corrupted, or the file could not be recovered because the alternate copy or log was absent or corrupted.
	REGISTRY_CORRUPT = 0x3F7,
	// An I/O operation initiated by the registry failed unrecoverably. The registry could not read in, or write out, or flush, one of the files that contain the system's image of the registry.
	REGISTRY_IO_FAILED = 0x3F8,
	// The system has attempted to load or restore a file into the registry, but the specified file is not in a registry file format.
	NOT_REGISTRY_FILE = 0x3F9,
	// Illegal operation attempted on a registry key that has been marked for deletion.
	KEY_DELETED = 0x3FA,
	// System could not allocate the required space in a registry log.
	NO_LOG_SPACE = 0x3FB,
	// Cannot create a symbolic link in a registry key that already has subkeys or values.
	KEY_HAS_CHILDREN = 0x3FC,
	// Cannot create a stable subkey under a volatile parent key.
	CHILD_MUST_BE_VOLATILE = 0x3FD,
	// A notify change request is being completed and the information is not being returned in the caller's buffer. The caller now needs to enumerate the files to find the changes.
	NOTIFY_ENUM_DIR = 0x3FE,
	// A stop control has been sent to a service that other running services are dependent on.
	DEPENDENT_SERVICES_RUNNING = 0x41B,
	// The requested control is not valid for this service.
	INVALID_SERVICE_CONTROL = 0x41C,
	// The service did not respond to the start or control request in a timely fashion.
	SERVICE_REQUEST_TIMEOUT = 0x41D,
	// A thread could not be created for the service.
	SERVICE_NO_THREAD = 0x41E,
	// The service database is locked.
	SERVICE_DATABASE_LOCKED = 0x41F,
	// An instance of the service is already running.
	SERVICE_ALREADY_RUNNING = 0x420,
	// The account name is invalid or does not exist, or the password is invalid for the account name specified.
	INVALID_SERVICE_ACCOUNT = 0x421,
	// The service cannot be started, either because it is disabled or because it has no enabled devices associated with it.
	SERVICE_DISABLED = 0x422,
	// Circular service dependency was specified.
	CIRCULAR_DEPENDENCY = 0x423,
	// The specified service does not exist as an installed service.
	SERVICE_DOES_NOT_EXIST = 0x424,
	// The service cannot accept control messages at this time.
	SERVICE_CANNOT_ACCEPT_CTRL = 0x425,
	// The service has not been started.
	SERVICE_NOT_ACTIVE = 0x426,
	// The service process could not connect to the service controller.
	FAILED_SERVICE_CONTROLLER_CONNECT = 0x427,
	// An exception occurred in the service when handling the control request.
	EXCEPTION_IN_SERVICE = 0x428,
	// The database specified does not exist.
	DATABASE_DOES_NOT_EXIST = 0x429,
	// The service has returned a service-specific error code.
	SERVICE_SPECIFIC_ERROR = 0x42A,
	// The process terminated unexpectedly.
	PROCESS_ABORTED = 0x42B,
	// The dependency service or group failed to start.
	SERVICE_DEPENDENCY_FAIL = 0x42C,
	// The service did not start due to a logon failure.
	SERVICE_LOGON_FAILED = 0x42D,
	// After starting, the service hung in a start-pending state.
	SERVICE_START_HANG = 0x42E,
	// The specified service database lock is invalid.
	INVALID_SERVICE_LOCK = 0x42F,
	// The specified service has been marked for deletion.
	SERVICE_MARKED_FOR_DELETE = 0x430,
	// The specified service already exists.
	SERVICE_EXISTS = 0x431,
	// The system is currently running with the last-known-good configuration.
	ALREADY_RUNNING_LKG = 0x432,
	// The dependency service does not exist or has been marked for deletion.
	SERVICE_DEPENDENCY_DELETED = 0x433,
	// The current boot has already been accepted for use as the last-known-good control set.
	BOOT_ALREADY_ACCEPTED = 0x434,
	// No attempts to start the service have been made since the last boot.
	SERVICE_NEVER_STARTED = 0x435,
	// The name is already in use as either a service name or a service display name.
	DUPLICATE_SERVICE_NAME = 0x436,
	// The account specified for this service is different from the account specified for other services running in the same process.
	DIFFERENT_SERVICE_ACCOUNT = 0x437,
	// Failure actions can only be set for Win32 services, not for drivers.
	CANNOT_DETECT_DRIVER_FAILURE = 0x438,
	// This service runs in the same process as the service control manager. Therefore, the service control manager cannot take action if this service's process terminates unexpectedly.
	CANNOT_DETECT_PROCESS_ABORT = 0x439,
	// No recovery program has been configured for this service.
	NO_RECOVERY_PROGRAM = 0x43A,
	// The executable program that this service is configured to run in does not implement the service.
	SERVICE_NOT_IN_EXE = 0x43B,
	// This service cannot be started in Safe Mode.
	NOT_SAFEBOOT_SERVICE = 0x43C,
	// The physical end of the tape has been reached.
	END_OF_MEDIA = 0x44C,
	// A tape access reached a filemark.
	FILEMARK_DETECTED = 0x44D,
	// The beginning of the tape or a partition was encountered.
	BEGINNING_OF_MEDIA = 0x44E,
	// A tape access reached the end of a set of files.
	SETMARK_DETECTED = 0x44F,
	// No more data is on the tape.
	NO_DATA_DETECTED = 0x450,
	// Tape could not be partitioned.
	PARTITION_FAILURE = 0x451,
	// When accessing a new tape of a multivolume partition, the current block size is incorrect.
	INVALID_BLOCK_LENGTH = 0x452,
	// Tape partition information could not be found when loading a tape.
	DEVICE_NOT_PARTITIONED = 0x453,
	// Unable to lock the media eject mechanism.
	UNABLE_TO_LOCK_MEDIA = 0x454,
	// Unable to unload the media.
	UNABLE_TO_UNLOAD_MEDIA = 0x455,
	// The media in the drive may have changed.
	MEDIA_CHANGED = 0x456,
	// The I/O bus was reset.
	BUS_RESET = 0x457,
	// No media in drive.
	NO_MEDIA_IN_DRIVE = 0x458,
	// No mapping for the Unicode character exists in the target multi-byte code page.
	NO_UNICODE_TRANSLATION = 0x459,
	// A dynamic link library (DLL) initialization routine failed.
	DLL_INIT_FAILED = 0x45A,
	// A system shutdown is in progress.
	SHUTDOWN_IN_PROGRESS = 0x45B,
	// Unable to abort the system shutdown because no shutdown was in progress.
	NO_SHUTDOWN_IN_PROGRESS = 0x45C,
	// The request could not be performed because of an I/O device error.
	IO_DEVICE = 0x45D,
	// No serial device was successfully initialized. The serial driver will unload.
	SERIAL_NO_DEVICE = 0x45E,
	// Unable to open a device that was sharing an interrupt request (IRQ) with other devices. At least one other device that uses that IRQ was already opened.
	IRQ_BUSY = 0x45F,
	// A serial I/O operation was completed by another write to the serial port. The IOCTL_SERIAL_XOFF_COUNTER reached zero.)
	MORE_WRITES = 0x460,
	// A serial I/O operation completed because the timeout period expired. The IOCTL_SERIAL_XOFF_COUNTER did not reach zero.)
	COUNTER_TIMEOUT = 0x461,
	// No ID address mark was found on the floppy disk.
	FLOPPY_ID_MARK_NOT_FOUND = 0x462,
	// Mismatch between the floppy disk sector ID field and the floppy disk controller track address.
	FLOPPY_WRONG_CYLINDER = 0x463,
	// The floppy disk controller reported an error that is not recognized by the floppy disk driver.
	FLOPPY_UNKNOWN_ERROR = 0x464,
	// The floppy disk controller returned inconsistent results in its registers.
	FLOPPY_BAD_REGISTERS = 0x465,
	// While accessing the hard disk, a recalibrate operation failed, even after retries.
	DISK_RECALIBRATE_FAILED = 0x466,
	// While accessing the hard disk, a disk operation failed even after retries.
	DISK_OPERATION_FAILED = 0x467,
	// While accessing the hard disk, a disk controller reset was needed, but even that failed.
	DISK_RESET_FAILED = 0x468,
	// Physical end of tape encountered.
	EOM_OVERFLOW = 0x469,
	// Not enough server storage is available to process this command.
	NOT_ENOUGH_SERVER_MEMORY = 0x46A,
	// A potential deadlock condition has been detected.
	POSSIBLE_DEADLOCK = 0x46B,
	// The base address or the file offset specified does not have the proper alignment.
	MAPPED_ALIGNMENT = 0x46C,
	// An attempt to change the system power state was vetoed by another application or driver.
	SET_POWER_STATE_VETOED = 0x474,
	// The system BIOS failed an attempt to change the system power state.
	SET_POWER_STATE_FAILED = 0x475,
	// An attempt was made to create more links on a file than the file system supports.
	TOO_MANY_LINKS = 0x476,
	// The specified program requires a newer version of Windows.
	OLD_WIN_VERSION = 0x47E,
	// The specified program is not a Windows or MS-DOS program.
	APP_WRONG_OS = 0x47F,
	// Cannot start more than one instance of the specified program.
	SINGLE_INSTANCE_APP = 0x480,
	// The specified program was written for an earlier version of Windows.
	RMODE_APP = 0x481,
	// One of the library files needed to run this application is damaged.
	INVALID_DLL = 0x482,
	// No application is associated with the specified file for this operation.
	NO_ASSOCIATION = 0x483,
	// An error occurred in sending the command to the application.
	DDE_FAIL = 0x484,
	// One of the library files needed to run this application cannot be found.
	DLL_NOT_FOUND = 0x485,
	// The current process has used all of its system allowance of handles for Window Manager objects.
	NO_MORE_USER_HANDLES = 0x486,
	// The message can be used only with synchronous operations.
	MESSAGE_SYNC_ONLY = 0x487,
	// The indicated source element has no media.
	SOURCE_ELEMENT_EMPTY = 0x488,
	// The indicated destination element already contains media.
	DESTINATION_ELEMENT_FULL = 0x489,
	// The indicated element does not exist.
	ILLEGAL_ELEMENT_ADDRESS = 0x48A,
	// The indicated element is part of a magazine that is not present.
	MAGAZINE_NOT_PRESENT = 0x48B,
	// The indicated device requires reinitialization due to hardware errors.
	DEVICE_REINITIALIZATION_NEEDED = 0x48C,
	// The device has indicated that cleaning is required before further operations are attempted.
	DEVICE_REQUIRES_CLEANING = 0x48D,
	// The device has indicated that its door is open.
	DEVICE_DOOR_OPEN = 0x48E,
	// The device is not connected.
	DEVICE_NOT_CONNECTED = 0x48F,
	// Element not found.
	NOT_FOUND = 0x490,
	// There was no match for the specified key in the index.
	NO_MATCH = 0x491,
	// The property set specified does not exist on the object.
	SET_NOT_FOUND = 0x492,
	// The point passed to GetMouseMovePoints is not in the buffer.
	POINT_NOT_FOUND = 0x493,
	// The tracking (workstation) service is not running.
	NO_TRACKING_SERVICE = 0x494,
	// The Volume ID could not be found.
	NO_VOLUME_ID = 0x495,
	// Unable to remove the file to be replaced.
	UNABLE_TO_REMOVE_REPLACED = 0x497,
	// Unable to move the replacement file to the file to be replaced. The file to be replaced has retained its original name.
	UNABLE_TO_MOVE_REPLACEMENT = 0x498,
	// Unable to move the replacement file to the file to be replaced. The file to be replaced has been renamed using the backup name.
	UNABLE_TO_MOVE_REPLACEMENT_2 = 0x499,
	// The volume change journal is being deleted.
	JOURNAL_DELETE_IN_PROGRESS = 0x49A,
	// The volume change journal is not active.
	JOURNAL_NOT_ACTIVE = 0x49B,
	// A file was found, but it may not be the correct file.
	POTENTIAL_FILE_FOUND = 0x49C,
	// The journal entry has been deleted from the journal.
	JOURNAL_ENTRY_DELETED = 0x49D,
	// A system shutdown has already been scheduled.
	SHUTDOWN_IS_SCHEDULED = 0x4A6,
	// The system shutdown cannot be initiated because there are other users logged on to the computer.
	SHUTDOWN_USERS_LOGGED_ON = 0x4A7,
	// The specified device name is invalid.
	BAD_DEVICE = 0x4B0,
	// The device is not currently connected but it is a remembered connection.
	CONNECTION_UNAVAIL = 0x4B1,
	// The local device name has a remembered connection to another network resource.
	DEVICE_ALREADY_REMEMBERED = 0x4B2,
	// The network path was either typed incorrectly, does not exist, or the network provider is not currently available. Please try retyping the path or contact your network administrator.
	NO_NET_OR_BAD_PATH = 0x4B3,
	// The specified network provider name is invalid.
	BAD_PROVIDER = 0x4B4,
	// Unable to open the network connection profile.
	CANNOT_OPEN_PROFILE = 0x4B5,
	// The network connection profile is corrupted.
	BAD_PROFILE = 0x4B6,
	// Cannot enumerate a noncontainer.
	NOT_CONTAINER = 0x4B7,
	// An extended error has occurred.
	EXTENDED_ERROR = 0x4B8,
	// The format of the specified group name is invalid.
	INVALID_GROUPNAME = 0x4B9,
	// The format of the specified computer name is invalid.
	INVALID_COMPUTERNAME = 0x4BA,
	// The format of the specified event name is invalid.
	INVALID_EVENTNAME = 0x4BB,
	// The format of the specified domain name is invalid.
	INVALID_DOMAINNAME = 0x4BC,
	// The format of the specified service name is invalid.
	INVALID_SERVICENAME = 0x4BD,
	// The format of the specified network name is invalid.
	INVALID_NETNAME = 0x4BE,
	// The format of the specified share name is invalid.
	INVALID_SHARENAME = 0x4BF,
	// The format of the specified password is invalid.
	INVALID_PASSWORDNAME = 0x4C0,
	// The format of the specified message name is invalid.
	INVALID_MESSAGENAME = 0x4C1,
	// The format of the specified message destination is invalid.
	INVALID_MESSAGEDEST = 0x4C2,
	// Multiple connections to a server or shared resource by the same user, using more than one user name, are not allowed. Disconnect all previous connections to the server or shared resource and try again.
	SESSION_CREDENTIAL_CONFLICT = 0x4C3,
	// An attempt was made to establish a session to a network server, but there are already too many sessions established to that server.
	REMOTE_SESSION_LIMIT_EXCEEDED = 0x4C4,
	// The workgroup or domain name is already in use by another computer on the network.
	DUP_DOMAINNAME = 0x4C5,
	// The network is not present or not started.
	NO_NETWORK = 0x4C6,
	// The operation was canceled by the user.
	CANCELLED = 0x4C7,
	// The requested operation cannot be performed on a file with a user-mapped section open.
	USER_MAPPED_FILE = 0x4C8,
	// The remote computer refused the network connection.
	CONNECTION_REFUSED = 0x4C9,
	// The network connection was gracefully closed.
	GRACEFUL_DISCONNECT = 0x4CA,
	// The network transport endpoint already has an address associated with it.
	ADDRESS_ALREADY_ASSOCIATED = 0x4CB,
	// An address has not yet been associated with the network endpoint.
	ADDRESS_NOT_ASSOCIATED = 0x4CC,
	// An operation was attempted on a nonexistent network connection.
	CONNECTION_INVALID = 0x4CD,
	// An invalid operation was attempted on an active network connection.
	CONNECTION_ACTIVE = 0x4CE,
	// The network location cannot be reached. For information about network troubleshooting, see Windows Help.
	NETWORK_UNREACHABLE = 0x4CF,
	// The network location cannot be reached. For information about network troubleshooting, see Windows Help.
	HOST_UNREACHABLE = 0x4D0,
	// The network location cannot be reached. For information about network troubleshooting, see Windows Help.
	PROTOCOL_UNREACHABLE = 0x4D1,
	// No service is operating at the destination network endpoint on the remote system.
	PORT_UNREACHABLE = 0x4D2,
	// The request was aborted.
	REQUEST_ABORTED = 0x4D3,
	// The network connection was aborted by the local system.
	CONNECTION_ABORTED = 0x4D4,
	// The operation could not be completed. A retry should be performed.
	RETRY = 0x4D5,
	// A connection to the server could not be made because the limit on the number of concurrent connections for this account has been reached.
	CONNECTION_COUNT_LIMIT = 0x4D6,
	// Attempting to log in during an unauthorized time of day for this account.
	LOGIN_TIME_RESTRICTION = 0x4D7,
	// The account is not authorized to log in from this station.
	LOGIN_WKSTA_RESTRICTION = 0x4D8,
	// The network address could not be used for the operation requested.
	INCORRECT_ADDRESS = 0x4D9,
	// The service is already registered.
	ALREADY_REGISTERED = 0x4DA,
	// The specified service does not exist.
	SERVICE_NOT_FOUND = 0x4DB,
	// The operation being requested was not performed because the user has not been authenticated.
	NOT_AUTHENTICATED = 0x4DC,
	// The operation being requested was not performed because the user has not logged on to the network. The specified service does not exist.
	NOT_LOGGED_ON = 0x4DD,
	// Continue with work in progress.
	CONTINUE = 0x4DE,
	// An attempt was made to perform an initialization operation when initialization has already been completed.
	ALREADY_INITIALIZED = 0x4DF,
	// No more local devices.
	NO_MORE_DEVICES = 0x4E0,
	// The specified site does not exist.
	NO_SUCH_SITE = 0x4E1,
	// A domain controller with the specified name already exists.
	DOMAIN_CONTROLLER_EXISTS = 0x4E2,
	// This operation is supported only when you are connected to the server.
	ONLY_IF_CONNECTED = 0x4E3,
	// The group policy framework should call the extension even if there are no changes.
	OVERRIDE_NOCHANGES = 0x4E4,
	// The specified user does not have a valid profile.
	BAD_USER_PROFILE = 0x4E5,
	// This operation is not supported on a computer running Windows Server 2003 for Small Business Server.
	NOT_SUPPORTED_ON_SBS = 0x4E6,
	// The server machine is shutting down.
	SERVER_SHUTDOWN_IN_PROGRESS = 0x4E7,
	// The remote system is not available. For information about network troubleshooting, see Windows Help.
	HOST_DOWN = 0x4E8,
	// The security identifier provided is not from an account domain.
	NON_ACCOUNT_SID = 0x4E9,
	// The security identifier provided does not have a domain component.
	NON_DOMAIN_SID = 0x4EA,
	// AppHelp dialog canceled thus preventing the application from starting.
	APPHELP_BLOCK = 0x4EB,
	// This program is blocked by group policy. For more information, contact your system administrator.
	ACCESS_DISABLED_BY_POLICY = 0x4EC,
	// A program attempt to use an invalid register value. Normally caused by an uninitialized register. This error is Itanium specific.
	REG_NAT_CONSUMPTION = 0x4ED,
	// The share is currently offline or does not exist.
	CSCSHARE_OFFLINE = 0x4EE,
	// The Kerberos protocol encountered an error while validating the KDC certificate during smartcard logon. There is more information in the system event log.
	PKINIT_FAILURE = 0x4EF,
	// The Kerberos protocol encountered an error while attempting to utilize the smartcard subsystem.
	SMARTCARD_SUBSYSTEM_FAILURE = 0x4F0,
	// The system cannot contact a domain controller to service the authentication request. Please try again later.
	DOWNGRADE_DETECTED = 0x4F1,
	// The machine is locked and cannot be shut down without the force option.
	MACHINE_LOCKED = 0x4F7,
	// An application-defined callback gave invalid data when called.
	CALLBACK_SUPPLIED_INVALID_DATA = 0x4F9,
	// The group policy framework should call the extension in the synchronous foreground policy refresh.
	SYNC_FOREGROUND_REFRESH_REQUIRED = 0x4FA,
	// This driver has been blocked from loading.
	DRIVER_BLOCKED = 0x4FB,
	// A dynamic link library (DLL) referenced a module that was neither a DLL nor the process's executable image.
	INVALID_IMPORT_OF_NON_DLL = 0x4FC,
	// Windows cannot open this program since it has been disabled.
	ACCESS_DISABLED_WEBBLADE = 0x4FD,
	// Windows cannot open this program because the license enforcement system has been tampered with or become corrupted.
	ACCESS_DISABLED_WEBBLADE_TAMPER = 0x4FE,
	// A transaction recover failed.
	RECOVERY_FAILURE = 0x4FF,
	// The current thread has already been converted to a fiber.
	ALREADY_FIBER = 0x500,
	// The current thread has already been converted from a fiber.
	ALREADY_THREAD = 0x501,
	// The system detected an overrun of a stack-based buffer in this application. This overrun could potentially allow a malicious user to gain control of this application.
	STACK_BUFFER_OVERRUN = 0x502,
	// Data present in one of the parameters is more than the function can operate on.
	PARAMETER_QUOTA_EXCEEDED = 0x503,
	// An attempt to do an operation on a debug object failed because the object is in the process of being deleted.
	DEBUGGER_INACTIVE = 0x504,
	// An attempt to delay-load a .dll or get a function address in a delay-loaded .dll failed.
	DELAY_LOAD_FAILED = 0x505,
	// %1 is a 16-bit application. You do not have permissions to execute 16-bit applications. Check your permissions with your system administrator.
	VDM_DISALLOWED = 0x506,
	// Insufficient information exists to identify the cause of failure.
	UNIDENTIFIED_ERROR = 0x507,
	// The parameter passed to a C runtime function is incorrect.
	INVALID_CRUNTIME_PARAMETER = 0x508,
	// The operation occurred beyond the valid data length of the file.
	BEYOND_VDL = 0x509,
	// The service start failed since one or more services in the same process have an incompatible service SID type setting. A service with restricted service SID type can only coexist in the same process with other services with a restricted SID type. If the service SID type for this service was just configured, the hosting process must be restarted in order to start this service.
	// On Windows Server 2003 and Windows XP, an unrestricted service cannot coexist in the same process with other services. The service with the unrestricted service SID type must be moved to an owned process in order to start this service.
	INCOMPATIBLE_SERVICE_SID_TYPE = 0x50A,
	// The process hosting the driver for this device has been terminated.
	DRIVER_PROCESS_TERMINATED = 0x50B,
	// An operation attempted to exceed an implementation-defined limit.
	IMPLEMENTATION_LIMIT = 0x50C,
	// Either the target process, or the target thread's containing process, is a protected process.
	PROCESS_IS_PROTECTED = 0x50D,
	// The service notification client is lagging too far behind the current state of services in the machine.
	SERVICE_NOTIFY_CLIENT_LAGGING = 0x50E,
	// The requested file operation failed because the storage quota was exceeded. To free up disk space, move files to a different location or delete unnecessary files. For more information, contact your system administrator.
	DISK_QUOTA_EXCEEDED = 0x50F,
	// The requested file operation failed because the storage policy blocks that type of file. For more information, contact your system administrator.
	CONTENT_BLOCKED = 0x510,
	// A privilege that the service requires to function properly does not exist in the service account configuration. You may use the Services Microsoft Management Console (MMC) snap-in (services.msc) and the Local Security Settings MMC snap-in (secpol.msc) to view the service configuration and the account configuration.
	INCOMPATIBLE_SERVICE_PRIVILEGE = 0x511,
	// A thread involved in this operation appears to be unresponsive.
	APP_HANG = 0x512,
	// Indicates a particular Security ID may not be assigned as the label of an object.
	INVALID_LABEL = 0x513,

	// Not all privileges or groups referenced are assigned to the caller.
	NOT_ALL_ASSIGNED = 0x514,
	// Some mapping between account names and security IDs was not done.
	SOME_NOT_MAPPED = 0x515,
	// No system quota limits are specifically set for this account.
	NO_QUOTAS_FOR_ACCOUNT = 0x516,
	// No encryption key is available. A well-known encryption key was returned.
	LOCAL_USER_SESSION_KEY = 0x517,
	// The password is too complex to be converted to a LAN Manager password. The LAN Manager password returned is a NULL string.
	NULL_LM_PASSWORD = 0x518,
	// The revision level is unknown.
	UNKNOWN_REVISION = 0x519,
	// Indicates two revision levels are incompatible.
	REVISION_MISMATCH = 0x51A,
	// This security ID may not be assigned as the owner of this object.
	INVALID_OWNER = 0x51B,
	// This security ID may not be assigned as the primary group of an object.
	INVALID_PRIMARY_GROUP = 0x51C,
	// An attempt has been made to operate on an impersonation token by a thread that is not currently impersonating a client.
	NO_IMPERSONATION_TOKEN = 0x51D,
	// The group may not be disabled.
	CANT_DISABLE_MANDATORY = 0x51E,
	// There are currently no logon servers available to service the logon request.
	NO_LOGON_SERVERS = 0x51F,
	// A specified logon session does not exist. It may already have been terminated.
	NO_SUCH_LOGON_SESSION = 0x520,
	// A specified privilege does not exist.
	NO_SUCH_PRIVILEGE = 0x521,
	// A required privilege is not held by the client.
	PRIVILEGE_NOT_HELD = 0x522,
	// The name provided is not a properly formed account name.
	INVALID_ACCOUNT_NAME = 0x523,
	// The specified account already exists.
	USER_EXISTS = 0x524,
	// The specified account does not exist.
	NO_SUCH_USER = 0x525,
	// The specified group already exists.
	GROUP_EXISTS = 0x526,
	// The specified group does not exist.
	NO_SUCH_GROUP = 0x527,
	// Either the specified user account is already a member of the specified group, or the specified group cannot be deleted because it contains a member.
	MEMBER_IN_GROUP = 0x528,
	// The specified user account is not a member of the specified group account.
	MEMBER_NOT_IN_GROUP = 0x529,
	// This operation is disallowed as it could result in an administration account being disabled, deleted or unable to log on.
	LAST_ADMIN = 0x52A,
	// Unable to update the password. The value provided as the current password is incorrect.
	WRONG_PASSWORD = 0x52B,
	// Unable to update the password. The value provided for the new password contains values that are not allowed in passwords.
	ILL_FORMED_PASSWORD = 0x52C,
	// Unable to update the password. The value provided for the new password does not meet the length, complexity, or history requirements of the domain.
	PASSWORD_RESTRICTION = 0x52D,
	// The user name or password is incorrect.
	LOGON_FAILURE = 0x52E,
	// Account restrictions are preventing this user from signing in. For example: blank passwords aren't allowed, sign-in times are limited, or a policy restriction has been enforced.
	ACCOUNT_RESTRICTION = 0x52F,
	// Your account has time restrictions that keep you from signing in right now.
	INVALID_LOGON_HOURS = 0x530,
	// This user isn't allowed to sign in to this computer.
	INVALID_WORKSTATION = 0x531,
	// The password for this account has expired.
	PASSWORD_EXPIRED = 0x532,
	// This user can't sign in because this account is currently disabled.
	ACCOUNT_DISABLED = 0x533,
	// No mapping between account names and security IDs was done.
	NONE_MAPPED = 0x534,
	// Too many local user identifiers (LUIDs) were requested at one time.
	TOO_MANY_LUIDS_REQUESTED = 0x535,
	// No more local user identifiers (LUIDs) are available.
	LUIDS_EXHAUSTED = 0x536,
	// The subauthority part of a security ID is invalid for this particular use.
	INVALID_SUB_AUTHORITY = 0x537,
	// The access control list (ACL) structure is invalid.
	INVALID_ACL = 0x538,
	// The security ID structure is invalid.
	INVALID_SID = 0x539,
	// The security descriptor structure is invalid.
	INVALID_SECURITY_DESCR = 0x53A,
	// The inherited access control list (ACL) or access control entry (ACE) could not be built.
	BAD_INHERITANCE_ACL = 0x53C,
	// The server is currently disabled.
	SERVER_DISABLED = 0x53D,
	// The server is currently enabled.
	SERVER_NOT_DISABLED = 0x53E,
	// The value provided was an invalid value for an identifier authority.
	INVALID_ID_AUTHORITY = 0x53F,
	// No more memory is available for security information updates.
	ALLOTTED_SPACE_EXCEEDED = 0x540,
	// The specified attributes are invalid, or incompatible with the attributes for the group as a whole.
	INVALID_GROUP_ATTRIBUTES = 0x541,
	// Either a required impersonation level was not provided, or the provided impersonation level is invalid.
	BAD_IMPERSONATION_LEVEL = 0x542,
	// Cannot open an anonymous level security token.
	CANT_OPEN_ANONYMOUS = 0x543,
	// The validation information class requested was invalid.
	BAD_VALIDATION_CLASS = 0x544,
	// The type of the token is inappropriate for its attempted use.
	BAD_TOKEN_TYPE = 0x545,
	// Unable to perform a security operation on an object that has no associated security.
	NO_SECURITY_ON_OBJECT = 0x546,
	// Configuration information could not be read from the domain controller, either because the machine is unavailable, or access has been denied.
	CANT_ACCESS_DOMAIN_INFO = 0x547,
	// The security account manager (SAM) or local security authority (LSA) server was in the wrong state to perform the security operation.
	INVALID_SERVER_STATE = 0x548,
	// The domain was in the wrong state to perform the security operation.
	INVALID_DOMAIN_STATE = 0x549,
	// This operation is only allowed for the Primary Domain Controller of the domain.
	INVALID_DOMAIN_ROLE = 0x54A,
	// The specified domain either does not exist or could not be contacted.
	NO_SUCH_DOMAIN = 0x54B,
	// The specified domain already exists.
	DOMAIN_EXISTS = 0x54C,
	// An attempt was made to exceed the limit on the number of domains per server.
	DOMAIN_LIMIT_EXCEEDED = 0x54D,
	// Unable to complete the requested operation because of either a catastrophic media failure or a data structure corruption on the disk.
	INTERNAL_DB_CORRUPTION = 0x54E,
	// An internal error occurred.
	INTERNAL_ERROR = 0x54F,
	// Generic access types were contained in an access mask which should already be mapped to nongeneric types.
	GENERIC_NOT_MAPPED = 0x550,
	// A security descriptor is not in the right format (absolute or self-relative).
	BAD_DESCRIPTOR_FORMAT = 0x551,
	// The requested action is restricted for use by logon processes only. The calling process has not registered as a logon process.
	NOT_LOGON_PROCESS = 0x552,
	// Cannot start a new logon session with an ID that is already in use.
	LOGON_SESSION_EXISTS = 0x553,
	// A specified authentication package is unknown.
	NO_SUCH_PACKAGE = 0x554,
	// The logon session is not in a state that is consistent with the requested operation.
	BAD_LOGON_SESSION_STATE = 0x555,
	// The logon session ID is already in use.
	LOGON_SESSION_COLLISION = 0x556,
	// A logon request contained an invalid logon type value.
	INVALID_LOGON_TYPE = 0x557,
	// Unable to impersonate using a named pipe until data has been read from that pipe.
	CANNOT_IMPERSONATE = 0x558,
	// The transaction state of a registry subtree is incompatible with the requested operation.
	RXACT_INVALID_STATE = 0x559,
	// An internal security database corruption has been encountered.
	RXACT_COMMIT_FAILURE = 0x55A,
	// Cannot perform this operation on built-in accounts.
	SPECIAL_ACCOUNT = 0x55B,
	// Cannot perform this operation on this built-in special group.
	SPECIAL_GROUP = 0x55C,
	// Cannot perform this operation on this built-in special user.
	SPECIAL_USER = 0x55D,
	// The user cannot be removed from a group because the group is currently the user's primary group.
	MEMBERS_PRIMARY_GROUP = 0x55E,
	// The token is already in use as a primary token.
	TOKEN_ALREADY_IN_USE = 0x55F,
	// The specified local group does not exist.
	NO_SUCH_ALIAS = 0x560,
	// The specified account name is not a member of the group.
	MEMBER_NOT_IN_ALIAS = 0x561,
	// The specified account name is already a member of the group.
	MEMBER_IN_ALIAS = 0x562,
	// The specified local group already exists.
	ALIAS_EXISTS = 0x563,
	// Logon failure: the user has not been granted the requested logon type at this computer.
	LOGON_NOT_GRANTED = 0x564,
	// The maximum number of secrets that may be stored in a single system has been exceeded.
	TOO_MANY_SECRETS = 0x565,
	// The length of a secret exceeds the maximum length allowed.
	SECRET_TOO_LONG = 0x566,
	// The local security authority database contains an internal inconsistency.
	INTERNAL_DB_ERROR = 0x567,
	// During a logon attempt, the user's security context accumulated too many security IDs.
	TOO_MANY_CONTEXT_IDS = 0x568,
	// Logon failure: the user has not been granted the requested logon type at this computer.
	LOGON_TYPE_NOT_GRANTED = 0x569,
	// A cross-encrypted password is necessary to change a user password.
	NT_CROSS_ENCRYPTION_REQUIRED = 0x56A,
	// A member could not be added to or removed from the local group because the member does not exist.
	NO_SUCH_MEMBER = 0x56B,
	// A new member could not be added to a local group because the member has the wrong account type.
	INVALID_MEMBER = 0x56C,
	// Too many security IDs have been specified.
	TOO_MANY_SIDS = 0x56D,
	// A cross-encrypted password is necessary to change this user password.
	LM_CROSS_ENCRYPTION_REQUIRED = 0x56E,
	// Indicates an ACL contains no inheritable components.
	NO_INHERITANCE = 0x56F,
	// The file or directory is corrupted and unreadable.
	FILE_CORRUPT = 0x570,
	// The disk structure is corrupted and unreadable.
	DISK_CORRUPT = 0x571,
	// There is no user session key for the specified logon session.
	NO_USER_SESSION_KEY = 0x572,
	// The service being accessed is licensed for a particular number of connections. No more connections can be made to the service at this time because there are already as many connections as the service can accept.
	LICENSE_QUOTA_EXCEEDED = 0x573,
	// The target account name is incorrect.
	WRONG_TARGET_NAME = 0x574,
	// Mutual Authentication failed. The server's password is out of date at the domain controller.
	MUTUAL_AUTH_FAILED = 0x575,
	// There is a time and/or date difference between the client and server.
	TIME_SKEW = 0x576,
	// This operation cannot be performed on the current domain.
	CURRENT_DOMAIN_NOT_ALLOWED = 0x577,
	// Invalid window handle.
	INVALID_WINDOW_HANDLE = 0x578,
	// Invalid menu handle.
	INVALID_MENU_HANDLE = 0x579,
	// Invalid cursor handle.
	INVALID_CURSOR_HANDLE = 0x57A,
	// Invalid accelerator table handle.
	INVALID_ACCEL_HANDLE = 0x57B,
	// Invalid hook handle.
	INVALID_HOOK_HANDLE = 0x57C,
	// Invalid handle to a multiple-window position structure.
	INVALID_DWP_HANDLE = 0x57D,
	// Cannot create a top-level child window.
	TLW_WITH_WSCHILD = 0x57E,
	// Cannot find window class.
	CANNOT_FIND_WND_CLASS = 0x57F,
	// Invalid window; it belongs to other thread.
	WINDOW_OF_OTHER_THREAD = 0x580,
	// Hot key is already registered.
	HOTKEY_ALREADY_REGISTERED = 0x581,
	// Class already exists.
	CLASS_ALREADY_EXISTS = 0x582,
	// Class does not exist.
	CLASS_DOES_NOT_EXIST = 0x583,
	// Class still has open windows.
	CLASS_HAS_WINDOWS = 0x584,
	// Invalid index.
	INVALID_INDEX = 0x585,
	// Invalid icon handle.
	INVALID_ICON_HANDLE = 0x586,
	// Using private DIALOG window words.
	PRIVATE_DIALOG_INDEX = 0x587,
	// The list box identifier was not found.
	LISTBOX_ID_NOT_FOUND = 0x588,
	// No wildcards were found.
	NO_WILDCARD_CHARACTERS = 0x589,
	// Thread does not have a clipboard open.
	CLIPBOARD_NOT_OPEN = 0x58A,
	// Hot key is not registered.
	HOTKEY_NOT_REGISTERED = 0x58B,
	// The window is not a valid dialog window.
	WINDOW_NOT_DIALOG = 0x58C,
	// Control ID not found.
	CONTROL_ID_NOT_FOUND = 0x58D,
	// Invalid message for a combo box because it does not have an edit control.
	INVALID_COMBOBOX_MESSAGE = 0x58E,
	// The window is not a combo box.
	WINDOW_NOT_COMBOBOX = 0x58F,
	// Height must be less than 256.
	INVALID_EDIT_HEIGHT = 0x590,
	// Invalid device context (DC) handle.
	DC_NOT_FOUND = 0x591,
	// Invalid hook procedure type.
	INVALID_HOOK_FILTER = 0x592,
	// Invalid hook procedure.
	INVALID_FILTER_PROC = 0x593,
	// Cannot set nonlocal hook without a module handle.
	HOOK_NEEDS_HMOD = 0x594,
	// This hook procedure can only be set globally.
	GLOBAL_ONLY_HOOK = 0x595,
	// The journal hook procedure is already installed.
	JOURNAL_HOOK_SET = 0x596,
	// The hook procedure is not installed.
	HOOK_NOT_INSTALLED = 0x597,
	// Invalid message for single-selection list box.
	INVALID_LB_MESSAGE = 0x598,
	// LB_SETCOUNT sent to non-lazy list box.
	SETCOUNT_ON_BAD_LB = 0x599,
	// This list box does not support tab stops.
	LB_WITHOUT_TABSTOPS = 0x59A,
	// Cannot destroy object created by another thread.
	DESTROY_OBJECT_OF_OTHER_THREAD = 0x59B,
	// Child windows cannot have menus.
	CHILD_WINDOW_MENU = 0x59C,
	// The window does not have a system menu.
	NO_SYSTEM_MENU = 0x59D,
	// Invalid message box style.
	INVALID_MSGBOX_STYLE = 0x59E,
	// Invalid system-wide (SPI_*) parameter.
	INVALID_SPI_VALUE = 0x59F,
	// Screen already locked.
	SCREEN_ALREADY_LOCKED = 0x5A0,
	// All handles to windows in a multiple-window position structure must have the same parent.
	HWNDS_HAVE_DIFF_PARENT = 0x5A1,
	// The window is not a child window.
	NOT_CHILD_WINDOW = 0x5A2,
	// Invalid GW_* command.
	INVALID_GW_COMMAND = 0x5A3,
	// Invalid thread identifier.
	INVALID_THREAD_ID = 0x5A4,
	// Cannot process a message from a window that is not a multiple document interface (MDI) window.
	NON_MDICHILD_WINDOW = 0x5A5,
	// Popup menu already active.
	POPUP_ALREADY_ACTIVE = 0x5A6,
	// The window does not have scroll bars.
	NO_SCROLLBARS = 0x5A7,
	// Scroll bar range cannot be greater than MAXLONG.
	INVALID_SCROLLBAR_RANGE = 0x5A8,
	// Cannot show or remove the window in the way specified.
	INVALID_SHOWWIN_COMMAND = 0x5A9,
	// Insufficient system resources exist to complete the requested service.
	NO_SYSTEM_RESOURCES = 0x5AA,
	// Insufficient system resources exist to complete the requested service.
	NONPAGED_SYSTEM_RESOURCES = 0x5AB,
	// Insufficient system resources exist to complete the requested service.
	PAGED_SYSTEM_RESOURCES = 0x5AC,
	// Insufficient quota to complete the requested service.
	WORKING_SET_QUOTA = 0x5AD,
	// Insufficient quota to complete the requested service.
	PAGEFILE_QUOTA = 0x5AE,
	// The paging file is too small for this operation to complete.
	COMMITMENT_LIMIT = 0x5AF,
	// A menu item was not found.
	MENU_ITEM_NOT_FOUND = 0x5B0,
	// Invalid keyboard layout handle.
	INVALID_KEYBOARD_HANDLE = 0x5B1,
	// Hook type not allowed.
	HOOK_TYPE_NOT_ALLOWED = 0x5B2,
	// This operation requires an interactive window station.
	REQUIRES_INTERACTIVE_WINDOWSTATION = 0x5B3,
	// This operation returned because the timeout period expired.
	TIMEOUT = 0x5B4,
	// Invalid monitor handle.
	INVALID_MONITOR_HANDLE = 0x5B5,
	// Incorrect size argument.
	INCORRECT_SIZE = 0x5B6,
	// The symbolic link cannot be followed because its type is disabled.
	SYMLINK_CLASS_DISABLED = 0x5B7,
	// This application does not support the current operation on symbolic links.
	SYMLINK_NOT_SUPPORTED = 0x5B8,
	// Windows was unable to parse the requested XML data.
	XML_PARSE_ERROR = 0x5B9,
	// An error was encountered while processing an XML digital signature.
	XMLDSIG_ERROR = 0x5BA,
	// This application must be restarted.
	RESTART_APPLICATION = 0x5BB,
	// The caller made the connection request in the wrong routing compartment.
	WRONG_COMPARTMENT = 0x5BC,
	// There was an AuthIP failure when attempting to connect to the remote host.
	AUTHIP_FAILURE = 0x5BD,
	// Insufficient NVRAM resources exist to complete the requested service. A reboot might be required.
	NO_NVRAM_RESOURCES = 0x5BE,
	// Unable to finish the requested operation because the specified process is not a GUI process.
	NOT_GUI_PROCESS = 0x5BF,
	// The event log file is corrupted.
	EVENTLOG_FILE_CORRUPT = 0x5DC,
	// No event log file could be opened, so the event logging service did not start.
	EVENTLOG_CANT_START = 0x5DD,
	// The event log file is full.
	LOG_FILE_FULL = 0x5DE,
	// The event log file has changed between read operations.
	EVENTLOG_FILE_CHANGED = 0x5DF,
	// The specified task name is invalid.
	INVALID_TASK_NAME = 0x60E,
	// The specified task index is invalid.
	INVALID_TASK_INDEX = 0x60F,
	// The specified thread is already joining a task.
	THREAD_ALREADY_IN_TASK = 0x610,
	// The Windows Installer Service could not be accessed. This can occur if the Windows Installer is not correctly installed. Contact your support personnel for assistance.
	INSTALL_SERVICE_FAILURE = 0x641,
	// User cancelled installation.
	INSTALL_USEREXIT = 0x642,
	// Fatal error during installation.
	INSTALL_FAILURE = 0x643,
	// Installation suspended, incomplete.
	INSTALL_SUSPEND = 0x644,
	// This action is only valid for products that are currently installed.
	UNKNOWN_PRODUCT = 0x645,
	// Feature ID not registered.
	UNKNOWN_FEATURE = 0x646,
	// Component ID not registered.
	UNKNOWN_COMPONENT = 0x647,
	// Unknown property.
	UNKNOWN_PROPERTY = 0x648,
	// Handle is in an invalid state.
	INVALID_HANDLE_STATE = 0x649,
	// The configuration data for this product is corrupt. Contact your support personnel.
	BAD_CONFIGURATION = 0x64A,
	// Component qualifier not present.
	INDEX_ABSENT = 0x64B,
	// The installation source for this product is not available. Verify that the source exists and that you can access it.
	INSTALL_SOURCE_ABSENT = 0x64C,
	// This installation package cannot be installed by the Windows Installer service. You must install a Windows service pack that contains a newer version of the Windows Installer service.
	INSTALL_PACKAGE_VERSION = 0x64D,
	// Product is uninstalled.
	PRODUCT_UNINSTALLED = 0x64E,
	// SQL query syntax invalid or unsupported.
	BAD_QUERY_SYNTAX = 0x64F,
	// Record field does not exist.
	INVALID_FIELD = 0x650,
	// The device has been removed.
	DEVICE_REMOVED = 0x651,
	// Another installation is already in progress. Complete that installation before proceeding with this install.
	INSTALL_ALREADY_RUNNING = 0x652,
	// This installation package could not be opened. Verify that the package exists and that you can access it, or contact the application vendor to verify that this is a valid Windows Installer package.
	INSTALL_PACKAGE_OPEN_FAILED = 0x653,
	// This installation package could not be opened. Contact the application vendor to verify that this is a valid Windows Installer package.
	INSTALL_PACKAGE_INVALID = 0x654,
	// There was an error starting the Windows Installer service user interface. Contact your support personnel.
	INSTALL_UI_FAILURE = 0x655,
	// Error opening installation log file. Verify that the specified log file location exists and that you can write to it.
	INSTALL_LOG_FAILURE = 0x656,
	// The language of this installation package is not supported by your system.
	INSTALL_LANGUAGE_UNSUPPORTED = 0x657,
	// Error applying transforms. Verify that the specified transform paths are valid.
	INSTALL_TRANSFORM_FAILURE = 0x658,
	// This installation is forbidden by system policy. Contact your system administrator.
	INSTALL_PACKAGE_REJECTED = 0x659,
	// Function could not be executed.
	FUNCTION_NOT_CALLED = 0x65A,
	// Function failed during execution.
	FUNCTION_FAILED = 0x65B,
	// Invalid or unknown table specified.
	INVALID_TABLE = 0x65C,
	// Data supplied is of wrong type.
	DATATYPE_MISMATCH = 0x65D,
	// Data of this type is not supported.
	UNSUPPORTED_TYPE = 0x65E,
	// The Windows Installer service failed to start. Contact your support personnel.
	CREATE_FAILED = 0x65F,
	// The Temp folder is on a drive that is full or is inaccessible. Free up space on the drive or verify that you have write permission on the Temp folder.
	INSTALL_TEMP_UNWRITABLE = 0x660,
	// This installation package is not supported by this processor type. Contact your product vendor.
	INSTALL_PLATFORM_UNSUPPORTED = 0x661,
	// Component not used on this computer.
	INSTALL_NOTUSED = 0x662,
	// This update package could not be opened. Verify that the update package exists and that you can access it, or contact the application vendor to verify that this is a valid Windows Installer update package.
	PATCH_PACKAGE_OPEN_FAILED = 0x663,
	// This update package could not be opened. Contact the application vendor to verify that this is a valid Windows Installer update package.
	PATCH_PACKAGE_INVALID = 0x664,
	// This update package cannot be processed by the Windows Installer service. You must install a Windows service pack that contains a newer version of the Windows Installer service.
	PATCH_PACKAGE_UNSUPPORTED = 0x665,
	// Another version of this product is already installed. Installation of this version cannot continue. To configure or remove the existing version of this product, use Add/Remove Programs on the Control Panel.
	PRODUCT_VERSION = 0x666,
	// Invalid command line argument. Consult the Windows Installer SDK for detailed command line help.
	INVALID_COMMAND_LINE = 0x667,
	// Only administrators have permission to add, remove, or configure server software during a Terminal services remote session. If you want to install or configure software on the server, contact your network administrator.
	INSTALL_REMOTE_DISALLOWED = 0x668,
	// The requested operation completed successfully. The system will be restarted so the changes can take effect.
	SUCCESS_REBOOT_INITIATED = 0x669,
	// The upgrade cannot be installed by the Windows Installer service because the program to be upgraded may be missing, or the upgrade may update a different version of the program. Verify that the program to be upgraded exists on your computer and that you have the correct upgrade.
	PATCH_TARGET_NOT_FOUND = 0x66A,
	// The update package is not permitted by software restriction policy.
	PATCH_PACKAGE_REJECTED = 0x66B,
	// One or more customizations are not permitted by software restriction policy.
	INSTALL_TRANSFORM_REJECTED = 0x66C,
	// The Windows Installer does not permit installation from a Remote Desktop Connection.
	INSTALL_REMOTE_PROHIBITED = 0x66D,
	// Uninstallation of the update package is not supported.
	PATCH_REMOVAL_UNSUPPORTED = 0x66E,
	// The update is not applied to this product.
	UNKNOWN_PATCH = 0x66F,
	// No valid sequence could be found for the set of updates.
	PATCH_NO_SEQUENCE = 0x670,
	// Update removal was disallowed by policy.
	PATCH_REMOVAL_DISALLOWED = 0x671,
	// The XML update data is invalid.
	INVALID_PATCH_XML = 0x672,
	// Windows Installer does not permit updating of managed advertised products. At least one feature of the product must be installed before applying the update.
	PATCH_MANAGED_ADVERTISED_PRODUCT = 0x673,
	// The Windows Installer service is not accessible in Safe Mode. Please try again when your computer is not in Safe Mode or you can use System Restore to return your machine to a previous good state.
	INSTALL_SERVICE_SAFEBOOT = 0x674,
	// A fail fast exception occurred. Exception handlers will not be invoked and the process will be terminated immediately.
	FAIL_FAST_EXCEPTION = 0x675,
	// The app that you are trying to run is not supported on this version of Windows.
	INSTALL_REJECTED = 0x676,

	// The string binding is invalid.
	RPC_S_INVALID_STRING_BINDING = 0x6A4,
	// The binding handle is not the correct type.
	RPC_S_WRONG_KIND_OF_BINDING = 0x6A5,
	// The binding handle is invalid.
	RPC_S_INVALID_BINDING = 0x6A6,
	// The RPC protocol sequence is not supported.
	RPC_S_PROTSEQ_NOT_SUPPORTED = 0x6A7,
	// The RPC protocol sequence is invalid.
	RPC_S_INVALID_RPC_PROTSEQ = 0x6A8,
	// The string universal unique identifier (UUID) is invalid.
	RPC_S_INVALID_STRING_UUID = 0x6A9,
	// The endpoint format is invalid.
	RPC_S_INVALID_ENDPOINT_FORMAT = 0x6AA,
	// The network address is invalid.
	RPC_S_INVALID_NET_ADDR = 0x6AB,
	// No endpoint was found.
	RPC_S_NO_ENDPOINT_FOUND = 0x6AC,
	// The timeout value is invalid.
	RPC_S_INVALID_TIMEOUT = 0x6AD,
	// The object universal unique identifier (UUID) was not found.
	RPC_S_OBJECT_NOT_FOUND = 0x6AE,
	// The object universal unique identifier (UUID) has already been registered.
	RPC_S_ALREADY_REGISTERED = 0x6AF,
	// The type universal unique identifier (UUID) has already been registered.
	RPC_S_TYPE_ALREADY_REGISTERED = 0x6B0,
	// The RPC server is already listening.
	RPC_S_ALREADY_LISTENING = 0x6B1,
	// No protocol sequences have been registered.
	RPC_S_NO_PROTSEQS_REGISTERED = 0x6B2,
	// The RPC server is not listening.
	RPC_S_NOT_LISTENING = 0x6B3,
	// The manager type is unknown.
	RPC_S_UNKNOWN_MGR_TYPE = 0x6B4,
	// The interface is unknown.
	RPC_S_UNKNOWN_IF = 0x6B5,
	// There are no bindings.
	RPC_S_NO_BINDINGS = 0x6B6,
	// There are no protocol sequences.
	RPC_S_NO_PROTSEQS = 0x6B7,
	// The endpoint cannot be created.
	RPC_S_CANT_CREATE_ENDPOINT = 0x6B8,
	// Not enough resources are available to complete this operation.
	RPC_S_OUT_OF_RESOURCES = 0x6B9,
	// The RPC server is unavailable.
	RPC_S_SERVER_UNAVAILABLE = 0x6BA,
	// The RPC server is too busy to complete this operation.
	RPC_S_SERVER_TOO_BUSY = 0x6BB,
	// The network options are invalid.
	RPC_S_INVALID_NETWORK_OPTIONS = 0x6BC,
	// There are no remote procedure calls active on this thread.
	RPC_S_NO_CALL_ACTIVE = 0x6BD,
	// The remote procedure call failed.
	RPC_S_CALL_FAILED = 0x6BE,
	// The remote procedure call failed and did not execute.
	RPC_S_CALL_FAILED_DNE = 0x6BF,
	// A remote procedure call (RPC) protocol error occurred.
	RPC_S_PROTOCOL_ERROR = 0x6C0,
	// Access to the HTTP proxy is denied.
	RPC_S_PROXY_ACCESS_DENIED = 0x6C1,
	// The transfer syntax is not supported by the RPC server.
	RPC_S_UNSUPPORTED_TRANS_SYN = 0x6C2,
	// The universal unique identifier (UUID) type is not supported.
	RPC_S_UNSUPPORTED_TYPE = 0x6C4,
	// The tag is invalid.
	RPC_S_INVALID_TAG = 0x6C5,
	// The array bounds are invalid.
	RPC_S_INVALID_BOUND = 0x6C6,
	// The binding does not contain an entry name.
	RPC_S_NO_ENTRY_NAME = 0x6C7,
	// The name syntax is invalid.
	RPC_S_INVALID_NAME_SYNTAX = 0x6C8,
	// The name syntax is not supported.
	RPC_S_UNSUPPORTED_NAME_SYNTAX = 0x6C9,
	// No network address is available to use to construct a universal unique identifier (UUID).
	RPC_S_UUID_NO_ADDRESS = 0x6CB,
	// The endpoint is a duplicate.
	RPC_S_DUPLICATE_ENDPOINT = 0x6CC,
	// The authentication type is unknown.
	RPC_S_UNKNOWN_AUTHN_TYPE = 0x6CD,
	// The maximum number of calls is too small.
	RPC_S_MAX_CALLS_TOO_SMALL = 0x6CE,
	// The string is too long.
	RPC_S_STRING_TOO_LONG = 0x6CF,
	// The RPC protocol sequence was not found.
	RPC_S_PROTSEQ_NOT_FOUND = 0x6D0,
	// The procedure number is out of range.
	RPC_S_PROCNUM_OUT_OF_RANGE = 0x6D1,
	// The binding does not contain any authentication information.
	RPC_S_BINDING_HAS_NO_AUTH = 0x6D2,
	// The authentication service is unknown.
	RPC_S_UNKNOWN_AUTHN_SERVICE = 0x6D3,
	// The authentication level is unknown.
	RPC_S_UNKNOWN_AUTHN_LEVEL = 0x6D4,
	// The security context is invalid.
	RPC_S_INVALID_AUTH_IDENTITY = 0x6D5,
	// The authorization service is unknown.
	RPC_S_UNKNOWN_AUTHZ_SERVICE = 0x6D6,
	// The entry is invalid.
	EPT_S_INVALID_ENTRY = 0x6D7,
	// The server endpoint cannot perform the operation.
	EPT_S_CANT_PERFORM_OP = 0x6D8,
	// There are no more endpoints available from the endpoint mapper.
	EPT_S_NOT_REGISTERED = 0x6D9,
	// No interfaces have been exported.
	RPC_S_NOTHING_TO_EXPORT = 0x6DA,
	// The entry name is incomplete.
	RPC_S_INCOMPLETE_NAME = 0x6DB,
	// The version option is invalid.
	RPC_S_INVALID_VERS_OPTION = 0x6DC,
	// There are no more members.
	RPC_S_NO_MORE_MEMBERS = 0x6DD,
	// There is nothing to unexport.
	RPC_S_NOT_ALL_OBJS_UNEXPORTED = 0x6DE,
	// The interface was not found.
	RPC_S_INTERFACE_NOT_FOUND = 0x6DF,
	// The entry already exists.
	RPC_S_ENTRY_ALREADY_EXISTS = 0x6E0,
	// The entry is not found.
	RPC_S_ENTRY_NOT_FOUND = 0x6E1,
	// The name service is unavailable.
	RPC_S_NAME_SERVICE_UNAVAILABLE = 0x6E2,
	// The network address family is invalid.
	RPC_S_INVALID_NAF_ID = 0x6E3,
	// The requested operation is not supported.
	RPC_S_CANNOT_SUPPORT = 0x6E4,
	// No security context is available to allow impersonation.
	RPC_S_NO_CONTEXT_AVAILABLE = 0x6E5,
	// An internal error occurred in a remote procedure call (RPC).
	RPC_S_INTERNAL_ERROR = 0x6E6,
	// The RPC server attempted an integer division by zero.
	RPC_S_ZERO_DIVIDE = 0x6E7,
	// An addressing error occurred in the RPC server.
	RPC_S_ADDRESS_ERROR = 0x6E8,
	// A floating-point operation at the RPC server caused a division by zero.
	RPC_S_FP_DIV_ZERO = 0x6E9,
	// A floating-point underflow occurred at the RPC server.
	RPC_S_FP_UNDERFLOW = 0x6EA,
	// A floating-point overflow occurred at the RPC server.
	RPC_S_FP_OVERFLOW = 0x6EB,
	// The list of RPC servers available for the binding of auto handles has been exhausted.
	RPC_X_NO_MORE_ENTRIES = 0x6EC,
	// Unable to open the character translation table file.
	RPC_X_SS_CHAR_TRANS_OPEN_FAIL = 0x6ED,
	// The file containing the character translation table has fewer than 512 bytes.
	RPC_X_SS_CHAR_TRANS_SHORT_FILE = 0x6EE,
	// A null context handle was passed from the client to the host during a remote procedure call.
	RPC_X_SS_IN_NULL_CONTEXT = 0x6EF,
	// The context handle changed during a remote procedure call.
	RPC_X_SS_CONTEXT_DAMAGED = 0x6F1,
	// The binding handles passed to a remote procedure call do not match.
	RPC_X_SS_HANDLES_MISMATCH = 0x6F2,
	// The stub is unable to get the remote procedure call handle.
	RPC_X_SS_CANNOT_GET_CALL_HANDLE = 0x6F3,
	// A null reference pointer was passed to the stub.
	RPC_X_NULL_REF_POINTER = 0x6F4,
	// The enumeration value is out of range.
	RPC_X_ENUM_VALUE_OUT_OF_RANGE = 0x6F5,
	// The byte count is too small.
	RPC_X_BYTE_COUNT_TOO_SMALL = 0x6F6,
	// The stub received bad data.
	RPC_X_BAD_STUB_DATA = 0x6F7,
	// The supplied user buffer is not valid for the requested operation.
	INVALID_USER_BUFFER = 0x6F8,
	// The disk media is not recognized. It may not be formatted.
	UNRECOGNIZED_MEDIA = 0x6F9,
	// The workstation does not have a trust secret.
	NO_TRUST_LSA_SECRET = 0x6FA,
	// The security database on the server does not have a computer account for this workstation trust relationship.
	NO_TRUST_SAM_ACCOUNT = 0x6FB,
	// The trust relationship between the primary domain and the trusted domain failed.
	TRUSTED_DOMAIN_FAILURE = 0x6FC,
	// The trust relationship between this workstation and the primary domain failed.
	TRUSTED_RELATIONSHIP_FAILURE = 0x6FD,
	// The network logon failed.
	TRUST_FAILURE = 0x6FE,
	// A remote procedure call is already in progress for this thread.
	RPC_S_CALL_IN_PROGRESS = 0x6FF,
	// An attempt was made to logon, but the network logon service was not started.
	NETLOGON_NOT_STARTED = 0x700,
	// The user's account has expired.
	ACCOUNT_EXPIRED = 0x701,
	// The redirector is in use and cannot be unloaded.
	REDIRECTOR_HAS_OPEN_HANDLES = 0x702,
	// The specified printer driver is already installed.
	PRINTER_DRIVER_ALREADY_INSTALLED = 0x703,
	// The specified port is unknown.
	UNKNOWN_PORT = 0x704,
	// The printer driver is unknown.
	UNKNOWN_PRINTER_DRIVER = 0x705,
	// The print processor is unknown.
	UNKNOWN_PRINTPROCESSOR = 0x706,
	// The specified separator file is invalid.
	INVALID_SEPARATOR_FILE = 0x707,
	// The specified priority is invalid.
	INVALID_PRIORITY = 0x708,
	// The printer name is invalid.
	INVALID_PRINTER_NAME = 0x709,
	// The printer already exists.
	PRINTER_ALREADY_EXISTS = 0x70A,
	// The printer command is invalid.
	INVALID_PRINTER_COMMAND = 0x70B,
	// The specified datatype is invalid.
	INVALID_DATATYPE = 0x70C,
	// The environment specified is invalid.
	INVALID_ENVIRONMENT = 0x70D,
	// There are no more bindings.
	RPC_S_NO_MORE_BINDINGS = 0x70E,
	// The account used is an interdomain trust account. Use your global user account or local user account to access this server.
	NOLOGON_INTERDOMAIN_TRUST_ACCOUNT = 0x70F,
	// The account used is a computer account. Use your global user account or local user account to access this server.
	NOLOGON_WORKSTATION_TRUST_ACCOUNT = 0x710,
	// The account used is a server trust account. Use your global user account or local user account to access this server.
	NOLOGON_SERVER_TRUST_ACCOUNT = 0x711,
	// The name or security ID (SID) of the domain specified is inconsistent with the trust information for that domain.
	DOMAIN_TRUST_INCONSISTENT = 0x712,
	// The server is in use and cannot be unloaded.
	SERVER_HAS_OPEN_HANDLES = 0x713,
	// The specified image file did not contain a resource section.
	RESOURCE_DATA_NOT_FOUND = 0x714,
	// The specified resource type cannot be found in the image file.
	RESOURCE_TYPE_NOT_FOUND = 0x715,
	// The specified resource name cannot be found in the image file.
	RESOURCE_NAME_NOT_FOUND = 0x716,
	// The specified resource language ID cannot be found in the image file.
	RESOURCE_LANG_NOT_FOUND = 0x717,
	// Not enough quota is available to process this command.
	NOT_ENOUGH_QUOTA = 0x718,
	// No interfaces have been registered.
	RPC_S_NO_INTERFACES = 0x719,
	// The remote procedure call was cancelled.
	RPC_S_CALL_CANCELLED = 0x71A,
	// The binding handle does not contain all required information.
	RPC_S_BINDING_INCOMPLETE = 0x71B,
	// A communications failure occurred during a remote procedure call.
	RPC_S_COMM_FAILURE = 0x71C,
	// The requested authentication level is not supported.
	RPC_S_UNSUPPORTED_AUTHN_LEVEL = 0x71D,
	// No principal name registered.
	RPC_S_NO_PRINC_NAME = 0x71E,
	// The error specified is not a valid Windows RPC error code.
	RPC_S_NOT_RPC_ERROR = 0x71F,
	// A UUID that is valid only on this computer has been allocated.
	RPC_S_UUID_LOCAL_ONLY = 0x720,
	// A security package specific error occurred.
	RPC_S_SEC_PKG_ERROR = 0x721,
	// Thread is not canceled.
	RPC_S_NOT_CANCELLED = 0x722,
	// Invalid operation on the encoding/decoding handle.
	RPC_X_INVALID_ES_ACTION = 0x723,
	// Incompatible version of the serializing package.
	RPC_X_WRONG_ES_VERSION = 0x724,
	// Incompatible version of the RPC stub.
	RPC_X_WRONG_STUB_VERSION = 0x725,
	// The RPC pipe object is invalid or corrupted.
	RPC_X_INVALID_PIPE_OBJECT = 0x726,
	// An invalid operation was attempted on an RPC pipe object.
	RPC_X_WRONG_PIPE_ORDER = 0x727,
	// Unsupported RPC pipe version.
	RPC_X_WRONG_PIPE_VERSION = 0x728,
	// HTTP proxy server rejected the connection because the cookie authentication failed.
	RPC_S_COOKIE_AUTH_FAILED = 0x729,
	// The group member was not found.
	RPC_S_GROUP_MEMBER_NOT_FOUND = 0x76A,
	// The endpoint mapper database entry could not be created.
	EPT_S_CANT_CREATE = 0x76B,
	// The object universal unique identifier (UUID) is the nil UUID.
	RPC_S_INVALID_OBJECT = 0x76C,
	// The specified time is invalid.
	INVALID_TIME = 0x76D,
	// The specified form name is invalid.
	INVALID_FORM_NAME = 0x76E,
	// The specified form size is invalid.
	INVALID_FORM_SIZE = 0x76F,
	// The specified printer handle is already being waited on.
	ALREADY_WAITING = 0x770,
	// The specified printer has been deleted.
	PRINTER_DELETED = 0x771,
	// The state of the printer is invalid.
	INVALID_PRINTER_STATE = 0x772,
	// The user's password must be changed before signing in.
	PASSWORD_MUST_CHANGE = 0x773,
	// Could not find the domain controller for this domain.
	DOMAIN_CONTROLLER_NOT_FOUND = 0x774,
	// The referenced account is currently locked out and may not be logged on to.
	ACCOUNT_LOCKED_OUT = 0x775,
	// The object exporter specified was not found.
	OR_INVALID_OXID = 0x776,
	// The object specified was not found.
	OR_INVALID_OID = 0x777,
	// The object resolver set specified was not found.
	OR_INVALID_SET = 0x778,
	// Some data remains to be sent in the request buffer.
	RPC_S_SEND_INCOMPLETE = 0x779,
	// Invalid asynchronous remote procedure call handle.
	RPC_S_INVALID_ASYNC_HANDLE = 0x77A,
	// Invalid asynchronous RPC call handle for this operation.
	RPC_S_INVALID_ASYNC_CALL = 0x77B,
	// The RPC pipe object has already been closed.
	RPC_X_PIPE_CLOSED = 0x77C,
	// The RPC call completed before all pipes were processed.
	RPC_X_PIPE_DISCIPLINE_ERROR = 0x77D,
	// No more data is available from the RPC pipe.
	RPC_X_PIPE_EMPTY = 0x77E,
	// No site name is available for this machine.
	NO_SITENAME = 0x77F,
	// The file cannot be accessed by the system.
	CANT_ACCESS_FILE = 0x780,
	// The name of the file cannot be resolved by the system.
	CANT_RESOLVE_FILENAME = 0x781,
	// The entry is not of the expected type.
	RPC_S_ENTRY_TYPE_MISMATCH = 0x782,
	// Not all object UUIDs could be exported to the specified entry.
	RPC_S_NOT_ALL_OBJS_EXPORTED = 0x783,
	// Interface could not be exported to the specified entry.
	RPC_S_INTERFACE_NOT_EXPORTED = 0x784,
	// The specified profile entry could not be added.
	RPC_S_PROFILE_NOT_ADDED = 0x785,
	// The specified profile element could not be added.
	RPC_S_PRF_ELT_NOT_ADDED = 0x786,
	// The specified profile element could not be removed.
	RPC_S_PRF_ELT_NOT_REMOVED = 0x787,
	// The group element could not be added.
	RPC_S_GRP_ELT_NOT_ADDED = 0x788,
	// The group element could not be removed.
	RPC_S_GRP_ELT_NOT_REMOVED = 0x789,
	// The printer driver is not compatible with a policy enabled on your computer that blocks NT 4.0 drivers.
	KM_DRIVER_BLOCKED = 0x78A,
	// The context has expired and can no longer be used.
	CONTEXT_EXPIRED = 0x78B,
	// The current user's delegated trust creation quota has been exceeded.
	PER_USER_TRUST_QUOTA_EXCEEDED = 0x78C,
	// The total delegated trust creation quota has been exceeded.
	ALL_USER_TRUST_QUOTA_EXCEEDED = 0x78D,
	// The current user's delegated trust deletion quota has been exceeded.
	USER_DELETE_TRUST_QUOTA_EXCEEDED = 0x78E,
	// The computer you are signing into is protected by an authentication firewall. The specified account is not allowed to authenticate to the computer.
	AUTHENTICATION_FIREWALL_FAILED = 0x78F,
	// Remote connections to the Print Spooler are blocked by a policy set on your machine.
	REMOTE_PRINT_CONNECTIONS_BLOCKED = 0x790,
	// Authentication failed because NTLM authentication has been disabled.
	NTLM_BLOCKED = 0x791,
	// Logon Failure: EAS policy requires that the user change their password before this operation can be performed.
	PASSWORD_CHANGE_REQUIRED = 0x792,
	// The pixel format is invalid.
	INVALID_PIXEL_FORMAT = 0x7D0,
	// The specified driver is invalid.
	BAD_DRIVER = 0x7D1,
	// The window style or class attribute is invalid for this operation.
	INVALID_WINDOW_STYLE = 0x7D2,
	// The requested metafile operation is not supported.
	METAFILE_NOT_SUPPORTED = 0x7D3,
	// The requested transformation operation is not supported.
	TRANSFORM_NOT_SUPPORTED = 0x7D4,
	// The requested clipping operation is not supported.
	CLIPPING_NOT_SUPPORTED = 0x7D5,
	// The specified color management module is invalid.
	INVALID_CMM = 0x7DA,
	// The specified color profile is invalid.
	INVALID_PROFILE = 0x7DB,
	// The specified tag was not found.
	TAG_NOT_FOUND = 0x7DC,
	// A required tag is not present.
	TAG_NOT_PRESENT = 0x7DD,
	// The specified tag is already present.
	DUPLICATE_TAG = 0x7DE,
	// The specified color profile is not associated with the specified device.
	PROFILE_NOT_ASSOCIATED_WITH_DEVICE = 0x7DF,
	// The specified color profile was not found.
	PROFILE_NOT_FOUND = 0x7E0,
	// The specified color space is invalid.
	INVALID_COLORSPACE = 0x7E1,
	// Image Color Management is not enabled.
	ICM_NOT_ENABLED = 0x7E2,
	// There was an error while deleting the color transform.
	DELETING_ICM_XFORM = 0x7E3,
	// The specified color transform is invalid.
	INVALID_TRANSFORM = 0x7E4,
	// The specified transform does not match the bitmap's color space.
	COLORSPACE_MISMATCH = 0x7E5,
	// The specified named color index is not present in the profile.
	INVALID_COLORINDEX = 0x7E6,
	// The specified profile is intended for a device of a different type than the specified device.
	PROFILE_DOES_NOT_MATCH_DEVICE = 0x7E7,
	// The network connection was made successfully, but the user had to be prompted for a password other than the one originally specified.
	CONNECTED_OTHER_PASSWORD = 0x83C,
	// The network connection was made successfully using default credentials.
	CONNECTED_OTHER_PASSWORD_DEFAULT = 0x83D,
	// The specified username is invalid.
	BAD_USERNAME = 0x89A,
	// This network connection does not exist.
	NOT_CONNECTED = 0x8CA,
	// This network connection has files open or requests pending.
	OPEN_FILES = 0x961,
	// Active connections still exist.
	ACTIVE_CONNECTIONS = 0x962,
	// The device is in use by an active process and cannot be disconnected.
	DEVICE_IN_USE = 0x964,
	// The specified print monitor is unknown.
	UNKNOWN_PRINT_MONITOR = 0xBB8,
	// The specified printer driver is currently in use.
	PRINTER_DRIVER_IN_USE = 0xBB9,
	// The spool file was not found.
	SPOOL_FILE_NOT_FOUND = 0xBBA,
	// A StartDocPrinter call was not issued.
	SPL_NO_STARTDOC = 0xBBB,
	// An AddJob call was not issued.
	SPL_NO_ADDJOB = 0xBBC,
	// The specified print processor has already been installed.
	PRINT_PROCESSOR_ALREADY_INSTALLED = 0xBBD,
	// The specified print monitor has already been installed.
	PRINT_MONITOR_ALREADY_INSTALLED = 0xBBE,
	// The specified print monitor does not have the required functions.
	INVALID_PRINT_MONITOR = 0xBBF,
	// The specified print monitor is currently in use.
	PRINT_MONITOR_IN_USE = 0xBC0,
	// The requested operation is not allowed when there are jobs queued to the printer.
	PRINTER_HAS_JOBS_QUEUED = 0xBC1,
	// The requested operation is successful. Changes will not be effective until the system is rebooted.
	SUCCESS_REBOOT_REQUIRED = 0xBC2,
	// The requested operation is successful. Changes will not be effective until the service is restarted.
	SUCCESS_RESTART_REQUIRED = 0xBC3,
	// No printers were found.
	PRINTER_NOT_FOUND = 0xBC4,
	// The printer driver is known to be unreliable.
	PRINTER_DRIVER_WARNED = 0xBC5,
	// The printer driver is known to harm the system.
	PRINTER_DRIVER_BLOCKED = 0xBC6,
	// The specified printer driver package is currently in use.
	PRINTER_DRIVER_PACKAGE_IN_USE = 0xBC7,
	// Unable to find a core driver package that is required by the printer driver package.
	CORE_DRIVER_PACKAGE_NOT_FOUND = 0xBC8,
	// The requested operation failed. A system reboot is required to roll back changes made.
	FAIL_REBOOT_REQUIRED = 0xBC9,
	// The requested operation failed. A system reboot has been initiated to roll back changes made.
	FAIL_REBOOT_INITIATED = 0xBCA,
	// The specified printer driver was not found on the system and needs to be downloaded.
	PRINTER_DRIVER_DOWNLOAD_NEEDED = 0xBCB,
	// The requested print job has failed to print. A print system update requires the job to be resubmitted.
	PRINT_JOB_RESTART_REQUIRED = 0xBCC,
	// The printer driver does not contain a valid manifest, or contains too many manifests.
	INVALID_PRINTER_DRIVER_MANIFEST = 0xBCD,
	// The specified printer cannot be shared.
	PRINTER_NOT_SHAREABLE = 0xBCE,
	// The operation was paused.
	REQUEST_PAUSED = 0xBEA,
	// Reissue the given operation as a cached IO operation.
	IO_REISSUE_AS_CACHED = 0xF6E,

	// WINS encountered an error while processing the command.
	WINS_INTERNAL = 0xFA0,
	// The local WINS cannot be deleted.
	CAN_NOT_DEL_LOCAL_WINS = 0xFA1,
	// The importation from the file failed.
	STATIC_INIT = 0xFA2,
	// The backup failed. Was a full backup done before?
	INC_BACKUP = 0xFA3,
	// The backup failed. Check the directory to which you are backing the database.
	FULL_BACKUP = 0xFA4,
	// The name does not exist in the WINS database.
	REC_NON_EXISTENT = 0xFA5,
	// Replication with a nonconfigured partner is not allowed.
	RPL_NOT_ALLOWED = 0xFA6,
	// The version of the supplied content information is not supported.
	PEERDIST_ERROR_CONTENTINFO_VERSION_UNSUPPORTED = 0xFD2,
	// The supplied content information is malformed.
	PEERDIST_ERROR_CANNOT_PARSE_CONTENTINFO = 0xFD3,
	// The requested data cannot be found in local or peer caches.
	PEERDIST_ERROR_MISSING_DATA = 0xFD4,
	// No more data is available or required.
	PEERDIST_ERROR_NO_MORE = 0xFD5,
	// The supplied object has not been initialized.
	PEERDIST_ERROR_NOT_INITIALIZED = 0xFD6,
	// The supplied object has already been initialized.
	PEERDIST_ERROR_ALREADY_INITIALIZED = 0xFD7,
	// A shutdown operation is already in progress.
	PEERDIST_ERROR_SHUTDOWN_IN_PROGRESS = 0xFD8,
	// The supplied object has already been invalidated.
	PEERDIST_ERROR_INVALIDATED = 0xFD9,
	// An element already exists and was not replaced.
	PEERDIST_ERROR_ALREADY_EXISTS = 0xFDA,
	// Cannot cancel the requested operation as it has already been completed.
	PEERDIST_ERROR_OPERATION_NOTFOUND = 0xFDB,
	// Can not perform the reqested operation because it has already been carried out.
	PEERDIST_ERROR_ALREADY_COMPLETED = 0xFDC,
	// An operation accessed data beyond the bounds of valid data.
	PEERDIST_ERROR_OUT_OF_BOUNDS = 0xFDD,
	// The requested version is not supported.
	PEERDIST_ERROR_VERSION_UNSUPPORTED = 0xFDE,
	// A configuration value is invalid.
	PEERDIST_ERROR_INVALID_CONFIGURATION = 0xFDF,
	// The SKU is not licensed.
	PEERDIST_ERROR_NOT_LICENSED = 0xFE0,
	// PeerDist Service is still initializing and will be available shortly.
	PEERDIST_ERROR_SERVICE_UNAVAILABLE = 0xFE1,
	// Communication with one or more computers will be temporarily blocked due to recent errors.
	PEERDIST_ERROR_TRUST_FAILURE = 0xFE2,
	// The DHCP client has obtained an IP address that is already in use on the network. The local interface will be disabled until the DHCP client can obtain a new address.
	DHCP_ADDRESS_CONFLICT = 0x1004,
	// The GUID passed was not recognized as valid by a WMI data provider.
	WMI_GUID_NOT_FOUND = 0x1068,
	// The instance name passed was not recognized as valid by a WMI data provider.
	WMI_INSTANCE_NOT_FOUND = 0x1069,
	// The data item ID passed was not recognized as valid by a WMI data provider.
	WMI_ITEMID_NOT_FOUND = 0x106A,
	// The WMI request could not be completed and should be retried.
	WMI_TRY_AGAIN = 0x106B,
	// The WMI data provider could not be located.
	WMI_DP_NOT_FOUND = 0x106C,
	// The WMI data provider references an instance set that has not been registered.
	WMI_UNRESOLVED_INSTANCE_REF = 0x106D,
	// The WMI data block or event notification has already been enabled.
	WMI_ALREADY_ENABLED = 0x106E,
	// The WMI data block is no longer available.
	WMI_GUID_DISCONNECTED = 0x106F,
	// The WMI data service is not available.
	WMI_SERVER_UNAVAILABLE = 0x1070,
	// The WMI data provider failed to carry out the request.
	WMI_DP_FAILED = 0x1071,
	// The WMI MOF information is not valid.
	WMI_INVALID_MOF = 0x1072,
	// The WMI registration information is not valid.
	WMI_INVALID_REGINFO = 0x1073,
	// The WMI data block or event notification has already been disabled.
	WMI_ALREADY_DISABLED = 0x1074,
	// The WMI data item or data block is read only.
	WMI_READ_ONLY = 0x1075,
	// The WMI data item or data block could not be changed.
	WMI_SET_FAILURE = 0x1076,
	// This operation is only valid in the context of an app container.
	NOT_APPCONTAINER = 0x109A,
	// This application can only run in the context of an app container.
	APPCONTAINER_REQUIRED = 0x109B,
	// This functionality is not supported in the context of an app container.
	NOT_SUPPORTED_IN_APPCONTAINER = 0x109C,
	// The length of the SID supplied is not a valid length for app container SIDs.
	INVALID_PACKAGE_SID_LENGTH = 0x109D,
	// The media identifier does not represent a valid medium.
	INVALID_MEDIA = 0x10CC,
	// The library identifier does not represent a valid library.
	INVALID_LIBRARY = 0x10CD,
	// The media pool identifier does not represent a valid media pool.
	INVALID_MEDIA_POOL = 0x10CE,
	// The drive and medium are not compatible or exist in different libraries.
	DRIVE_MEDIA_MISMATCH = 0x10CF,
	// The medium currently exists in an offline library and must be online to perform this operation.
	MEDIA_OFFLINE = 0x10D0,
	// The operation cannot be performed on an offline library.
	LIBRARY_OFFLINE = 0x10D1,
	// The library, drive, or media pool is empty.
	EMPTY = 0x10D2,
	// The library, drive, or media pool must be empty to perform this operation.
	NOT_EMPTY = 0x10D3,
	// No media is currently available in this media pool or library.
	MEDIA_UNAVAILABLE = 0x10D4,
	// A resource required for this operation is disabled.
	RESOURCE_DISABLED = 0x10D5,
	// The media identifier does not represent a valid cleaner.
	INVALID_CLEANER = 0x10D6,
	// The drive cannot be cleaned or does not support cleaning.
	UNABLE_TO_CLEAN = 0x10D7,
	// The object identifier does not represent a valid object.
	OBJECT_NOT_FOUND = 0x10D8,
	// Unable to read from or write to the database.
	DATABASE_FAILURE = 0x10D9,
	// The database is full.
	DATABASE_FULL = 0x10DA,
	// The medium is not compatible with the device or media pool.
	MEDIA_INCOMPATIBLE = 0x10DB,
	// The resource required for this operation does not exist.
	RESOURCE_NOT_PRESENT = 0x10DC,
	// The operation identifier is not valid.
	INVALID_OPERATION = 0x10DD,
	// The media is not mounted or ready for use.
	MEDIA_NOT_AVAILABLE = 0x10DE,
	// The device is not ready for use.
	DEVICE_NOT_AVAILABLE = 0x10DF,
	// The operator or administrator has refused the request.
	REQUEST_REFUSED = 0x10E0,
	// The drive identifier does not represent a valid drive.
	INVALID_DRIVE_OBJECT = 0x10E1,
	// Library is full. No slot is available for use.
	LIBRARY_FULL = 0x10E2,
	// The transport cannot access the medium.
	MEDIUM_NOT_ACCESSIBLE = 0x10E3,
	// Unable to load the medium into the drive.
	UNABLE_TO_LOAD_MEDIUM = 0x10E4,
	// Unable to retrieve the drive status.
	UNABLE_TO_INVENTORY_DRIVE = 0x10E5,
	// Unable to retrieve the slot status.
	UNABLE_TO_INVENTORY_SLOT = 0x10E6,
	// Unable to retrieve status about the transport.
	UNABLE_TO_INVENTORY_TRANSPORT = 0x10E7,
	// Cannot use the transport because it is already in use.
	TRANSPORT_FULL = 0x10E8,
	// Unable to open or close the inject/eject port.
	CONTROLLING_IEPORT = 0x10E9,
	// Unable to eject the medium because it is in a drive.
	UNABLE_TO_EJECT_MOUNTED_MEDIA = 0x10EA,
	// A cleaner slot is already reserved.
	CLEANER_SLOT_SET = 0x10EB,
	// A cleaner slot is not reserved.
	CLEANER_SLOT_NOT_SET = 0x10EC,
	// The cleaner cartridge has performed the maximum number of drive cleanings.
	CLEANER_CARTRIDGE_SPENT = 0x10ED,
	// Unexpected on-medium identifier.
	UNEXPECTED_OMID = 0x10EE,
	// The last remaining item in this group or resource cannot be deleted.
	CANT_DELETE_LAST_ITEM = 0x10EF,
	// The message provided exceeds the maximum size allowed for this parameter.
	MESSAGE_EXCEEDS_MAX_SIZE = 0x10F0,
	// The volume contains system or paging files.
	VOLUME_CONTAINS_SYS_FILES = 0x10F1,
	// The media type cannot be removed from this library since at least one drive in the library reports it can support this media type.
	INDIGENOUS_TYPE = 0x10F2,
	// This offline media cannot be mounted on this system since no enabled drives are present which can be used.
	NO_SUPPORTING_DRIVES = 0x10F3,
	// A cleaner cartridge is present in the tape library.
	CLEANER_CARTRIDGE_INSTALLED = 0x10F4,
	// Cannot use the inject/eject port because it is not empty.
	IEPORT_FULL = 0x10F5,
	// This file is currently not available for use on this computer.
	FILE_OFFLINE = 0x10FE,
	// The remote storage service is not operational at this time.
	REMOTE_STORAGE_NOT_ACTIVE = 0x10FF,
	// The remote storage service encountered a media error.
	REMOTE_STORAGE_MEDIA_ERROR = 0x1100,
	// The file or directory is not a reparse point.
	NOT_A_REPARSE_POINT = 0x1126,
	// The reparse point attribute cannot be set because it conflicts with an existing attribute.
	REPARSE_ATTRIBUTE_CONFLICT = 0x1127,
	// The data present in the reparse point buffer is invalid.
	INVALID_REPARSE_DATA = 0x1128,
	// The tag present in the reparse point buffer is invalid.
	REPARSE_TAG_INVALID = 0x1129,
	// There is a mismatch between the tag specified in the request and the tag present in the reparse point.
	REPARSE_TAG_MISMATCH = 0x112A,
	// Fast Cache data not found.
	APP_DATA_NOT_FOUND = 0x1130,
	// Fast Cache data expired.
	APP_DATA_EXPIRED = 0x1131,
	// Fast Cache data corrupt.
	APP_DATA_CORRUPT = 0x1132,
	// Fast Cache data has exceeded its max size and cannot be updated.
	APP_DATA_LIMIT_EXCEEDED = 0x1133,
	// Fast Cache has been ReArmed and requires a reboot until it can be updated.
	APP_DATA_REBOOT_REQUIRED = 0x1134,
	// Secure Boot detected that rollback of protected data has been attempted.
	SECUREBOOT_ROLLBACK_DETECTED = 0x1144,
	// The value is protected by Secure Boot policy and cannot be modified or deleted.
	SECUREBOOT_POLICY_VIOLATION = 0x1145,
	// The Secure Boot policy is invalid.
	SECUREBOOT_INVALID_POLICY = 0x1146,
	// A new Secure Boot policy did not contain the current publisher on its update list.
	SECUREBOOT_POLICY_PUBLISHER_NOT_FOUND = 0x1147,
	// The Secure Boot policy is either not signed or is signed by a non-trusted signer.
	SECUREBOOT_POLICY_NOT_SIGNED = 0x1148,
	// Secure Boot is not enabled on this machine.
	SECUREBOOT_NOT_ENABLED = 0x1149,
	// Secure Boot requires that certain files and drivers are not replaced by other files or drivers.
	SECUREBOOT_FILE_REPLACED = 0x114A,
	// The copy offload read operation is not supported by a filter.
	OFFLOAD_READ_FLT_NOT_SUPPORTED = 0x1158,
	// The copy offload write operation is not supported by a filter.
	OFFLOAD_WRITE_FLT_NOT_SUPPORTED = 0x1159,
	// The copy offload read operation is not supported for the file.
	OFFLOAD_READ_FILE_NOT_SUPPORTED = 0x115A,
	// The copy offload write operation is not supported for the file.
	OFFLOAD_WRITE_FILE_NOT_SUPPORTED = 0x115B,
	// Single Instance Storage is not available on this volume.
	VOLUME_NOT_SIS_ENABLED = 0x1194,
	// The operation cannot be completed because other resources are dependent on this resource.
	DEPENDENT_RESOURCE_EXISTS = 0x1389,
	// The cluster resource dependency cannot be found.
	DEPENDENCY_NOT_FOUND = 0x138A,
	// The cluster resource cannot be made dependent on the specified resource because it is already dependent.
	DEPENDENCY_ALREADY_EXISTS = 0x138B,
	// The cluster resource is not online.
	RESOURCE_NOT_ONLINE = 0x138C,
	// A cluster node is not available for this operation.
	HOST_NODE_NOT_AVAILABLE = 0x138D,
	// The cluster resource is not available.
	RESOURCE_NOT_AVAILABLE = 0x138E,
	// The cluster resource could not be found.
	RESOURCE_NOT_FOUND = 0x138F,
	// The cluster is being shut down.
	SHUTDOWN_CLUSTER = 0x1390,
	// A cluster node cannot be evicted from the cluster unless the node is down or it is the last node.
	CANT_EVICT_ACTIVE_NODE = 0x1391,
	// The object already exists.
	OBJECT_ALREADY_EXISTS = 0x1392,
	// The object is already in the list.
	OBJECT_IN_LIST = 0x1393,
	// The cluster group is not available for any new requests.
	GROUP_NOT_AVAILABLE = 0x1394,
	// The cluster group could not be found.
	GROUP_NOT_FOUND = 0x1395,
	// The operation could not be completed because the cluster group is not online.
	GROUP_NOT_ONLINE = 0x1396,
	// The operation failed because either the specified cluster node is not the owner of the resource, or the node is not a possible owner of the resource.
	HOST_NODE_NOT_RESOURCE_OWNER = 0x1397,
	// The operation failed because either the specified cluster node is not the owner of the group, or the node is not a possible owner of the group.
	HOST_NODE_NOT_GROUP_OWNER = 0x1398,
	// The cluster resource could not be created in the specified resource monitor.
	RESMON_CREATE_FAILED = 0x1399,
	// The cluster resource could not be brought online by the resource monitor.
	RESMON_ONLINE_FAILED = 0x139A,
	// The operation could not be completed because the cluster resource is online.
	RESOURCE_ONLINE = 0x139B,
	// The cluster resource could not be deleted or brought offline because it is the quorum resource.
	QUORUM_RESOURCE = 0x139C,
	// The cluster could not make the specified resource a quorum resource because it is not capable of being a quorum resource.
	NOT_QUORUM_CAPABLE = 0x139D,
	// The cluster software is shutting down.
	CLUSTER_SHUTTING_DOWN = 0x139E,
	// The group or resource is not in the correct state to perform the requested operation.
	INVALID_STATE = 0x139F,
	// The properties were stored but not all changes will take effect until the next time the resource is brought online.
	RESOURCE_PROPERTIES_STORED = 0x13A0,
	// The cluster could not make the specified resource a quorum resource because it does not belong to a shared storage class.
	NOT_QUORUM_CLASS = 0x13A1,
	// The cluster resource could not be deleted since it is a core resource.
	CORE_RESOURCE = 0x13A2,
	// The quorum resource failed to come online.
	QUORUM_RESOURCE_ONLINE_FAILED = 0x13A3,
	// The quorum log could not be created or mounted successfully.
	QUORUMLOG_OPEN_FAILED = 0x13A4,
	// The cluster log is corrupt.
	CLUSTERLOG_CORRUPT = 0x13A5,
	// The record could not be written to the cluster log since it exceeds the maximum size.
	CLUSTERLOG_RECORD_EXCEEDS_MAXSIZE = 0x13A6,
	// The cluster log exceeds its maximum size.
	CLUSTERLOG_EXCEEDS_MAXSIZE = 0x13A7,
	// No checkpoint record was found in the cluster log.
	CLUSTERLOG_CHKPOINT_NOT_FOUND = 0x13A8,
	// The minimum required disk space needed for logging is not available.
	CLUSTERLOG_NOT_ENOUGH_SPACE = 0x13A9,
	// The cluster node failed to take control of the quorum resource because the resource is owned by another active node.
	QUORUM_OWNER_ALIVE = 0x13AA,
	// A cluster network is not available for this operation.
	NETWORK_NOT_AVAILABLE = 0x13AB,
	// A cluster node is not available for this operation.
	NODE_NOT_AVAILABLE = 0x13AC,
	// All cluster nodes must be running to perform this operation.
	ALL_NODES_NOT_AVAILABLE = 0x13AD,
	// A cluster resource failed.
	RESOURCE_FAILED = 0x13AE,
	// The cluster node is not valid.
	CLUSTER_INVALID_NODE = 0x13AF,
	// The cluster node already exists.
	CLUSTER_NODE_EXISTS = 0x13B0,
	// A node is in the process of joining the cluster.
	CLUSTER_JOIN_IN_PROGRESS = 0x13B1,
	// The cluster node was not found.
	CLUSTER_NODE_NOT_FOUND = 0x13B2,
	// The cluster local node information was not found.
	CLUSTER_LOCAL_NODE_NOT_FOUND = 0x13B3,
	// The cluster network already exists.
	CLUSTER_NETWORK_EXISTS = 0x13B4,
	// The cluster network was not found.
	CLUSTER_NETWORK_NOT_FOUND = 0x13B5,
	// The cluster network interface already exists.
	CLUSTER_NETINTERFACE_EXISTS = 0x13B6,
	// The cluster network interface was not found.
	CLUSTER_NETINTERFACE_NOT_FOUND = 0x13B7,
	// The cluster request is not valid for this object.
	CLUSTER_INVALID_REQUEST = 0x13B8,
	// The cluster network provider is not valid.
	CLUSTER_INVALID_NETWORK_PROVIDER = 0x13B9,
	// The cluster node is down.
	CLUSTER_NODE_DOWN = 0x13BA,
	// The cluster node is not reachable.
	CLUSTER_NODE_UNREACHABLE = 0x13BB,
	// The cluster node is not a member of the cluster.
	CLUSTER_NODE_NOT_MEMBER = 0x13BC,
	// A cluster join operation is not in progress.
	CLUSTER_JOIN_NOT_IN_PROGRESS = 0x13BD,
	// The cluster network is not valid.
	CLUSTER_INVALID_NETWORK = 0x13BE,
	// The cluster node is up.
	CLUSTER_NODE_UP = 0x13C0,
	// The cluster IP address is already in use.
	CLUSTER_IPADDR_IN_USE = 0x13C1,
	// The cluster node is not paused.
	CLUSTER_NODE_NOT_PAUSED = 0x13C2,
	// No cluster security context is available.
	CLUSTER_NO_SECURITY_CONTEXT = 0x13C3,
	// The cluster network is not configured for internal cluster communication.
	CLUSTER_NETWORK_NOT_INTERNAL = 0x13C4,
	// The cluster node is already up.
	CLUSTER_NODE_ALREADY_UP = 0x13C5,
	// The cluster node is already down.
	CLUSTER_NODE_ALREADY_DOWN = 0x13C6,
	// The cluster network is already online.
	CLUSTER_NETWORK_ALREADY_ONLINE = 0x13C7,
	// The cluster network is already offline.
	CLUSTER_NETWORK_ALREADY_OFFLINE = 0x13C8,
	// The cluster node is already a member of the cluster.
	CLUSTER_NODE_ALREADY_MEMBER = 0x13C9,
	// The cluster network is the only one configured for internal cluster communication between two or more active cluster nodes. The internal communication capability cannot be removed from the network.
	CLUSTER_LAST_INTERNAL_NETWORK = 0x13CA,
	// One or more cluster resources depend on the network to provide service to clients. The client access capability cannot be removed from the network.
	CLUSTER_NETWORK_HAS_DEPENDENTS = 0x13CB,
	// This operation cannot be performed on the cluster resource as it the quorum resource. You may not bring the quorum resource offline or modify its possible owners list.
	INVALID_OPERATION_ON_QUORUM = 0x13CC,
	// The cluster quorum resource is not allowed to have any dependencies.
	DEPENDENCY_NOT_ALLOWED = 0x13CD,
	// The cluster node is paused.
	CLUSTER_NODE_PAUSED = 0x13CE,
	// The cluster resource cannot be brought online. The owner node cannot run this resource.
	NODE_CANT_HOST_RESOURCE = 0x13CF,
	// The cluster node is not ready to perform the requested operation.
	CLUSTER_NODE_NOT_READY = 0x13D0,
	// The cluster node is shutting down.
	CLUSTER_NODE_SHUTTING_DOWN = 0x13D1,
	// The cluster join operation was aborted.
	CLUSTER_JOIN_ABORTED = 0x13D2,
	// The cluster join operation failed due to incompatible software versions between the joining node and its sponsor.
	CLUSTER_INCOMPATIBLE_VERSIONS = 0x13D3,
	// This resource cannot be created because the cluster has reached the limit on the number of resources it can monitor.
	CLUSTER_MAXNUM_OF_RESOURCES_EXCEEDED = 0x13D4,
	// The system configuration changed during the cluster join or form operation. The join or form operation was aborted.
	CLUSTER_SYSTEM_CONFIG_CHANGED = 0x13D5,
	// The specified resource type was not found.
	CLUSTER_RESOURCE_TYPE_NOT_FOUND = 0x13D6,
	// The specified node does not support a resource of this type. This may be due to version inconsistencies or due to the absence of the resource DLL on this node.
	CLUSTER_RESTYPE_NOT_SUPPORTED = 0x13D7,
	// The specified resource name is not supported by this resource DLL. This may be due to a bad (or changed) name supplied to the resource DLL.
	CLUSTER_RESNAME_NOT_FOUND = 0x13D8,
	// No authentication package could be registered with the RPC server.
	CLUSTER_NO_RPC_PACKAGES_REGISTERED = 0x13D9,
	// You cannot bring the group online because the owner of the group is not in the preferred list for the group. To change the owner node for the group, move the group.
	CLUSTER_OWNER_NOT_IN_PREFLIST = 0x13DA,
	// The join operation failed because the cluster database sequence number has changed or is incompatible with the locker node. This may happen during a join operation if the cluster database was changing during the join.
	CLUSTER_DATABASE_SEQMISMATCH = 0x13DB,
	// The resource monitor will not allow the fail operation to be performed while the resource is in its current state. This may happen if the resource is in a pending state.
	RESMON_INVALID_STATE = 0x13DC,
	// A non locker code got a request to reserve the lock for making global updates.
	CLUSTER_GUM_NOT_LOCKER = 0x13DD,
	// The quorum disk could not be located by the cluster service.
	QUORUM_DISK_NOT_FOUND = 0x13DE,
	// The backed up cluster database is possibly corrupt.
	DATABASE_BACKUP_CORRUPT = 0x13DF,
	// A DFS root already exists in this cluster node.
	CLUSTER_NODE_ALREADY_HAS_DFS_ROOT = 0x13E0,
	// An attempt to modify a resource property failed because it conflicts with another existing property.
	RESOURCE_PROPERTY_UNCHANGEABLE = 0x13E1,
	// An operation was attempted that is incompatible with the current membership state of the node.
	CLUSTER_MEMBERSHIP_INVALID_STATE = 0x1702,
	// The quorum resource does not contain the quorum log.
	CLUSTER_QUORUMLOG_NOT_FOUND = 0x1703,
	// The membership engine requested shutdown of the cluster service on this node.
	CLUSTER_MEMBERSHIP_HALT = 0x1704,
	// The join operation failed because the cluster instance ID of the joining node does not match the cluster instance ID of the sponsor node.
	CLUSTER_INSTANCE_ID_MISMATCH = 0x1705,
	// A matching cluster network for the specified IP address could not be found.
	CLUSTER_NETWORK_NOT_FOUND_FOR_IP = 0x1706,
	// The actual data type of the property did not match the expected data type of the property.
	CLUSTER_PROPERTY_DATA_TYPE_MISMATCH = 0x1707,
	// The cluster node was evicted from the cluster successfully, but the node was not cleaned up. To determine what cleanup steps failed and how to recover, see the Failover Clustering application event log using Event Viewer.
	CLUSTER_EVICT_WITHOUT_CLEANUP = 0x1708,
	// Two or more parameter values specified for a resource's properties are in conflict.
	CLUSTER_PARAMETER_MISMATCH = 0x1709,
	// This computer cannot be made a member of a cluster.
	NODE_CANNOT_BE_CLUSTERED = 0x170A,
	// This computer cannot be made a member of a cluster because it does not have the correct version of Windows installed.
	CLUSTER_WRONG_OS_VERSION = 0x170B,
	// A cluster cannot be created with the specified cluster name because that cluster name is already in use. Specify a different name for the cluster.
	CLUSTER_CANT_CREATE_DUP_CLUSTER_NAME = 0x170C,
	// The cluster configuration action has already been committed.
	CLUSCFG_ALREADY_COMMITTED = 0x170D,
	// The cluster configuration action could not be rolled back.
	CLUSCFG_ROLLBACK_FAILED = 0x170E,
	// The drive letter assigned to a system disk on one node conflicted with the drive letter assigned to a disk on another node.
	CLUSCFG_SYSTEM_DISK_DRIVE_LETTER_CONFLICT = 0x170F,
	// One or more nodes in the cluster are running a version of Windows that does not support this operation.
	CLUSTER_OLD_VERSION = 0x1710,
	// The name of the corresponding computer account doesn't match the Network Name for this resource.
	CLUSTER_MISMATCHED_COMPUTER_ACCT_NAME = 0x1711,
	// No network adapters are available.
	CLUSTER_NO_NET_ADAPTERS = 0x1712,
	// The cluster node has been poisoned.
	CLUSTER_POISONED = 0x1713,
	// The group is unable to accept the request since it is moving to another node.
	CLUSTER_GROUP_MOVING = 0x1714,
	// The resource type cannot accept the request since is too busy performing another operation.
	CLUSTER_RESOURCE_TYPE_BUSY = 0x1715,
	// The call to the cluster resource DLL timed out.
	RESOURCE_CALL_TIMED_OUT = 0x1716,
	// The address is not valid for an IPv6 Address resource. A global IPv6 address is required, and it must match a cluster network. Compatibility addresses are not permitted.
	INVALID_CLUSTER_IPV6_ADDRESS = 0x1717,
	// An internal cluster error occurred. A call to an invalid function was attempted.
	CLUSTER_INTERNAL_INVALID_FUNCTION = 0x1718,
	// A parameter value is out of acceptable range.
	CLUSTER_PARAMETER_OUT_OF_BOUNDS = 0x1719,
	// A network error occurred while sending data to another node in the cluster. The number of bytes transmitted was less than required.
	CLUSTER_PARTIAL_SEND = 0x171A,
	// An invalid cluster registry operation was attempted.
	CLUSTER_REGISTRY_INVALID_FUNCTION = 0x171B,
	// An input string of characters is not properly terminated.
	CLUSTER_INVALID_STRING_TERMINATION = 0x171C,
	// An input string of characters is not in a valid format for the data it represents.
	CLUSTER_INVALID_STRING_FORMAT = 0x171D,
	// An internal cluster error occurred. A cluster database transaction was attempted while a transaction was already in progress.
	CLUSTER_DATABASE_TRANSACTION_IN_PROGRESS = 0x171E,
	// An internal cluster error occurred. There was an attempt to commit a cluster database transaction while no transaction was in progress.
	CLUSTER_DATABASE_TRANSACTION_NOT_IN_PROGRESS = 0x171F,
	// An internal cluster error occurred. Data was not properly initialized.
	CLUSTER_NULL_DATA = 0x1720,
	// An error occurred while reading from a stream of data. An unexpected number of bytes was returned.
	CLUSTER_PARTIAL_READ = 0x1721,
	// An error occurred while writing to a stream of data. The required number of bytes could not be written.
	CLUSTER_PARTIAL_WRITE = 0x1722,
	// An error occurred while deserializing a stream of cluster data.
	CLUSTER_CANT_DESERIALIZE_DATA = 0x1723,
	// One or more property values for this resource are in conflict with one or more property values associated with its dependent resource(s).
	DEPENDENT_RESOURCE_PROPERTY_CONFLICT = 0x1724,
	// A quorum of cluster nodes was not present to form a cluster.
	CLUSTER_NO_QUORUM = 0x1725,
	// The cluster network is not valid for an IPv6 Address resource, or it does not match the configured address.
	CLUSTER_INVALID_IPV6_NETWORK = 0x1726,
	// The cluster network is not valid for an IPv6 Tunnel resource. Check the configuration of the IP Address resource on which the IPv6 Tunnel resource depends.
	CLUSTER_INVALID_IPV6_TUNNEL_NETWORK = 0x1727,
	// Quorum resource cannot reside in the Available Storage group.
	QUORUM_NOT_ALLOWED_IN_THIS_GROUP = 0x1728,
	// The dependencies for this resource are nested too deeply.
	DEPENDENCY_TREE_TOO_COMPLEX = 0x1729,
	// The call into the resource DLL raised an unhandled exception.
	EXCEPTION_IN_RESOURCE_CALL = 0x172A,
	// The RHS process failed to initialize.
	CLUSTER_RHS_FAILED_INITIALIZATION = 0x172B,
	// The Failover Clustering feature is not installed on this node.
	CLUSTER_NOT_INSTALLED = 0x172C,
	// The resources must be online on the same node for this operation.
	CLUSTER_RESOURCES_MUST_BE_ONLINE_ON_THE_SAME_NODE = 0x172D,
	// A new node can not be added since this cluster is already at its maximum number of nodes.
	CLUSTER_MAX_NODES_IN_CLUSTER = 0x172E,
	// This cluster can not be created since the specified number of nodes exceeds the maximum allowed limit.
	CLUSTER_TOO_MANY_NODES = 0x172F,
	// An attempt to use the specified cluster name failed because an enabled computer object with the given name already exists in the domain.
	CLUSTER_OBJECT_ALREADY_USED = 0x1730,
	// This cluster cannot be destroyed. It has non-core application groups which must be deleted before the cluster can be destroyed.
	NONCORE_GROUPS_FOUND = 0x1731,
	// File share associated with file share witness resource cannot be hosted by this cluster or any of its nodes.
	FILE_SHARE_RESOURCE_CONFLICT = 0x1732,
	// Eviction of this node is invalid at this time. Due to quorum requirements node eviction will result in cluster shutdown. If it is the last node in the cluster, destroy cluster command should be used.
	CLUSTER_EVICT_INVALID_REQUEST = 0x1733,
	// Only one instance of this resource type is allowed in the cluster.
	CLUSTER_SINGLETON_RESOURCE = 0x1734,
	// Only one instance of this resource type is allowed per resource group.
	CLUSTER_GROUP_SINGLETON_RESOURCE = 0x1735,
	// The resource failed to come online due to the failure of one or more provider resources.
	CLUSTER_RESOURCE_PROVIDER_FAILED = 0x1736,
	// The resource has indicated that it cannot come online on any node.
	CLUSTER_RESOURCE_CONFIGURATION_ERROR = 0x1737,
	// The current operation cannot be performed on this group at this time.
	CLUSTER_GROUP_BUSY = 0x1738,
	// The directory or file is not located on a cluster shared volume.
	CLUSTER_NOT_SHARED_VOLUME = 0x1739,
	// The Security Descriptor does not meet the requirements for a cluster.
	CLUSTER_INVALID_SECURITY_DESCRIPTOR = 0x173A,
	// There is one or more shared volumes resources configured in the cluster. Those resources must be moved to available storage in order for operation to succeed.
	CLUSTER_SHARED_VOLUMES_IN_USE = 0x173B,
	// This group or resource cannot be directly manipulated. Use shared volume APIs to perform desired operation.
	CLUSTER_USE_SHARED_VOLUMES_API = 0x173C,
	// Back up is in progress. Please wait for backup completion before trying this operation again.
	CLUSTER_BACKUP_IN_PROGRESS = 0x173D,
	// The path does not belong to a cluster shared volume.
	NON_CSV_PATH = 0x173E,
	// The cluster shared volume is not locally mounted on this node.
	CSV_VOLUME_NOT_LOCAL = 0x173F,
	// The cluster watchdog is terminating.
	CLUSTER_WATCHDOG_TERMINATING = 0x1740,
	// A resource vetoed a move between two nodes because they are incompatible.
	CLUSTER_RESOURCE_VETOED_MOVE_INCOMPATIBLE_NODES = 0x1741,
	// The request is invalid either because node weight cannot be changed while the cluster is in disk-only quorum mode, or because changing the node weight would violate the minimum cluster quorum requirements.
	CLUSTER_INVALID_NODE_WEIGHT = 0x1742,
	// The resource vetoed the call.
	CLUSTER_RESOURCE_VETOED_CALL = 0x1743,
	// Resource could not start or run because it could not reserve sufficient system resources.
	RESMON_SYSTEM_RESOURCES_LACKING = 0x1744,
	// A resource vetoed a move between two nodes because the destination currently does not have enough resources to complete the operation.
	CLUSTER_RESOURCE_VETOED_MOVE_NOT_ENOUGH_RESOURCES_ON_DESTINATION = 0x1745,
	// A resource vetoed a move between two nodes because the source currently does not have enough resources to complete the operation.
	CLUSTER_RESOURCE_VETOED_MOVE_NOT_ENOUGH_RESOURCES_ON_SOURCE = 0x1746,
	// The requested operation can not be completed because the group is queued for an operation.
	CLUSTER_GROUP_QUEUED = 0x1747,
	// The requested operation can not be completed because a resource has locked status.
	CLUSTER_RESOURCE_LOCKED_STATUS = 0x1748,
	// The resource cannot move to another node because a cluster shared volume vetoed the operation.
	CLUSTER_SHARED_VOLUME_FAILOVER_NOT_ALLOWED = 0x1749,
	// A node drain is already in progress.
	// This value was also named ERROR_CLUSTER_NODE_EVACUATION_IN_PROGRESS
	CLUSTER_NODE_DRAIN_IN_PROGRESS = 0x174A,
	// Clustered storage is not connected to the node.
	CLUSTER_DISK_NOT_CONNECTED = 0x174B,
	// The disk is not configured in a way to be used with CSV. CSV disks must have at least one partition that is formatted with NTFS.
	DISK_NOT_CSV_CAPABLE = 0x174C,
	// The resource must be part of the Available Storage group to complete this action.
	RESOURCE_NOT_IN_AVAILABLE_STORAGE = 0x174D,
	// CSVFS failed operation as volume is in redirected mode.
	CLUSTER_SHARED_VOLUME_REDIRECTED = 0x174E,
	// CSVFS failed operation as volume is not in redirected mode.
	CLUSTER_SHARED_VOLUME_NOT_REDIRECTED = 0x174F,
	// Cluster properties cannot be returned at this time.
	CLUSTER_CANNOT_RETURN_PROPERTIES = 0x1750,
	// The clustered disk resource contains software snapshot diff area that are not supported for Cluster Shared Volumes.
	CLUSTER_RESOURCE_CONTAINS_UNSUPPORTED_DIFF_AREA_FOR_SHARED_VOLUMES = 0x1751,
	// The operation cannot be completed because the resource is in maintenance mode.
	CLUSTER_RESOURCE_IS_IN_MAINTENANCE_MODE = 0x1752,
	// The operation cannot be completed because of cluster affinity conflicts.
	CLUSTER_AFFINITY_CONFLICT = 0x1753,
	// The operation cannot be completed because the resource is a replica virtual machine.
	CLUSTER_RESOURCE_IS_REPLICA_VIRTUAL_MACHINE = 0x1754,

	// The specified file could not be encrypted.
	ENCRYPTION_FAILED = 0x1770,
	// The specified file could not be decrypted.
	DECRYPTION_FAILED = 0x1771,
	// The specified file is encrypted and the user does not have the ability to decrypt it.
	FILE_ENCRYPTED = 0x1772,
	// There is no valid encryption recovery policy configured for this system.
	NO_RECOVERY_POLICY = 0x1773,
	// The required encryption driver is not loaded for this system.
	NO_EFS = 0x1774,
	// The file was encrypted with a different encryption driver than is currently loaded.
	WRONG_EFS = 0x1775,
	// There are no EFS keys defined for the user.
	NO_USER_KEYS = 0x1776,
	// The specified file is not encrypted.
	FILE_NOT_ENCRYPTED = 0x1777,
	// The specified file is not in the defined EFS export format.
	NOT_EXPORT_FORMAT = 0x1778,
	// The specified file is read only.
	FILE_READ_ONLY = 0x1779,
	// The directory has been disabled for encryption.
	DIR_EFS_DISALLOWED = 0x177A,
	// The server is not trusted for remote encryption operation.
	EFS_SERVER_NOT_TRUSTED = 0x177B,
	// Recovery policy configured for this system contains invalid recovery certificate.
	BAD_RECOVERY_POLICY = 0x177C,
	// The encryption algorithm used on the source file needs a bigger key buffer than the one on the destination file.
	EFS_ALG_BLOB_TOO_BIG = 0x177D,
	// The disk partition does not support file encryption.
	VOLUME_NOT_SUPPORT_EFS = 0x177E,
	// This machine is disabled for file encryption.
	EFS_DISABLED = 0x177F,
	// A newer system is required to decrypt this encrypted file.
	EFS_VERSION_NOT_SUPPORT = 0x1780,
	// The remote server sent an invalid response for a file being opened with Client Side Encryption.
	CS_ENCRYPTION_INVALID_SERVER_RESPONSE = 0x1781,
	// Client Side Encryption is not supported by the remote server even though it claims to support it.
	CS_ENCRYPTION_UNSUPPORTED_SERVER = 0x1782,
	// File is encrypted and should be opened in Client Side Encryption mode.
	CS_ENCRYPTION_EXISTING_ENCRYPTED_FILE = 0x1783,
	// A new encrypted file is being created and a $EFS needs to be provided.
	CS_ENCRYPTION_NEW_ENCRYPTED_FILE = 0x1784,
	// The SMB client requested a CSE FSCTL on a non-CSE file.
	CS_ENCRYPTION_FILE_NOT_CSE = 0x1785,
	// The requested operation was blocked by policy. For more information, contact your system administrator.
	ENCRYPTION_POLICY_DENIES_OPERATION = 0x1786,
	// The list of servers for this workgroup is not currently available.
	NO_BROWSER_SERVERS_FOUND = 0x17E6,
	// The Task Scheduler service must be configured to run in the System account to function properly. Individual tasks may be configured to run in other accounts.
	SCHED_E_SERVICE_NOT_LOCALSYSTEM = 0x1838,
	// Log service encountered an invalid log sector.
	LOG_SECTOR_INVALID = 0x19C8,
	// Log service encountered a log sector with invalid block parity.
	LOG_SECTOR_PARITY_INVALID = 0x19C9,
	// Log service encountered a remapped log sector.
	LOG_SECTOR_REMAPPED = 0x19CA,
	// Log service encountered a partial or incomplete log block.
	LOG_BLOCK_INCOMPLETE = 0x19CB,
	// Log service encountered an attempt access data outside the active log range.
	LOG_INVALID_RANGE = 0x19CC,
	// Log service user marshalling buffers are exhausted.
	LOG_BLOCKS_EXHAUSTED = 0x19CD,
	// Log service encountered an attempt read from a marshalling area with an invalid read context.
	LOG_READ_CONTEXT_INVALID = 0x19CE,
	// Log service encountered an invalid log restart area.
	LOG_RESTART_INVALID = 0x19CF,
	// Log service encountered an invalid log block version.
	LOG_BLOCK_VERSION = 0x19D0,
	// Log service encountered an invalid log block.
	LOG_BLOCK_INVALID = 0x19D1,
	// Log service encountered an attempt to read the log with an invalid read mode.
	LOG_READ_MODE_INVALID = 0x19D2,
	// Log service encountered a log stream with no restart area.
	LOG_NO_RESTART = 0x19D3,
	// Log service encountered a corrupted metadata file.
	LOG_METADATA_CORRUPT = 0x19D4,
	// Log service encountered a metadata file that could not be created by the log file system.
	LOG_METADATA_INVALID = 0x19D5,
	// Log service encountered a metadata file with inconsistent data.
	LOG_METADATA_INCONSISTENT = 0x19D6,
	// Log service encountered an attempt to erroneous allocate or dispose reservation space.
	LOG_RESERVATION_INVALID = 0x19D7,
	// Log service cannot delete log file or file system container.
	LOG_CANT_DELETE = 0x19D8,
	// Log service has reached the maximum allowable containers allocated to a log file.
	LOG_CONTAINER_LIMIT_EXCEEDED = 0x19D9,
	// Log service has attempted to read or write backward past the start of the log.
	LOG_START_OF_LOG = 0x19DA,
	// Log policy could not be installed because a policy of the same type is already present.
	LOG_POLICY_ALREADY_INSTALLED = 0x19DB,
	// Log policy in question was not installed at the time of the request.
	LOG_POLICY_NOT_INSTALLED = 0x19DC,
	// The installed set of policies on the log is invalid.
	LOG_POLICY_INVALID = 0x19DD,
	// A policy on the log in question prevented the operation from completing.
	LOG_POLICY_CONFLICT = 0x19DE,
	// Log space cannot be reclaimed because the log is pinned by the archive tail.
	LOG_PINNED_ARCHIVE_TAIL = 0x19DF,
	// Log record is not a record in the log file.
	LOG_RECORD_NONEXISTENT = 0x19E0,
	// Number of reserved log records or the adjustment of the number of reserved log records is invalid.
	LOG_RECORDS_RESERVED_INVALID = 0x19E1,
	// Reserved log space or the adjustment of the log space is invalid.
	LOG_SPACE_RESERVED_INVALID = 0x19E2,
	// An new or existing archive tail or base of the active log is invalid.
	LOG_TAIL_INVALID = 0x19E3,
	// Log space is exhausted.
	LOG_FULL = 0x19E4,
	// The log could not be set to the requested size.
	COULD_NOT_RESIZE_LOG = 0x19E5,
	// Log is multiplexed, no direct writes to the physical log is allowed.
	LOG_MULTIPLEXED = 0x19E6,
	// The operation failed because the log is a dedicated log.
	LOG_DEDICATED = 0x19E7,
	// The operation requires an archive context.
	LOG_ARCHIVE_NOT_IN_PROGRESS = 0x19E8,
	// Log archival is in progress.
	LOG_ARCHIVE_IN_PROGRESS = 0x19E9,
	// The operation requires a non-ephemeral log, but the log is ephemeral.
	LOG_EPHEMERAL = 0x19EA,
	// The log must have at least two containers before it can be read from or written to.
	LOG_NOT_ENOUGH_CONTAINERS = 0x19EB,
	// A log client has already registered on the stream.
	LOG_CLIENT_ALREADY_REGISTERED = 0x19EC,
	// A log client has not been registered on the stream.
	LOG_CLIENT_NOT_REGISTERED = 0x19ED,
	// A request has already been made to handle the log full condition.
	LOG_FULL_HANDLER_IN_PROGRESS = 0x19EE,
	// Log service encountered an error when attempting to read from a log container.
	LOG_CONTAINER_READ_FAILED = 0x19EF,
	// Log service encountered an error when attempting to write to a log container.
	LOG_CONTAINER_WRITE_FAILED = 0x19F0,
	// Log service encountered an error when attempting open a log container.
	LOG_CONTAINER_OPEN_FAILED = 0x19F1,
	// Log service encountered an invalid container state when attempting a requested action.
	LOG_CONTAINER_STATE_INVALID = 0x19F2,
	// Log service is not in the correct state to perform a requested action.
	LOG_STATE_INVALID = 0x19F3,
	// Log space cannot be reclaimed because the log is pinned.
	LOG_PINNED = 0x19F4,
	// Log metadata flush failed.
	LOG_METADATA_FLUSH_FAILED = 0x19F5,
	// Security on the log and its containers is inconsistent.
	LOG_INCONSISTENT_SECURITY = 0x19F6,
	// Records were appended to the log or reservation changes were made, but the log could not be flushed.
	LOG_APPENDED_FLUSH_FAILED = 0x19F7,
	// The log is pinned due to reservation consuming most of the log space. Free some reserved records to make space available.
	LOG_PINNED_RESERVATION = 0x19F8,
	// The transaction handle associated with this operation is not valid.
	INVALID_TRANSACTION = 0x1A2C,
	// The requested operation was made in the context of a transaction that is no longer active.
	TRANSACTION_NOT_ACTIVE = 0x1A2D,
	// The requested operation is not valid on the Transaction object in its current state.
	TRANSACTION_REQUEST_NOT_VALID = 0x1A2E,
	// The caller has called a response API, but the response is not expected because the TM did not issue the corresponding request to the caller.
	TRANSACTION_NOT_REQUESTED = 0x1A2F,
	// It is too late to perform the requested operation, since the Transaction has already been aborted.
	TRANSACTION_ALREADY_ABORTED = 0x1A30,
	// It is too late to perform the requested operation, since the Transaction has already been committed.
	TRANSACTION_ALREADY_COMMITTED = 0x1A31,
	// The Transaction Manager was unable to be successfully initialized. Transacted operations are not supported.
	TM_INITIALIZATION_FAILED = 0x1A32,
	// The specified ResourceManager made no changes or updates to the resource under this transaction.
	RESOURCEMANAGER_READ_ONLY = 0x1A33,
	// The resource manager has attempted to prepare a transaction that it has not successfully joined.
	TRANSACTION_NOT_JOINED = 0x1A34,
	// The Transaction object already has a superior enlistment, and the caller attempted an operation that would have created a new superior. Only a single superior enlistment is allow.
	TRANSACTION_SUPERIOR_EXISTS = 0x1A35,
	// The RM tried to register a protocol that already exists.
	CRM_PROTOCOL_ALREADY_EXISTS = 0x1A36,
	// The attempt to propagate the Transaction failed.
	TRANSACTION_PROPAGATION_FAILED = 0x1A37,
	// The requested propagation protocol was not registered as a CRM.
	CRM_PROTOCOL_NOT_FOUND = 0x1A38,
	// The buffer passed in to PushTransaction or PullTransaction is not in a valid format.
	TRANSACTION_INVALID_MARSHALL_BUFFER = 0x1A39,
	// The current transaction context associated with the thread is not a valid handle to a transaction object.
	CURRENT_TRANSACTION_NOT_VALID = 0x1A3A,
	// The specified Transaction object could not be opened, because it was not found.
	TRANSACTION_NOT_FOUND = 0x1A3B,
	// The specified ResourceManager object could not be opened, because it was not found.
	RESOURCEMANAGER_NOT_FOUND = 0x1A3C,
	// The specified Enlistment object could not be opened, because it was not found.
	ENLISTMENT_NOT_FOUND = 0x1A3D,
	// The specified TransactionManager object could not be opened, because it was not found.
	TRANSACTIONMANAGER_NOT_FOUND = 0x1A3E,
	// The object specified could not be created or opened, because its associated TransactionManager is not online. The TransactionManager must be brought fully Online by calling RecoverTransactionManager to recover to the end of its LogFile before objects in its Transaction or ResourceManager namespaces can be opened. In addition, errors in writing records to its LogFile can cause a TransactionManager to go offline.
	TRANSACTIONMANAGER_NOT_ONLINE = 0x1A3F,
	// The specified TransactionManager was unable to create the objects contained in its logfile in the Ob namespace. Therefore, the TransactionManager was unable to recover.
	TRANSACTIONMANAGER_RECOVERY_NAME_COLLISION = 0x1A40,
	// The call to create a superior Enlistment on this Transaction object could not be completed, because the Transaction object specified for the enlistment is a subordinate branch of the Transaction. Only the root of the Transaction can be enlisted on as a superior.
	TRANSACTION_NOT_ROOT = 0x1A41,
	// Because the associated transaction manager or resource manager has been closed, the handle is no longer valid.
	TRANSACTION_OBJECT_EXPIRED = 0x1A42,
	// The specified operation could not be performed on this Superior enlistment, because the enlistment was not created with the corresponding completion response in the NotificationMask.
	TRANSACTION_RESPONSE_NOT_ENLISTED = 0x1A43,
	// The specified operation could not be performed, because the record that would be logged was too long. This can occur because of two conditions: either there are too many Enlistments on this Transaction, or the combined RecoveryInformation being logged on behalf of those Enlistments is too long.
	TRANSACTION_RECORD_TOO_LONG = 0x1A44,
	// Implicit transaction are not supported.
	IMPLICIT_TRANSACTION_NOT_SUPPORTED = 0x1A45,
	// The kernel transaction manager had to abort or forget the transaction because it blocked forward progress.
	TRANSACTION_INTEGRITY_VIOLATED = 0x1A46,
	// The TransactionManager identity that was supplied did not match the one recorded in the TransactionManager's log file.
	TRANSACTIONMANAGER_IDENTITY_MISMATCH = 0x1A47,
	// This snapshot operation cannot continue because a transactional resource manager cannot be frozen in its current state. Please try again.
	RM_CANNOT_BE_FROZEN_FOR_SNAPSHOT = 0x1A48,
	// The transaction cannot be enlisted on with the specified EnlistmentMask, because the transaction has already completed the PrePrepare phase. In order to ensure correctness, the ResourceManager must switch to a write- through mode and cease caching data within this transaction. Enlisting for only subsequent transaction phases may still succeed.
	TRANSACTION_MUST_WRITETHROUGH = 0x1A49,
	// The transaction does not have a superior enlistment.
	TRANSACTION_NO_SUPERIOR = 0x1A4A,
	// The attempt to commit the Transaction completed, but it is possible that some portion of the transaction tree did not commit successfully due to heuristics. Therefore it is possible that some data modified in the transaction may not have committed, resulting in transactional inconsistency. If possible, check the consistency of the associated data.
	HEURISTIC_DAMAGE_POSSIBLE = 0x1A4B,
	// The function attempted to use a name that is reserved for use by another transaction.
	TRANSACTIONAL_CONFLICT = 0x1A90,
	// Transaction support within the specified resource manager is not started or was shut down due to an error.
	RM_NOT_ACTIVE = 0x1A91,
	// The metadata of the RM has been corrupted. The RM will not function.
	RM_METADATA_CORRUPT = 0x1A92,
	// The specified directory does not contain a resource manager.
	DIRECTORY_NOT_RM = 0x1A93,
	// The remote server or share does not support transacted file operations.
	TRANSACTIONS_UNSUPPORTED_REMOTE = 0x1A95,
	// The requested log size is invalid.
	LOG_RESIZE_INVALID_SIZE = 0x1A96,
	// The object (file, stream, link) corresponding to the handle has been deleted by a Transaction Savepoint Rollback.
	OBJECT_NO_LONGER_EXISTS = 0x1A97,
	// The specified file miniversion was not found for this transacted file open.
	STREAM_MINIVERSION_NOT_FOUND = 0x1A98,
	// The specified file miniversion was found but has been invalidated. Most likely cause is a transaction savepoint rollback.
	STREAM_MINIVERSION_NOT_VALID = 0x1A99,
	// A miniversion may only be opened in the context of the transaction that created it.
	MINIVERSION_INACCESSIBLE_FROM_SPECIFIED_TRANSACTION = 0x1A9A,
	// It is not possible to open a miniversion with modify access.
	CANT_OPEN_MINIVERSION_WITH_MODIFY_INTENT = 0x1A9B,
	// It is not possible to create any more miniversions for this stream.
	CANT_CREATE_MORE_STREAM_MINIVERSIONS = 0x1A9C,
	// The remote server sent mismatching version number or Fid for a file opened with transactions.
	REMOTE_FILE_VERSION_MISMATCH = 0x1A9E,
	// The handle has been invalidated by a transaction. The most likely cause is the presence of memory mapping on a file or an open handle when the transaction ended or rolled back to savepoint.
	HANDLE_NO_LONGER_VALID = 0x1A9F,
	// There is no transaction metadata on the file.
	NO_TXF_METADATA = 0x1AA0,
	// The log data is corrupt.
	LOG_CORRUPTION_DETECTED = 0x1AA1,
	// The file can't be recovered because there is a handle still open on it.
	CANT_RECOVER_WITH_HANDLE_OPEN = 0x1AA2,
	// The transaction outcome is unavailable because the resource manager responsible for it has disconnected.
	RM_DISCONNECTED = 0x1AA3,
	// The request was rejected because the enlistment in question is not a superior enlistment.
	ENLISTMENT_NOT_SUPERIOR = 0x1AA4,
	// The transactional resource manager is already consistent. Recovery is not needed.
	RECOVERY_NOT_NEEDED = 0x1AA5,
	// The transactional resource manager has already been started.
	RM_ALREADY_STARTED = 0x1AA6,
	// The file cannot be opened transactionally, because its identity depends on the outcome of an unresolved transaction.
	FILE_IDENTITY_NOT_PERSISTENT = 0x1AA7,
	// The operation cannot be performed because another transaction is depending on the fact that this property will not change.
	CANT_BREAK_TRANSACTIONAL_DEPENDENCY = 0x1AA8,
	// The operation would involve a single file with two transactional resource managers and is therefore not allowed.
	CANT_CROSS_RM_BOUNDARY = 0x1AA9,
	// The $Txf directory must be empty for this operation to succeed.
	TXF_DIR_NOT_EMPTY = 0x1AAA,
	// The operation would leave a transactional resource manager in an inconsistent state and is therefore not allowed.
	INDOUBT_TRANSACTIONS_EXIST = 0x1AAB,
	// The operation could not be completed because the transaction manager does not have a log.
	TM_VOLATILE = 0x1AAC,
	// A rollback could not be scheduled because a previously scheduled rollback has already executed or been queued for execution.
	ROLLBACK_TIMER_EXPIRED = 0x1AAD,
	// The transactional metadata attribute on the file or directory is corrupt and unreadable.
	TXF_ATTRIBUTE_CORRUPT = 0x1AAE,
	// The encryption operation could not be completed because a transaction is active.
	EFS_NOT_ALLOWED_IN_TRANSACTION = 0x1AAF,
	// This object is not allowed to be opened in a transaction.
	TRANSACTIONAL_OPEN_NOT_ALLOWED = 0x1AB0,
	// An attempt to create space in the transactional resource manager's log failed. The failure status has been recorded in the event log.
	LOG_GROWTH_FAILED = 0x1AB1,
	// Memory mapping (creating a mapped section) a remote file under a transaction is not supported.
	TRANSACTED_MAPPING_UNSUPPORTED_REMOTE = 0x1AB2,
	// Transaction metadata is already present on this file and cannot be superseded.
	TXF_METADATA_ALREADY_PRESENT = 0x1AB3,
	// A transaction scope could not be entered because the scope handler has not been initialized.
	TRANSACTION_SCOPE_CALLBACKS_NOT_SET = 0x1AB4,
	// Promotion was required in order to allow the resource manager to enlist, but the transaction was set to disallow it.
	TRANSACTION_REQUIRED_PROMOTION = 0x1AB5,
	// This file is open for modification in an unresolved transaction and may be opened for execute only by a transacted reader.
	CANNOT_EXECUTE_FILE_IN_TRANSACTION = 0x1AB6,
	// The request to thaw frozen transactions was ignored because transactions had not previously been frozen.
	TRANSACTIONS_NOT_FROZEN = 0x1AB7,
	// Transactions cannot be frozen because a freeze is already in progress.
	TRANSACTION_FREEZE_IN_PROGRESS = 0x1AB8,
	// The target volume is not a snapshot volume. This operation is only valid on a volume mounted as a snapshot.
	NOT_SNAPSHOT_VOLUME = 0x1AB9,
	// The savepoint operation failed because files are open on the transaction. This is not permitted.
	NO_SAVEPOINT_WITH_OPEN_FILES = 0x1ABA,
	// Windows has discovered corruption in a file, and that file has since been repaired. Data loss may have occurred.
	DATA_LOST_REPAIR = 0x1ABB,
	// The sparse operation could not be completed because a transaction is active on the file.
	SPARSE_NOT_ALLOWED_IN_TRANSACTION = 0x1ABC,
	// The call to create a TransactionManager object failed because the Tm Identity stored in the logfile does not match the Tm Identity that was passed in as an argument.
	TM_IDENTITY_MISMATCH = 0x1ABD,
	// I/O was attempted on a section object that has been floated as a result of a transaction ending. There is no valid data.
	FLOATED_SECTION = 0x1ABE,
	// The transactional resource manager cannot currently accept transacted work due to a transient condition such as low resources.
	CANNOT_ACCEPT_TRANSACTED_WORK = 0x1ABF,
	// The transactional resource manager had too many tranactions outstanding that could not be aborted. The transactional resource manger has been shut down.
	CANNOT_ABORT_TRANSACTIONS = 0x1AC0,
	// The operation could not be completed due to bad clusters on disk.
	BAD_CLUSTERS = 0x1AC1,
	// The compression operation could not be completed because a transaction is active on the file.
	COMPRESSION_NOT_ALLOWED_IN_TRANSACTION = 0x1AC2,
	// The operation could not be completed because the volume is dirty. Please run chkdsk and try again.
	VOLUME_DIRTY = 0x1AC3,
	// The link tracking operation could not be completed because a transaction is active.
	NO_LINK_TRACKING_IN_TRANSACTION = 0x1AC4,
	// This operation cannot be performed in a transaction.
	OPERATION_NOT_SUPPORTED_IN_TRANSACTION = 0x1AC5,
	// The handle is no longer properly associated with its transaction. It may have been opened in a transactional resource manager that was subsequently forced to restart. Please close the handle and open a new one.
	EXPIRED_HANDLE = 0x1AC6,
	// The specified operation could not be performed because the resource manager is not enlisted in the transaction.
	TRANSACTION_NOT_ENLISTED = 0x1AC7,
	// The specified session name is invalid.
	CTX_WINSTATION_NAME_INVALID = 0x1B59,
	// The specified protocol driver is invalid.
	CTX_INVALID_PD = 0x1B5A,
	// The specified protocol driver was not found in the system path.
	CTX_PD_NOT_FOUND = 0x1B5B,
	// The specified terminal connection driver was not found in the system path.
	CTX_WD_NOT_FOUND = 0x1B5C,
	// A registry key for event logging could not be created for this session.
	CTX_CANNOT_MAKE_EVENTLOG_ENTRY = 0x1B5D,
	// A service with the same name already exists on the system.
	CTX_SERVICE_NAME_COLLISION = 0x1B5E,
	// A close operation is pending on the session.
	CTX_CLOSE_PENDING = 0x1B5F,
	// There are no free output buffers available.
	CTX_NO_OUTBUF = 0x1B60,
	// The MODEM.INF file was not found.
	CTX_MODEM_INF_NOT_FOUND = 0x1B61,
	// The modem name was not found in MODEM.INF.
	CTX_INVALID_MODEMNAME = 0x1B62,
	// The modem did not accept the command sent to it. Verify that the configured modem name matches the attached modem.
	CTX_MODEM_RESPONSE_ERROR = 0x1B63,
	// The modem did not respond to the command sent to it. Verify that the modem is properly cabled and powered on.
	CTX_MODEM_RESPONSE_TIMEOUT = 0x1B64,
	// Carrier detect has failed or carrier has been dropped due to disconnect.
	CTX_MODEM_RESPONSE_NO_CARRIER = 0x1B65,
	// Dial tone not detected within the required time. Verify that the phone cable is properly attached and functional.
	CTX_MODEM_RESPONSE_NO_DIALTONE = 0x1B66,
	// Busy signal detected at remote site on callback.
	CTX_MODEM_RESPONSE_BUSY = 0x1B67,
	// Voice detected at remote site on callback.
	CTX_MODEM_RESPONSE_VOICE = 0x1B68,
	// Transport driver error.
	CTX_TD_ERROR = 0x1B69,
	// The specified session cannot be found.
	CTX_WINSTATION_NOT_FOUND = 0x1B6E,
	// The specified session name is already in use.
	CTX_WINSTATION_ALREADY_EXISTS = 0x1B6F,
	// The task you are trying to do can't be completed because Remote Desktop Services is currently busy. Please try again in a few minutes. Other users should still be able to log on.
	CTX_WINSTATION_BUSY = 0x1B70,
	// An attempt has been made to connect to a session whose video mode is not supported by the current client.
	CTX_BAD_VIDEO_MODE = 0x1B71,
	// The application attempted to enable DOS graphics mode. DOS graphics mode is not supported.
	CTX_GRAPHICS_INVALID = 0x1B7B,
	// Your interactive logon privilege has been disabled. Please contact your administrator.
	CTX_LOGON_DISABLED = 0x1B7D,
	// The requested operation can be performed only on the system console. This is most often the result of a driver or system DLL requiring direct console access.
	CTX_NOT_CONSOLE = 0x1B7E,
	// The client failed to respond to the server connect message.
	CTX_CLIENT_QUERY_TIMEOUT = 0x1B80,
	// Disconnecting the console session is not supported.
	CTX_CONSOLE_DISCONNECT = 0x1B81,
	// Reconnecting a disconnected session to the console is not supported.
	CTX_CONSOLE_CONNECT = 0x1B82,
	// The request to control another session remotely was denied.
	CTX_SHADOW_DENIED = 0x1B84,
	// The requested session access is denied.
	CTX_WINSTATION_ACCESS_DENIED = 0x1B85,
	// The specified terminal connection driver is invalid.
	CTX_INVALID_WD = 0x1B89,
	// The requested session cannot be controlled remotely. This may be because the session is disconnected or does not currently have a user logged on.
	CTX_SHADOW_INVALID = 0x1B8A,
	// The requested session is not configured to allow remote control.
	CTX_SHADOW_DISABLED = 0x1B8B,
	// Your request to connect to this Terminal Server has been rejected. Your Terminal Server client license number is currently being used by another user. Please call your system administrator to obtain a unique license number.
	CTX_CLIENT_LICENSE_IN_USE = 0x1B8C,
	// Your request to connect to this Terminal Server has been rejected. Your Terminal Server client license number has not been entered for this copy of the Terminal Server client. Please contact your system administrator.
	CTX_CLIENT_LICENSE_NOT_SET = 0x1B8D,
	// The number of connections to this computer is limited and all connections are in use right now. Try connecting later or contact your system administrator.
	CTX_LICENSE_NOT_AVAILABLE = 0x1B8E,
	// The client you are using is not licensed to use this system. Your logon request is denied.
	CTX_LICENSE_CLIENT_INVALID = 0x1B8F,
	// The system license has expired. Your logon request is denied.
	CTX_LICENSE_EXPIRED = 0x1B90,
	// Remote control could not be terminated because the specified session is not currently being remotely controlled.
	CTX_SHADOW_NOT_RUNNING = 0x1B91,
	// The remote control of the console was terminated because the display mode was changed. Changing the display mode in a remote control session is not supported.
	CTX_SHADOW_ENDED_BY_MODE_CHANGE = 0x1B92,
	// Activation has already been reset the maximum number of times for this installation. Your activation timer will not be cleared.
	ACTIVATION_COUNT_EXCEEDED = 0x1B93,
	// Remote logins are currently disabled.
	CTX_WINSTATIONS_DISABLED = 0x1B94,
	// You do not have the proper encryption level to access this Session.
	CTX_ENCRYPTION_LEVEL_REQUIRED = 0x1B95,
	// The user %s\\%s is currently logged on to this computer. Only the current user or an administrator can log on to this computer.
	CTX_SESSION_IN_USE = 0x1B96,
	// The user %s\\%s is already logged on to the console of this computer. You do not have permission to log in at this time. To resolve this issue, contact %s\\%s and have them log off.
	CTX_NO_FORCE_LOGOFF = 0x1B97,
	// Unable to log you on because of an account restriction.
	CTX_ACCOUNT_RESTRICTION = 0x1B98,
	// The RDP protocol component %2 detected an error in the protocol stream and has disconnected the client.
	RDP_PROTOCOL_ERROR = 0x1B99,
	// The Client Drive Mapping Service Has Connected on Terminal Connection.
	CTX_CDM_CONNECT = 0x1B9A,
	// The Client Drive Mapping Service Has Disconnected on Terminal Connection.
	CTX_CDM_DISCONNECT = 0x1B9B,
	// The Terminal Server security layer detected an error in the protocol stream and has disconnected the client.
	CTX_SECURITY_LAYER_ERROR = 0x1B9C,
	// The target session is incompatible with the current session.
	TS_INCOMPATIBLE_SESSIONS = 0x1B9D,
	// Windows can't connect to your session because a problem occurred in the Windows video subsystem. Try connecting again later, or contact the server administrator for assistance.
	TS_VIDEO_SUBSYSTEM_ERROR = 0x1B9E,
	// The file replication service API was called incorrectly.
	FRS_ERR_INVALID_API_SEQUENCE = 0x1F41,
	// The file replication service cannot be started.
	FRS_ERR_STARTING_SERVICE = 0x1F42,
	// The file replication service cannot be stopped.
	FRS_ERR_STOPPING_SERVICE = 0x1F43,
	// The file replication service API terminated the request. The event log may have more information.
	FRS_ERR_INTERNAL_API = 0x1F44,
	// The file replication service terminated the request. The event log may have more information.
	FRS_ERR_INTERNAL = 0x1F45,
	// The file replication service cannot be contacted. The event log may have more information.
	FRS_ERR_SERVICE_COMM = 0x1F46,
	// The file replication service cannot satisfy the request because the user has insufficient privileges. The event log may have more information.
	FRS_ERR_INSUFFICIENT_PRIV = 0x1F47,
	// The file replication service cannot satisfy the request because authenticated RPC is not available. The event log may have more information.
	FRS_ERR_AUTHENTICATION = 0x1F48,
	// The file replication service cannot satisfy the request because the user has insufficient privileges on the domain controller. The event log may have more information.
	FRS_ERR_PARENT_INSUFFICIENT_PRIV = 0x1F49,
	// The file replication service cannot satisfy the request because authenticated RPC is not available on the domain controller. The event log may have more information.
	FRS_ERR_PARENT_AUTHENTICATION = 0x1F4A,
	// The file replication service cannot communicate with the file replication service on the domain controller. The event log may have more information.
	FRS_ERR_CHILD_TO_PARENT_COMM = 0x1F4B,
	// The file replication service on the domain controller cannot communicate with the file replication service on this computer. The event log may have more information.
	FRS_ERR_PARENT_TO_CHILD_COMM = 0x1F4C,
	// The file replication service cannot populate the system volume because of an internal error. The event log may have more information.
	FRS_ERR_SYSVOL_POPULATE = 0x1F4D,
	// The file replication service cannot populate the system volume because of an internal timeout. The event log may have more information.
	FRS_ERR_SYSVOL_POPULATE_TIMEOUT = 0x1F4E,
	// The file replication service cannot process the request. The system volume is busy with a previous request.
	FRS_ERR_SYSVOL_IS_BUSY = 0x1F4F,
	// The file replication service cannot stop replicating the system volume because of an internal error. The event log may have more information.
	FRS_ERR_SYSVOL_DEMOTE = 0x1F50,
	// The file replication service detected an invalid parameter.
	FRS_ERR_INVALID_SERVICE_PARAMETER = 0x1F51,


	// An error occurred while installing the directory service. For more information, see the event log.
	DS_NOT_INSTALLED = 0x2008,
	// The directory service evaluated group memberships locally.
	DS_MEMBERSHIP_EVALUATED_LOCALLY = 0x2009,
	// The specified directory service attribute or value does not exist.
	DS_NO_ATTRIBUTE_OR_VALUE = 0x200A,
	// The attribute syntax specified to the directory service is invalid.
	DS_INVALID_ATTRIBUTE_SYNTAX = 0x200B,
	// The attribute type specified to the directory service is not defined.
	DS_ATTRIBUTE_TYPE_UNDEFINED = 0x200C,
	// The specified directory service attribute or value already exists.
	DS_ATTRIBUTE_OR_VALUE_EXISTS = 0x200D,
	// The directory service is busy.
	DS_BUSY = 0x200E,
	// The directory service is unavailable.
	DS_UNAVAILABLE = 0x200F,
	// The directory service was unable to allocate a relative identifier.
	DS_NO_RIDS_ALLOCATED = 0x2010,
	// The directory service has exhausted the pool of relative identifiers.
	DS_NO_MORE_RIDS = 0x2011,
	// The requested operation could not be performed because the directory service is not the master for that type of operation.
	DS_INCORRECT_ROLE_OWNER = 0x2012,
	// The directory service was unable to initialize the subsystem that allocates relative identifiers.
	DS_RIDMGR_INIT_ERROR = 0x2013,
	// The requested operation did not satisfy one or more constraints associated with the class of the object.
	DS_OBJ_CLASS_VIOLATION = 0x2014,
	// The directory service can perform the requested operation only on a leaf object.
	DS_CANT_ON_NON_LEAF = 0x2015,
	// The directory service cannot perform the requested operation on the RDN attribute of an object.
	DS_CANT_ON_RDN = 0x2016,
	// The directory service detected an attempt to modify the object class of an object.
	DS_CANT_MOD_OBJ_CLASS = 0x2017,
	// The requested cross-domain move operation could not be performed.
	DS_CROSS_DOM_MOVE_ERROR = 0x2018,
	// Unable to contact the global catalog server.
	DS_GC_NOT_AVAILABLE = 0x2019,
	// The policy object is shared and can only be modified at the root.
	SHARED_POLICY = 0x201A,
	// The policy object does not exist.
	POLICY_OBJECT_NOT_FOUND = 0x201B,
	// The requested policy information is only in the directory service.
	POLICY_ONLY_IN_DS = 0x201C,
	// A domain controller promotion is currently active.
	PROMOTION_ACTIVE = 0x201D,
	// A domain controller promotion is not currently active.
	NO_PROMOTION_ACTIVE = 0x201E,
	// An operations error occurred.
	DS_OPERATIONS_ERROR = 0x2020,
	// A protocol error occurred.
	DS_PROTOCOL_ERROR = 0x2021,
	// The time limit for this request was exceeded.
	DS_TIMELIMIT_EXCEEDED = 0x2022,
	// The size limit for this request was exceeded.
	DS_SIZELIMIT_EXCEEDED = 0x2023,
	// The administrative limit for this request was exceeded.
	DS_ADMIN_LIMIT_EXCEEDED = 0x2024,
	// The compare response was false.
	DS_COMPARE_FALSE = 0x2025,
	// The compare response was true.
	DS_COMPARE_TRUE = 0x2026,
	// The requested authentication method is not supported by the server.
	DS_AUTH_METHOD_NOT_SUPPORTED = 0x2027,
	// A more secure authentication method is required for this server.
	DS_STRONG_AUTH_REQUIRED = 0x2028,
	// Inappropriate authentication.
	DS_INAPPROPRIATE_AUTH = 0x2029,
	// The authentication mechanism is unknown.
	DS_AUTH_UNKNOWN = 0x202A,
	// A referral was returned from the server.
	DS_REFERRAL = 0x202B,
	// The server does not support the requested critical extension.
	DS_UNAVAILABLE_CRIT_EXTENSION = 0x202C,
	// This request requires a secure connection.
	DS_CONFIDENTIALITY_REQUIRED = 0x202D,
	// Inappropriate matching.
	DS_INAPPROPRIATE_MATCHING = 0x202E,
	// A constraint violation occurred.
	DS_CONSTRAINT_VIOLATION = 0x202F,
	// There is no such object on the server.
	DS_NO_SUCH_OBJECT = 0x2030,
	// There is an alias problem.
	DS_ALIAS_PROBLEM = 0x2031,
	// An invalid dn syntax has been specified.
	DS_INVALID_DN_SYNTAX = 0x2032,
	// The object is a leaf object.
	DS_IS_LEAF = 0x2033,
	// There is an alias dereferencing problem.
	DS_ALIAS_DEREF_PROBLEM = 0x2034,
	// The server is unwilling to process the request.
	DS_UNWILLING_TO_PERFORM = 0x2035,
	// A loop has been detected.
	DS_LOOP_DETECT = 0x2036,
	// There is a naming violation.
	DS_NAMING_VIOLATION = 0x2037,
	// The result set is too large.
	DS_OBJECT_RESULTS_TOO_LARGE = 0x2038,
	// The operation affects multiple DSAs.
	DS_AFFECTS_MULTIPLE_DSAS = 0x2039,
	// The server is not operational.
	DS_SERVER_DOWN = 0x203A,
	// A local error has occurred.
	DS_LOCAL_ERROR = 0x203B,
	// An encoding error has occurred.
	DS_ENCODING_ERROR = 0x203C,
	// A decoding error has occurred.
	DS_DECODING_ERROR = 0x203D,
	// The search filter cannot be recognized.
	DS_FILTER_UNKNOWN = 0x203E,
	// One or more parameters are illegal.
	DS_PARAM_ERROR = 0x203F,
	// The specified method is not supported.
	DS_NOT_SUPPORTED = 0x2040,
	// No results were returned.
	DS_NO_RESULTS_RETURNED = 0x2041,
	// The specified control is not supported by the server.
	DS_CONTROL_NOT_FOUND = 0x2042,
	// A referral loop was detected by the client.
	DS_CLIENT_LOOP = 0x2043,
	// The preset referral limit was exceeded.
	DS_REFERRAL_LIMIT_EXCEEDED = 0x2044,
	// The search requires a SORT control.
	DS_SORT_CONTROL_MISSING = 0x2045,
	// The search results exceed the offset range specified.
	DS_OFFSET_RANGE_ERROR = 0x2046,
	// The directory service detected the subsystem that allocates relative identifiers is disabled. This can occur as a protective mechanism when the system determines a significant portion of relative identifiers (RIDs) have been exhausted. Please see https://go.microsoft.com/fwlink/p/?linkid=228610 for recommended diagnostic steps and the procedure to re-enable account creation.
	DS_RIDMGR_DISABLED = 0x2047,
	// The root object must be the head of a naming context. The root object cannot have an instantiated parent.
	DS_ROOT_MUST_BE_NC = 0x206D,
	// The add replica operation cannot be performed. The naming context must be writeable in order to create the replica.
	DS_ADD_REPLICA_INHIBITED = 0x206E,
	// A reference to an attribute that is not defined in the schema occurred.
	DS_ATT_NOT_DEF_IN_SCHEMA = 0x206F,
	// The maximum size of an object has been exceeded.
	DS_MAX_OBJ_SIZE_EXCEEDED = 0x2070,
	// An attempt was made to add an object to the directory with a name that is already in use.
	DS_OBJ_STRING_NAME_EXISTS = 0x2071,
	// An attempt was made to add an object of a class that does not have an RDN defined in the schema.
	DS_NO_RDN_DEFINED_IN_SCHEMA = 0x2072,
	// An attempt was made to add an object using an RDN that is not the RDN defined in the schema.
	DS_RDN_DOESNT_MATCH_SCHEMA = 0x2073,
	// None of the requested attributes were found on the objects.
	DS_NO_REQUESTED_ATTS_FOUND = 0x2074,
	// The user buffer is too small.
	DS_USER_BUFFER_TO_SMALL = 0x2075,
	// The attribute specified in the operation is not present on the object.
	DS_ATT_IS_NOT_ON_OBJ = 0x2076,
	// Illegal modify operation. Some aspect of the modification is not permitted.
	DS_ILLEGAL_MOD_OPERATION = 0x2077,
	// The specified object is too large.
	DS_OBJ_TOO_LARGE = 0x2078,
	// The specified instance type is not valid.
	DS_BAD_INSTANCE_TYPE = 0x2079,
	// The operation must be performed at a master DSA.
	DS_MASTERDSA_REQUIRED = 0x207A,
	// The object class attribute must be specified.
	DS_OBJECT_CLASS_REQUIRED = 0x207B,
	// A required attribute is missing.
	DS_MISSING_REQUIRED_ATT = 0x207C,
	// An attempt was made to modify an object to include an attribute that is not legal for its class.
	DS_ATT_NOT_DEF_FOR_CLASS = 0x207D,
	// The specified attribute is already present on the object.
	DS_ATT_ALREADY_EXISTS = 0x207E,
	// The specified attribute is not present, or has no values.
	DS_CANT_ADD_ATT_VALUES = 0x2080,
	// Multiple values were specified for an attribute that can have only one value.
	DS_SINGLE_VALUE_CONSTRAINT = 0x2081,
	// A value for the attribute was not in the acceptable range of values.
	DS_RANGE_CONSTRAINT = 0x2082,
	// The specified value already exists.
	DS_ATT_VAL_ALREADY_EXISTS = 0x2083,
	// The attribute cannot be removed because it is not present on the object.
	DS_CANT_REM_MISSING_ATT = 0x2084,
	// The attribute value cannot be removed because it is not present on the object.
	DS_CANT_REM_MISSING_ATT_VAL = 0x2085,
	// The specified root object cannot be a subref.
	DS_ROOT_CANT_BE_SUBREF = 0x2086,
	// Chaining is not permitted.
	DS_NO_CHAINING = 0x2087,
	// Chained evaluation is not permitted.
	DS_NO_CHAINED_EVAL = 0x2088,
	// The operation could not be performed because the object's parent is either uninstantiated or deleted.
	DS_NO_PARENT_OBJECT = 0x2089,
	// Having a parent that is an alias is not permitted. Aliases are leaf objects.
	DS_PARENT_IS_AN_ALIAS = 0x208A,
	// The object and parent must be of the same type, either both masters or both replicas.
	DS_CANT_MIX_MASTER_AND_REPS = 0x208B,
	// The operation cannot be performed because child objects exist. This operation can only be performed on a leaf object.
	DS_CHILDREN_EXIST = 0x208C,
	// Directory object not found.
	DS_OBJ_NOT_FOUND = 0x208D,
	// The aliased object is missing.
	DS_ALIASED_OBJ_MISSING = 0x208E,
	// The object name has bad syntax.
	DS_BAD_NAME_SYNTAX = 0x208F,
	// It is not permitted for an alias to refer to another alias.
	DS_ALIAS_POINTS_TO_ALIAS = 0x2090,
	// The alias cannot be dereferenced.
	DS_CANT_DEREF_ALIAS = 0x2091,
	// The operation is out of scope.
	DS_OUT_OF_SCOPE = 0x2092,
	// The operation cannot continue because the object is in the process of being removed.
	DS_OBJECT_BEING_REMOVED = 0x2093,
	// The DSA object cannot be deleted.
	DS_CANT_DELETE_DSA_OBJ = 0x2094,
	// A directory service error has occurred.
	DS_GENERIC_ERROR = 0x2095,
	// The operation can only be performed on an internal master DSA object.
	DS_DSA_MUST_BE_INT_MASTER = 0x2096,
	// The object must be of class DSA.
	DS_CLASS_NOT_DSA = 0x2097,
	// Insufficient access rights to perform the operation.
	DS_INSUFF_ACCESS_RIGHTS = 0x2098,
	// The object cannot be added because the parent is not on the list of possible superiors.
	DS_ILLEGAL_SUPERIOR = 0x2099,
	// Access to the attribute is not permitted because the attribute is owned by the Security Accounts Manager (SAM).
	DS_ATTRIBUTE_OWNED_BY_SAM = 0x209A,
	// The name has too many parts.
	DS_NAME_TOO_MANY_PARTS = 0x209B,
	// The name is too long.
	DS_NAME_TOO_LONG = 0x209C,
	// The name value is too long.
	DS_NAME_VALUE_TOO_LONG = 0x209D,
	// The directory service encountered an error parsing a name.
	DS_NAME_UNPARSEABLE = 0x209E,
	// The directory service cannot get the attribute type for a name.
	DS_NAME_TYPE_UNKNOWN = 0x209F,
	// The name does not identify an object; the name identifies a phantom.
	DS_NOT_AN_OBJECT = 0x20A0,
	// The security descriptor is too short.
	DS_SEC_DESC_TOO_SHORT = 0x20A1,
	// The security descriptor is invalid.
	DS_SEC_DESC_INVALID = 0x20A2,
	// Failed to create name for deleted object.
	DS_NO_DELETED_NAME = 0x20A3,
	// The parent of a new subref must exist.
	DS_SUBREF_MUST_HAVE_PARENT = 0x20A4,
	// The object must be a naming context.
	DS_NCNAME_MUST_BE_NC = 0x20A5,
	// It is not permitted to add an attribute which is owned by the system.
	DS_CANT_ADD_SYSTEM_ONLY = 0x20A6,
	// The class of the object must be structural; you cannot instantiate an abstract class.
	DS_CLASS_MUST_BE_CONCRETE = 0x20A7,
	// The schema object could not be found.
	DS_INVALID_DMD = 0x20A8,
	// A local object with this GUID (dead or alive) already exists.
	DS_OBJ_GUID_EXISTS = 0x20A9,
	// The operation cannot be performed on a back link.
	DS_NOT_ON_BACKLINK = 0x20AA,
	// The cross reference for the specified naming context could not be found.
	DS_NO_CROSSREF_FOR_NC = 0x20AB,
	// The operation could not be performed because the directory service is shutting down.
	DS_SHUTTING_DOWN = 0x20AC,
	// The directory service request is invalid.
	DS_UNKNOWN_OPERATION = 0x20AD,
	// The role owner attribute could not be read.
	DS_INVALID_ROLE_OWNER = 0x20AE,
	// The requested FSMO operation failed. The current FSMO holder could not be contacted.
	DS_COULDNT_CONTACT_FSMO = 0x20AF,
	// Modification of a DN across a naming context is not permitted.
	DS_CROSS_NC_DN_RENAME = 0x20B0,
	// The attribute cannot be modified because it is owned by the system.
	DS_CANT_MOD_SYSTEM_ONLY = 0x20B1,
	// Only the replicator can perform this function.
	DS_REPLICATOR_ONLY = 0x20B2,
	// The specified class is not defined.
	DS_OBJ_CLASS_NOT_DEFINED = 0x20B3,
	// The specified class is not a subclass.
	DS_OBJ_CLASS_NOT_SUBCLASS = 0x20B4,
	// The name reference is invalid.
	DS_NAME_REFERENCE_INVALID = 0x20B5,
	// A cross reference already exists.
	DS_CROSS_REF_EXISTS = 0x20B6,
	// It is not permitted to delete a master cross reference.
	DS_CANT_DEL_MASTER_CROSSREF = 0x20B7,
	// Subtree notifications are only supported on NC heads.
	DS_SUBTREE_NOTIFY_NOT_NC_HEAD = 0x20B8,
	// Notification filter is too complex.
	DS_NOTIFY_FILTER_TOO_COMPLEX = 0x20B9,
	// Schema update failed: duplicate RDN.
	DS_DUP_RDN = 0x20BA,
	// Schema update failed: duplicate OID.
	DS_DUP_OID = 0x20BB,
	// Schema update failed: duplicate MAPI identifier.
	DS_DUP_MAPI_ID = 0x20BC,
	// Schema update failed: duplicate schema-id GUID.
	DS_DUP_SCHEMA_ID_GUID = 0x20BD,
	// Schema update failed: duplicate LDAP display name.
	DS_DUP_LDAP_DISPLAY_NAME = 0x20BE,
	// Schema update failed: range-lower less than range upper.
	DS_SEMANTIC_ATT_TEST = 0x20BF,
	// Schema update failed: syntax mismatch.
	DS_SYNTAX_MISMATCH = 0x20C0,
	// Schema deletion failed: attribute is used in must-contain.
	DS_EXISTS_IN_MUST_HAVE = 0x20C1,
	// Schema deletion failed: attribute is used in may-contain.
	DS_EXISTS_IN_MAY_HAVE = 0x20C2,
	// Schema update failed: attribute in may-contain does not exist.
	DS_NONEXISTENT_MAY_HAVE = 0x20C3,
	// Schema update failed: attribute in must-contain does not exist.
	DS_NONEXISTENT_MUST_HAVE = 0x20C4,
	// Schema update failed: class in aux-class list does not exist or is not an auxiliary class.
	DS_AUX_CLS_TEST_FAIL = 0x20C5,
	// Schema update failed: class in poss-superiors does not exist.
	DS_NONEXISTENT_POSS_SUP = 0x20C6,
	// Schema update failed: class in subclassof list does not exist or does not satisfy hierarchy rules.
	DS_SUB_CLS_TEST_FAIL = 0x20C7,
	// Schema update failed: Rdn-Att-Id has wrong syntax.
	DS_BAD_RDN_ATT_ID_SYNTAX = 0x20C8,
	// Schema deletion failed: class is used as auxiliary class.
	DS_EXISTS_IN_AUX_CLS = 0x20C9,
	// Schema deletion failed: class is used as sub class.
	DS_EXISTS_IN_SUB_CLS = 0x20CA,
	// Schema deletion failed: class is used as poss superior.
	DS_EXISTS_IN_POSS_SUP = 0x20CB,
	// Schema update failed in recalculating validation cache.
	DS_RECALCSCHEMA_FAILED = 0x20CC,
	// The tree deletion is not finished. The request must be made again to continue deleting the tree.
	DS_TREE_DELETE_NOT_FINISHED = 0x20CD,
	// The requested delete operation could not be performed.
	DS_CANT_DELETE = 0x20CE,
	// Cannot read the governs class identifier for the schema record.
	DS_ATT_SCHEMA_REQ_ID = 0x20CF,
	// The attribute schema has bad syntax.
	DS_BAD_ATT_SCHEMA_SYNTAX = 0x20D0,
	// The attribute could not be cached.
	DS_CANT_CACHE_ATT = 0x20D1,
	// The class could not be cached.
	DS_CANT_CACHE_CLASS = 0x20D2,
	// The attribute could not be removed from the cache.
	DS_CANT_REMOVE_ATT_CACHE = 0x20D3,
	// The class could not be removed from the cache.
	DS_CANT_REMOVE_CLASS_CACHE = 0x20D4,
	// The distinguished name attribute could not be read.
	DS_CANT_RETRIEVE_DN = 0x20D5,
	// No superior reference has been configured for the directory service. The directory service is therefore unable to issue referrals to objects outside this forest.
	DS_MISSING_SUPREF = 0x20D6,
	// The instance type attribute could not be retrieved.
	DS_CANT_RETRIEVE_INSTANCE = 0x20D7,
	// An internal error has occurred.
	DS_CODE_INCONSISTENCY = 0x20D8,
	// A database error has occurred.
	DS_DATABASE_ERROR = 0x20D9,
	// The attribute GOVERNSID is missing.
	DS_GOVERNSID_MISSING = 0x20DA,
	// An expected attribute is missing.
	DS_MISSING_EXPECTED_ATT = 0x20DB,
	// The specified naming context is missing a cross reference.
	DS_NCNAME_MISSING_CR_REF = 0x20DC,
	// A security checking error has occurred.
	DS_SECURITY_CHECKING_ERROR = 0x20DD,
	// The schema is not loaded.
	DS_SCHEMA_NOT_LOADED = 0x20DE,
	// Schema allocation failed. Please check if the machine is running low on memory.
	DS_SCHEMA_ALLOC_FAILED = 0x20DF,
	// Failed to obtain the required syntax for the attribute schema.
	DS_ATT_SCHEMA_REQ_SYNTAX = 0x20E0,
	// The global catalog verification failed. The global catalog is not available or does not support the operation. Some part of the directory is currently not available.
	DS_GCVERIFY_ERROR = 0x20E1,
	// The replication operation failed because of a schema mismatch between the servers involved.
	DS_DRA_SCHEMA_MISMATCH = 0x20E2,
	// The DSA object could not be found.
	DS_CANT_FIND_DSA_OBJ = 0x20E3,
	// The naming context could not be found.
	DS_CANT_FIND_EXPECTED_NC = 0x20E4,
	// The naming context could not be found in the cache.
	DS_CANT_FIND_NC_IN_CACHE = 0x20E5,
	// The child object could not be retrieved.
	DS_CANT_RETRIEVE_CHILD = 0x20E6,
	// The modification was not permitted for security reasons.
	DS_SECURITY_ILLEGAL_MODIFY = 0x20E7,
	// The operation cannot replace the hidden record.
	DS_CANT_REPLACE_HIDDEN_REC = 0x20E8,
	// The hierarchy file is invalid.
	DS_BAD_HIERARCHY_FILE = 0x20E9,
	// The attempt to build the hierarchy table failed.
	DS_BUILD_HIERARCHY_TABLE_FAILED = 0x20EA,
	// The directory configuration parameter is missing from the registry.
	DS_CONFIG_PARAM_MISSING = 0x20EB,
	// The attempt to count the address book indices failed.
	DS_COUNTING_AB_INDICES_FAILED = 0x20EC,
	// The allocation of the hierarchy table failed.
	DS_HIERARCHY_TABLE_MALLOC_FAILED = 0x20ED,
	// The directory service encountered an internal failure.
	DS_INTERNAL_FAILURE = 0x20EE,
	// The directory service encountered an unknown failure.
	DS_UNKNOWN_ERROR = 0x20EF,
	// A root object requires a class of 'top'.
	DS_ROOT_REQUIRES_CLASS_TOP = 0x20F0,
	// This directory server is shutting down, and cannot take ownership of new floating single-master operation roles.
	DS_REFUSING_FSMO_ROLES = 0x20F1,
	// The directory service is missing mandatory configuration information, and is unable to determine the ownership of floating single-master operation roles.
	DS_MISSING_FSMO_SETTINGS = 0x20F2,
	// The directory service was unable to transfer ownership of one or more floating single-master operation roles to other servers.
	DS_UNABLE_TO_SURRENDER_ROLES = 0x20F3,
	// The replication operation failed.
	DS_DRA_GENERIC = 0x20F4,
	// An invalid parameter was specified for this replication operation.
	DS_DRA_INVALID_PARAMETER = 0x20F5,
	// The directory service is too busy to complete the replication operation at this time.
	DS_DRA_BUSY = 0x20F6,
	// The distinguished name specified for this replication operation is invalid.
	DS_DRA_BAD_DN = 0x20F7,
	// The naming context specified for this replication operation is invalid.
	DS_DRA_BAD_NC = 0x20F8,
	// The distinguished name specified for this replication operation already exists.
	DS_DRA_DN_EXISTS = 0x20F9,
	// The replication system encountered an internal error.
	DS_DRA_INTERNAL_ERROR = 0x20FA,
	// The replication operation encountered a database inconsistency.
	DS_DRA_INCONSISTENT_DIT = 0x20FB,
	// The server specified for this replication operation could not be contacted.
	DS_DRA_CONNECTION_FAILED = 0x20FC,
	// The replication operation encountered an object with an invalid instance type.
	DS_DRA_BAD_INSTANCE_TYPE = 0x20FD,
	// The replication operation failed to allocate memory.
	DS_DRA_OUT_OF_MEM = 0x20FE,
	// The replication operation encountered an error with the mail system.
	DS_DRA_MAIL_PROBLEM = 0x20FF,
	// The replication reference information for the target server already exists.
	DS_DRA_REF_ALREADY_EXISTS = 0x2100,
	// The replication reference information for the target server does not exist.
	DS_DRA_REF_NOT_FOUND = 0x2101,
	// The naming context cannot be removed because it is replicated to another server.
	DS_DRA_OBJ_IS_REP_SOURCE = 0x2102,
	// The replication operation encountered a database error.
	DS_DRA_DB_ERROR = 0x2103,
	// The naming context is in the process of being removed or is not replicated from the specified server.
	DS_DRA_NO_REPLICA = 0x2104,
	// Replication access was denied.
	DS_DRA_ACCESS_DENIED = 0x2105,
	// The requested operation is not supported by this version of the directory service.
	DS_DRA_NOT_SUPPORTED = 0x2106,
	// The replication remote procedure call was cancelled.
	DS_DRA_RPC_CANCELLED = 0x2107,
	// The source server is currently rejecting replication requests.
	DS_DRA_SOURCE_DISABLED = 0x2108,
	// The destination server is currently rejecting replication requests.
	DS_DRA_SINK_DISABLED = 0x2109,
	// The replication operation failed due to a collision of object names.
	DS_DRA_NAME_COLLISION = 0x210A,
	// The replication source has been reinstalled.
	DS_DRA_SOURCE_REINSTALLED = 0x210B,
	// The replication operation failed because a required parent object is missing.
	DS_DRA_MISSING_PARENT = 0x210C,
	// The replication operation was preempted.
	DS_DRA_PREEMPTED = 0x210D,
	// The replication synchronization attempt was abandoned because of a lack of updates.
	DS_DRA_ABANDON_SYNC = 0x210E,
	// The replication operation was terminated because the system is shutting down.
	DS_DRA_SHUTDOWN = 0x210F,
	// Synchronization attempt failed because the destination DC is currently waiting to synchronize new partial attributes from source. This condition is normal if a recent schema change modified the partial attribute set. The destination partial attribute set is not a subset of source partial attribute set.
	DS_DRA_INCOMPATIBLE_PARTIAL_SET = 0x2110,
	// The replication synchronization attempt failed because a master replica attempted to sync from a partial replica.
	DS_DRA_SOURCE_IS_PARTIAL_REPLICA = 0x2111,
	// The server specified for this replication operation was contacted, but that server was unable to contact an additional server needed to complete the operation.
	DS_DRA_EXTN_CONNECTION_FAILED = 0x2112,
	// The version of the directory service schema of the source forest is not compatible with the version of directory service on this computer.
	DS_INSTALL_SCHEMA_MISMATCH = 0x2113,
	// Schema update failed: An attribute with the same link identifier already exists.
	DS_DUP_LINK_ID = 0x2114,
	// Name translation: Generic processing error.
	DS_NAME_ERROR_RESOLVING = 0x2115,
	// Name translation: Could not find the name or insufficient right to see name.
	DS_NAME_ERROR_NOT_FOUND = 0x2116,
	// Name translation: Input name mapped to more than one output name.
	DS_NAME_ERROR_NOT_UNIQUE = 0x2117,
	// Name translation: Input name found, but not the associated output format.
	DS_NAME_ERROR_NO_MAPPING = 0x2118,
	// Name translation: Unable to resolve completely, only the domain was found.
	DS_NAME_ERROR_DOMAIN_ONLY = 0x2119,
	// Name translation: Unable to perform purely syntactical mapping at the client without going out to the wire.
	DS_NAME_ERROR_NO_SYNTACTICAL_MAPPING = 0x211A,
	// Modification of a constructed attribute is not allowed.
	DS_CONSTRUCTED_ATT_MOD = 0x211B,
	// The OM-Object-Class specified is incorrect for an attribute with the specified syntax.
	DS_WRONG_OM_OBJ_CLASS = 0x211C,
	// The replication request has been posted; waiting for reply.
	DS_DRA_REPL_PENDING = 0x211D,
	// The requested operation requires a directory service, and none was available.
	DS_DS_REQUIRED = 0x211E,
	// The LDAP display name of the class or attribute contains non-ASCII characters.
	DS_INVALID_LDAP_DISPLAY_NAME = 0x211F,
	// The requested search operation is only supported for base searches.
	DS_NON_BASE_SEARCH = 0x2120,
	// The search failed to retrieve attributes from the database.
	DS_CANT_RETRIEVE_ATTS = 0x2121,
	// The schema update operation tried to add a backward link attribute that has no corresponding forward link.
	DS_BACKLINK_WITHOUT_LINK = 0x2122,
	// Source and destination of a cross-domain move do not agree on the object's epoch number. Either source or destination does not have the latest version of the object.
	DS_EPOCH_MISMATCH = 0x2123,
	// Source and destination of a cross-domain move do not agree on the object's current name. Either source or destination does not have the latest version of the object.
	DS_SRC_NAME_MISMATCH = 0x2124,
	// Source and destination for the cross-domain move operation are identical. Caller should use local move operation instead of cross-domain move operation.
	DS_SRC_AND_DST_NC_IDENTICAL = 0x2125,
	// Source and destination for a cross-domain move are not in agreement on the naming contexts in the forest. Either source or destination does not have the latest version of the Partitions container.
	DS_DST_NC_MISMATCH = 0x2126,
	// Destination of a cross-domain move is not authoritative for the destination naming context.
	DS_NOT_AUTHORITIVE_FOR_DST_NC = 0x2127,
	// Source and destination of a cross-domain move do not agree on the identity of the source object. Either source or destination does not have the latest version of the source object.
	DS_SRC_GUID_MISMATCH = 0x2128,
	// Object being moved across-domains is already known to be deleted by the destination server. The source server does not have the latest version of the source object.
	DS_CANT_MOVE_DELETED_OBJECT = 0x2129,
	// Another operation which requires exclusive access to the PDC FSMO is already in progress.
	DS_PDC_OPERATION_IN_PROGRESS = 0x212A,
	// A cross-domain move operation failed such that two versions of the moved object exist - one each in the source and destination domains. The destination object needs to be removed to restore the system to a consistent state.
	DS_CROSS_DOMAIN_CLEANUP_REQD = 0x212B,
	// This object may not be moved across domain boundaries either because cross-domain moves for this class are disallowed, or the object has some special characteristics, e.g.: trust account or restricted RID, which prevent its move.
	DS_ILLEGAL_XDOM_MOVE_OPERATION = 0x212C,
	// Can't move objects with memberships across domain boundaries as once moved, this would violate the membership conditions of the account group. Remove the object from any account group memberships and retry.
	DS_CANT_WITH_ACCT_GROUP_MEMBERSHPS = 0x212D,
	// A naming context head must be the immediate child of another naming context head, not of an interior node.
	DS_NC_MUST_HAVE_NC_PARENT = 0x212E,
	// The directory cannot validate the proposed naming context name because it does not hold a replica of the naming context above the proposed naming context. Please ensure that the domain naming master role is held by a server that is configured as a global catalog server, and that the server is up to date with its replication partners. (Applies only to Windows 2000 Domain Naming masters.)
	DS_CR_IMPOSSIBLE_TO_VALIDATE = 0x212F,
	// Destination domain must be in native mode.
	DS_DST_DOMAIN_NOT_NATIVE = 0x2130,
	// The operation cannot be performed because the server does not have an infrastructure container in the domain of interest.
	DS_MISSING_INFRASTRUCTURE_CONTAINER = 0x2131,
	// Cross-domain move of non-empty account groups is not allowed.
	DS_CANT_MOVE_ACCOUNT_GROUP = 0x2132,
	// Cross-domain move of non-empty resource groups is not allowed.
	DS_CANT_MOVE_RESOURCE_GROUP = 0x2133,
	// The search flags for the attribute are invalid. The ANR bit is valid only on attributes of Unicode or Teletex strings.
	DS_INVALID_SEARCH_FLAG = 0x2134,
	// Tree deletions starting at an object which has an NC head as a descendant are not allowed.
	DS_NO_TREE_DELETE_ABOVE_NC = 0x2135,
	// The directory service failed to lock a tree in preparation for a tree deletion because the tree was in use.
	DS_COULDNT_LOCK_TREE_FOR_DELETE = 0x2136,
	// The directory service failed to identify the list of objects to delete while attempting a tree deletion.
	DS_COULDNT_IDENTIFY_OBJECTS_FOR_TREE_DELETE = 0x2137,
	// Security Accounts Manager initialization failed because of the following error: %1. Error Status: 0x%2. Please shutdown this system and reboot into Directory Services Restore Mode, check the event log for more detailed information.
	DS_SAM_INIT_FAILURE = 0x2138,
	// Only an administrator can modify the membership list of an administrative group.
	DS_SENSITIVE_GROUP_VIOLATION = 0x2139,
	// Cannot change the primary group ID of a domain controller account.
	DS_CANT_MOD_PRIMARYGROUPID = 0x213A,
	// An attempt is made to modify the base schema.
	DS_ILLEGAL_BASE_SCHEMA_MOD = 0x213B,
	// Adding a new mandatory attribute to an existing class, deleting a mandatory attribute from an existing class, or adding an optional attribute to the special class Top that is not a backlink attribute (directly or through inheritance, for example, by adding or deleting an auxiliary class) is not allowed.
	DS_NONSAFE_SCHEMA_CHANGE = 0x213C,
	// Schema update is not allowed on this DC because the DC is not the schema FSMO Role Owner.
	DS_SCHEMA_UPDATE_DISALLOWED = 0x213D,
	// An object of this class cannot be created under the schema container. You can only create attribute-schema and class-schema objects under the schema container.
	DS_CANT_CREATE_UNDER_SCHEMA = 0x213E,
	// The replica/child install failed to get the objectVersion attribute on the schema container on the source DC. Either the attribute is missing on the schema container or the credentials supplied do not have permission to read it.
	DS_INSTALL_NO_SRC_SCH_VERSION = 0x213F,
	// The replica/child install failed to read the objectVersion attribute in the SCHEMA section of the file schema.ini in the system32 directory.
	DS_INSTALL_NO_SCH_VERSION_IN_INIFILE = 0x2140,
	// The specified group type is invalid.
	DS_INVALID_GROUP_TYPE = 0x2141,
	// You cannot nest global groups in a mixed domain if the group is security-enabled.
	DS_NO_NEST_GLOBALGROUP_IN_MIXEDDOMAIN = 0x2142,
	// You cannot nest local groups in a mixed domain if the group is security-enabled.
	DS_NO_NEST_LOCALGROUP_IN_MIXEDDOMAIN = 0x2143,
	// A global group cannot have a local group as a member.
	DS_GLOBAL_CANT_HAVE_LOCAL_MEMBER = 0x2144,
	// A global group cannot have a universal group as a member.
	DS_GLOBAL_CANT_HAVE_UNIVERSAL_MEMBER = 0x2145,
	// A universal group cannot have a local group as a member.
	DS_UNIVERSAL_CANT_HAVE_LOCAL_MEMBER = 0x2146,
	// A global group cannot have a cross-domain member.
	DS_GLOBAL_CANT_HAVE_CROSSDOMAIN_MEMBER = 0x2147,
	// A local group cannot have another cross domain local group as a member.
	DS_LOCAL_CANT_HAVE_CROSSDOMAIN_LOCAL_MEMBER = 0x2148,
	// A group with primary members cannot change to a security-disabled group.
	DS_HAVE_PRIMARY_MEMBERS = 0x2149,
	// The schema cache load failed to convert the string default SD on a class-schema object.
	DS_STRING_SD_CONVERSION_FAILED = 0x214A,
	// Only DSAs configured to be Global Catalog servers should be allowed to hold the Domain Naming Master FSMO role. (Applies only to Windows 2000 servers.)
	DS_NAMING_MASTER_GC = 0x214B,
	// The DSA operation is unable to proceed because of a DNS lookup failure.
	DS_DNS_LOOKUP_FAILURE = 0x214C,
	// While processing a change to the DNS Host Name for an object, the Service Principal Name values could not be kept in sync.
	DS_COULDNT_UPDATE_SPNS = 0x214D,
	// The Security Descriptor attribute could not be read.
	DS_CANT_RETRIEVE_SD = 0x214E,
	// The object requested was not found, but an object with that key was found.
	DS_KEY_NOT_UNIQUE = 0x214F,
	// The syntax of the linked attribute being added is incorrect. Forward links can only have syntax 2.5.5.1, 2.5.5.7, and 2.5.5.14, and backlinks can only have syntax 2.5.5.1.
	DS_WRONG_LINKED_ATT_SYNTAX = 0x2150,
	// Security Account Manager needs to get the boot password.
	DS_SAM_NEED_BOOTKEY_PASSWORD = 0x2151,
	// Security Account Manager needs to get the boot key from floppy disk.
	DS_SAM_NEED_BOOTKEY_FLOPPY = 0x2152,
	// Directory Service cannot start.
	DS_CANT_START = 0x2153,
	// Directory Services could not start.
	DS_INIT_FAILURE = 0x2154,
	// The connection between client and server requires packet privacy or better.
	DS_NO_PKT_PRIVACY_ON_CONNECTION = 0x2155,
	// The source domain may not be in the same forest as destination.
	DS_SOURCE_DOMAIN_IN_FOREST = 0x2156,
	// The destination domain must be in the forest.
	DS_DESTINATION_DOMAIN_NOT_IN_FOREST = 0x2157,
	// The operation requires that destination domain auditing be enabled.
	DS_DESTINATION_AUDITING_NOT_ENABLED = 0x2158,
	// The operation couldn't locate a DC for the source domain.
	DS_CANT_FIND_DC_FOR_SRC_DOMAIN = 0x2159,
	// The source object must be a group or user.
	DS_SRC_OBJ_NOT_GROUP_OR_USER = 0x215A,
	// The source object's SID already exists in destination forest.
	DS_SRC_SID_EXISTS_IN_FOREST = 0x215B,
	// The source and destination object must be of the same type.
	DS_SRC_AND_DST_OBJECT_CLASS_MISMATCH = 0x215C,
	// Security Accounts Manager initialization failed because of the following error: %1. Error Status: 0x%2. Click OK to shut down the system and reboot into Safe Mode. Check the event log for detailed information.
	SAM_INIT_FAILURE = 0x215D,
	// Schema information could not be included in the replication request.
	DS_DRA_SCHEMA_INFO_SHIP = 0x215E,
	// The replication operation could not be completed due to a schema incompatibility.
	DS_DRA_SCHEMA_CONFLICT = 0x215F,
	// The replication operation could not be completed due to a previous schema incompatibility.
	DS_DRA_EARLIER_SCHEMA_CONFLICT = 0x2160,
	// The replication update could not be applied because either the source or the destination has not yet received information regarding a recent cross-domain move operation.
	DS_DRA_OBJ_NC_MISMATCH = 0x2161,
	// The requested domain could not be deleted because there exist domain controllers that still host this domain.
	DS_NC_STILL_HAS_DSAS = 0x2162,
	// The requested operation can be performed only on a global catalog server.
	DS_GC_REQUIRED = 0x2163,
	// A local group can only be a member of other local groups in the same domain.
	DS_LOCAL_MEMBER_OF_LOCAL_ONLY = 0x2164,
	// Foreign security principals cannot be members of universal groups.
	DS_NO_FPO_IN_UNIVERSAL_GROUPS = 0x2165,
	// The attribute is not allowed to be replicated to the GC because of security reasons.
	DS_CANT_ADD_TO_GC = 0x2166,
	// The checkpoint with the PDC could not be taken because there too many modifications being processed currently.
	DS_NO_CHECKPOINT_WITH_PDC = 0x2167,
	// The operation requires that source domain auditing be enabled.
	DS_SOURCE_AUDITING_NOT_ENABLED = 0x2168,
	// Security principal objects can only be created inside domain naming contexts.
	DS_CANT_CREATE_IN_NONDOMAIN_NC = 0x2169,
	// A Service Principal Name (SPN) could not be constructed because the provided hostname is not in the necessary format.
	DS_INVALID_NAME_FOR_SPN = 0x216A,
	// A Filter was passed that uses constructed attributes.
	DS_FILTER_USES_CONTRUCTED_ATTRS = 0x216B,
	// The unicodePwd attribute value must be enclosed in double quotes.
	DS_UNICODEPWD_NOT_IN_QUOTES = 0x216C,
	// Your computer could not be joined to the domain. You have exceeded the maximum number of computer accounts you are allowed to create in this domain. Contact your system administrator to have this limit reset or increased.
	DS_MACHINE_ACCOUNT_QUOTA_EXCEEDED = 0x216D,
	// For security reasons, the operation must be run on the destination DC.
	DS_MUST_BE_RUN_ON_DST_DC = 0x216E,
	// For security reasons, the source DC must be NT4SP4 or greater.
	DS_SRC_DC_MUST_BE_SP4_OR_GREATER = 0x216F,
	// Critical Directory Service System objects cannot be deleted during tree delete operations. The tree delete may have been partially performed.
	DS_CANT_TREE_DELETE_CRITICAL_OBJ = 0x2170,
	// Directory Services could not start because of the following error: %1. Error Status: 0x%2. Please click OK to shutdown the system. You can use the recovery console to diagnose the system further.
	DS_INIT_FAILURE_CONSOLE = 0x2171,
	// Security Accounts Manager initialization failed because of the following error: %1. Error Status: 0x%2. Please click OK to shutdown the system. You can use the recovery console to diagnose the system further.
	DS_SAM_INIT_FAILURE_CONSOLE = 0x2172,
	// The version of the operating system is incompatible with the current AD DS forest functional level or AD LDS Configuration Set functional level. You must upgrade to a new version of the operating system before this server can become an AD DS Domain Controller or add an AD LDS Instance in this AD DS Forest or AD LDS Configuration Set.
	DS_FOREST_VERSION_TOO_HIGH = 0x2173,
	// The version of the operating system installed is incompatible with the current domain functional level. You must upgrade to a new version of the operating system before this server can become a domain controller in this domain.
	DS_DOMAIN_VERSION_TOO_HIGH = 0x2174,
	// The version of the operating system installed on this server no longer supports the current AD DS Forest functional level or AD LDS Configuration Set functional level. You must raise the AD DS Forest functional level or AD LDS Configuration Set functional level before this server can become an AD DS Domain Controller or an AD LDS Instance in this Forest or Configuration Set.
	DS_FOREST_VERSION_TOO_LOW = 0x2175,
	// The version of the operating system installed on this server no longer supports the current domain functional level. You must raise the domain functional level before this server can become a domain controller in this domain.
	DS_DOMAIN_VERSION_TOO_LOW = 0x2176,
	// The version of the operating system installed on this server is incompatible with the functional level of the domain or forest.
	DS_INCOMPATIBLE_VERSION = 0x2177,
	// The functional level of the domain (or forest) cannot be raised to the requested value, because there exist one or more domain controllers in the domain (or forest) that are at a lower incompatible functional level.
	DS_LOW_DSA_VERSION = 0x2178,
	// The forest functional level cannot be raised to the requested value since one or more domains are still in mixed domain mode. All domains in the forest must be in native mode, for you to raise the forest functional level.
	DS_NO_BEHAVIOR_VERSION_IN_MIXEDDOMAIN = 0x2179,
	// The sort order requested is not supported.
	DS_NOT_SUPPORTED_SORT_ORDER = 0x217A,
	// The requested name already exists as a unique identifier.
	DS_NAME_NOT_UNIQUE = 0x217B,
	// The machine account was created pre-NT4. The account needs to be recreated.
	DS_MACHINE_ACCOUNT_CREATED_PRENT4 = 0x217C,
	// The database is out of version store.
	DS_OUT_OF_VERSION_STORE = 0x217D,
	// Unable to continue operation because multiple conflicting controls were used.
	DS_INCOMPATIBLE_CONTROLS_USED = 0x217E,
	// Unable to find a valid security descriptor reference domain for this partition.
	DS_NO_REF_DOMAIN = 0x217F,
	// Schema update failed: The link identifier is reserved.
	DS_RESERVED_LINK_ID = 0x2180,
	// Schema update failed: There are no link identifiers available.
	DS_LINK_ID_NOT_AVAILABLE = 0x2181,
	// An account group cannot have a universal group as a member.
	DS_AG_CANT_HAVE_UNIVERSAL_MEMBER = 0x2182,
	// Rename or move operations on naming context heads or read-only objects are not allowed.
	DS_MODIFYDN_DISALLOWED_BY_INSTANCE_TYPE = 0x2183,
	// Move operations on objects in the schema naming context are not allowed.
	DS_NO_OBJECT_MOVE_IN_SCHEMA_NC = 0x2184,
	// A system flag has been set on the object and does not allow the object to be moved or renamed.
	DS_MODIFYDN_DISALLOWED_BY_FLAG = 0x2185,
	// This object is not allowed to change its grandparent container. Moves are not forbidden on this object, but are restricted to sibling containers.
	DS_MODIFYDN_WRONG_GRANDPARENT = 0x2186,
	// Unable to resolve completely, a referral to another forest is generated.
	DS_NAME_ERROR_TRUST_REFERRAL = 0x2187,
	// The requested action is not supported on standard server.
	NOT_SUPPORTED_ON_STANDARD_SERVER = 0x2188,
	// Could not access a partition of the directory service located on a remote server. Make sure at least one server is running for the partition in question.
	DS_CANT_ACCESS_REMOTE_PART_OF_AD = 0x2189,
	// The directory cannot validate the proposed naming context (or partition) name because it does not hold a replica nor can it contact a replica of the naming context above the proposed naming context. Please ensure that the parent naming context is properly registered in DNS, and at least one replica of this naming context is reachable by the Domain Naming master.
	DS_CR_IMPOSSIBLE_TO_VALIDATE_V2 = 0x218A,
	// The thread limit for this request was exceeded.
	DS_THREAD_LIMIT_EXCEEDED = 0x218B,
	// The Global catalog server is not in the closest site.
	DS_NOT_CLOSEST = 0x218C,
	// The DS cannot derive a service principal name (SPN) with which to mutually authenticate the target server because the corresponding server object in the local DS database has no serverReference attribute.
	DS_CANT_DERIVE_SPN_WITHOUT_SERVER_REF = 0x218D,
	// The Directory Service failed to enter single user mode.
	DS_SINGLE_USER_MODE_FAILED = 0x218E,
	// The Directory Service cannot parse the script because of a syntax error.
	DS_NTDSCRIPT_SYNTAX_ERROR = 0x218F,
	// The Directory Service cannot process the script because of an error.
	DS_NTDSCRIPT_PROCESS_ERROR = 0x2190,
	// The directory service cannot perform the requested operation because the servers involved are of different replication epochs (which is usually related to a domain rename that is in progress).
	DS_DIFFERENT_REPL_EPOCHS = 0x2191,
	// The directory service binding must be renegotiated due to a change in the server extensions information.
	DS_DRS_EXTENSIONS_CHANGED = 0x2192,
	// Operation not allowed on a disabled cross ref.
	DS_REPLICA_SET_CHANGE_NOT_ALLOWED_ON_DISABLED_CR = 0x2193,
	// Schema update failed: No values for msDS-IntId are available.
	DS_NO_MSDS_INTID = 0x2194,
	// Schema update failed: Duplicate msDS-INtId. Retry the operation.
	DS_DUP_MSDS_INTID = 0x2195,
	// Schema deletion failed: attribute is used in rDNAttID.
	DS_EXISTS_IN_RDNATTID = 0x2196,
	// The directory service failed to authorize the request.
	DS_AUTHORIZATION_FAILED = 0x2197,
	// The Directory Service cannot process the script because it is invalid.
	DS_INVALID_SCRIPT = 0x2198,
	// The remote create cross reference operation failed on the Domain Naming Master FSMO. The operation's error is in the extended data.
	DS_REMOTE_CROSSREF_OP_FAILED = 0x2199,
	// A cross reference is in use locally with the same name.
	DS_CROSS_REF_BUSY = 0x219A,
	// The DS cannot derive a service principal name (SPN) with which to mutually authenticate the target server because the server's domain has been deleted from the forest.
	DS_CANT_DERIVE_SPN_FOR_DELETED_DOMAIN = 0x219B,
	// Writeable NCs prevent this DC from demoting.
	DS_CANT_DEMOTE_WITH_WRITEABLE_NC = 0x219C,
	// The requested object has a non-unique identifier and cannot be retrieved.
	DS_DUPLICATE_ID_FOUND = 0x219D,
	// Insufficient attributes were given to create an object. This object may not exist because it may have been deleted and already garbage collected.
	DS_INSUFFICIENT_ATTR_TO_CREATE_OBJECT = 0x219E,
	// The group cannot be converted due to attribute restrictions on the requested group type.
	DS_GROUP_CONVERSION_ERROR = 0x219F,
	// Cross-domain move of non-empty basic application groups is not allowed.
	DS_CANT_MOVE_APP_BASIC_GROUP = 0x21A0,
	// Cross-domain move of non-empty query based application groups is not allowed.
	DS_CANT_MOVE_APP_QUERY_GROUP = 0x21A1,
	// The FSMO role ownership could not be verified because its directory partition has not replicated successfully with at least one replication partner.
	DS_ROLE_NOT_VERIFIED = 0x21A2,
	// The target container for a redirection of a well known object container cannot already be a special container.
	DS_WKO_CONTAINER_CANNOT_BE_SPECIAL = 0x21A3,
	// The Directory Service cannot perform the requested operation because a domain rename operation is in progress.
	DS_DOMAIN_RENAME_IN_PROGRESS = 0x21A4,
	// The directory service detected a child partition below the requested partition name. The partition hierarchy must be created in a top down method.
	DS_EXISTING_AD_CHILD_NC = 0x21A5,
	// The directory service cannot replicate with this server because the time since the last replication with this server has exceeded the tombstone lifetime.
	DS_REPL_LIFETIME_EXCEEDED = 0x21A6,
	// The requested operation is not allowed on an object under the system container.
	DS_DISALLOWED_IN_SYSTEM_CONTAINER = 0x21A7,
	// The LDAP servers network send queue has filled up because the client is not processing the results of its requests fast enough. No more requests will be processed until the client catches up. If the client does not catch up then it will be disconnected.
	DS_LDAP_SEND_QUEUE_FULL = 0x21A8,
	// The scheduled replication did not take place because the system was too busy to execute the request within the schedule window. The replication queue is overloaded. Consider reducing the number of partners or decreasing the scheduled replication frequency.
	DS_DRA_OUT_SCHEDULE_WINDOW = 0x21A9,
	// At this time, it cannot be determined if the branch replication policy is available on the hub domain controller. Please retry at a later time to account for replication latencies.
	DS_POLICY_NOT_KNOWN = 0x21AA,
	// The site settings object for the specified site does not exist.
	NO_SITE_SETTINGS_OBJECT = 0x21AB,
	// The local account store does not contain secret material for the specified account.
	NO_SECRETS = 0x21AC,
	// Could not find a writable domain controller in the domain.
	NO_WRITABLE_DC_FOUND = 0x21AD,
	// The server object for the domain controller does not exist.
	DS_NO_SERVER_OBJECT = 0x21AE,
	// The NTDS Settings object for the domain controller does not exist.
	DS_NO_NTDSA_OBJECT = 0x21AF,
	// The requested search operation is not supported for ASQ searches.
	DS_NON_ASQ_SEARCH = 0x21B0,
	// A required audit event could not be generated for the operation.
	DS_AUDIT_FAILURE = 0x21B1,
	// The search flags for the attribute are invalid. The subtree index bit is valid only on single valued attributes.
	DS_INVALID_SEARCH_FLAG_SUBTREE = 0x21B2,
	// The search flags for the attribute are invalid. The tuple index bit is valid only on attributes of Unicode strings.
	DS_INVALID_SEARCH_FLAG_TUPLE = 0x21B3,
	// The address books are nested too deeply. Failed to build the hierarchy table.
	DS_HIERARCHY_TABLE_TOO_DEEP = 0x21B4,
	// The specified up-to-date-ness vector is corrupt.
	DS_DRA_CORRUPT_UTD_VECTOR = 0x21B5,
	// The request to replicate secrets is denied.
	DS_DRA_SECRETS_DENIED = 0x21B6,
	// Schema update failed: The MAPI identifier is reserved.
	DS_RESERVED_MAPI_ID = 0x21B7,
	// Schema update failed: There are no MAPI identifiers available.
	DS_MAPI_ID_NOT_AVAILABLE = 0x21B8,
	// The replication operation failed because the required attributes of the local krbtgt object are missing.
	DS_DRA_MISSING_KRBTGT_SECRET = 0x21B9,
	// The domain name of the trusted domain already exists in the forest.
	DS_DOMAIN_NAME_EXISTS_IN_FOREST = 0x21BA,
	// The flat name of the trusted domain already exists in the forest.
	DS_FLAT_NAME_EXISTS_IN_FOREST = 0x21BB,
	// The User Principal Name (UPN) is invalid.
	INVALID_USER_PRINCIPAL_NAME = 0x21BC,
	// OID mapped groups cannot have members.
	DS_OID_MAPPED_GROUP_CANT_HAVE_MEMBERS = 0x21BD,
	// The specified OID cannot be found.
	DS_OID_NOT_FOUND = 0x21BE,
	// The replication operation failed because the target object referred by a link value is recycled.
	DS_DRA_RECYCLED_TARGET = 0x21BF,
	// The redirect operation failed because the target object is in a NC different from the domain NC of the current domain controller.
	DS_DISALLOWED_NC_REDIRECT = 0x21C0,
	// The functional level of the AD LDS configuration set cannot be lowered to the requested value.
	DS_HIGH_ADLDS_FFL = 0x21C1,
	// The functional level of the domain (or forest) cannot be lowered to the requested value.
	DS_HIGH_DSA_VERSION = 0x21C2,
	// The functional level of the AD LDS configuration set cannot be raised to the requested value, because there exist one or more ADLDS instances that are at a lower incompatible functional level.
	DS_LOW_ADLDS_FFL = 0x21C3,
	// The domain join cannot be completed because the SID of the domain you attempted to join was identical to the SID of this machine. This is a symptom of an improperly cloned operating system install. You should run sysprep on this machine in order to generate a new machine SID. Please see https://go.microsoft.com/fwlink/p/?linkid=168895 for more information.
	DOMAIN_SID_SAME_AS_LOCAL_WORKSTATION = 0x21C4,
	// The undelete operation failed because the Sam Account Name or Additional Sam Account Name of the object being undeleted conflicts with an existing live object.
	DS_UNDELETE_SAM_VALIDATION_FAILED = 0x21C5,
	// The system is not authoritative for the specified account and therefore cannot complete the operation. Please retry the operation using the provider associated with this account. If this is an online provider please use the provider's online site.
	INCORRECT_ACCOUNT_TYPE = 0x21C6,


	// DNS server unable to interpret format.
	DNS_ERROR_RCODE_FORMAT_ERROR = 0x2329,
	// DNS server failure.
	DNS_ERROR_RCODE_SERVER_FAILURE = 0x232A,
	// DNS name does not exist.
	DNS_ERROR_RCODE_NAME_ERROR = 0x232B,
	// DNS request not supported by name server.
	DNS_ERROR_RCODE_NOT_IMPLEMENTED = 0x232C,
	// DNS operation refused.
	DNS_ERROR_RCODE_REFUSED = 0x232D,
	// DNS name that ought not exist, does exist.
	DNS_ERROR_RCODE_YXDOMAIN = 0x232E,
	// DNS RR set that ought not exist, does exist.
	DNS_ERROR_RCODE_YXRRSET = 0x232F,
	// DNS RR set that ought to exist, does not exist.
	DNS_ERROR_RCODE_NXRRSET = 0x2330,
	// DNS server not authoritative for zone.
	DNS_ERROR_RCODE_NOTAUTH = 0x2331,
	// DNS name in update or prereq is not in zone.
	DNS_ERROR_RCODE_NOTZONE = 0x2332,
	// DNS signature failed to verify.
	DNS_ERROR_RCODE_BADSIG = 0x2338,
	// DNS bad key.
	DNS_ERROR_RCODE_BADKEY = 0x2339,
	// DNS signature validity expired.
	DNS_ERROR_RCODE_BADTIME = 0x233A,
	// Only the DNS server acting as the key master for the zone may perform this operation.
	DNS_ERROR_KEYMASTER_REQUIRED = 0x238D,
	// This operation is not allowed on a zone that is signed or has signing keys.
	DNS_ERROR_NOT_ALLOWED_ON_SIGNED_ZONE = 0x238E,
	// NSEC3 is not compatible with the RSA-SHA-1 algorithm. Choose a different algorithm or use NSEC.
	// This value was also named DNS_ERROR_INVALID_NSEC3_PARAMETERS
	DNS_ERROR_NSEC3_INCOMPATIBLE_WITH_RSA_SHA1 = 0x238F,
	// The zone does not have enough signing keys. There must be at least one key signing key (KSK) and at least one zone signing key (ZSK).
	DNS_ERROR_NOT_ENOUGH_SIGNING_KEY_DESCRIPTORS = 0x2390,
	// The specified algorithm is not supported.
	DNS_ERROR_UNSUPPORTED_ALGORITHM = 0x2391,
	// The specified key size is not supported.
	DNS_ERROR_INVALID_KEY_SIZE = 0x2392,
	// One or more of the signing keys for a zone are not accessible to the DNS server. Zone signing will not be operational until this error is resolved.
	DNS_ERROR_SIGNING_KEY_NOT_ACCESSIBLE = 0x2393,
	// The specified key storage provider does not support DPAPI++ data protection. Zone signing will not be operational until this error is resolved.
	DNS_ERROR_KSP_DOES_NOT_SUPPORT_PROTECTION = 0x2394,
	// An unexpected DPAPI++ error was encountered. Zone signing will not be operational until this error is resolved.
	DNS_ERROR_UNEXPECTED_DATA_PROTECTION_ERROR = 0x2395,
	// An unexpected crypto error was encountered. Zone signing may not be operational until this error is resolved.
	DNS_ERROR_UNEXPECTED_CNG_ERROR = 0x2396,
	// The DNS server encountered a signing key with an unknown version. Zone signing will not be operational until this error is resolved.
	DNS_ERROR_UNKNOWN_SIGNING_PARAMETER_VERSION = 0x2397,
	// The specified key service provider cannot be opened by the DNS server.
	DNS_ERROR_KSP_NOT_ACCESSIBLE = 0x2398,
	// The DNS server cannot accept any more signing keys with the specified algorithm and KSK flag value for this zone.
	DNS_ERROR_TOO_MANY_SKDS = 0x2399,
	// The specified rollover period is invalid.
	DNS_ERROR_INVALID_ROLLOVER_PERIOD = 0x239A,
	// The specified initial rollover offset is invalid.
	DNS_ERROR_INVALID_INITIAL_ROLLOVER_OFFSET = 0x239B,
	// The specified signing key is already in process of rolling over keys.
	DNS_ERROR_ROLLOVER_IN_PROGRESS = 0x239C,
	// The specified signing key does not have a standby key to revoke.
	DNS_ERROR_STANDBY_KEY_NOT_PRESENT = 0x239D,
	// This operation is not allowed on a zone signing key (ZSK).
	DNS_ERROR_NOT_ALLOWED_ON_ZSK = 0x239E,
	// This operation is not allowed on an active signing key.
	DNS_ERROR_NOT_ALLOWED_ON_ACTIVE_SKD = 0x239F,
	// The specified signing key is already queued for rollover.
	DNS_ERROR_ROLLOVER_ALREADY_QUEUED = 0x23A0,
	// This operation is not allowed on an unsigned zone.
	DNS_ERROR_NOT_ALLOWED_ON_UNSIGNED_ZONE = 0x23A1,
	// This operation could not be completed because the DNS server listed as the current key master for this zone is down or misconfigured. Resolve the problem on the current key master for this zone or use another DNS server to seize the key master role.
	DNS_ERROR_BAD_KEYMASTER = 0x23A2,
	// The specified signature validity period is invalid.
	DNS_ERROR_INVALID_SIGNATURE_VALIDITY_PERIOD = 0x23A3,
	// The specified NSEC3 iteration count is higher than allowed by the minimum key length used in the zone.
	DNS_ERROR_INVALID_NSEC3_ITERATION_COUNT = 0x23A4,
	// This operation could not be completed because the DNS server has been configured with DNSSEC features disabled. Enable DNSSEC on the DNS server.
	DNS_ERROR_DNSSEC_IS_DISABLED = 0x23A5,
	// This operation could not be completed because the XML stream received is empty or syntactically invalid.
	DNS_ERROR_INVALID_XML = 0x23A6,
	// This operation completed, but no trust anchors were added because all of the trust anchors received were either invalid, unsupported, expired, or would not become valid in less than 30 days.
	DNS_ERROR_NO_VALID_TRUST_ANCHORS = 0x23A7,
	// The specified signing key is not waiting for parental DS update.
	DNS_ERROR_ROLLOVER_NOT_POKEABLE = 0x23A8,
	// Hash collision detected during NSEC3 signing. Specify a different user-provided salt, or use a randomly generated salt, and attempt to sign the zone again.
	DNS_ERROR_NSEC3_NAME_COLLISION = 0x23A9,
	// NSEC is not compatible with the NSEC3-RSA-SHA-1 algorithm. Choose a different algorithm or use NSEC3.
	DNS_ERROR_NSEC_INCOMPATIBLE_WITH_NSEC3_RSA_SHA1 = 0x23AA,
	// No records found for given DNS query.
	DNS_INFO_NO_RECORDS = 0x251D,
	// Bad DNS packet.
	DNS_ERROR_BAD_PACKET = 0x251E,
	// No DNS packet.
	DNS_ERROR_NO_PACKET = 0x251F,
	// DNS error, check rcode.
	DNS_ERROR_RCODE = 0x2520,
	// Unsecured DNS packet.
	DNS_ERROR_UNSECURE_PACKET = 0x2521,
	// DNS query request is pending.
	DNS_REQUEST_PENDING = 0x2522,
	// Invalid DNS type.
	DNS_ERROR_INVALID_TYPE = 0x254F,
	// Invalid IP address.
	DNS_ERROR_INVALID_IP_ADDRESS = 0x2550,
	// Invalid property.
	DNS_ERROR_INVALID_PROPERTY = 0x2551,
	// Try DNS operation again later.
	DNS_ERROR_TRY_AGAIN_LATER = 0x2552,
	// Record for given name and type is not unique.
	DNS_ERROR_NOT_UNIQUE = 0x2553,
	// DNS name does not comply with RFC specifications.
	DNS_ERROR_NON_RFC_NAME = 0x2554,
	// DNS name is a fully-qualified DNS name.
	DNS_STATUS_FQDN = 0x2555,
	// DNS name is dotted (multi-label).
	DNS_STATUS_DOTTED_NAME = 0x2556,
	// DNS name is a single-part name.
	DNS_STATUS_SINGLE_PART_NAME = 0x2557,
	// DNS name contains an invalid character.
	DNS_ERROR_INVALID_NAME_CHAR = 0x2558,
	// DNS name is entirely numeric.
	DNS_ERROR_NUMERIC_NAME = 0x2559,
	// The operation requested is not permitted on a DNS root server.
	DNS_ERROR_NOT_ALLOWED_ON_ROOT_SERVER = 0x255A,
	// The record could not be created because this part of the DNS namespace has been delegated to another server.
	DNS_ERROR_NOT_ALLOWED_UNDER_DELEGATION = 0x255B,
	// The DNS server could not find a set of root hints.
	DNS_ERROR_CANNOT_FIND_ROOT_HINTS = 0x255C,
	// The DNS server found root hints but they were not consistent across all adapters.
	DNS_ERROR_INCONSISTENT_ROOT_HINTS = 0x255D,
	// The specified value is too small for this parameter.
	DNS_ERROR_DWORD_VALUE_TOO_SMALL = 0x255E,
	// The specified value is too large for this parameter.
	DNS_ERROR_DWORD_VALUE_TOO_LARGE = 0x255F,
	// This operation is not allowed while the DNS server is loading zones in the background. Please try again later.
	DNS_ERROR_BACKGROUND_LOADING = 0x2560,
	// The operation requested is not permitted on against a DNS server running on a read-only DC.
	DNS_ERROR_NOT_ALLOWED_ON_RODC = 0x2561,
	// No data is allowed to exist underneath a DNAME record.
	DNS_ERROR_NOT_ALLOWED_UNDER_DNAME = 0x2562,
	// This operation requires credentials delegation.
	DNS_ERROR_DELEGATION_REQUIRED = 0x2563,
	// Name resolution policy table has been corrupted. DNS resolution will fail until it is fixed. Contact your network administrator.
	DNS_ERROR_INVALID_POLICY_TABLE = 0x2564,
	// DNS zone does not exist.
	DNS_ERROR_ZONE_DOES_NOT_EXIST = 0x2581,
	// DNS zone information not available.
	DNS_ERROR_NO_ZONE_INFO = 0x2582,
	// Invalid operation for DNS zone.
	DNS_ERROR_INVALID_ZONE_OPERATION = 0x2583,
	// Invalid DNS zone configuration.
	DNS_ERROR_ZONE_CONFIGURATION_ERROR = 0x2584,
	// DNS zone has no start of authority (SOA) record.
	DNS_ERROR_ZONE_HAS_NO_SOA_RECORD = 0x2585,
	// DNS zone has no Name Server (NS) record.
	DNS_ERROR_ZONE_HAS_NO_NS_RECORDS = 0x2586,
	// DNS zone is locked.
	DNS_ERROR_ZONE_LOCKED = 0x2587,
	// DNS zone creation failed.
	DNS_ERROR_ZONE_CREATION_FAILED = 0x2588,
	// DNS zone already exists.
	DNS_ERROR_ZONE_ALREADY_EXISTS = 0x2589,
	// DNS automatic zone already exists.
	DNS_ERROR_AUTOZONE_ALREADY_EXISTS = 0x258A,
	// Invalid DNS zone type.
	DNS_ERROR_INVALID_ZONE_TYPE = 0x258B,
	// Secondary DNS zone requires master IP address.
	DNS_ERROR_SECONDARY_REQUIRES_MASTER_IP = 0x258C,
	// DNS zone not secondary.
	DNS_ERROR_ZONE_NOT_SECONDARY = 0x258D,
	// Need secondary IP address.
	DNS_ERROR_NEED_SECONDARY_ADDRESSES = 0x258E,
	// WINS initialization failed.
	DNS_ERROR_WINS_INIT_FAILED = 0x258F,
	// Need WINS servers.
	DNS_ERROR_NEED_WINS_SERVERS = 0x2590,
	// NBTSTAT initialization call failed.
	DNS_ERROR_NBSTAT_INIT_FAILED = 0x2591,
	// Invalid delete of start of authority (SOA).
	DNS_ERROR_SOA_DELETE_INVALID = 0x2592,
	// A conditional forwarding zone already exists for that name.
	DNS_ERROR_FORWARDER_ALREADY_EXISTS = 0x2593,
	// This zone must be configured with one or more master DNS server IP addresses.
	DNS_ERROR_ZONE_REQUIRES_MASTER_IP = 0x2594,
	// The operation cannot be performed because this zone is shut down.
	DNS_ERROR_ZONE_IS_SHUTDOWN = 0x2595,
	// This operation cannot be performed because the zone is currently being signed. Please try again later.
	DNS_ERROR_ZONE_LOCKED_FOR_SIGNING = 0x2596,
	// Primary DNS zone requires datafile.
	DNS_ERROR_PRIMARY_REQUIRES_DATAFILE = 0x25B3,
	// Invalid datafile name for DNS zone.
	DNS_ERROR_INVALID_DATAFILE_NAME = 0x25B4,
	// Failed to open datafile for DNS zone.
	DNS_ERROR_DATAFILE_OPEN_FAILURE = 0x25B5,
	// Failed to write datafile for DNS zone.
	DNS_ERROR_FILE_WRITEBACK_FAILED = 0x25B6,
	// Failure while reading datafile for DNS zone.
	DNS_ERROR_DATAFILE_PARSING = 0x25B7,
	// DNS record does not exist.
	DNS_ERROR_RECORD_DOES_NOT_EXIST = 0x25E5,
	// DNS record format error.
	DNS_ERROR_RECORD_FORMAT = 0x25E6,
	// Node creation failure in DNS.
	DNS_ERROR_NODE_CREATION_FAILED = 0x25E7,
	// Unknown DNS record type.
	DNS_ERROR_UNKNOWN_RECORD_TYPE = 0x25E8,
	// DNS record timed out.
	DNS_ERROR_RECORD_TIMED_OUT = 0x25E9,
	// Name not in DNS zone.
	DNS_ERROR_NAME_NOT_IN_ZONE = 0x25EA,
	// CNAME loop detected.
	DNS_ERROR_CNAME_LOOP = 0x25EB,
	// Node is a CNAME DNS record.
	DNS_ERROR_NODE_IS_CNAME = 0x25EC,
	// A CNAME record already exists for given name.
	DNS_ERROR_CNAME_COLLISION = 0x25ED,
	// Record only at DNS zone root.
	DNS_ERROR_RECORD_ONLY_AT_ZONE_ROOT = 0x25EE,
	// DNS record already exists.
	DNS_ERROR_RECORD_ALREADY_EXISTS = 0x25EF,
	// Secondary DNS zone data error.
	DNS_ERROR_SECONDARY_DATA = 0x25F0,
	// Could not create DNS cache data.
	DNS_ERROR_NO_CREATE_CACHE_DATA = 0x25F1,
	// DNS name does not exist.
	DNS_ERROR_NAME_DOES_NOT_EXIST = 0x25F2,
	// Could not create pointer (PTR) record.
	DNS_WARNING_PTR_CREATE_FAILED = 0x25F3,
	// DNS domain was undeleted.
	DNS_WARNING_DOMAIN_UNDELETED = 0x25F4,
	// The directory service is unavailable.
	DNS_ERROR_DS_UNAVAILABLE = 0x25F5,
	// DNS zone already exists in the directory service.
	DNS_ERROR_DS_ZONE_ALREADY_EXISTS = 0x25F6,
	// DNS server not creating or reading the boot file for the directory service integrated DNS zone.
	DNS_ERROR_NO_BOOTFILE_IF_DS_ZONE = 0x25F7,
	// Node is a DNAME DNS record.
	DNS_ERROR_NODE_IS_DNAME = 0x25F8,
	// A DNAME record already exists for given name.
	DNS_ERROR_DNAME_COLLISION = 0x25F9,
	// An alias loop has been detected with either CNAME or DNAME records.
	DNS_ERROR_ALIAS_LOOP = 0x25FA,
	// DNS AXFR (zone transfer) complete.
	DNS_INFO_AXFR_COMPLETE = 0x2617,
	// DNS zone transfer failed.
	DNS_ERROR_AXFR = 0x2618,
	// Added local WINS server.
	DNS_INFO_ADDED_LOCAL_WINS = 0x2619,
	// Secure update call needs to continue update request.
	DNS_STATUS_CONTINUE_NEEDED = 0x2649,
	// TCP/IP network protocol not installed.
	DNS_ERROR_NO_TCPIP = 0x267B,
	// No DNS servers configured for local system.
	DNS_ERROR_NO_DNS_SERVERS = 0x267C,
	// The specified directory partition does not exist.
	DNS_ERROR_DP_DOES_NOT_EXIST = 0x26AD,
	// The specified directory partition already exists.
	DNS_ERROR_DP_ALREADY_EXISTS = 0x26AE,
	// This DNS server is not enlisted in the specified directory partition.
	DNS_ERROR_DP_NOT_ENLISTED = 0x26AF,
	// This DNS server is already enlisted in the specified directory partition.
	DNS_ERROR_DP_ALREADY_ENLISTED = 0x26B0,
	// The directory partition is not available at this time. Please wait a few minutes and try again.
	DNS_ERROR_DP_NOT_AVAILABLE = 0x26B1,
	// The operation failed because the domain naming master FSMO role could not be reached. The domain controller holding the domain naming master FSMO role is down or unable to service the request or is not running Windows Server 2003 or later.
	DNS_ERROR_DP_FSMO_ERROR = 0x26B2,
	// A blocking operation was interrupted by a call to WSACancelBlockingCall.
	WSAEINTR = 0x2714,
	// The file handle supplied is not valid.
	WSAEBADF = 0x2719,
	// An attempt was made to access a socket in a way forbidden by its access permissions.
	WSAEACCES = 0x271D,
	// The system detected an invalid pointer address in attempting to use a pointer argument in a call.
	WSAEFAULT = 0x271E,
	// An invalid argument was supplied.
	WSAEINVAL = 0x2726,
	// Too many open sockets.
	WSAEMFILE = 0x2728,
	// A non-blocking socket operation could not be completed immediately.
	WSAEWOULDBLOCK = 0x2733,
	// A blocking operation is currently executing.
	WSAEINPROGRESS = 0x2734,
	// An operation was attempted on a non-blocking socket that already had an operation in progress.
	WSAEALREADY = 0x2735,
	// An operation was attempted on something that is not a socket.
	WSAENOTSOCK = 0x2736,
	// A required address was omitted from an operation on a socket.
	WSAEDESTADDRREQ = 0x2737,
	// A message sent on a datagram socket was larger than the internal message buffer or some other network limit, or the buffer used to receive a datagram into was smaller than the datagram itself.
	WSAEMSGSIZE = 0x2738,
	// A protocol was specified in the socket function call that does not support the semantics of the socket type requested.
	WSAEPROTOTYPE = 0x2739,
	// An unknown, invalid, or unsupported option or level was specified in a getsockopt or setsockopt call.
	WSAENOPROTOOPT = 0x273A,
	// The requested protocol has not been configured into the system, or no implementation for it exists.
	WSAEPROTONOSUPPORT = 0x273B,
	// The support for the specified socket type does not exist in this address family.
	WSAESOCKTNOSUPPORT = 0x273C,
	// The attempted operation is not supported for the type of object referenced.
	WSAEOPNOTSUPP = 0x273D,
	// The protocol family has not been configured into the system or no implementation for it exists.
	WSAEPFNOSUPPORT = 0x273E,
	// An address incompatible with the requested protocol was used.
	WSAEAFNOSUPPORT = 0x273F,
	// Only one usage of each socket address (protocol/network address/port) is normally permitted.
	WSAEADDRINUSE = 0x2740,
	// The requested address is not valid in its context.
	WSAEADDRNOTAVAIL = 0x2741,
	// A socket operation encountered a dead network.
	WSAENETDOWN = 0x2742,
	// A socket operation was attempted to an unreachable network.
	WSAENETUNREACH = 0x2743,
	// The connection has been broken due to keep-alive activity detecting a failure while the operation was in progress.
	WSAENETRESET = 0x2744,
	// An established connection was aborted by the software in your host machine.
	WSAECONNABORTED = 0x2745,
	// An existing connection was forcibly closed by the remote host.
	WSAECONNRESET = 0x2746,
	// An operation on a socket could not be performed because the system lacked sufficient buffer space or because a queue was full.
	WSAENOBUFS = 0x2747,
	// A connect request was made on an already connected socket.
	WSAEISCONN = 0x2748,
	// A request to send or receive data was disallowed because the socket is not connected and (when sending on a datagram socket using a sendto call) no address was supplied.
	WSAENOTCONN = 0x2749,
	// A request to send or receive data was disallowed because the socket had already been shut down in that direction with a previous shutdown call.
	WSAESHUTDOWN = 0x274A,
	// Too many references to some kernel object.
	WSAETOOMANYREFS = 0x274B,
	// A connection attempt failed because the connected party did not properly respond after a period of time, or established connection failed because connected host has failed to respond.
	WSAETIMEDOUT = 0x274C,
	// No connection could be made because the target machine actively refused it.
	WSAECONNREFUSED = 0x274D,
	// Cannot translate name.
	WSAELOOP = 0x274E,
	// Name component or name was too long.
	WSAENAMETOOLONG = 0x274F,
	// A socket operation failed because the destination host was down.
	WSAEHOSTDOWN = 0x2750,
	// A socket operation was attempted to an unreachable host.
	WSAEHOSTUNREACH = 0x2751,
	// Cannot remove a directory that is not empty.
	WSAENOTEMPTY = 0x2752,
	// A Windows Sockets implementation may have a limit on the number of applications that may use it simultaneously.
	WSAEPROCLIM = 0x2753,
	// Ran out of quota.
	WSAEUSERS = 0x2754,
	// Ran out of disk quota.
	WSAEDQUOT = 0x2755,
	// File handle reference is no longer available.
	WSAESTALE = 0x2756,
	// Item is not available locally.
	WSAEREMOTE = 0x2757,
	// WSAStartup cannot function at this time because the underlying system it uses to provide network services is currently unavailable. = = 0x276C,
	WSASYSNOTREADY = 0x276B, // The Windows Sockets version requested is not supported.
 // Either the application has not called WSAStartup, or WSAStartup failed.
	WSANOTINITIALISED = 0x276D,
	// Returned by WSARecv or WSARecvFrom to indicate the remote party has initiated a graceful shutdown sequence.
	WSAEDISCON = 0x2775,
	// No more results can be returned by WSALookupServiceNext.
	WSAENOMORE = 0x2776,
	// A call to WSALookupServiceEnd was made while this call was still processing. The call has been canceled.
	WSAECANCELLED = 0x2777,
	// The procedure call table is invalid.
	WSAEINVALIDPROCTABLE = 0x2778,
	// The requested service provider is invalid.
	WSAEINVALIDPROVIDER = 0x2779,
	// The requested service provider could not be loaded or initialized.
	WSAEPROVIDERFAILEDINIT = 0x277A,
	// A system call has failed.
	WSASYSCALLFAILURE = 0x277B,
	// No such service is known. The service cannot be found in the specified name space.
	WSASERVICE_NOT_FOUND = 0x277C,
	// The specified class was not found.
	WSATYPE_NOT_FOUND = 0x277D,
	// No more results can be returned by WSALookupServiceNext.
	WSA_E_NO_MORE = 0x277E,
	// A call to WSALookupServiceEnd was made while this call was still processing. The call has been canceled.
	WSA_E_CANCELLED = 0x277F,
	// A database query failed because it was actively refused.
	WSAEREFUSED = 0x2780,
	// No such host is known.
	WSAHOST_NOT_FOUND = 0x2AF9,
	// This is usually a temporary error during hostname resolution and means that the local server did not receive a response from an authoritative server.
	WSATRY_AGAIN = 0x2AFA,
	// A non-recoverable error occurred during a database lookup.
	WSANO_RECOVERY = 0x2AFB,
	// The requested name is valid, but no data of the requested type was found.
	WSANO_DATA = 0x2AFC,
	// At least one reserve has arrived.
	WSA_QOS_RECEIVERS = 0x2AFD,
	// At least one path has arrived.
	WSA_QOS_SENDERS = 0x2AFE,
	// There are no senders.
	WSA_QOS_NO_SENDERS = 0x2AFF,
	// There are no receivers.
	WSA_QOS_NO_RECEIVERS = 0x2B00,
	// Reserve has been confirmed.
	WSA_QOS_REQUEST_CONFIRMED = 0x2B01,
	// Error due to lack of resources.
	WSA_QOS_ADMISSION_FAILURE = 0x2B02,
	// Rejected for administrative reasons - bad credentials.
	WSA_QOS_POLICY_FAILURE = 0x2B03,
	// Unknown or conflicting style.
	WSA_QOS_BAD_STYLE = 0x2B04,
	// Problem with some part of the filterspec or providerspecific buffer in general.
	WSA_QOS_BAD_OBJECT = 0x2B05,
	// Problem with some part of the flowspec.
	WSA_QOS_TRAFFIC_CTRL_ERROR = 0x2B06,
	// General QOS error.
	WSA_QOS_GENERIC_ERROR = 0x2B07,
	// An invalid or unrecognized service type was found in the flowspec.
	WSA_QOS_ESERVICETYPE = 0x2B08,
	// An invalid or inconsistent flowspec was found in the QOS structure.
	WSA_QOS_EFLOWSPEC = 0x2B09,
	// Invalid QOS provider-specific buffer.
	WSA_QOS_EPROVSPECBUF = 0x2B0A,
	// An invalid QOS filter style was used.
	WSA_QOS_EFILTERSTYLE = 0x2B0B,
	// An invalid QOS filter type was used.
	WSA_QOS_EFILTERTYPE = 0x2B0C,
	// An incorrect number of QOS FILTERSPECs were specified in the FLOWDESCRIPTOR.
	WSA_QOS_EFILTERCOUNT = 0x2B0D,
	// An object with an invalid ObjectLength field was specified in the QOS provider-specific buffer.
	WSA_QOS_EOBJLENGTH = 0x2B0E,
	// An incorrect number of flow descriptors was specified in the QOS structure.
	WSA_QOS_EFLOWCOUNT = 0x2B0F,
	// An unrecognized object was found in the QOS provider-specific buffer.
	WSA_QOS_EUNKOWNPSOBJ = 0x2B10,
	// An invalid policy object was found in the QOS provider-specific buffer.
	WSA_QOS_EPOLICYOBJ = 0x2B11,
	// An invalid QOS flow descriptor was found in the flow descriptor list.
	WSA_QOS_EFLOWDESC = 0x2B12,
	// An invalid or inconsistent flowspec was found in the QOS provider specific buffer.
	WSA_QOS_EPSFLOWSPEC = 0x2B13,
	// An invalid FILTERSPEC was found in the QOS provider-specific buffer.
	WSA_QOS_EPSFILTERSPEC = 0x2B14,
	// An invalid shape discard mode object was found in the QOS provider specific buffer.
	WSA_QOS_ESDMODEOBJ = 0x2B15,
	// An invalid shaping rate object was found in the QOS provider-specific buffer.
	WSA_QOS_ESHAPERATEOBJ = 0x2B16,
	// A reserved policy element was found in the QOS provider-specific buffer.
	WSA_QOS_RESERVED_PETYPE = 0x2B17,
	// No such host is known securely.
	WSA_SECURE_HOST_NOT_FOUND = 0x2B18,
	// Name based IPSEC policy could not be added.
	WSA_IPSEC_NAME_POLICY_ERROR = 0x2B19,

	// See Internet Error Codes and WinInet.h.
	INTERNET_ = 0x2EE0,
	// See WinHTTP Error Codes and Winhttp.h.
	WINHTTP_ = 0x2EE1,
	// The specified quick mode policy already exists.
	IPSEC_QM_POLICY_EXISTS = 0x32C8,
	// The specified quick mode policy was not found.
	IPSEC_QM_POLICY_NOT_FOUND = 0x32C9,
	// The specified quick mode policy is being used.
	IPSEC_QM_POLICY_IN_USE = 0x32CA,
	// The specified main mode policy already exists.
	IPSEC_MM_POLICY_EXISTS = 0x32CB,
	// The specified main mode policy was not found.
	IPSEC_MM_POLICY_NOT_FOUND = 0x32CC,
	// The specified main mode policy is being used.
	IPSEC_MM_POLICY_IN_USE = 0x32CD,
	// The specified main mode filter already exists.
	IPSEC_MM_FILTER_EXISTS = 0x32CE,
	// The specified main mode filter was not found.
	IPSEC_MM_FILTER_NOT_FOUND = 0x32CF,
	// The specified transport mode filter already exists.
	IPSEC_TRANSPORT_FILTER_EXISTS = 0x32D0,
	// The specified transport mode filter does not exist.
	IPSEC_TRANSPORT_FILTER_NOT_FOUND = 0x32D1,
	// The specified main mode authentication list exists.
	IPSEC_MM_AUTH_EXISTS = 0x32D2,
	// The specified main mode authentication list was not found.
	IPSEC_MM_AUTH_NOT_FOUND = 0x32D3,
	// The specified main mode authentication list is being used.
	IPSEC_MM_AUTH_IN_USE = 0x32D4,
	// The specified default main mode policy was not found.
	IPSEC_DEFAULT_MM_POLICY_NOT_FOUND = 0x32D5,
	// The specified default main mode authentication list was not found.
	IPSEC_DEFAULT_MM_AUTH_NOT_FOUND = 0x32D6,
	// The specified default quick mode policy was not found.
	IPSEC_DEFAULT_QM_POLICY_NOT_FOUND = 0x32D7,
	// The specified tunnel mode filter exists.
	IPSEC_TUNNEL_FILTER_EXISTS = 0x32D8,
	// The specified tunnel mode filter was not found.
	IPSEC_TUNNEL_FILTER_NOT_FOUND = 0x32D9,
	// The Main Mode filter is pending deletion.
	IPSEC_MM_FILTER_PENDING_DELETION = 0x32DA,
	// The transport filter is pending deletion.
	IPSEC_TRANSPORT_FILTER_PENDING_DELETION = 0x32DB,
	// The tunnel filter is pending deletion.
	IPSEC_TUNNEL_FILTER_PENDING_DELETION = 0x32DC,
	// The Main Mode policy is pending deletion.
	IPSEC_MM_POLICY_PENDING_DELETION = 0x32DD,
	// The Main Mode authentication bundle is pending deletion.
	IPSEC_MM_AUTH_PENDING_DELETION = 0x32DE,
	// The Quick Mode policy is pending deletion.
	IPSEC_QM_POLICY_PENDING_DELETION = 0x32DF,
	// The Main Mode policy was successfully added, but some of the requested offers are not supported.
	WARNING_IPSEC_MM_POLICY_PRUNED = 0x32E0,
	// The Quick Mode policy was successfully added, but some of the requested offers are not supported.
	WARNING_IPSEC_QM_POLICY_PRUNED = 0x32E1,
	// IPSEC_IKE_NEG_STATUS_BEGIN = = 0x35E9,
	IPSEC_IKE_NEG_STATUS_BEGIN = 0x35E8, // IKE authentication credentials are unacceptable.
 // IKE security attributes are unacceptable.
	IPSEC_IKE_ATTRIB_FAIL = 0x35EA,
	// IKE Negotiation in progress.
	IPSEC_IKE_NEGOTIATION_PENDING = 0x35EB,
	// General processing error.
	IPSEC_IKE_GENERAL_PROCESSING_ERROR = 0x35EC,
	// Negotiation timed out.
	IPSEC_IKE_TIMED_OUT = 0x35ED,
	// IKE failed to find valid machine certificate. Contact your Network Security Administrator about installing a valid certificate in the appropriate Certificate Store.
	IPSEC_IKE_NO_CERT = 0x35EE,
	// IKE SA deleted by peer before establishment completed.
	IPSEC_IKE_SA_DELETED = 0x35EF,
	// IKE SA deleted before establishment completed.
	IPSEC_IKE_SA_REAPED = 0x35F0,
	// Negotiation request sat in Queue too long.
	IPSEC_IKE_MM_ACQUIRE_DROP = 0x35F1,
	// Negotiation request sat in Queue too long.
	IPSEC_IKE_QM_ACQUIRE_DROP = 0x35F2,
	// Negotiation request sat in Queue too long.
	IPSEC_IKE_QUEUE_DROP_MM = 0x35F3,
	// Negotiation request sat in Queue too long.
	IPSEC_IKE_QUEUE_DROP_NO_MM = 0x35F4,
	// No response from peer.
	IPSEC_IKE_DROP_NO_RESPONSE = 0x35F5,
	// Negotiation took too long.
	IPSEC_IKE_MM_DELAY_DROP = 0x35F6,
	// Negotiation took too long.
	IPSEC_IKE_QM_DELAY_DROP = 0x35F7,
	// Unknown error occurred.
	IPSEC_IKE_ERROR = 0x35F8,
	// Certificate Revocation Check failed.
	IPSEC_IKE_CRL_FAILED = 0x35F9,
	// Invalid certificate key usage.
	IPSEC_IKE_INVALID_KEY_USAGE = 0x35FA,
	// Invalid certificate type.
	IPSEC_IKE_INVALID_CERT_TYPE = 0x35FB,
	// IKE negotiation failed because the machine certificate used does not have a private key. IPsec certificates require a private key. Contact your Network Security administrator about replacing with a certificate that has a private key.
	IPSEC_IKE_NO_PRIVATE_KEY = 0x35FC,
	// Simultaneous rekeys were detected.
	IPSEC_IKE_SIMULTANEOUS_REKEY = 0x35FD,
	// Failure in Diffie-Hellman computation.
	IPSEC_IKE_DH_FAIL = 0x35FE,
	// Don't know how to process critical payload.
	IPSEC_IKE_CRITICAL_PAYLOAD_NOT_RECOGNIZED = 0x35FF,
	// Invalid header.
	IPSEC_IKE_INVALID_HEADER = 0x3600,
	// No policy configured.
	IPSEC_IKE_NO_POLICY = 0x3601,
	// Failed to verify signature.
	IPSEC_IKE_INVALID_SIGNATURE = 0x3602,
	// Failed to authenticate using Kerberos.
	IPSEC_IKE_KERBEROS_ERROR = 0x3603,
	// Peer's certificate did not have a public key.
	IPSEC_IKE_NO_PUBLIC_KEY = 0x3604,
	// Error processing error payload.
	IPSEC_IKE_PROCESS_ERR = 0x3605,
	// Error processing SA payload.
	IPSEC_IKE_PROCESS_ERR_SA = 0x3606,
	// Error processing Proposal payload.
	IPSEC_IKE_PROCESS_ERR_PROP = 0x3607,
	// Error processing Transform payload.
	IPSEC_IKE_PROCESS_ERR_TRANS = 0x3608,
	// Error processing KE payload.
	IPSEC_IKE_PROCESS_ERR_KE = 0x3609,
	// Error processing ID payload.
	IPSEC_IKE_PROCESS_ERR_ID = 0x360A,
	// Error processing Cert payload.
	IPSEC_IKE_PROCESS_ERR_CERT = 0x360B,
	// Error processing Certificate Request payload.
	IPSEC_IKE_PROCESS_ERR_CERT_REQ = 0x360C,
	// Error processing Hash payload.
	IPSEC_IKE_PROCESS_ERR_HASH = 0x360D,
	// Error processing Signature payload.
	IPSEC_IKE_PROCESS_ERR_SIG = 0x360E,
	// Error processing Nonce payload.
	IPSEC_IKE_PROCESS_ERR_NONCE = 0x360F,
	// Error processing Notify payload.
	IPSEC_IKE_PROCESS_ERR_NOTIFY = 0x3610,
	// Error processing Delete Payload.
	IPSEC_IKE_PROCESS_ERR_DELETE = 0x3611,
	// Error processing VendorId payload.
	IPSEC_IKE_PROCESS_ERR_VENDOR = 0x3612,
	// Invalid payload received.
	IPSEC_IKE_INVALID_PAYLOAD = 0x3613,
	// Soft SA loaded.
	IPSEC_IKE_LOAD_SOFT_SA = 0x3614,
	// Soft SA torn down.
	IPSEC_IKE_SOFT_SA_TORN_DOWN = 0x3615,
	// Invalid cookie received.
	IPSEC_IKE_INVALID_COOKIE = 0x3616,
	// Peer failed to send valid machine certificate.
	IPSEC_IKE_NO_PEER_CERT = 0x3617,
	// Certification Revocation check of peer's certificate failed.
	IPSEC_IKE_PEER_CRL_FAILED = 0x3618,
	// New policy invalidated SAs formed with old policy.
	IPSEC_IKE_POLICY_CHANGE = 0x3619,
	// There is no available Main Mode IKE policy.
	IPSEC_IKE_NO_MM_POLICY = 0x361A,
	// Failed to enabled TCB privilege.
	IPSEC_IKE_NOTCBPRIV = 0x361B,
	// Failed to load SECURITY.DLL.
	IPSEC_IKE_SECLOADFAIL = 0x361C,
	// Failed to obtain security function table dispatch address from SSPI.
	IPSEC_IKE_FAILSSPINIT = 0x361D,
	// Failed to query Kerberos package to obtain max token size.
	IPSEC_IKE_FAILQUERYSSP = 0x361E,
	// Failed to obtain Kerberos server credentials for ISAKMP/ERROR_IPSEC_IKE service. Kerberos authentication will not function. The most likely reason for this is lack of domain membership. This is normal if your computer is a member of a workgroup.
	IPSEC_IKE_SRVACQFAIL = 0x361F,
	// Failed to determine SSPI principal name for ISAKMP/ERROR_IPSEC_IKE service (QueryCredentialsAttributes).
	IPSEC_IKE_SRVQUERYCRED = 0x3620,
	// Failed to obtain new SPI for the inbound SA from IPsec driver. The most common cause for this is that the driver does not have the correct filter. Check your policy to verify the filters.
	IPSEC_IKE_GETSPIFAIL = 0x3621,
	// Given filter is invalid.
	IPSEC_IKE_INVALID_FILTER = 0x3622,
	// Memory allocation failed.
	IPSEC_IKE_OUT_OF_MEMORY = 0x3623,
	// Failed to add Security Association to IPsec Driver. The most common cause for this is if the IKE negotiation took too long to complete. If the problem persists, reduce the load on the faulting machine.
	IPSEC_IKE_ADD_UPDATE_KEY_FAILED = 0x3624,
	// Invalid policy.
	IPSEC_IKE_INVALID_POLICY = 0x3625,
	// Invalid DOI.
	IPSEC_IKE_UNKNOWN_DOI = 0x3626,
	// Invalid situation.
	IPSEC_IKE_INVALID_SITUATION = 0x3627,
	// Diffie-Hellman failure.
	IPSEC_IKE_DH_FAILURE = 0x3628,
	// Invalid Diffie-Hellman group.
	IPSEC_IKE_INVALID_GROUP = 0x3629,
	// Error encrypting payload.
	IPSEC_IKE_ENCRYPT = 0x362A,
	// Error decrypting payload.
	IPSEC_IKE_DECRYPT = 0x362B,
	// Policy match error.
	IPSEC_IKE_POLICY_MATCH = 0x362C,
	// Unsupported ID.
	IPSEC_IKE_UNSUPPORTED_ID = 0x362D,
	// Hash verification failed.
	IPSEC_IKE_INVALID_HASH = 0x362E,
	// Invalid hash algorithm.
	IPSEC_IKE_INVALID_HASH_ALG = 0x362F,
	// Invalid hash size.
	IPSEC_IKE_INVALID_HASH_SIZE = 0x3630,
	// Invalid encryption algorithm.
	IPSEC_IKE_INVALID_ENCRYPT_ALG = 0x3631,
	// Invalid authentication algorithm.
	IPSEC_IKE_INVALID_AUTH_ALG = 0x3632,
	// Invalid certificate signature.
	IPSEC_IKE_INVALID_SIG = 0x3633,
	// Load failed.
	IPSEC_IKE_LOAD_FAILED = 0x3634,
	// Deleted via RPC call.
	IPSEC_IKE_RPC_DELETE = 0x3635,
	// Temporary state created to perform reinitialization. This is not a real failure.
	IPSEC_IKE_BENIGN_REINIT = 0x3636,
	// The lifetime value received in the Responder Lifetime Notify is below the Windows 2000 configured minimum value. Please fix the policy on the peer machine.
	IPSEC_IKE_INVALID_RESPONDER_LIFETIME_NOTIFY = 0x3637,
	// The recipient cannot handle version of IKE specified in the header.
	IPSEC_IKE_INVALID_MAJOR_VERSION = 0x3638,
	// Key length in certificate is too small for configured security requirements.
	IPSEC_IKE_INVALID_CERT_KEYLEN = 0x3639,
	// Max number of established MM SAs to peer exceeded.
	IPSEC_IKE_MM_LIMIT = 0x363A,
	// IKE received a policy that disables negotiation.
	IPSEC_IKE_NEGOTIATION_DISABLED = 0x363B,
	// Reached maximum quick mode limit for the main mode. New main mode will be started.
	IPSEC_IKE_QM_LIMIT = 0x363C,
	// Main mode SA lifetime expired or peer sent a main mode delete.
	IPSEC_IKE_MM_EXPIRED = 0x363D,
	// Main mode SA assumed to be invalid because peer stopped responding.
	IPSEC_IKE_PEER_MM_ASSUMED_INVALID = 0x363E,
	// Certificate doesn't chain to a trusted root in IPsec policy.
	IPSEC_IKE_CERT_CHAIN_POLICY_MISMATCH = 0x363F,
	// Received unexpected message ID.
	IPSEC_IKE_UNEXPECTED_MESSAGE_ID = 0x3640,
	// Received invalid authentication offers.
	IPSEC_IKE_INVALID_AUTH_PAYLOAD = 0x3641,
	// Sent DoS cookie notify to initiator.
	IPSEC_IKE_DOS_COOKIE_SENT = 0x3642,
	// IKE service is shutting down.
	IPSEC_IKE_SHUTTING_DOWN = 0x3643,
	// Could not verify binding between CGA address and certificate.
	IPSEC_IKE_CGA_AUTH_FAILED = 0x3644,
	// Error processing NatOA payload.
	IPSEC_IKE_PROCESS_ERR_NATOA = 0x3645,
	// Parameters of the main mode are invalid for this quick mode.
	IPSEC_IKE_INVALID_MM_FOR_QM = 0x3646,
	// Quick mode SA was expired by IPsec driver.
	IPSEC_IKE_QM_EXPIRED = 0x3647,
	// Too many dynamically added IKEEXT filters were detected.
	IPSEC_IKE_TOO_MANY_FILTERS = 0x3648,
	// IPSEC_IKE_NEG_STATUS_END = = 0x364A,
	IPSEC_IKE_NEG_STATUS_END = 0x3649, // NAP reauth succeeded and must delete the dummy NAP IKEv2 tunnel.
 // Error in assigning inner IP address to initiator in tunnel mode.
	IPSEC_IKE_INNER_IP_ASSIGNMENT_FAILURE = 0x364B,
	// Require configuration payload missing.
	IPSEC_IKE_REQUIRE_CP_PAYLOAD_MISSING = 0x364C,
	// A negotiation running as the security principle who issued the connection is in progress.
	IPSEC_KEY_MODULE_IMPERSONATION_NEGOTIATION_PENDING = 0x364D,
	// SA was deleted due to IKEv1/AuthIP co-existence suppress check.
	IPSEC_IKE_COEXISTENCE_SUPPRESS = 0x364E,
	// Incoming SA request was dropped due to peer IP address rate limiting.
	IPSEC_IKE_RATELIMIT_DROP = 0x364F,
	// Peer does not support MOBIKE.
	IPSEC_IKE_PEER_DOESNT_SUPPORT_MOBIKE = 0x3650,
	// SA establishment is not authorized.
	IPSEC_IKE_AUTHORIZATION_FAILURE = 0x3651,
	// SA establishment is not authorized because there is not a sufficiently strong PKINIT-based credential.
	IPSEC_IKE_STRONG_CRED_AUTHORIZATION_FAILURE = 0x3652,
	// SA establishment is not authorized. You may need to enter updated or different credentials such as a smartcard.
	IPSEC_IKE_AUTHORIZATION_FAILURE_WITH_OPTIONAL_RETRY = 0x3653,
	// SA establishment is not authorized because there is not a sufficiently strong PKINIT-based credential. This might be related to certificate-to-account mapping failure for the SA.
	IPSEC_IKE_STRONG_CRED_AUTHORIZATION_AND_CERTMAP_FAILURE = 0x3654,
	// IPSEC_IKE_NEG_STATUS_EXTENDED_END = = 0x3656,
	IPSEC_IKE_NEG_STATUS_EXTENDED_END = 0x3655, // The SPI in the packet does not match a valid IPsec SA.
 // Packet was received on an IPsec SA whose lifetime has expired.
	IPSEC_SA_LIFETIME_EXPIRED = 0x3657,
	// Packet was received on an IPsec SA that does not match the packet characteristics.
	IPSEC_WRONG_SA = 0x3658,
	// Packet sequence number replay check failed.
	IPSEC_REPLAY_CHECK_FAILED = 0x3659,
	// IPsec header and/or trailer in the packet is invalid.
	IPSEC_INVALID_PACKET = 0x365A,
	// IPsec integrity check failed.
	IPSEC_INTEGRITY_CHECK_FAILED = 0x365B,
	// IPsec dropped a clear text packet.
	IPSEC_CLEAR_TEXT_DROP = 0x365C,
	// IPsec dropped an incoming ESP packet in authenticated firewall mode. This drop is benign.
	IPSEC_AUTH_FIREWALL_DROP = 0x365D,
	// IPsec dropped a packet due to DoS throttling.
	IPSEC_THROTTLE_DROP = 0x365E,
	// IPsec DoS Protection matched an explicit block rule.
	IPSEC_DOSP_BLOCK = 0x3665,
	// IPsec DoS Protection received an IPsec specific multicast packet which is not allowed.
	IPSEC_DOSP_RECEIVED_MULTICAST = 0x3666,
	// IPsec DoS Protection received an incorrectly formatted packet.
	IPSEC_DOSP_INVALID_PACKET = 0x3667,
	// IPsec DoS Protection failed to look up state.
	IPSEC_DOSP_STATE_LOOKUP_FAILED = 0x3668,
	// IPsec DoS Protection failed to create state because the maximum number of entries allowed by policy has been reached.
	IPSEC_DOSP_MAX_ENTRIES = 0x3669,
	// IPsec DoS Protection received an IPsec negotiation packet for a keying module which is not allowed by policy.
	IPSEC_DOSP_KEYMOD_NOT_ALLOWED = 0x366A,
	// IPsec DoS Protection has not been enabled.
	IPSEC_DOSP_NOT_INSTALLED = 0x366B,
	// IPsec DoS Protection failed to create a per internal IP rate limit queue because the maximum number of queues allowed by policy has been reached.
	IPSEC_DOSP_MAX_PER_IP_RATELIMIT_QUEUES = 0x366C,
	// The requested section was not present in the activation context.
	SXS_SECTION_NOT_FOUND = 0x36B0,
	// The application has failed to start because its side-by-side configuration is incorrect. Please see the application event log or use the command-line sxstrace.exe tool for more detail.
	SXS_CANT_GEN_ACTCTX = 0x36B1,
	// The application binding data format is invalid.
	SXS_INVALID_ACTCTXDATA_FORMAT = 0x36B2,
	// The referenced assembly is not installed on your system.
	SXS_ASSEMBLY_NOT_FOUND = 0x36B3,
	// The manifest file does not begin with the required tag and format information.
	SXS_MANIFEST_FORMAT_ERROR = 0x36B4,
	// The manifest file contains one or more syntax errors.
	SXS_MANIFEST_PARSE_ERROR = 0x36B5,
	// The application attempted to activate a disabled activation context.
	SXS_ACTIVATION_CONTEXT_DISABLED = 0x36B6,
	// The requested lookup key was not found in any active activation context.
	SXS_KEY_NOT_FOUND = 0x36B7,
	// A component version required by the application conflicts with another component version already active.
	SXS_VERSION_CONFLICT = 0x36B8,
	// The type requested activation context section does not match the query API used.
	SXS_WRONG_SECTION_TYPE = 0x36B9,
	// Lack of system resources has required isolated activation to be disabled for the current thread of execution.
	SXS_THREAD_QUERIES_DISABLED = 0x36BA,
	// An attempt to set the process default activation context failed because the process default activation context was already set.
	SXS_PROCESS_DEFAULT_ALREADY_SET = 0x36BB,
	// The encoding group identifier specified is not recognized.
	SXS_UNKNOWN_ENCODING_GROUP = 0x36BC,
	// The encoding requested is not recognized.
	SXS_UNKNOWN_ENCODING = 0x36BD,
	// The manifest contains a reference to an invalid URI.
	SXS_INVALID_XML_NAMESPACE_URI = 0x36BE,
	// The application manifest contains a reference to a dependent assembly which is not installed.
	SXS_ROOT_MANIFEST_DEPENDENCY_NOT_INSTALLED = 0x36BF,
	// The manifest for an assembly used by the application has a reference to a dependent assembly which is not installed.
	SXS_LEAF_MANIFEST_DEPENDENCY_NOT_INSTALLED = 0x36C0,
	// The manifest contains an attribute for the assembly identity which is not valid.
	SXS_INVALID_ASSEMBLY_IDENTITY_ATTRIBUTE = 0x36C1,
	// The manifest is missing the required default namespace specification on the assembly element.
	SXS_MANIFEST_MISSING_REQUIRED_DEFAULT_NAMESPACE = 0x36C2,
	// The manifest has a default namespace specified on the assembly element but its value is not "urn:schemas-microsoft-com:asm.v1".
	SXS_MANIFEST_INVALID_REQUIRED_DEFAULT_NAMESPACE = 0x36C3,
	// The private manifest probed has crossed a path with an unsupported reparse point.
	SXS_PRIVATE_MANIFEST_CROSS_PATH_WITH_REPARSE_POINT = 0x36C4,
	// Two or more components referenced directly or indirectly by the application manifest have files by the same name.
	SXS_DUPLICATE_DLL_NAME = 0x36C5,
	// Two or more components referenced directly or indirectly by the application manifest have window classes with the same name.
	SXS_DUPLICATE_WINDOWCLASS_NAME = 0x36C6,
	// Two or more components referenced directly or indirectly by the application manifest have the same COM server CLSIDs.
	SXS_DUPLICATE_CLSID = 0x36C7,
	// Two or more components referenced directly or indirectly by the application manifest have proxies for the same COM interface IIDs.
	SXS_DUPLICATE_IID = 0x36C8,
	// Two or more components referenced directly or indirectly by the application manifest have the same COM type library TLBIDs.
	SXS_DUPLICATE_TLBID = 0x36C9,
	// Two or more components referenced directly or indirectly by the application manifest have the same COM ProgIDs.
	SXS_DUPLICATE_PROGID = 0x36CA,
	// Two or more components referenced directly or indirectly by the application manifest are different versions of the same component which is not permitted.
	SXS_DUPLICATE_ASSEMBLY_NAME = 0x36CB,
	// A component's file does not match the verification information present in the component manifest.
	SXS_FILE_HASH_MISMATCH = 0x36CC,
	// The policy manifest contains one or more syntax errors.
	SXS_POLICY_PARSE_ERROR = 0x36CD,
	// Manifest Parse Error : A string literal was expected, but no opening quote character was found.
	SXS_XML_E_MISSINGQUOTE = 0x36CE,
	// Manifest Parse Error : Incorrect syntax was used in a comment.
	SXS_XML_E_COMMENTSYNTAX = 0x36CF,
	// Manifest Parse Error : A name was started with an invalid character.
	SXS_XML_E_BADSTARTNAMECHAR = 0x36D0,
	// Manifest Parse Error : A name contained an invalid character.
	SXS_XML_E_BADNAMECHAR = 0x36D1,
	// Manifest Parse Error : A string literal contained an invalid character.
	SXS_XML_E_BADCHARINSTRING = 0x36D2,
	// Manifest Parse Error : Invalid syntax for an xml declaration.
	SXS_XML_E_XMLDECLSYNTAX = 0x36D3,
	// Manifest Parse Error : An Invalid character was found in text content.
	SXS_XML_E_BADCHARDATA = 0x36D4,
	// Manifest Parse Error : Required white space was missing.
	SXS_XML_E_MISSINGWHITESPACE = 0x36D5,
	// Manifest Parse Error : The character '>' was expected.
	SXS_XML_E_EXPECTINGTAGEND = 0x36D6,
	// Manifest Parse Error : A semi colon character was expected.
	SXS_XML_E_MISSINGSEMICOLON = 0x36D7,
	// Manifest Parse Error : Unbalanced parentheses.
	SXS_XML_E_UNBALANCEDPAREN = 0x36D8,
	// Manifest Parse Error : Internal error.
	SXS_XML_E_INTERNALERROR = 0x36D9,
	// Manifest Parse Error : Whitespace is not allowed at this location.
	SXS_XML_E_UNEXPECTED_WHITESPACE = 0x36DA,
	// Manifest Parse Error : End of file reached in invalid state for current encoding.
	SXS_XML_E_INCOMPLETE_ENCODING = 0x36DB,
	// Manifest Parse Error : Missing parenthesis.
	SXS_XML_E_MISSING_PAREN = 0x36DC,
	// Manifest Parse Error : A single or double closing quote character (\' or \") is missing.
	SXS_XML_E_EXPECTINGCLOSEQUOTE = 0x36DD,
	// Manifest Parse Error : Multiple colons are not allowed in a name.
	SXS_XML_E_MULTIPLE_COLONS = 0x36DE,
	// Manifest Parse Error : Invalid character for decimal digit.
	SXS_XML_E_INVALID_DECIMAL = 0x36DF,
	// Manifest Parse Error : Invalid character for hexadecimal digit.
	SXS_XML_E_INVALID_HEXIDECIMAL = 0x36E0,
	// Manifest Parse Error : Invalid unicode character value for this platform.
	SXS_XML_E_INVALID_UNICODE = 0x36E1,
	// Manifest Parse Error : Expecting whitespace or '?'.
	SXS_XML_E_WHITESPACEORQUESTIONMARK = 0x36E2,
	// Manifest Parse Error : End tag was not expected at this location.
	SXS_XML_E_UNEXPECTEDENDTAG = 0x36E3,
	// Manifest Parse Error : The following tags were not closed: %1.
	SXS_XML_E_UNCLOSEDTAG = 0x36E4,
	// Manifest Parse Error : Duplicate attribute.
	SXS_XML_E_DUPLICATEATTRIBUTE = 0x36E5,
	// Manifest Parse Error : Only one top level element is allowed in an XML document.
	SXS_XML_E_MULTIPLEROOTS = 0x36E6,
	// Manifest Parse Error : Invalid at the top level of the document.
	SXS_XML_E_INVALIDATROOTLEVEL = 0x36E7,
	// Manifest Parse Error : Invalid xml declaration.
	SXS_XML_E_BADXMLDECL = 0x36E8,
	// Manifest Parse Error : XML document must have a top level element.
	SXS_XML_E_MISSINGROOT = 0x36E9,
	// Manifest Parse Error : Unexpected end of file.
	SXS_XML_E_UNEXPECTEDEOF = 0x36EA,
	// Manifest Parse Error : Parameter entities cannot be used inside markup declarations in an internal subset.
	SXS_XML_E_BADPEREFINSUBSET = 0x36EB,
	// Manifest Parse Error : Element was not closed.
	SXS_XML_E_UNCLOSEDSTARTTAG = 0x36EC,
	// Manifest Parse Error : End element was missing the character '>'.
	SXS_XML_E_UNCLOSEDENDTAG = 0x36ED,
	// Manifest Parse Error : A string literal was not closed.
	SXS_XML_E_UNCLOSEDSTRING = 0x36EE,
	// Manifest Parse Error : A comment was not closed.
	SXS_XML_E_UNCLOSEDCOMMENT = 0x36EF,
	// Manifest Parse Error : A declaration was not closed.
	SXS_XML_E_UNCLOSEDDECL = 0x36F0,
	// Manifest Parse Error : A CDATA section was not closed.
	SXS_XML_E_UNCLOSEDCDATA = 0x36F1,
	// Manifest Parse Error : The namespace prefix is not allowed to start with the reserved string "xml".
	SXS_XML_E_RESERVEDNAMESPACE = 0x36F2,
	// Manifest Parse Error : System does not support the specified encoding.
	SXS_XML_E_INVALIDENCODING = 0x36F3,
	// Manifest Parse Error : Switch from current encoding to specified encoding not supported.
	SXS_XML_E_INVALIDSWITCH = 0x36F4,
	// Manifest Parse Error : The name 'xml' is reserved and must be lower case.
	SXS_XML_E_BADXMLCASE = 0x36F5,
	// Manifest Parse Error : The standalone attribute must have the value 'yes' or 'no'.
	SXS_XML_E_INVALID_STANDALONE = 0x36F6,
	// Manifest Parse Error : The standalone attribute cannot be used in external entities.
	SXS_XML_E_UNEXPECTED_STANDALONE = 0x36F7,
	// Manifest Parse Error : Invalid version number.
	SXS_XML_E_INVALID_VERSION = 0x36F8,
	// Manifest Parse Error : Missing equals sign between attribute and attribute value.
	SXS_XML_E_MISSINGEQUALS = 0x36F9,
	// Assembly Protection Error : Unable to recover the specified assembly.
	SXS_PROTECTION_RECOVERY_FAILED = 0x36FA,
	// Assembly Protection Error : The public key for an assembly was too short to be allowed.
	SXS_PROTECTION_PUBLIC_KEY_TOO_SHORT = 0x36FB,
	// Assembly Protection Error : The catalog for an assembly is not valid, or does not match the assembly's manifest.
	SXS_PROTECTION_CATALOG_NOT_VALID = 0x36FC,
	// An HRESULT could not be translated to a corresponding Win32 error code.
	SXS_UNTRANSLATABLE_HRESULT = 0x36FD,
	// Assembly Protection Error : The catalog for an assembly is missing.
	SXS_PROTECTION_CATALOG_FILE_MISSING = 0x36FE,
	// The supplied assembly identity is missing one or more attributes which must be present in this context.
	SXS_MISSING_ASSEMBLY_IDENTITY_ATTRIBUTE = 0x36FF,
	// The supplied assembly identity has one or more attribute names that contain characters not permitted in XML names.
	SXS_INVALID_ASSEMBLY_IDENTITY_ATTRIBUTE_NAME = 0x3700,
	// The referenced assembly could not be found.
	SXS_ASSEMBLY_MISSING = 0x3701,
	// The activation context activation stack for the running thread of execution is corrupt.
	SXS_CORRUPT_ACTIVATION_STACK = 0x3702,
	// The application isolation metadata for this process or thread has become corrupt.
	SXS_CORRUPTION = 0x3703,
	// The activation context being deactivated is not the most recently activated one.
	SXS_EARLY_DEACTIVATION = 0x3704,
	// The activation context being deactivated is not active for the current thread of execution.
	SXS_INVALID_DEACTIVATION = 0x3705,
	// The activation context being deactivated has already been deactivated.
	SXS_MULTIPLE_DEACTIVATION = 0x3706,
	// A component used by the isolation facility has requested to terminate the process.
	SXS_PROCESS_TERMINATION_REQUESTED = 0x3707,
	// A kernel mode component is releasing a reference on an activation context.
	SXS_RELEASE_ACTIVATION_CONTEXT = 0x3708,
	// The activation context of system default assembly could not be generated.
	SXS_SYSTEM_DEFAULT_ACTIVATION_CONTEXT_EMPTY = 0x3709,
	// The value of an attribute in an identity is not within the legal range.
	SXS_INVALID_IDENTITY_ATTRIBUTE_VALUE = 0x370A,
	// The name of an attribute in an identity is not within the legal range.
	SXS_INVALID_IDENTITY_ATTRIBUTE_NAME = 0x370B,
	// An identity contains two definitions for the same attribute.
	SXS_IDENTITY_DUPLICATE_ATTRIBUTE = 0x370C,
	// The identity string is malformed. This may be due to a trailing comma, more than two unnamed attributes, missing attribute name or missing attribute value.
	SXS_IDENTITY_PARSE_ERROR = 0x370D,
	// A string containing localized substitutable content was malformed. Either a dollar sign ($) was followed by something other than a left parenthesis or another dollar sign or an substitution's right parenthesis was not found.
	MALFORMED_SUBSTITUTION_STRING = 0x370E,
	// The public key token does not correspond to the public key specified.
	SXS_INCORRECT_PUBLIC_KEY_TOKEN = 0x370F,
	// A substitution string had no mapping.
	UNMAPPED_SUBSTITUTION_STRING = 0x3710,
	// The component must be locked before making the request.
	SXS_ASSEMBLY_NOT_LOCKED = 0x3711,
	// The component store has been corrupted.
	SXS_COMPONENT_STORE_CORRUPT = 0x3712,
	// An advanced installer failed during setup or servicing.
	ADVANCED_INSTALLER_FAILED = 0x3713,
	// The character encoding in the XML declaration did not match the encoding used in the document.
	XML_ENCODING_MISMATCH = 0x3714,
	// The identities of the manifests are identical but their contents are different.
	SXS_MANIFEST_IDENTITY_SAME_BUT_CONTENTS_DIFFERENT = 0x3715,
	// The component identities are different.
	SXS_IDENTITIES_DIFFERENT = 0x3716,
	// The assembly is not a deployment.
	SXS_ASSEMBLY_IS_NOT_A_DEPLOYMENT = 0x3717,
	// The file is not a part of the assembly.
	SXS_FILE_NOT_PART_OF_ASSEMBLY = 0x3718,
	// The size of the manifest exceeds the maximum allowed.
	SXS_MANIFEST_TOO_BIG = 0x3719,
	// The setting is not registered.
	SXS_SETTING_NOT_REGISTERED = 0x371A,
	// One or more required members of the transaction are not present.
	SXS_TRANSACTION_CLOSURE_INCOMPLETE = 0x371B,
	// The SMI primitive installer failed during setup or servicing.
	SMI_PRIMITIVE_INSTALLER_FAILED = 0x371C,
	// A generic command executable returned a result that indicates failure.
	GENERIC_COMMAND_FAILED = 0x371D,
	// A component is missing file verification information in its manifest.
	SXS_FILE_HASH_MISSING = 0x371E,
	// The specified channel path is invalid.
	EVT_INVALID_CHANNEL_PATH = 0x3A98,
	// The specified query is invalid.
	EVT_INVALID_QUERY = 0x3A99,
	// The publisher metadata cannot be found in the resource.
	EVT_PUBLISHER_METADATA_NOT_FOUND = 0x3A9A,
	// The template for an event definition cannot be found in the resource (error = %1).
	EVT_EVENT_TEMPLATE_NOT_FOUND = 0x3A9B,
	// The specified publisher name is invalid.
	EVT_INVALID_PUBLISHER_NAME = 0x3A9C,
	// The event data raised by the publisher is not compatible with the event template definition in the publisher's manifest.
	EVT_INVALID_EVENT_DATA = 0x3A9D,
	// The specified channel could not be found. Check channel configuration.
	EVT_CHANNEL_NOT_FOUND = 0x3A9F,
	// The specified xml text was not well-formed. See Extended Error for more details.
	EVT_MALFORMED_XML_TEXT = 0x3AA0,
	// The caller is trying to subscribe to a direct channel which is not allowed. The events for a direct channel go directly to a logfile and cannot be subscribed to.
	EVT_SUBSCRIPTION_TO_DIRECT_CHANNEL = 0x3AA1,
	// Configuration error.
	EVT_CONFIGURATION_ERROR = 0x3AA2,
	// The query result is stale / invalid. This may be due to the log being cleared or rolling over after the query result was created. Users should handle this code by releasing the query result object and reissuing the query.
	EVT_QUERY_RESULT_STALE = 0x3AA3,
	// Query result is currently at an invalid position.
	EVT_QUERY_RESULT_INVALID_POSITION = 0x3AA4,
	// Registered MSXML doesn't support validation.
	EVT_NON_VALIDATING_MSXML = 0x3AA5,
	// An expression can only be followed by a change of scope operation if it itself evaluates to a node set and is not already part of some other change of scope operation.
	EVT_FILTER_ALREADYSCOPED = 0x3AA6,
	// Can't perform a step operation from a term that does not represent an element set.
	EVT_FILTER_NOTELTSET = 0x3AA7,
	// Left hand side arguments to binary operators must be either attributes, nodes or variables and right hand side arguments must be constants.
	EVT_FILTER_INVARG = 0x3AA8,
	// A step operation must involve either a node test or, in the case of a predicate, an algebraic expression against which to test each node in the node set identified by the preceeding node set can be evaluated.
	EVT_FILTER_INVTEST = 0x3AA9,
	// This data type is currently unsupported.
	EVT_FILTER_INVTYPE = 0x3AAA,
	// A syntax error occurred at position %1!d!.
	EVT_FILTER_PARSEERR = 0x3AAB,
	// This operator is unsupported by this implementation of the filter.
	EVT_FILTER_UNSUPPORTEDOP = 0x3AAC,
	// The token encountered was unexpected.
	EVT_FILTER_UNEXPECTEDTOKEN = 0x3AAD,
	// The requested operation cannot be performed over an enabled direct channel. The channel must first be disabled before performing the requested operation.
	EVT_INVALID_OPERATION_OVER_ENABLED_DIRECT_CHANNEL = 0x3AAE,
	// Channel property %1!s! contains invalid value. The value has invalid type, is outside of valid range, can't be updated or is not supported by this type of channel.
	EVT_INVALID_CHANNEL_PROPERTY_VALUE = 0x3AAF,
	// Publisher property %1!s! contains invalid value. The value has invalid type, is outside of valid range, can't be updated or is not supported by this type of publisher.
	EVT_INVALID_PUBLISHER_PROPERTY_VALUE = 0x3AB0,
	// The channel fails to activate.
	EVT_CHANNEL_CANNOT_ACTIVATE = 0x3AB1,
	// The xpath expression exceeded supported complexity. Please symplify it or split it into two or more simple expressions.
	EVT_FILTER_TOO_COMPLEX = 0x3AB2,
	// the message resource is present but the message is not found in the string/message table.
	EVT_MESSAGE_NOT_FOUND = 0x3AB3,
	// The message id for the desired message could not be found.
	EVT_MESSAGE_ID_NOT_FOUND = 0x3AB4,
	// The substitution string for insert index (%1) could not be found.
	EVT_UNRESOLVED_VALUE_INSERT = 0x3AB5,
	// The description string for parameter reference (%1) could not be found.
	EVT_UNRESOLVED_PARAMETER_INSERT = 0x3AB6,
	// The maximum number of replacements has been reached.
	EVT_MAX_INSERTS_REACHED = 0x3AB7,
	// The event definition could not be found for event id (%1).
	EVT_EVENT_DEFINITION_NOT_FOUND = 0x3AB8,
	// The locale specific resource for the desired message is not present.
	EVT_MESSAGE_LOCALE_NOT_FOUND = 0x3AB9,
	// The resource is too old to be compatible.
	EVT_VERSION_TOO_OLD = 0x3ABA,
	// The resource is too new to be compatible.
	EVT_VERSION_TOO_NEW = 0x3ABB,
	// The channel at index %1!d! of the query can't be opened.
	EVT_CANNOT_OPEN_CHANNEL_OF_QUERY = 0x3ABC,
	// The publisher has been disabled and its resource is not available. This usually occurs when the publisher is in the process of being uninstalled or upgraded.
	EVT_PUBLISHER_DISABLED = 0x3ABD,
	// Attempted to create a numeric type that is outside of its valid range.
	EVT_FILTER_OUT_OF_RANGE = 0x3ABE,
	// The subscription fails to activate.
	EC_SUBSCRIPTION_CANNOT_ACTIVATE = 0x3AE8,
	// The log of the subscription is in disabled state, and cannot be used to forward events to. The log must first be enabled before the subscription can be activated.
	EC_LOG_DISABLED = 0x3AE9,
	// When forwarding events from local machine to itself, the query of the subscription can't contain target log of the subscription.
	EC_CIRCULAR_FORWARDING = 0x3AEA,
	// The credential store that is used to save credentials is full.
	EC_CREDSTORE_FULL = 0x3AEB,
	// The credential used by this subscription can't be found in credential store.
	EC_CRED_NOT_FOUND = 0x3AEC,
	// No active channel is found for the query.
	EC_NO_ACTIVE_CHANNEL = 0x3AED,
	// The resource loader failed to find MUI file.
	MUI_FILE_NOT_FOUND = 0x3AFC,
	// The resource loader failed to load MUI file because the file fail to pass validation.
	MUI_INVALID_FILE = 0x3AFD,
	// The RC Manifest is corrupted with garbage data or unsupported version or missing required item.
	MUI_INVALID_RC_CONFIG = 0x3AFE,
	// The RC Manifest has invalid culture name.
	MUI_INVALID_LOCALE_NAME = 0x3AFF,
	// The RC Manifest has invalid ultimatefallback name.
	MUI_INVALID_ULTIMATEFALLBACK_NAME = 0x3B00,
	// The resource loader cache doesn't have loaded MUI entry.
	MUI_FILE_NOT_LOADED = 0x3B01,
	// User stopped resource enumeration.
	RESOURCE_ENUM_USER_STOP = 0x3B02,
	// UI language installation failed.
	MUI_INTLSETTINGS_UILANG_NOT_INSTALLED = 0x3B03,
	// Locale installation failed.
	MUI_INTLSETTINGS_INVALID_LOCALE_NAME = 0x3B04,
	// A resource does not have default or neutral value.
	MRM_RUNTIME_NO_DEFAULT_OR_NEUTRAL_RESOURCE = 0x3B06,
	// Invalid PRI config file.
	MRM_INVALID_PRICONFIG = 0x3B07,
	// Invalid file type.
	MRM_INVALID_FILE_TYPE = 0x3B08,
	// Unknown qualifier.
	MRM_UNKNOWN_QUALIFIER = 0x3B09,
	// Invalid qualifier value.
	MRM_INVALID_QUALIFIER_VALUE = 0x3B0A,
	// No Candidate found.
	MRM_NO_CANDIDATE = 0x3B0B,
	// The ResourceMap or NamedResource has an item that does not have default or neutral resource..
	MRM_NO_MATCH_OR_DEFAULT_CANDIDATE = 0x3B0C,
	// Invalid ResourceCandidate type.
	MRM_RESOURCE_TYPE_MISMATCH = 0x3B0D,
	// Duplicate Resource Map.
	MRM_DUPLICATE_MAP_NAME = 0x3B0E,
	// Duplicate Entry.
	MRM_DUPLICATE_ENTRY = 0x3B0F,
	// Invalid Resource Identifier.
	MRM_INVALID_RESOURCE_IDENTIFIER = 0x3B10,
	// Filepath too long.
	MRM_FILEPATH_TOO_LONG = 0x3B11,
	// Unsupported directory type.
	MRM_UNSUPPORTED_DIRECTORY_TYPE = 0x3B12,
	// Invalid PRI File.
	MRM_INVALID_PRI_FILE = 0x3B16,
	// NamedResource Not Found.
	MRM_NAMED_RESOURCE_NOT_FOUND = 0x3B17,
	// ResourceMap Not Found.
	MRM_MAP_NOT_FOUND = 0x3B1F,
	// Unsupported MRT profile type.
	MRM_UNSUPPORTED_PROFILE_TYPE = 0x3B20,
	// Invalid qualifier operator.
	MRM_INVALID_QUALIFIER_OPERATOR = 0x3B21,
	// Unable to determine qualifier value or qualifier value has not been set.
	MRM_INDETERMINATE_QUALIFIER_VALUE = 0x3B22,
	// Automerge is enabled in the PRI file.
	MRM_AUTOMERGE_ENABLED = 0x3B23,
	// Too many resources defined for package.
	MRM_TOO_MANY_RESOURCES = 0x3B24,
	// The monitor returned a DDC/CI capabilities string that did not comply with the ACCESS.bus 3.0, DDC/CI 1.1 or MCCS 2 Revision 1 specification.
	MCA_INVALID_CAPABILITIES_STRING = 0x3B60,
	// The monitor's VCP Version (0xDF) VCP code returned an invalid version value.
	MCA_INVALID_VCP_VERSION = 0x3B61,
	// The monitor does not comply with the MCCS specification it claims to support.
	MCA_MONITOR_VIOLATES_MCCS_SPECIFICATION = 0x3B62,
	// The MCCS version in a monitor's mccs_ver capability does not match the MCCS version the monitor reports when the VCP Version (0xDF) VCP code is used.
	MCA_MCCS_VERSION_MISMATCH = 0x3B63,
	// The Monitor Configuration API only works with monitors that support the MCCS 1.0 specification, MCCS 2.0 specification or the MCCS 2.0 Revision 1 specification.
	MCA_UNSUPPORTED_MCCS_VERSION = 0x3B64,
	// An internal Monitor Configuration API error occurred.
	MCA_INTERNAL_ERROR = 0x3B65,
	// The monitor returned an invalid monitor technology type. CRT, Plasma and LCD (TFT) are examples of monitor technology types. This error implies that the monitor violated the MCCS 2.0 or MCCS 2.0 Revision 1 specification.
	MCA_INVALID_TECHNOLOGY_TYPE_RETURNED = 0x3B66,
	// The caller of SetMonitorColorTemperature specified a color temperature that the current monitor did not support. This error implies that the monitor violated the MCCS 2.0 or MCCS 2.0 Revision 1 specification.
	MCA_UNSUPPORTED_COLOR_TEMPERATURE = 0x3B67,
	// The requested system device cannot be identified due to multiple indistinguishable devices potentially matching the identification criteria.
	AMBIGUOUS_SYSTEM_DEVICE = 0x3B92,
	// The requested system device cannot be found.
	SYSTEM_DEVICE_NOT_FOUND = 0x3BC3,
	// Hash generation for the specified hash version and hash type is not enabled on the server.
	HASH_NOT_SUPPORTED = 0x3BC4,
	// The hash requested from the server is not available or no longer valid.
	HASH_NOT_PRESENT = 0x3BC5,
	// The secondary interrupt controller instance that manages the specified interrupt is not registered.
	SECONDARY_IC_PROVIDER_NOT_REGISTERED = 0x3BD9,
	// The information supplied by the GPIO client driver is invalid.
	GPIO_CLIENT_INFORMATION_INVALID = 0x3BDA,
	// The version specified by the GPIO client driver is not supported.
	GPIO_VERSION_NOT_SUPPORTED = 0x3BDB,
	// The registration packet supplied by the GPIO client driver is not valid.
	GPIO_INVALID_REGISTRATION_PACKET = 0x3BDC,
	// The requested operation is not supported for the specified handle.
	GPIO_OPERATION_DENIED = 0x3BDD,
	// The requested connect mode conflicts with an existing mode on one or more of the specified pins.
	GPIO_INCOMPATIBLE_CONNECT_MODE = 0x3BDE,
	// The interrupt requested to be unmasked is not masked.
	GPIO_INTERRUPT_ALREADY_UNMASKED = 0x3BDF,
	// The requested run level switch cannot be completed successfully.
	CANNOT_SWITCH_RUNLEVEL = 0x3C28,
	// The service has an invalid run level setting. The run level for a service must not be higher than the run level of its dependent services.
	INVALID_RUNLEVEL_SETTING = 0x3C29,
	// The requested run level switch cannot be completed successfully since one or more services will not stop or restart within the specified timeout.
	RUNLEVEL_SWITCH_TIMEOUT = 0x3C2A,
	// A run level switch agent did not respond within the specified timeout.
	RUNLEVEL_SWITCH_AGENT_TIMEOUT = 0x3C2B,
	// A run level switch is currently in progress.
	RUNLEVEL_SWITCH_IN_PROGRESS = 0x3C2C,
	// One or more services failed to start during the service startup phase of a run level switch.
	SERVICES_FAILED_AUTOSTART = 0x3C2D,
	// The task stop request cannot be completed immediately since task needs more time to shutdown.
	COM_TASK_STOP_PENDING = 0x3C8D,
	// Package could not be opened.
	INSTALL_OPEN_PACKAGE_FAILED = 0x3CF0,
	// Package was not found.
	INSTALL_PACKAGE_NOT_FOUND = 0x3CF1,
	// Package data is invalid.
	INSTALL_INVALID_PACKAGE = 0x3CF2,
	// Package failed updates, dependency or conflict validation.
	INSTALL_RESOLVE_DEPENDENCY_FAILED = 0x3CF3,
	// There is not enough disk space on your computer. Please free up some space and try again.
	INSTALL_OUT_OF_DISK_SPACE = 0x3CF4,
	// There was a problem downloading your product.
	INSTALL_NETWORK_FAILURE = 0x3CF5,
	// Package could not be registered.
	INSTALL_REGISTRATION_FAILURE = 0x3CF6,
	// Package could not be unregistered.
	INSTALL_DEREGISTRATION_FAILURE = 0x3CF7,
	// User cancelled the install request.
	INSTALL_CANCEL = 0x3CF8,
	// Install failed. Please contact your software vendor.
	INSTALL_FAILED = 0x3CF9,
	// Removal failed. Please contact your software vendor.
	REMOVE_FAILED = 0x3CFA,
	// The provided package is already installed, and reinstallation of the package was blocked. Check the AppXDeployment-Server event log for details.
	PACKAGE_ALREADY_EXISTS = 0x3CFB,
	// The application cannot be started. Try reinstalling the application to fix the problem.
	NEEDS_REMEDIATION = 0x3CFC,
	// A Prerequisite for an install could not be satisfied.
	INSTALL_PREREQUISITE_FAILED = 0x3CFD,
	// The package repository is corrupted.
	PACKAGE_REPOSITORY_CORRUPTED = 0x3CFE,
	// To install this application you need either a Windows developer license or a sideloading-enabled system.
	INSTALL_POLICY_FAILURE = 0x3CFF,
	// The application cannot be started because it is currently updating.
	PACKAGE_UPDATING = 0x3D00,
	// The package deployment operation is blocked by policy. Please contact your system administrator.
	DEPLOYMENT_BLOCKED_BY_POLICY = 0x3D01,
	// The package could not be installed because resources it modifies are currently in use.
	PACKAGES_IN_USE = 0x3D02,
	// The package could not be recovered because necessary data for recovery have been corrupted.
	RECOVERY_FILE_CORRUPT = 0x3D03,
	// The signature is invalid. To register in developer mode, AppxSignature.p7x and AppxBlockMap.xml must be valid or should not be present.
	INVALID_STAGED_SIGNATURE = 0x3D04,
	// An error occurred while deleting the package's previously existing application data.
	DELETING_EXISTING_APPLICATIONDATA_STORE_FAILED = 0x3D05,
	// The package could not be installed because a higher version of this package is already installed.
	INSTALL_PACKAGE_DOWNGRADE = 0x3D06,
	// An error in a system binary was detected. Try refreshing the PC to fix the problem.
	SYSTEM_NEEDS_REMEDIATION = 0x3D07,
	// A corrupted CLR NGEN binary was detected on the system.
	APPX_INTEGRITY_FAILURE_CLR_NGEN = 0x3D08,
	// The operation could not be resumed because necessary data for recovery have been corrupted.
	RESILIENCY_FILE_CORRUPT = 0x3D09,
	// The package could not be installed because the Windows Firewall service is not running. Enable the Windows Firewall service and try again.
	INSTALL_FIREWALL_SERVICE_NOT_RUNNING = 0x3D0A,
	// The process has no package identity.
	APPMODEL_ERROR_NO_PACKAGE = 0x3D54,
	// The package runtime information is corrupted.
	APPMODEL_ERROR_PACKAGE_RUNTIME_CORRUPT = 0x3D55,
	// The package identity is corrupted.
	APPMODEL_ERROR_PACKAGE_IDENTITY_CORRUPT = 0x3D56,
	// The process has no application identity.
	APPMODEL_ERROR_NO_APPLICATION = 0x3D57,
	// Loading the state store failed.
	STATE_LOAD_STORE_FAILED = 0x3DB8,
	// Retrieving the state version for the application failed.
	STATE_GET_VERSION_FAILED = 0x3DB9,
	// Setting the state version for the application failed.
	STATE_SET_VERSION_FAILED = 0x3DBA,
	// Resetting the structured state of the application failed.
	STATE_STRUCTURED_RESET_FAILED = 0x3DBB,
	// State Manager failed to open the container.
	STATE_OPEN_CONTAINER_FAILED = 0x3DBC,
	// State Manager failed to create the container.
	STATE_CREATE_CONTAINER_FAILED = 0x3DBD,
	// State Manager failed to delete the container.
	STATE_DELETE_CONTAINER_FAILED = 0x3DBE,
	// State Manager failed to read the setting.
	STATE_READ_SETTING_FAILED = 0x3DBF,
	// State Manager failed to write the setting.
	STATE_WRITE_SETTING_FAILED = 0x3DC0,
	// State Manager failed to delete the setting.
	STATE_DELETE_SETTING_FAILED = 0x3DC1,
	// State Manager failed to query the setting.
	STATE_QUERY_SETTING_FAILED = 0x3DC2,
	// State Manager failed to read the composite setting.
	STATE_READ_COMPOSITE_SETTING_FAILED = 0x3DC3,
	// State Manager failed to write the composite setting.
	STATE_WRITE_COMPOSITE_SETTING_FAILED = 0x3DC4,
	// State Manager failed to enumerate the containers.
	STATE_ENUMERATE_CONTAINER_FAILED = 0x3DC5,
	// State Manager failed to enumerate the settings.
	STATE_ENUMERATE_SETTINGS_FAILED = 0x3DC6,
	// The size of the state manager composite setting value has exceeded the limit.
	STATE_COMPOSITE_SETTING_VALUE_SIZE_LIMIT_EXCEEDED = 0x3DC7,
	// The size of the state manager setting value has exceeded the limit.
	STATE_SETTING_VALUE_SIZE_LIMIT_EXCEEDED = 0x3DC8,
	// The length of the state manager setting name has exceeded the limit.
	STATE_SETTING_NAME_SIZE_LIMIT_EXCEEDED = 0x3DC9,
	// The length of the state manager container name has exceeded the limit.
	STATE_CONTAINER_NAME_SIZE_LIMIT_EXCEEDED = 0x3DCA,
	// This API cannot be used in the context of the caller's application type.
	API_UNAVAILABLE = 0x3DE1,
}
