#+build darwin
package tests_vendor

// Homebrew stops shipping lua@5.4 on 2027-08-26, so macOS tests 5.5. Only one Lua version can be linked into a program.
@(require) import _ "lua/5.5"
