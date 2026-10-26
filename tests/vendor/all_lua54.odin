#+build !darwin
package tests_vendor

// Lua 5.4 where the system library is 5.4 (Ubuntu 24.04) or vendored; macOS uses 5.5, see all_lua55.odin.
// Only one Lua version can be linked into a program.
@(require) import _ "lua/5.4"
