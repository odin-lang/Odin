#+private
#+build !js
package archive_sevenz

import "core:archive"

Solid_Entry :: struct {
	using entry: archive.Walked_Entry,
	pick:        Filter_Pick,
	stream:      bool,
}
