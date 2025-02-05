package sdl3

import "core:c"

Folder :: enum c.int {
	HOME,        /**< The folder which contains all of the current user's data, preferences, and documents. It usually contains most of the other folders. If a requested folder does not exist, the home folder can be considered a safe fallback to store a user's documents. */
	DESKTOP,     /**< The folder of files that are displayed on the desktop. Note that the existence of a desktop folder does not guarantee that the system does show icons on its desktop; certain GNU/Linux distros with a graphical environment may not have desktop icons. */
	DOCUMENTS,   /**< User document files, possibly application-specific. This is a good place to save a user's projects. */
	DOWNLOADS,   /**< Standard folder for user files downloaded from the internet. */
	MUSIC,       /**< Music files that can be played using a standard music player (mp3, ogg...). */
	PICTURES,    /**< Image files that can be displayed using a standard viewer (png, jpg...). */
	PUBLICSHARE, /**< Files that are meant to be shared with other users on the same computer. */
	SAVEDGAMES,  /**< Save files for games. */
	SCREENSHOTS, /**< Application screenshots. */
	TEMPLATES,   /**< Template files to be used when the user requests the desktop environment to create a new file in a certain folder, such as "New Text File.txt".  Any file in the Templates folder can be used as a starting point for a new file. */
	VIDEOS,      /**< Video files that can be played using a standard video player (mp4, webm...). */
}

PathType :: enum c.int {
	NONE,      /**< path does not exist */
	FILE,      /**< a normal file */
	DIRECTORY, /**< a directory */
	OTHER,     /**< something completely different like a device node (not a symlink, those are always followed) */
}

PathInfo :: struct {
	type:        PathType,  /**< the path type */
	size:        Uint64,    /**< the file size in bytes */
	create_time: Time,      /**< the time when the path was created */
	modify_time: Time,      /**< the last time the path was modified */
	access_time: Time,      /**< the last time the path was read */
}


GlobFlags :: distinct bit_set[GlobFlag; Uint32]
GlobFlag :: enum Uint32 {
	CASEINSENSITIVE  = 0,
}

GLOB_CASEINSENSITIVE :: GlobFlags{.CASEINSENSITIVE}

EnumerationResult :: enum c.int {
	CONTINUE,   /**< Value that requests that enumeration continue. */
	SUCCESS,    /**< Value that requests that enumeration stop, successfully. */
	FAILURE,    /**< Value that requests that enumeration stop, as a failure. */
}


EnumerateDirectoryCallback :: #type proc "c" (userdata: rawptr, dirname, fname: cstring) -> EnumerationResult


@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	GetBasePath         :: proc() -> cstring ---
	GetPrefPath         :: proc(org, app: cstring) -> [^]c.char ---
	GetUserFolder       :: proc(folder: Folder) -> cstring ---
	CreateDirectory     :: proc(path: cstring) -> bool ---
	EnumerateDirectory  :: proc(path: cstring, callback: EnumerateDirectoryCallback, userdata: rawptr) -> bool ---
	RemovePath          :: proc(path: cstring) -> bool ---
	RenamePath          :: proc(oldpath, newpath: cstring) -> bool ---
	CopyFile            :: proc(oldpath, newpath: cstring) -> bool ---
	GetPathInfo         :: proc(path: cstring, info: ^PathInfo) -> bool ---
	GlobDirectory       :: proc(path: cstring, pattern: cstring, flags: GlobFlags, count: ^c.int) -> [^][^]c.char ---
	GetCurrentDirectory :: proc() -> [^]c.char ---
}