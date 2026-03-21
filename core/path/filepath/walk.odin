#+build !wasi
#+build !js
package filepath

import "core:os"

Walker :: os.Walker

/*
Initializes a walker, either using a path or a file pointer to a directory the walker will start at.

You are allowed to repeatedly call this to reuse it for later walks.

For an example on how to use the walker, see `walker_walk`.
*/
walker_init :: os.walker_init

/*
Creates a walker, either using a path or a file pointer to a directory the walker will start at.

For an example on how to use the walker, see `walker_walk`.
*/
walker_create :: os.walker_create

/*
Returns the last error that occurred during the walker's operations.

Can be called while iterating, or only at the end to check if anything failed.
*/
walker_error :: os.walker_error

walker_destroy :: os.walker_destroy

// Marks the current directory to be skipped (not entered into).
walker_skip_dir :: os.walker_skip_dir

/*
Returns the next file info in the iterator, files are iterated in breadth-first order.

If an error occurred opening a directory, you may get zero'd info struct and
`walker_error` will return the error.

Example:
	package main

	import "core:fmt"
	import "core:strings"
	import "core:os"

	main :: proc() {
		w := os.walker_create("core")
		defer os.walker_destroy(&w)

		for info in os.walker_walk(&w) {
			// Optionally break on the first error:
			// _ = walker_error(&w) or_break

			// Or, handle error as we go:
			if path, err := os.walker_error(&w); err != nil {
				fmt.eprintfln("failed walking %s: %s", path, err)
				continue
			}

			// Or, do not handle errors during iteration, and just check the error at the end.



			// Skip a directory:
			if strings.has_suffix(info.fullpath, ".git") {
				os.walker_skip_dir(&w)
				continue
			}

			fmt.printfln("%#v", info)
		}

		// Handle error if one happened during iteration at the end:
		if path, err := os.walker_error(&w); err != nil {
			fmt.eprintfln("failed walking %s: %v", path, err)
		}
	}
*/
walker_walk :: os.walker_walk

/*
	Reads the file `f` (assuming it is a directory) and returns the unsorted directory entries.
	This returns up to `n` entries OR all of them if `n <= 0`.
*/
read_directory :: os.read_directory

/*
	Reads the file `f` (assuming it is a directory) and returns all of the unsorted directory entries.
*/
read_all_directory :: os.read_all_directory

/*
	Reads the named directory by path (assuming it is a directory) and returns the unsorted directory entries.
	This returns up to `n` entries OR all of them if `n <= 0`.
*/
read_directory_by_path :: os.read_directory_by_path

/*
	Reads the named directory by path (assuming it is a directory) and returns all of the unsorted directory entries.
*/
read_all_directory_by_path :: os.read_all_directory_by_path