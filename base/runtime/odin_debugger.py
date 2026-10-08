# Pretty printers for Odin types in gdb and lldb
#
#   gdb:  source <odin>/base/runtime/odin_debugger.py
#   lldb: command script import <odin>/base/runtime/odin_debugger.py
#
# gdb also loads it by itself from the `.debug_gdb_scripts` section of an ELF binary built with `-debug`,
# once that binary's directory is trusted, with `add-auto-load-safe-path <directory>`, and lldb from the dSYM
# of a macOS binary built with `-debug`, once `settings set target.load-script-from-symbol-file true`
#
# Shown: `string`, `string16`, slices, dynamic arrays (and fixed capacity ones), `#soa` slices and dynamic arrays,
# maps as their entries (a map of zero sized values as its keys), unions as the variant they hold, or `nil`,
# and `any` as the value it holds.
# Types are recognised by their fields rather than their names, so named types, such as
# `Table :: map[string]int`, are shown the same way.
#
# gdb: front ends which mishandle the "map" display hint, such as Microsoft's C/C++ extension for VS Code,
# need `set odin-map-hint off`, which names each entry by its key instead.
#
# A map's debug type does not describe its memory: `data` points to a struct whose fields give the
# `key`, `value` and `hash` types and how keys and values are packed into cells, `key_cell` and `value_cell`
# (see `init_map_internal_debug_types` in the compiler and `Raw_Map` in `base:runtime`).
# A union's members are its variants, `v<tag>`, and the `tag` itself, except for a `Maybe` of a pointer,
# which is `v0` alone and nil when the pointer is (see `lb_debug_union`).
# An `any`'s `id` is an enum named by each type's canonical name, which finds the type of what `data` points to;
# a `typeid` is the hash of that name, which picks the type when a debugger shortens the name (lldb does, from a PDB).
# Every target Odin supports is little-endian.

import re

MAX_STRING_BYTES = 64*1024

MAP_METADATA_FIELDS = ["key", "value", "hash", "key_cell", "value_cell"]

# the kind and size of each basic type, by its name in `typeid`; None is the size of a pointer
ODIN_BASIC_TYPES = {
	"i8":   ("int",  1), "i16": ("int",  2), "i32": ("int", 4),  "i64": ("int",  8), "i128": ("int",  16),
	"u8":   ("uint", 1), "u16": ("uint", 2), "u32": ("uint", 4), "u64": ("uint", 8), "u128": ("uint", 16),

	"i16le": ("int",  2), "i32le": ("int",  4), "i64le": ("int",  8), "i128le": ("int",  16),
	"u16le": ("uint", 2), "u32le": ("uint", 4), "u64le": ("uint", 8), "u128le": ("uint", 16),

	"f16":   ("float", 2), "f32":   ("float", 4), "f64":   ("float", 8),
	"f16le": ("float", 2), "f32le": ("float", 4), "f64le": ("float", 8),
	"f16be": ("float", 2), "f32be": ("float", 4), "f64be": ("float", 8),

	"bool": ("bool", 1), "b8": ("bool", 1), "b16": ("uint", 2), "b32": ("uint", 4), "b64": ("uint", 8),

	"rune": ("rune", 4),

	"int": ("int", None), "uint": ("uint", None), "uintptr": ("uint", None),

	"rawptr": ("rawptr", None),

	"cstring": ("cstring", None), "cstring16": ("cstring16", None),
}


def typeid_hash(name):
	# SipHash-2-4 of a type's canonical name, which is its `typeid` (see `type_hash_canonical_type`)
	mask = (1 << 64) - 1
	k0 = 0xa6592ea25e04ac3c
	k1 = 0xba3cba04ed28a9ae
	v = [0x736f6d6570736575 ^ k0, 0x646f72616e646f6d ^ k1, 0x6c7967656e657261 ^ k0, 0x7465646279746573 ^ k1]
	def rotl(x, k):
		return ((x << k) | (x >> (64 - k))) & mask
	def rounds(n):
		for _ in range(n):
			v[0] = (v[0] + v[1]) & mask; v[1] = rotl(v[1], 13); v[1] ^= v[0]; v[0] = rotl(v[0], 32)
			v[2] = (v[2] + v[3]) & mask; v[3] = rotl(v[3], 16); v[3] ^= v[2]
			v[0] = (v[0] + v[3]) & mask; v[3] = rotl(v[3], 21); v[3] ^= v[0]
			v[2] = (v[2] + v[1]) & mask; v[1] = rotl(v[1], 17); v[1] ^= v[2]; v[2] = rotl(v[2], 32)
	data = name.encode("utf-8")
	full = len(data) & ~7
	last = bytearray(data[full:]) + bytearray(8 - (len(data) - full))
	last[7] = len(data) & 0xff
	for block in [data[i:i+8] for i in range(0, full, 8)] + [bytes(last)]:
		m = int.from_bytes(block, "little")
		v[3] ^= m
		rounds(2)
		v[0] ^= m
	v[2] ^= 0xff
	rounds(4)
	h = v[0] ^ v[1] ^ v[2] ^ v[3]
	return h if h != 0 else 1


def is_map_metadata(field_names):
	# the members of a zero sized value can be missing
	if not all(n in MAP_METADATA_FIELDS for n in field_names):
		return False
	return all(n in field_names for n in ("key", "hash", "key_cell"))


def odin_kind(type_name, field_names, data_is_pointer, data_is_array, data_target_fields):
	if field_names == ["data", "len"] and type_name in ("string", "string16"):
		return type_name
	if field_names == ["data", "id"] and type_name == "any":
		return "any"
	if field_names == ["data", "len", "allocator"] and is_map_metadata(data_target_fields):
		return "map"
	if field_names == ["data", "len", "cap", "allocator"] and data_is_pointer:
		return "dynamic"
	if field_names == ["data", "len"] and data_is_pointer:
		return "slice"
	if field_names == ["data", "len"] and data_is_array:
		return "fixed"
	if field_names[-3:] == ["__$len", "__$cap", "allocator"]:
		return "soa_dynamic"
	if field_names[-1:] == ["__$len"]:
		return "soa_slice"
	return None


def composite_type(name):
	# the element of a pointer, multi-pointer or fixed array type named by a `typeid` and the array's count,
	# which is None for a pointer; None for other types
	if name.startswith("^"):
		return name[1:], None
	if name.startswith("[^]"):
		return name[3:], None
	m = re.fullmatch(r"\[([0-9]+)\](.+)", name)
	if m:
		return m.group(2), int(m.group(1))
	return None


def soa_fields(field_names):
	return [n for n in field_names if n not in ("__$len", "__$cap", "allocator", "_")]


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


def array_count(data, length, capacity=None, read_memory=None):
	# how many elements to show, none for a variable not yet initialised, whose data cannot be read
	if data == 0:
		return 0
	if length <= 0:
		return 0
	if capacity is not None and length > capacity:
		return 0
	if read_memory is not None:
		try:
			read_memory(data, 1)
		except Exception:
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
	# NOTE: gdb 14 and later fetch the children of a `gdb.ValuePrinter` one at a time, through `num_children` and `child`
	_GdbPrinter = getattr(gdb, "ValuePrinter", object)

	class _GdbMapHintParameter(gdb.Parameter):
		"""Whether Odin maps use the "map" display hint; when off, each entry is named by its key."""
		set_doc = "Set whether Odin maps use the \"map\" display hint."
		show_doc = "Show whether Odin maps use the \"map\" display hint."

		def __init__(self):
			super().__init__("odin-map-hint", gdb.COMMAND_DATA, gdb.PARAM_BOOLEAN)
			self.value = True

	try:
		gdb.parameter("odin-map-hint")
	except RuntimeError:
		_gdb_map_hint_parameter = _GdbMapHintParameter()

	def _gdb_map_hint():
		try:
			return bool(gdb.parameter("odin-map-hint"))
		except RuntimeError:
			return True

	def _gdb_read(address, size):
		return bytes(gdb.selected_inferior().read_memory(address, size))

	def _gdb_fields(t):
		return {f.name: f.type for f in t.fields()}

	def _gdb_kind(t):
		if t.code != gdb.TYPE_CODE_STRUCT:
			return None
		fields = t.fields()
		names = [f.name for f in fields]
		data_is_pointer = False
		data_is_array = False
		target_fields = []
		if names and names[0] == "data":
			data = fields[0].type.strip_typedefs()
			data_is_pointer = data.code == gdb.TYPE_CODE_PTR
			data_is_array = data.code == gdb.TYPE_CODE_ARRAY
			if data_is_pointer:
				target = data.target().strip_typedefs()
				if target.code == gdb.TYPE_CODE_STRUCT:
					target_fields = [f.name for f in target.fields()]
		return odin_kind(t.name, names, data_is_pointer, data_is_array, target_fields)

	def _gdb_cell_layout(elem, cell):
		cell_data_size = 0
		if cell.sizeof != elem.sizeof:
			cell_data_size = _gdb_fields(cell.strip_typedefs())["v"].sizeof
		return cell_layout(elem.sizeof, cell.sizeof, cell_data_size)

	def _gdb_type(*names):
		for name in names:
			try:
				return gdb.lookup_type(name)
			except gdb.error:
				continue
		return None

	def _gdb_odin_type(name):
		composite = composite_type(name)
		if composite is not None:
			elem_name, count = composite
			elem = _gdb_odin_type(elem_name)
			if elem is None:
				return None
			if count is None:
				return elem.pointer()
			return elem.array(count - 1)

		basic = ODIN_BASIC_TYPES.get(name)
		if basic is None:
			return _gdb_type(name, "struct " + name, "union " + name, "enum " + name)

		kind, size = basic
		if size is None:
			size = gdb.lookup_type("void").pointer().sizeof

		if kind == "rawptr":
			return gdb.lookup_type("void").pointer()
		if kind == "cstring":
			return gdb.lookup_type("char").pointer()
		if kind == "cstring16":
			return _gdb_type("char16_t", "unsigned short").pointer()
		if kind == "float":
			return _gdb_type({2: "_Float16", 4: "float", 8: "double"}[size])
		if kind == "bool":
			return _gdb_type("_Bool", "bool")
		if kind == "rune":
			return _gdb_type("char32_t", "unsigned int")

		ints = {1: "char", 2: "short", 4: "int", 8: "long long", 16: "__int128"}
		if kind == "uint":
			return _gdb_type("unsigned " + ints[size])

		return _gdb_type("signed char" if size == 1 else ints[size])

	def _gdb_is_short(t):
		t = t.strip_typedefs()
		if t.code in (gdb.TYPE_CODE_INT, gdb.TYPE_CODE_ENUM, gdb.TYPE_CODE_FLT, gdb.TYPE_CODE_PTR, gdb.TYPE_CODE_CHAR, gdb.TYPE_CODE_BOOL):
			return True
		return _gdb_kind(t) in ("string", "string16")

	class _GdbString(_GdbPrinter):
		def __init__(self, val, kind):
			self._val = val
			self._unit, self._encoding = (1, "utf-8") if kind == "string" else (2, "utf-16-le")

		def to_string(self):
			return read_text(_gdb_read, int(self._val["data"]), int(self._val["len"]), self._unit, self._encoding)

		def display_hint(self):
			return "string"

	class _GdbArray(_GdbPrinter):
		# A dynamic array also shows its allocator, after its elements
		def __init__(self, val, kind):
			self._val = val
			self._kind = kind
			self._data = val["data"]
			length = int(val["len"])
			if kind == "fixed":
				capacity = self._data.type.strip_typedefs().range()[1] + 1
				self._count = array_count(1, length, capacity)
			else:
				capacity = int(val["cap"]) if kind == "dynamic" else None
				self._count = array_count(int(self._data), length, capacity, _gdb_read)

		def to_string(self):
			if self._kind == "dynamic":
				return "len=%d cap=%d" % (int(self._val["len"]), int(self._val["cap"]))
			return "len=%d" % int(self._val["len"])

		def display_hint(self):
			if self._kind == "dynamic":
				return None
			return "array"

		def num_children(self):
			if self._kind == "dynamic":
				return self._count + 1
			return self._count

		def child(self, index):
			if index == self._count:
				return "allocator", self._val["allocator"]
			if self._kind == "fixed":
				return "[%d]" % index, self._data[index]
			return "[%d]" % index, (self._data + index).dereference()

		def children(self):
			for i in range(self.num_children()):
				yield self.child(i)

	class _GdbSoa(_GdbPrinter):
		# Each field as an array of the length, then a dynamic array's allocator
		def __init__(self, val, kind):
			self._val = val
			self._kind = kind
			t = val.type.strip_typedefs()
			self._fields = soa_fields([f.name for f in t.fields()])
			length = int(val["__$len"])
			capacity = int(val["__$cap"]) if kind == "soa_dynamic" else None
			first = int(val[self._fields[0]]) if self._fields else 0
			self._count = array_count(first, length, capacity, _gdb_read)

		def to_string(self):
			if self._kind == "soa_dynamic":
				return "len=%d cap=%d" % (int(self._val["__$len"]), int(self._val["__$cap"]))
			return "len=%d" % int(self._val["__$len"])

		def num_children(self):
			fields = len(self._fields) if self._count > 0 else 0
			if self._kind == "soa_dynamic":
				return fields + 1
			return fields

		def child(self, index):
			if self._count == 0 or index == len(self._fields):
				return "allocator", self._val["allocator"]
			name = self._fields[index]
			pointer = self._val[name]
			array = pointer.type.strip_typedefs().target().array(0, self._count - 1)
			return name, pointer.cast(array.pointer()).dereference()

		def children(self):
			for i in range(self.num_children()):
				yield self.child(i)

	class _GdbMap(_GdbPrinter):
		def __init__(self, val):
			self._val = val
			f = _gdb_fields(val["data"].type.strip_typedefs().target().strip_typedefs())
			self._key_type   = f["key"]
			self._value_type = f.get("value")
			key_layout   = _gdb_cell_layout(f["key"], f["key_cell"])
			value_layout = (0, 1, 0)
			if self._value_type is not None:
				value_layout = _gdb_cell_layout(self._value_type, f["value_cell"])
			data = int(val["data"])
			self._count = int(val["len"])
			if map_capacity(data, self._count) == 0:
				self._count = 0
			self._slots = []
			self._scan = map_slots(data, self._count, key_layout, value_layout, f["hash"].sizeof, _gdb_read)
			self._set = self._value_type is None or self._value_type.sizeof == 0
			self._hint = _gdb_map_hint()
			self._pairs = self._hint or not _gdb_is_short(self._key_type)

		def to_string(self):
			return "len=%d" % int(self._val["len"])

		def display_hint(self):
			if self._set:
				return "array"
			if self._hint:
				return "map"
			return None

		def _slot(self, entry):
			while len(self._slots) <= entry:
				try:
					self._slots.append(next(self._scan))
				except (StopIteration, gdb.MemoryError):
					return None
			return self._slots[entry]

		def num_children(self):
			if self._set or not self._pairs:
				return self._count
			return 2*self._count

		def child(self, index):
			entry = index
			if not self._set and self._pairs:
				entry = index//2
			slot = self._slot(entry)
			if slot is None:
				return None
			key = gdb.Value(slot[0]).cast(self._key_type.pointer()).dereference()
			if self._set:
				return "[%d]" % entry, key
			value = gdb.Value(slot[1]).cast(self._value_type.pointer()).dereference()
			if self._hint:
				if index % 2 == 0:
					return "key", key
				return "value", value
			if self._pairs:
				if index % 2 == 0:
					return "[%d].key" % entry, key
				return "[%d].value" % entry, value
			return "[%s]" % key.format_string(), value

		def children(self):
			for i in range(self.num_children()):
				c = self.child(i)
				if c is None:
					return
				yield c

	class _GdbUnion(_GdbPrinter):
		def __init__(self, val):
			self._val = val

		def to_string(self):
			names = [f.name for f in self._val.type.strip_typedefs().fields()]
			tag = int(self._val["tag"]) if "tag" in names else None
			try:
				name = union_variant(names, tag)
			except ValueError as e:
				return "<%s>" % e
			if name is None or (tag is None and int(self._val[name]) == 0):
				return "nil"
			value = self._val[name]
			if value.type.strip_typedefs().code == gdb.TYPE_CODE_PTR:
				# gdb prints nothing for a pointer value returned by `to_string`
				return value.format_string()
			return value

	class _GdbAny(_GdbPrinter):
		# The value it holds, after the name of its type; an unknown type shows the `any` itself
		def __init__(self, val):
			self._val = val

		def to_string(self):
			data = int(self._val["data"])
			name = self._val["id"].format_string()
			if data == 0 or int(self._val["id"]) == 0:
				return "nil"
			t = _gdb_odin_type(name)
			if t is None:
				return self._val.format_string(raw=True)
			value = gdb.Value(data).cast(t.pointer()).dereference()
			return "%s %s" % (name, value.format_string())

	def _gdb_lookup(val):
		t = val.type.strip_typedefs()
		if t.code == gdb.TYPE_CODE_UNION and is_odin_union([f.name for f in t.fields()]):
			return _GdbUnion(val)
		kind = _gdb_kind(t)
		if kind in ("string", "string16"):
			return _GdbString(val, kind)
		if kind == "any":
			return _GdbAny(val)
		if kind == "map":
			return _GdbMap(val)
		if kind in ("soa_slice", "soa_dynamic"):
			return _GdbSoa(val, kind)
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
		data_is_pointer = False
		data_is_array = False
		target_fields = []
		if names and names[0] == "data":
			data = t.GetFieldAtIndex(0).GetType().GetCanonicalType()
			data_is_pointer = data.IsPointerType()
			data_is_array = data.IsArrayType()
			if data_is_pointer:
				target = data.GetPointeeType().GetCanonicalType()
				target_fields = [target.GetFieldAtIndex(i).GetName() for i in range(target.GetNumberOfFields())]
		return odin_kind(t.GetName(), names, data_is_pointer, data_is_array, target_fields)

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

	def _lldb_odin_type(target, name, id):
		# the type a `typeid` names, None when it cannot be found
		composite = composite_type(name)
		if composite is not None and typeid_hash(name) == id:
			elem_name, count = composite
			elem = _lldb_odin_type(target, elem_name, typeid_hash(elem_name))
			if elem is None:
				return None
			if count is None:
				return elem.GetPointerType()
			return elem.GetArrayType(count)

		basic = ODIN_BASIC_TYPES.get(name)
		if basic is None:
			types = target.FindTypes(name)
			for i in range(types.GetSize()):
				t = types.GetTypeAtIndex(i)
				if typeid_hash(t.GetName()) == id:
					return t
			return None

		kind, size = basic
		if size is None:
			size = target.GetAddressByteSize()

		if kind == "rawptr":
			return target.GetBasicType(lldb.eBasicTypeVoid).GetPointerType()
		if kind == "cstring":
			return target.GetBasicType(lldb.eBasicTypeChar).GetPointerType()
		if kind == "cstring16":
			return target.GetBasicType(lldb.eBasicTypeChar16).GetPointerType()

		basics = {
			("int",   1):  lldb.eBasicTypeSignedChar,
			("int",   2):  lldb.eBasicTypeShort,
			("int",   4):  lldb.eBasicTypeInt,
			("int",   8):  lldb.eBasicTypeLongLong,
			("int",   16): lldb.eBasicTypeInt128,
			("uint",  1):  lldb.eBasicTypeUnsignedChar,
			("uint",  2):  lldb.eBasicTypeUnsignedShort,
			("uint",  4):  lldb.eBasicTypeUnsignedInt,
			("uint",  8):  lldb.eBasicTypeUnsignedLongLong,
			("uint",  16): lldb.eBasicTypeUnsignedInt128,
			("float", 2):  lldb.eBasicTypeHalf,
			("float", 4):  lldb.eBasicTypeFloat,
			("float", 8):  lldb.eBasicTypeDouble,
			("bool",  1):  lldb.eBasicTypeBool,
			("rune",  4):  lldb.eBasicTypeChar32,
		}
		basic_type = basics.get((kind, size))
		if basic_type is None:
			return None
		return target.GetBasicType(basic_type)

	def lldb_is_string(sbtype, internal_dict):
		return _lldb_kind(sbtype) in ("string", "string16")

	def lldb_is_array(sbtype, internal_dict):
		return _lldb_kind(sbtype) in ("slice", "dynamic", "fixed")

	def lldb_is_soa(sbtype, internal_dict):
		return _lldb_kind(sbtype) in ("soa_slice", "soa_dynamic")

	def lldb_is_map(sbtype, internal_dict):
		return _lldb_kind(sbtype) == "map"

	def lldb_is_any(sbtype, internal_dict):
		return _lldb_kind(sbtype) == "any"

	def lldb_is_container(sbtype, internal_dict):
		return _lldb_kind(sbtype) in ("slice", "dynamic", "fixed", "map", "soa_slice", "soa_dynamic")

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

	def _lldb_any_value(valobj):
		# the name of the type and the value an `any` holds; the value is None when it is nil, and when its type is unknown
		v = valobj.GetNonSyntheticValue()
		data = v.GetChildMemberWithName("data").GetValueAsUnsigned()
		id = v.GetChildMemberWithName("id")
		name = id.GetValue() or ""
		if data == 0 or id.GetValueAsUnsigned() == 0:
			return "nil", None
		t = _lldb_odin_type(valobj.GetTarget(), name, id.GetValueAsUnsigned())
		if t is None:
			return name, None
		if name not in ODIN_BASIC_TYPES and composite_type(name) is None:
			name = t.GetName()
		value = valobj.CreateValueFromAddress("value", data, t)
		value.SetPreferSyntheticValue(True)
		return name, value

	def lldb_union_summary(valobj, internal_dict):
		try:
			value = _lldb_union_value(valobj)
		except ValueError as e:
			return "<%s>" % e
		if value is None:
			return "nil"
		# NOTE: a struct has neither, so it is shown by its fields, the union's children
		return value.GetSummary() or value.GetValue() or ""

	def lldb_any_summary(valobj, internal_dict):
		name, value = _lldb_any_value(valobj)
		if value is None:
			return name
		return ("%s %s" % (name, value.GetSummary() or value.GetValue() or "")).strip()

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
		kind = _lldb_kind(v.GetType())
		if kind in ("soa_slice", "soa_dynamic"):
			summary = "len=%d" % v.GetChildMemberWithName("__$len").GetValueAsSigned()
			if kind == "soa_dynamic":
				summary += " cap=%d" % v.GetChildMemberWithName("__$cap").GetValueAsSigned()
			return summary
		summary = "len=%d" % v.GetChildMemberWithName("len").GetValueAsSigned()
		if kind == "dynamic":
			summary += " cap=%d" % v.GetChildMemberWithName("cap").GetValueAsSigned()
		return summary

	class LldbArraySynth:
		# A dynamic array also shows its allocator, after its elements
		def __init__(self, valobj, internal_dict):
			self.valobj = valobj

		def update(self):
			data = self.valobj.GetChildMemberWithName("data")
			t = data.GetType().GetCanonicalType()
			length = self.valobj.GetChildMemberWithName("len").GetValueAsSigned()
			self.allocator = None
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
					self.allocator = self.valobj.GetChildMemberWithName("allocator")
				self.count = array_count(self.address, length, capacity, _lldb_reader(self.valobj))
			return False

		def num_children(self):
			if self.allocator is not None:
				return self.count + 1
			return self.count

		def get_child_index(self, name):
			if name == "allocator" and self.allocator is not None:
				return self.count
			try:
				return int(name.strip("[]"))
			except ValueError:
				return -1

		def get_child_at_index(self, index):
			if index == self.count:
				return self.allocator
			return self.valobj.CreateValueFromAddress("[%d]" % index, self.address + index*self.elem.GetByteSize(), self.elem)

		def has_children(self):
			return True

	class LldbSoaSynth:
		# Each field as an array of the length, then a dynamic array's allocator
		def __init__(self, valobj, internal_dict):
			self.valobj = valobj

		def update(self):
			v = self.valobj
			kind = _lldb_kind(v.GetType())
			self.fields = soa_fields(list(_lldb_fields(v.GetType())))
			length = v.GetChildMemberWithName("__$len").GetValueAsSigned()
			capacity = None
			self.allocator = None
			if kind == "soa_dynamic":
				capacity = v.GetChildMemberWithName("__$cap").GetValueAsSigned()
				self.allocator = v.GetChildMemberWithName("allocator")
			first = v.GetChildMemberWithName(self.fields[0]).GetValueAsUnsigned() if self.fields else 0
			self.count = array_count(first, length, capacity, _lldb_reader(v))
			return False

		def num_children(self):
			fields = len(self.fields) if self.count > 0 else 0
			if self.allocator is not None:
				return fields + 1
			return fields

		def get_child_index(self, name):
			fields = len(self.fields) if self.count > 0 else 0
			if name == "allocator" and self.allocator is not None:
				return fields
			if name in self.fields[:fields]:
				return self.fields.index(name)
			return -1

		def get_child_at_index(self, index):
			if self.count == 0 or index == len(self.fields):
				return self.allocator
			name = self.fields[index]
			pointer = self.valobj.GetChildMemberWithName(name)
			array = pointer.GetType().GetCanonicalType().GetPointeeType().GetArrayType(self.count)
			return self.valobj.CreateValueFromAddress(name, pointer.GetValueAsUnsigned(), array)

		def has_children(self):
			return True

	class LldbMapSynth:
		# Each entry is a child named by its key; a key without a short form, such as a struct,
		# gives two children per entry instead, `[i].key` and `[i].value`; a map of zero sized values shows its keys
		def __init__(self, valobj, internal_dict):
			self.valobj = valobj

		def update(self):
			data = self.valobj.GetChildMemberWithName("data")
			f = _lldb_fields(data.GetType().GetCanonicalType().GetPointeeType())
			self.key_type   = f["key"]
			self.value_type = f.get("value")
			key_layout   = _lldb_cell_layout(f["key"], f["key_cell"])
			value_layout = (0, 1, 0)
			if self.value_type is not None:
				value_layout = _lldb_cell_layout(self.value_type, f["value_cell"])
			raw = data.GetValueAsUnsigned()
			self.count = self.valobj.GetChildMemberWithName("len").GetValueAsSigned()
			if map_capacity(raw, self.count) == 0:
				self.count = 0
			self.slots = []
			self.scan = map_slots(raw, self.count, key_layout, value_layout, f["hash"].GetByteSize(), _lldb_reader(self.valobj))
			self.set = self.value_type is None or self.value_type.GetByteSize() == 0
			key = self.key_type.GetCanonicalType()
			self.pairs = not (self.set or key.GetTypeClass() in (lldb.eTypeClassBuiltin, lldb.eTypeClassEnumeration, lldb.eTypeClassPointer) or lldb_is_string(key, None))
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
			if self.set:
				return self.valobj.CreateValueFromAddress("[%d]" % entry, key, self.key_type)
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

	class LldbAnySynth:
		# The children of the value it holds, or of the `any` itself when that value's type is unknown
		def __init__(self, valobj, internal_dict):
			self.valobj = valobj

		def update(self):
			name, value = _lldb_any_value(self.valobj)
			self.value = value
			if value is None and name != "nil":
				self.value = self.valobj.GetNonSyntheticValue()
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
			("type summary add -w odin -e -F %s.lldb_len_summary"    % m, "lldb_is_container", "^([[][]]|[[]dynamic|map[[]|#soa)"),
			("type synthetic add -w odin -l %s.LldbArraySynth"       % m, "lldb_is_array",     "^([[][]]|[[]dynamic)"),
			("type synthetic add -w odin -l %s.LldbSoaSynth"         % m, "lldb_is_soa",       "^#soa[[]([]]|dynamic)"),
			("type synthetic add -w odin -l %s.LldbMapSynth"         % m, "lldb_is_map",       "^map[[]"),
			("type summary add -w odin -e -F %s.lldb_union_summary"  % m, "lldb_is_union",     "^union[{]"),
			("type synthetic add -w odin -l %s.LldbUnionSynth"       % m, "lldb_is_union",     "^union[{]"),
			("type summary add -w odin -e -F %s.lldb_any_summary"    % m, "lldb_is_any",       "^any$"),
			("type synthetic add -w odin -l %s.LldbAnySynth"         % m, "lldb_is_any",       "^any$"),
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
