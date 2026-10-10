// Tests PR #7848 https://github.com/odin-lang/Odin/pull/7848
// `run.bat` and `run.sh` first check `pr_7848` with `-overlay`, `-workspace`, and `-export-semantics`
package test_issues

import "core:encoding/json"
import "core:os"
import "core:strings"
import "core:testing"
import tf "core:odin/tool-format"

@(private="file")
load :: proc(t: ^testing.T, path: string) -> (s: tf.Semantics) {
	data, err := os.read_entire_file(path, context.temp_allocator)
	testing.expectf(t, err == nil, "cannot read %s: %v", path, err)
	uerr := tf.unmarshal_semantics(data, &s, context.temp_allocator)
	testing.expectf(t, uerr == nil, "cannot decode %s: %v", path, uerr)
	return
}

@(private="file")
file_index :: proc(s: tf.Semantics, suffix: string) -> int {
	for f, i in s.files {
		if strings.has_suffix(f, suffix) {
			return i
		}
	}
	return -1
}

@(private="file")
find_entity :: proc(s: tf.Semantics, name: string, kind: tf.Entity_Kind) -> (e: tf.Entity, count: int) {
	for x in s.entities {
		if x.name == name && x.kind == kind {
			e = x
			count += 1
		}
	}
	return
}

@(private="file")
offset_of :: proc(t: ^testing.T, path, text: string) -> int {
	data, err := os.read_entire_file(path, context.temp_allocator)
	testing.expectf(t, err == nil, "cannot read %s: %v", path, err)
	offset := strings.index(string(data), text)
	testing.expectf(t, offset >= 0, "%q is not in %s", text, path)
	return offset
}

@(test)
test_pr_7848_formats :: proc(t: ^testing.T) {
	js := load(t, "pr_7848.json")
	cb := load(t, "pr_7848.cbor")
	a, _ := json.marshal(js, allocator=context.temp_allocator)
	b, _ := json.marshal(cb, allocator=context.temp_allocator)
	testing.expect(t, len(js.entities) > 0)
	testing.expect(t, string(a) == string(b), "the JSON and CBOR exports differ")
}

@(test)
test_pr_7848_overlay :: proc(t: ^testing.T) {
	s := load(t, "pr_7848.cbor")
	for f in s.files {
		testing.expectf(t, !strings.has_suffix(f, "deleted.odin") && !strings.contains(f, "pr_7848/overlay"), "%s should not be checked", f)
	}

	replaced, _ := find_entity(s, "REPLACED", .Constant)
	added,    _ := find_entity(s, "ADDED", .Constant)
	testing.expect_value(t, replaced.value, "2")
	testing.expect_value(t, added.value, "4")
	testing.expect_value(t, replaced.file, file_index(s, "pkg_a/a.odin"))
	testing.expect_value(t, added.file, file_index(s, "pkg_a/added.odin"))

	// offsets are into the replacement's text
	testing.expect_value(t, replaced.offset, offset_of(t, "../pr_7848/overlay/a.odin", "REPLACED"))
}

@(test)
test_pr_7848_workspace :: proc(t: ^testing.T) {
	s := load(t, "pr_7848.cbor")
	testing.expect_value(t, len(s.exported), 4)
	for suffix in ([]string{"pkg_a/a.odin", "pkg_a/added.odin", "pkg_a/b.odin", "pkg_b/b.odin"}) {
		i := file_index(s, suffix)
		testing.expectf(t, 0 <= i && i < len(s.exported), "%s should be exported", suffix)
	}

	b := file_index(s, "pkg_b/b.odin")
	if !testing.expect(t, 0 <= b && b < len(s.exported)) {
		return
	}
	ids := tf.find_idents(s.exported[b].uses, offset_of(t, "../pr_7848/pkg_b/b.odin", "FIVE"))
	if testing.expect_value(t, len(ids), 1) {
		five := s.entities[ids[0].entity]
		testing.expect_value(t, five.name, "FIVE")
		testing.expect_value(t, five.file, file_index(s, "pkg_a/b.odin"))
	}
}

@(test)
test_pr_7848_export :: proc(t: ^testing.T) {
	s := load(t, "pr_7848.cbor")
	path := "../pr_7848/pkg_a/b.odin"
	i := file_index(s, "pkg_a/b.odin")
	if !testing.expect(t, 0 <= i && i < len(s.exported)) {
		return
	}
	b := s.exported[i]

	point, _ := find_entity(s, "Point", .Type)
	testing.expect_value(t, point.size, 16)
	testing.expect_value(t, point.align, 8)
	if testing.expect_value(t, len(point.fields), 3) {
		testing.expect_value(t, point.fields[1], tf.Field{"y", 4})
		testing.expect_value(t, point.fields[2], tf.Field{"z", 8})
	}

	five, _ := find_entity(s, "FIVE", .Constant)
	testing.expect_value(t, five.value, "5")

	// the copies made by each instantiation are one entity, with the generic's own type
	twice, count := find_entity(s, "twice", .Procedure)
	testing.expect_value(t, count, 1)
	testing.expectf(t, 0 <= twice.type && twice.type < len(s.types) && strings.contains(s.types[twice.type], "$T"), "`twice` should have the generic's type")

	// a call to a group refers to the procedure it picks
	ids := tf.find_idents(b.uses, offset_of(t, path, "add(a"))
	if testing.expect_value(t, len(ids), 1) {
		picked := s.entities[ids[0].entity]
		testing.expect_value(t, picked.name, "add_int")
		testing.expect_value(t, picked.kind, tf.Entity_Kind.Procedure)
	}

	ids = tf.find_idents(b.uses, offset_of(t, path, "p.z") + 2)
	if testing.expect_value(t, len(ids), 1) {
		z := s.entities[ids[0].entity]
		testing.expect_value(t, z.name, "z")
		testing.expect_value(t, z.kind, tf.Entity_Kind.Field)
	}

	// the `when` branch that is not taken
	untaken := offset_of(t, path, "c += 100")
	inactive := false
	for j := 0; j+1 < len(b.inactive); j += 2 {
		inactive ||= int(b.inactive[j]) <= untaken && untaken < int(b.inactive[j+1])
	}
	testing.expect(t, inactive, "the untaken `when` branch should be inactive")
	testing.expect_value(t, len(tf.find_idents(b.uses, untaken)), 0)
}
