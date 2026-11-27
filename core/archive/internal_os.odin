#+build !js
package archive

import "base:runtime"
import "core:os"
import "core:slice"
import "core:strings"

Walked_Entry :: struct {
	name: string,
	info: os.File_Info,
}

Walk :: struct {
	root:      string,
	walker:    os.Walker,
	name:      [dynamic]u8,
	prefix:    int,
	entries:   [dynamic]Walked_Entry,
	index:     int,
	sorted:    bool,
	err:       Error,
	allocator: runtime.Allocator,
}

_walk_create :: proc(w: ^Walk, dir: string, prefix := "", sorted := false, allocator := context.allocator) -> (err: Error) {
	w^ = {}
	w.allocator         = allocator
	w.sorted            = sorted
	w.name.allocator    = allocator
	w.entries.allocator = allocator
	w.root   = os.get_absolute_path(dir, allocator) or_return
	w.walker = os.walker_create(w.root)
	if base := strings.trim(prefix, "/"); base != "" {
		append(&w.name, base) or_return
		append(&w.name, '/') or_return
		w.prefix = len(w.name)
		info := os.stat(w.root, allocator) or_return
		_walk_keep(w, base, info) or_return
	}
	if !sorted {
		return nil
	}
	for entry in _walk_step(w) {
		info := os.file_info_clone(entry.info, allocator) or_return
		_walk_keep(w, entry.name, info) or_return
	}
	slice.sort_by(w.entries[:], proc(a, b: Walked_Entry) -> bool {
		return a.name < b.name
	})
	return w.err
}

_walk_next :: proc(w: ^Walk) -> (entry: Walked_Entry, ok: bool) {
	if w.index < len(w.entries) {
		w.index += 1
		return w.entries[w.index - 1], true
	}
	if w.sorted || w.err != nil {
		return
	}
	return _walk_step(w)
}

_walk_destroy :: proc(w: ^Walk) {
	for entry in w.entries {
		delete(entry.name, w.allocator)
		os.file_info_delete(entry.info, w.allocator)
	}
	delete(w.entries)
	delete(w.name)
	delete(w.root, w.allocator)
	os.walker_destroy(&w.walker)
	w^ = {}
}

@(private="file")
_walk_step :: proc(w: ^Walk) -> (entry: Walked_Entry, ok: bool) {
	info, more := os.walker_walk(&w.walker)
	if _, walk_err := os.walker_error(&w.walker); walk_err != nil {
		w.err = walk_err
		return
	}
	if !more {
		return
	}
	rel := info.fullpath[len(w.root):]
	for len(rel) > 0 && (rel[0] == '/' || rel[0] == os.Path_Separator) {
		rel = rel[1:]
	}
	resize(&w.name, w.prefix)
	if _, append_err := append(&w.name, rel); append_err != nil {
		w.err = append_err
		return
	}
	for &c in w.name[w.prefix:] {
		if c == os.Path_Separator {
			c = '/'
		}
	}
	return {string(w.name[:]), info}, true
}

@(private="file")
_walk_keep :: proc(w: ^Walk, name: string, info: os.File_Info) -> (err: Error) {
	entry := Walked_Entry{info = info}
	defer if err != nil {
		delete(entry.name, w.allocator)
		os.file_info_delete(info, w.allocator)
	}
	entry.name = strings.clone(name, w.allocator) or_return
	append(&w.entries, entry) or_return
	return nil
}
