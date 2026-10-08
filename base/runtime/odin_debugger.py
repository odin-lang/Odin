# Pretty printers for Odin types in gdb and lldb
#
#   gdb:  source <odin>/base/runtime/odin_debugger.py
#   lldb: command script import <odin>/base/runtime/odin_debugger.py
#
# gdb also loads it by itself from the `.debug_gdb_scripts` section of an ELF binary built with `-debug`,
# once that binary's directory is trusted, with `add-auto-load-safe-path <directory>`
#
# Shown: `string`, `string16`, slices, dynamic arrays (and fixed capacity ones), maps as their entries,
# and unions as the variant they hold, or `nil`.
# Types are recognised by their fields rather than their names, so named types, such as
# `Table :: map[string]int`, are shown the same way.
#
# A map's debug type does not describe its memory: `data` points to a struct whose fields give the
# `key`, `value` and `hash` types and how keys and values are packed into cells, `key_cell` and `value_cell`
# (see `init_map_internal_debug_types` in the compiler and `Raw_Map` in `base:runtime`).
# A union's members are its variants, `v<tag>`, and the `tag` itself, except for a `Maybe` of a pointer,
# which is `v0` alone and nil when the pointer is (see `lb_debug_union`).
# Every target Odin supports is little-endian.

import re

MAX_STRING_BYTES = 64*1024

MAP_METADATA_FIELDS = ["key", "value", "hash", "key_cell", "value_cell"]


def odin_kind(type_name, field_names, data_is_pointer, data_is_array, data_target_fields):
	if field_names == ["data", "len"] and type_name in ("string", "string16"):
		return type_name
	if field_names == ["data", "len", "allocator"] and data_target_fields == MAP_METADATA_FIELDS:
		return "map"
	if field_names == ["data", "len", "cap", "allocator"] and data_is_pointer:
		return "dynamic"
	if field_names == ["data", "len"] and data_is_pointer:
		return "slice"
	if field_names == ["data", "len"] and data_is_array:
		return "fixed"
	return None


def is_odin_union(field_names):
	variants = [n for n in field_names if n != "tag"]
	return len(variants) != 0 and all(re.fullmatch(r"v[0-9]+", n) for n in variants)


def union_variant(field_names, tag):
	# the member holding the union's value, None when it is nil; `tag` is None for a `Maybe` of a pointer
	if tag is None:
		return "v0"
	name = "v%d" % tag
	if name in field_names:
		return name
	if tag == 0:
		return None
	raise ValueError("invalid tag %d" % tag)


def cell_layout(elem_size, cell_size, cell_data_size):
	# A cell is the element type itself when packing needs no padding,
	# else `struct{v: [n]T, _: [padding]u8}`, where `cell_data_size` is the size of `v`
	if cell_size == elem_size:
		return elem_size, 1, 0
	per_cell = cell_data_size // elem_size
	if per_cell == 1:
		return cell_size, 1, 0
	return elem_size, per_cell, cell_size - per_cell*elem_size


def cell_address(base, layout, index):
	stride, per_cell, padding = layout
	return base + index*stride + (index // per_cell)*padding


def map_capacity(data, length):
	if data == 0:
		return 0
	capacity = 1 << (data & 63)
	if length <= 0 or length > capacity:
		return 0
	if capacity > 1 << 40:
		return 0
	return capacity


def map_slots(data, length, key_layout, value_layout, hash_size, read_memory):
	capacity = map_capacity(data, length)
	if capacity == 0:
		return
	keys   = data & ~63
	values = cell_address(keys,   key_layout,   capacity)
	hashes = cell_address(values, value_layout, capacity)
	tombstone = 1 << (8*hash_size - 1)
	found = 0
	chunk = 1024
	for start in range(0, capacity, chunk):
		count = min(chunk, capacity - start)
		raw = read_memory(hashes + start*hash_size, count*hash_size)
		for j in range(count):
			h = int.from_bytes(raw[j*hash_size:(j+1)*hash_size], "little")
			if h != 0 and h & tombstone == 0:
				yield cell_address(keys, key_layout, start+j), cell_address(values, value_layout, start+j)
				found += 1
				if found == length:
					return


def array_count(data, length, capacity=None):
	if data == 0:
		return 0
	if length <= 0:
		return 0
	if capacity is not None and length > capacity:
		return 0
	return length


def read_text(read_memory, address, count, unit, encoding):
	if address == 0 or count <= 0:
		return ""
	size = min(count*unit, MAX_STRING_BYTES)
	text = read_memory(address, size).decode(encoding, "replace")
	if size < count*unit:
		text += "..."
	return text


################################################################################
# gdb

try:
	import gdb
except ImportError:
	gdb = None

if gdb is not None:
	def _gdb_read(address, size):
		return bytes(gdb.selected_inferior().read_memory(address, size))

	def _gdb_fields(t):
		return {f.name: f.type for f in t.fields()}

	def _gdb_kind(t):
		if t.code != gdb.TYPE_CODE_STRUCT:
			return None
		names = [f.name for f in t.fields()]
		if not names or names[0] != "data":
			return None
		data = t.fields()[0].type.strip_typedefs()
		target_fields = []
		if data.code == gdb.TYPE_CODE_PTR:
			target = data.target().strip_typedefs()
			if target.code == gdb.TYPE_CODE_STRUCT:
				target_fields = [f.name for f in target.fields()]
		return odin_kind(t.name, names, data.code == gdb.TYPE_CODE_PTR, data.code == gdb.TYPE_CODE_ARRAY, target_fields)

	def _gdb_cell_layout(elem, cell):
		cell_data_size = 0
		if cell.sizeof != elem.sizeof:
			cell_data_size = _gdb_fields(cell.strip_typedefs())["v"].sizeof
		return cell_layout(elem.sizeof, cell.sizeof, cell_data_size)

	class _GdbString:
		def __init__(self, val, kind):
			self.val = val
			self.unit, self.encoding = (1, "utf-8") if kind == "string" else (2, "utf-16-le")

		def to_string(self):
			return read_text(_gdb_read, int(self.val["data"]), int(self.val["len"]), self.unit, self.encoding)

		def display_hint(self):
			return "string"

	class _GdbArray:
		def __init__(self, val, kind):
			self.val = val
			self.kind = kind

		def to_string(self):
			if self.kind == "dynamic":
				return "len=%d cap=%d" % (int(self.val["len"]), int(self.val["cap"]))
			return "len=%d" % int(self.val["len"])

		def display_hint(self):
			return "array"

		def children(self):
			data = self.val["data"]
			length = int(self.val["len"])
			if self.kind == "fixed":
				capacity = data.type.strip_typedefs().range()[1] + 1
				for i in range(array_count(1, length, capacity)):
					yield "[%d]" % i, data[i]
				return
			capacity = int(self.val["cap"]) if self.kind == "dynamic" else None
			for i in range(array_count(int(data), length, capacity)):
				yield "[%d]" % i, (data + i).dereference()

	class _GdbMap:
		def __init__(self, val):
			self.val = val
			f = _gdb_fields(val["data"].type.strip_typedefs().target().strip_typedefs())
			self.key_type   = f["key"]
			self.value_type = f["value"]
			self.key_layout   = _gdb_cell_layout(f["key"],   f["key_cell"])
			self.value_layout = _gdb_cell_layout(f["value"], f["value_cell"])
			self.hash_size = f["hash"].sizeof

		def to_string(self):
			return "len=%d" % int(self.val["len"])

		def display_hint(self):
			return "map"

		def children(self):
			slots = map_slots(int(self.val["data"]), int(self.val["len"]), self.key_layout, self.value_layout, self.hash_size, _gdb_read)
			for key, value in slots:
				yield "key",   gdb.Value(key).cast(self.key_type.pointer()).dereference()
				yield "value", gdb.Value(value).cast(self.value_type.pointer()).dereference()

	class _GdbUnion:
		def __init__(self, val):
			self.val = val

		def to_string(self):
			names = [f.name for f in self.val.type.strip_typedefs().fields()]
			tag = int(self.val["tag"]) if "tag" in names else None
			try:
				name = union_variant(names, tag)
			except ValueError as e:
				return "<%s>" % e
			if name is None or (tag is None and int(self.val[name]) == 0):
				return "nil"
			return self.val[name]

	def _gdb_lookup(val):
		t = val.type.strip_typedefs()
		if t.code == gdb.TYPE_CODE_UNION and is_odin_union([f.name for f in t.fields()]):
			return _GdbUnion(val)
		kind = _gdb_kind(t)
		if kind in ("string", "string16"):
			return _GdbString(val, kind)
		if kind == "map":
			return _GdbMap(val)
		if kind is not None:
			return _GdbArray(val, kind)
		return None

	# NOTE: loaded from a binary's `.debug_gdb_scripts` section, the printers belong to that binary
	if gdb.current_objfile() is not None:
		gdb.current_objfile().pretty_printers.append(_gdb_lookup)
	else:
		gdb.pretty_printers.append(_gdb_lookup)


################################################################################
# lldb

try:
	import lldb
except ImportError:
	lldb = None

if lldb is not None:
	def _lldb_kind(sbtype):
		t = sbtype.GetCanonicalType()
		if t.GetTypeClass() not in (lldb.eTypeClassStruct, lldb.eTypeClassClass):
			return None
		names = [t.GetFieldAtIndex(i).GetName() for i in range(t.GetNumberOfFields())]
		if not names or names[0] != "data":
			return None
		data = t.GetFieldAtIndex(0).GetType().GetCanonicalType()
		target_fields = []
		if data.IsPointerType():
			target = data.GetPointeeType().GetCanonicalType()
			target_fields = [target.GetFieldAtIndex(i).GetName() for i in range(target.GetNumberOfFields())]
		return odin_kind(t.GetName(), names, data.IsPointerType(), data.IsArrayType(), target_fields)

	def _lldb_reader(valobj):
		process = valobj.GetProcess()
		def read(address, size):
			error = lldb.SBError()
			data = process.ReadMemory(address, size, error)
			if error.Fail():
				raise MemoryError(error.GetCString())
			return data
		return read

	def _lldb_fields(t):
		t = t.GetCanonicalType()
		return {t.GetFieldAtIndex(i).GetName(): t.GetFieldAtIndex(i).GetType() for i in range(t.GetNumberOfFields())}

	def _lldb_cell_layout(elem, cell):
		cell_data_size = 0
		if cell.GetByteSize() != elem.GetByteSize():
			cell_data_size = _lldb_fields(cell)["v"].GetByteSize()
		return cell_layout(elem.GetByteSize(), cell.GetByteSize(), cell_data_size)

	def lldb_is_string(sbtype, internal_dict):
		return _lldb_kind(sbtype) in ("string", "string16")

	def lldb_is_array(sbtype, internal_dict):
		return _lldb_kind(sbtype) in ("slice", "dynamic", "fixed")

	def lldb_is_map(sbtype, internal_dict):
		return _lldb_kind(sbtype) == "map"

	def lldb_is_container(sbtype, internal_dict):
		return _lldb_kind(sbtype) in ("slice", "dynamic", "fixed", "map")

	def lldb_is_union(sbtype, internal_dict):
		t = sbtype.GetCanonicalType()
		return t.GetTypeClass() == lldb.eTypeClassUnion and is_odin_union(list(_lldb_fields(t)))

	def _lldb_union_value(valobj):
		# the variant the union holds, None when it is nil; raises ValueError for an invalid tag
		v = valobj.GetNonSyntheticValue()
		names = list(_lldb_fields(v.GetType()))
		tag = v.GetChildMemberWithName("tag").GetValueAsUnsigned() if "tag" in names else None
		name = union_variant(names, tag)
		if name is None:
			return None
		value = v.GetChildMemberWithName(name)
		if tag is None and value.GetValueAsUnsigned() == 0:
			return None
		value.SetPreferSyntheticValue(True)
		return value

	def lldb_union_summary(valobj, internal_dict):
		try:
			value = _lldb_union_value(valobj)
		except ValueError as e:
			return "<%s>" % e
		if value is None:
			return "nil"
		# NOTE: a struct has neither, so it is shown by its fields, the union's children
		return value.GetSummary() or value.GetValue() or ""

	def lldb_string_summary(valobj, internal_dict):
		v = valobj.GetNonSyntheticValue()
		unit, encoding = (1, "utf-8") if _lldb_kind(v.GetType()) == "string" else (2, "utf-16-le")
		data = v.GetChildMemberWithName("data").GetValueAsUnsigned()
		count = v.GetChildMemberWithName("len").GetValueAsSigned()
		try:
			text = read_text(_lldb_reader(v), data, count, unit, encoding)
		except MemoryError:
			return "<invalid>"
		return '"%s"' % text.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")

	def lldb_len_summary(valobj, internal_dict):
		v = valobj.GetNonSyntheticValue()
		summary = "len=%d" % v.GetChildMemberWithName("len").GetValueAsSigned()
		if _lldb_kind(v.GetType()) == "dynamic":
			summary += " cap=%d" % v.GetChildMemberWithName("cap").GetValueAsSigned()
		return summary

	class LldbArraySynth:
		def __init__(self, valobj, internal_dict):
			self.valobj = valobj

		def update(self):
			data = self.valobj.GetChildMemberWithName("data")
			t = data.GetType().GetCanonicalType()
			length = self.valobj.GetChildMemberWithName("len").GetValueAsSigned()
			if t.IsArrayType():
				self.elem = t.GetArrayElementType()
				self.address = data.GetLoadAddress()
				capacity = t.GetByteSize() // max(1, self.elem.GetByteSize())
				self.count = array_count(1, length, capacity)
			else:
				self.elem = t.GetPointeeType()
				self.address = data.GetValueAsUnsigned()
				capacity = None
				if self.valobj.GetChildMemberWithName("cap").IsValid():
					capacity = self.valobj.GetChildMemberWithName("cap").GetValueAsSigned()
				self.count = array_count(self.address, length, capacity)
			return False

		def num_children(self):
			return self.count

		def get_child_index(self, name):
			try:
				return int(name.strip("[]"))
			except ValueError:
				return -1

		def get_child_at_index(self, index):
			return self.valobj.CreateValueFromAddress("[%d]" % index, self.address + index*self.elem.GetByteSize(), self.elem)

		def has_children(self):
			return True

	class LldbMapSynth:
		# Each entry is a child named by its key; a key without a short form, such as a struct,
		# gives two children per entry instead, `[i].key` and `[i].value`
		def __init__(self, valobj, internal_dict):
			self.valobj = valobj

		def update(self):
			data = self.valobj.GetChildMemberWithName("data")
			f = _lldb_fields(data.GetType().GetCanonicalType().GetPointeeType())
			self.key_type   = f["key"]
			self.value_type = f["value"]
			key_layout   = _lldb_cell_layout(f["key"],   f["key_cell"])
			value_layout = _lldb_cell_layout(f["value"], f["value_cell"])
			raw = data.GetValueAsUnsigned()
			self.count = self.valobj.GetChildMemberWithName("len").GetValueAsSigned()
			if map_capacity(raw, self.count) == 0:
				self.count = 0
			self.slots = []
			self.scan = map_slots(raw, self.count, key_layout, value_layout, f["hash"].GetByteSize(), _lldb_reader(self.valobj))
			key = self.key_type.GetCanonicalType()
			self.pairs = not (key.GetTypeClass() in (lldb.eTypeClassBuiltin, lldb.eTypeClassEnumeration, lldb.eTypeClassPointer) or lldb_is_string(key, None))
			return False

		def _slot(self, entry):
			while len(self.slots) <= entry:
				try:
					self.slots.append(next(self.scan))
				except (StopIteration, MemoryError):
					return None
			return self.slots[entry]

		def num_children(self):
			return 2*self.count if self.pairs else self.count

		def get_child_index(self, name):
			return -1

		def get_child_at_index(self, index):
			entry = index//2 if self.pairs else index
			slot = self._slot(entry)
			if slot is None:
				return None
			key, value = slot
			if self.pairs:
				if index % 2 == 0:
					return self.valobj.CreateValueFromAddress("[%d].key" % entry, key, self.key_type)
				return self.valobj.CreateValueFromAddress("[%d].value" % entry, value, self.value_type)
			k = self.valobj.CreateValueFromAddress("key", key, self.key_type)
			text = k.GetSummary() or k.GetValue() or str(entry)
			return self.valobj.CreateValueFromAddress("[%s]" % text, value, self.value_type)

		def has_children(self):
			return True

	class LldbUnionSynth:
		# The children of the variant the union holds
		def __init__(self, valobj, internal_dict):
			self.valobj = valobj

		def update(self):
			try:
				self.value = _lldb_union_value(self.valobj)
			except ValueError:
				self.value = None
			if self.value is not None and self.value.GetSummary() and not self.value.IsSynthetic():
				# a string, which its summary shows whole
				self.value = None
			return False

		def num_children(self):
			return self.value.GetNumChildren() if self.value is not None else 0

		def get_child_index(self, name):
			return self.value.GetIndexOfChildWithName(name) if self.value is not None else -1

		def get_child_at_index(self, index):
			return self.value.GetChildAtIndex(index)

		def has_children(self):
			return self.value is not None and self.value.MightHaveChildren()

	def __lldb_init_module(debugger, internal_dict):
		# NOTE: commands go through the interpreter with a result object, as `SBDebugger.HandleCommand` writes to
		# the debugger's output, which lldb-dap uses for its protocol, so editors using it lose the session.
		# `--recognizer-function` needs LLDB 15; before it, types are matched by their names, so named types are not.
		m = __name__
		rules = [
			("type summary add -w odin -F %s.lldb_string_summary"    % m, "lldb_is_string",    "^string(16)?$"),
			("type summary add -w odin -e -F %s.lldb_len_summary"    % m, "lldb_is_container", "^([[][]]|[[]dynamic|map[[])"),
			("type synthetic add -w odin -l %s.LldbArraySynth"       % m, "lldb_is_array",     "^([[][]]|[[]dynamic)"),
			("type synthetic add -w odin -l %s.LldbMapSynth"         % m, "lldb_is_map",       "^map[[]"),
			("type summary add -w odin -e -F %s.lldb_union_summary"  % m, "lldb_is_union",     "^union[{]"),
			("type synthetic add -w odin -l %s.LldbUnionSynth"       % m, "lldb_is_union",     "^union[{]"),
		]
		interpreter = debugger.GetCommandInterpreter()
		def run(command):
			result = lldb.SBCommandReturnObject()
			interpreter.HandleCommand(command, result)
			return result.Succeeded()
		for command, recognizer, regex in rules:
			if not run("%s --recognizer-function %s.%s" % (command, m, recognizer)):
				run('%s -x "%s"' % (command, regex))
		run("type category enable odin")
