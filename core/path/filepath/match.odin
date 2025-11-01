#+build !wasi
#+build !js
package filepath

import os "core:os/os2"

// match states whether "name" matches the shell pattern
// Pattern syntax is:
//	pattern:
//		{term}
//	term:
//		'*'	        matches any sequence of non-/ characters
//		'?'             matches any single non-/ character
//		'[' ['^']  { character-range } ']'
//		                character classification (cannot be empty)
//		c               matches character c (c != '*', '?', '\\', '[')
//		'\\' c          matches character c
//
//	character-range
//		c               matches character c (c != '\\', '-', ']')
//		'\\' c          matches character c
//		lo '-' hi       matches character c for lo <= c <= hi
//
// match requires that the pattern matches the entirety of the name, not just a substring
// The only possible error returned is .Syntax_Error
//
// NOTE(bill): This is effectively the shell pattern matching system found
//
match :: os.match

// glob returns the names of all files matching pattern or nil if there are no matching files
// The syntax of patterns is the same as "match".
// The pattern may describe hierarchical names such as /usr/*/bin (assuming '/' is a separator)
//
// glob ignores file system errors
//
glob :: os.glob