"""
A small reader for the parts of Java class files that `generate.py` needs: names, access flags,
superclasses, interfaces, fields (with constant values), methods, and the inner-class table.
"""

import struct

ACC_PUBLIC    = 0x0001
ACC_PRIVATE   = 0x0002
ACC_PROTECTED = 0x0004
ACC_STATIC    = 0x0008
ACC_FINAL     = 0x0010
ACC_BRIDGE    = 0x0040
ACC_VARARGS   = 0x0080
ACC_INTERFACE = 0x0200
ACC_ABSTRACT  = 0x0400
ACC_SYNTHETIC = 0x1000
ACC_ENUM      = 0x4000


class ClassFileError(Exception):
	pass


class Reader:
	def __init__(self, data):
		self.data = data
		self.pos  = 0

	def u1(self):
		v = self.data[self.pos]
		self.pos += 1
		return v

	def u2(self):
		v = struct.unpack_from(">H", self.data, self.pos)[0]
		self.pos += 2
		return v

	def u4(self):
		v = struct.unpack_from(">I", self.data, self.pos)[0]
		self.pos += 4
		return v

	def bytes(self, n):
		v = self.data[self.pos:self.pos+n]
		self.pos += n
		return v


def decode_modified_utf8(b):
	# Class files use modified UTF-8: NUL is 0xC0 0x80 and supplementary characters are surrogate pairs.
	return b.replace(b"\xc0\x80", b"\x00").decode("utf-8", "surrogatepass")


class Member:
	def __init__(self, access, name, descriptor):
		self.access     = access
		self.name       = name
		self.descriptor = descriptor
		self.constant   = None  # fields: the ConstantValue, if any


class ClassFile:
	def __init__(self, data):
		r = Reader(data)
		if r.u4() != 0xCAFEBABE:
			raise ClassFileError("not a class file")
		r.u2()
		r.u2()

		count = r.u2()
		self.pool = [None] * count
		i = 1
		while i < count:
			tag = r.u1()
			if tag == 1:
				self.pool[i] = ("utf8", decode_modified_utf8(r.bytes(r.u2())))
			elif tag == 3:
				self.pool[i] = ("int", struct.unpack(">i", r.bytes(4))[0])
			elif tag == 4:
				self.pool[i] = ("float", struct.unpack(">f", r.bytes(4))[0])
			elif tag == 5:
				self.pool[i] = ("long", struct.unpack(">q", r.bytes(8))[0])
				i += 1
			elif tag == 6:
				self.pool[i] = ("double", struct.unpack(">d", r.bytes(8))[0])
				i += 1
			elif tag in (7, 8, 16, 19, 20):
				self.pool[i] = ({7: "class", 8: "string", 16: "methodtype", 19: "module", 20: "package"}[tag], r.u2())
			elif tag in (9, 10, 11, 12, 17, 18):
				self.pool[i] = ("ref", r.u2(), r.u2())
			elif tag == 15:
				self.pool[i] = ("methodhandle", r.u1(), r.u2())
			else:
				raise ClassFileError(f"unknown constant pool tag {tag}")
			i += 1

		self.access     = r.u2()
		self.name       = self.class_name(r.u2())
		super_index     = r.u2()
		self.super      = self.class_name(super_index) if super_index else None
		self.interfaces = [self.class_name(r.u2()) for _ in range(r.u2())]

		self.fields  = [self.read_member(r) for _ in range(r.u2())]
		self.methods = [self.read_member(r) for _ in range(r.u2())]

		self.inner = {}  # inner class name -> access flags
		for _ in range(r.u2()):
			name, body = self.read_attribute(r)
			if name == "InnerClasses":
				b = Reader(body)
				for _ in range(b.u2()):
					inner, outer, simple, access = b.u2(), b.u2(), b.u2(), b.u2()
					self.inner[self.class_name(inner)] = access

	def utf8(self, index):
		return self.pool[index][1]

	def class_name(self, index):
		return self.utf8(self.pool[index][1])

	def read_attribute(self, r):
		name = self.utf8(r.u2())
		return name, r.bytes(r.u4())

	def read_member(self, r):
		m = Member(r.u2(), self.utf8(r.u2()), self.utf8(r.u2()))
		for _ in range(r.u2()):
			name, body = self.read_attribute(r)
			if name == "ConstantValue":
				entry = self.pool[struct.unpack(">H", body)[0]]
				m.constant = (entry[0], self.utf8(entry[1]) if entry[0] == "string" else entry[1])
		return m


def parse_descriptor(desc):
	"""A method descriptor -> (parameter types, return type), each a field descriptor string."""
	assert desc[0] == "("
	params, i = [], 1
	while desc[i] != ")":
		start = i
		while desc[i] == "[":
			i += 1
		if desc[i] == "L":
			i = desc.index(";", i)
		i += 1
		params.append(desc[start:i])
	return params, desc[i+1:]
