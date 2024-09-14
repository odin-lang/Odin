#+build windows
package sys_windows

foreign import uxtheme "system:UxTheme.lib"

MARGINS :: distinct [4]int
PMARGINS :: ^MARGINS

@(default_calling_convention="system")
foreign uxtheme {
    IsThemeActive :: proc() -> BOOL ---
}
