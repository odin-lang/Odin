package filepath

SEPARATOR :: '\\'
SEPARATOR_STRING :: `\`
LIST_SEPARATOR :: ';'

is_UNC :: proc(path: string) -> bool {
	return len(volume_name(path)) > 2
}