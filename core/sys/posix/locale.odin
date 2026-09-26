#+build windows, linux, darwin, netbsd, openbsd, freebsd
package posix

import "core:c/libc"

localeconv      :: libc.localeconv
setlocale       :: libc.setlocale

lconv           :: libc.lconv

Locale_Category :: libc.Locale_Category
