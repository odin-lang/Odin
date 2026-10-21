// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_arm32_tablegen

import lib "../"

// =============================================================================
// ADVANCED SIMD (NEON), A32
// =============================================================================
//
// Not a list of rows but of the classes the Architecture Reference Manual
// divides the Advanced SIMD space into, each expanded here into its rows: one
// per element size, data type and register shape. The size and the type are
// fixed bits of a row, so a row decodes to exactly one `.<dt>` and the
// encoder picks the row by it.
//
// The Thumb forms follow from these: thumb_form_of moves U from bit 24 to 28
// and the element and structure loads from 1111 0100 to 1111 1001.

Operand_Type     :: lib.Operand_Type
Operand_Encoding :: lib.Operand_Encoding
Data_Type        :: lib.Data_Type
Data_Types       :: lib.Data_Types
Feature          :: lib.Feature

// Element sizes, by the value of the size field.
Element_Size  :: enum u32 { E8, E16, E32, E64 }
Element_Sizes :: bit_set[Element_Size; u32]

// How a class writes an element's data type.
Type_Kind :: enum u8 {
	SIGNED_BY_U,   // .s at U = 0, .u at U = 1
	INTEGER,       // .i
	SIGNED,        // .s
	UNSIGNED,      // .u
	BARE,          // .8, .16 -- the size and nothing else
	POLYNOMIAL,    // .p
	FLOAT,         // .f
	NO_TYPE,       // nothing: VAND, VSWP
}

// The register shapes a class comes in: doubleword and quadword.
Shape  :: enum u8 { D, Q }
Shapes :: bit_set[Shape; u8]

BOTH_SHAPES :: Shapes{.D, .Q}

// Whether U is fixed by the opcode, or is the type's signedness.
U_Bit :: enum u8 { U0, U1, BOTH }

@(private="file")
data_type :: proc(kind: Type_Kind, size: Element_Size, u: u32) -> Data_Type {
	switch kind {
	case .SIGNED_BY_U:
		return u == 0 ? signed_type(size) : unsigned_type(size)
	case .INTEGER:
		switch size {
		case .E8:  return .I8
		case .E16: return .I16
		case .E32: return .I32
		case .E64: return .I64
		}
	case .SIGNED:
		return signed_type(size)
	case .UNSIGNED:
		return unsigned_type(size)
	case .BARE:
		switch size {
		case .E8:  return .SZ8
		case .E16: return .SZ16
		case .E32: return .SZ32
		case .E64: return .SZ64
		}
	case .POLYNOMIAL:
		switch size {
		case .E8:  return .P8
		case .E16: return .P16
		case .E32: panic("no 32-bit polynomial type")
		case .E64: return .P64
		}
	case .FLOAT:
		switch size {
		case .E8:  panic("no 8-bit float type")
		case .E16: return .F16
		case .E32: return .F32
		case .E64: return .F64
		}
	case .NO_TYPE:
		return .NONE
	}
	return .NONE
}

@(private="file")
signed_type :: proc(size: Element_Size) -> Data_Type {
	switch size {
	case .E8:  return .S8
	case .E16: return .S16
	case .E32: return .S32
	case .E64: return .S64
	}
	return .NONE
}

@(private="file")
unsigned_type :: proc(size: Element_Size) -> Data_Type {
	switch size {
	case .E8:  return .U8
	case .E16: return .U16
	case .E32: return .U32
	case .E64: return .U64
	}
	return .NONE
}

@(private="file")
u_values :: proc(u: U_Bit) -> []u32 {
	@(rodata, static) ZERO := []u32{0}
	@(rodata, static) ONE  := []u32{1}
	@(rodata, static) BOTH := []u32{0, 1}
	switch u {
	case .U0:   return ZERO
	case .U1:   return ONE
	case .BOTH: return BOTH
	}
	return nil
}

@(private="file")
append_row :: proc(
	rows:     ^[dynamic]Encoding,
	mnemonic: Mnemonic,
	ops:      []Operand_Type,
	enc:      []Operand_Encoding,
	bits:     u32,
	mask:     u32,
	feature:  Feature,
	dt:       Data_Types,
	flags:    lib.Encoding_Flags = {},
) {
	// Advanced SIMD is the A profile's, whatever the feature: VFMA's is
	// VFPv4, which the M profile has, and v8.1-M gives the space to MVE.
	row_flags := flags
	row_flags.a_profile_only = true
	row := Encoding{
		mnemonic = mnemonic,
		bits     = bits,
		mask     = mask,
		feature  = feature,
		mode     = .A32,
		flags    = row_flags,
		dt       = dt,
	}
	for k in 0 ..< len(ops) {
		row.ops[k] = ops[k]
		row.enc[k] = enc[k]
	}
	append(rows, row)
}

// The three-register operand lists, in the order the syntax writes them.
@(private="file")
three_registers :: proc(shape: Shape, swapped := false) -> ([]Operand_Type, []Operand_Encoding) {
	@(rodata, static) D_TYPES   := []Operand_Type{.DPR, .DPR, .DPR}
	@(rodata, static) Q_TYPES   := []Operand_Type{.QPR, .QPR, .QPR}
	@(rodata, static) D_FIELDS  := []Operand_Encoding{.VD_D, .VN_D, .VM_D}
	@(rodata, static) Q_FIELDS  := []Operand_Encoding{.VD_Q, .VN_Q, .VM_Q}
	@(rodata, static) D_SWAPPED := []Operand_Encoding{.VD_D, .VM_D, .VN_D}
	@(rodata, static) Q_SWAPPED := []Operand_Encoding{.VD_Q, .VM_Q, .VN_Q}
	switch shape {
	case .D: return D_TYPES, swapped ? D_SWAPPED : D_FIELDS
	case .Q: return Q_TYPES, swapped ? Q_SWAPPED : Q_FIELDS
	}
	return nil, nil
}

@(private="file")
two_registers :: proc(shape: Shape) -> ([]Operand_Type, []Operand_Encoding) {
	@(rodata, static) D_TYPES  := []Operand_Type{.DPR, .DPR}
	@(rodata, static) Q_TYPES  := []Operand_Type{.QPR, .QPR}
	@(rodata, static) D_FIELDS := []Operand_Encoding{.VD_D, .VM_D}
	@(rodata, static) Q_FIELDS := []Operand_Encoding{.VD_Q, .VM_Q}
	switch shape {
	case .D: return D_TYPES, D_FIELDS
	case .Q: return Q_TYPES, Q_FIELDS
	}
	return nil, nil
}

// =============================================================================
// Three registers of the same length
// =============================================================================
//
//   1111 001U 0Dzz nnnn dddd oooo NQMo mmmm
//
// zz is the element size for the integer operations. The floating-point ones
// use bit 21 as part of the opcode and bit 20 as the size, 0 for .f32 and 1
// for .f16; the logical ones use both bits as the opcode.

Same_Length :: struct {
	mnemonic: Mnemonic,
	u:        U_Bit,
	opcode:   u32,             // bits 11-8
	o1:       u32,             // bit 4
	kind:     Type_Kind,
	sizes:    Element_Sizes,
	shapes:   Shapes,
	swapped:  bool,            // written Vd, Vm, Vn: the shifts by register
	feature:  Feature,
}

@(rodata)
SAME_LENGTH := []Same_Length{
	{.VHADD,    .BOTH, 0x0, 0, .SIGNED_BY_U, {.E8, .E16, .E32},       BOTH_SHAPES, false, .NEON},
	{.VQADD,    .BOTH, 0x0, 1, .SIGNED_BY_U, {.E8, .E16, .E32, .E64}, BOTH_SHAPES, false, .NEON},
	{.VRHADD,   .BOTH, 0x1, 0, .SIGNED_BY_U, {.E8, .E16, .E32},       BOTH_SHAPES, false, .NEON},
	{.VHSUB,    .BOTH, 0x2, 0, .SIGNED_BY_U, {.E8, .E16, .E32},       BOTH_SHAPES, false, .NEON},
	{.VQSUB,    .BOTH, 0x2, 1, .SIGNED_BY_U, {.E8, .E16, .E32, .E64}, BOTH_SHAPES, false, .NEON},
	{.VCGT,     .BOTH, 0x3, 0, .SIGNED_BY_U, {.E8, .E16, .E32},       BOTH_SHAPES, false, .NEON},
	{.VCGE,     .BOTH, 0x3, 1, .SIGNED_BY_U, {.E8, .E16, .E32},       BOTH_SHAPES, false, .NEON},
	{.VSHL,     .BOTH, 0x4, 0, .SIGNED_BY_U, {.E8, .E16, .E32, .E64}, BOTH_SHAPES, true,  .NEON},
	{.VQSHL,    .BOTH, 0x4, 1, .SIGNED_BY_U, {.E8, .E16, .E32, .E64}, BOTH_SHAPES, true,  .NEON},
	{.VRSHL,    .BOTH, 0x5, 0, .SIGNED_BY_U, {.E8, .E16, .E32, .E64}, BOTH_SHAPES, true,  .NEON},
	{.VQRSHL,   .BOTH, 0x5, 1, .SIGNED_BY_U, {.E8, .E16, .E32, .E64}, BOTH_SHAPES, true,  .NEON},
	{.VMAX,     .BOTH, 0x6, 0, .SIGNED_BY_U, {.E8, .E16, .E32},       BOTH_SHAPES, false, .NEON},
	{.VMIN,     .BOTH, 0x6, 1, .SIGNED_BY_U, {.E8, .E16, .E32},       BOTH_SHAPES, false, .NEON},
	{.VABD,     .BOTH, 0x7, 0, .SIGNED_BY_U, {.E8, .E16, .E32},       BOTH_SHAPES, false, .NEON},
	{.VABA,     .BOTH, 0x7, 1, .SIGNED_BY_U, {.E8, .E16, .E32},       BOTH_SHAPES, false, .NEON},
	{.VADD,     .U0,   0x8, 0, .INTEGER,     {.E8, .E16, .E32, .E64}, BOTH_SHAPES, false, .NEON},
	{.VSUB,     .U1,   0x8, 0, .INTEGER,     {.E8, .E16, .E32, .E64}, BOTH_SHAPES, false, .NEON},
	{.VTST,     .U0,   0x8, 1, .BARE,        {.E8, .E16, .E32},       BOTH_SHAPES, false, .NEON},
	{.VCEQ,     .U1,   0x8, 1, .INTEGER,     {.E8, .E16, .E32},       BOTH_SHAPES, false, .NEON},
	{.VMLA,     .U0,   0x9, 0, .INTEGER,     {.E8, .E16, .E32},       BOTH_SHAPES, false, .NEON},
	{.VMLS,     .U1,   0x9, 0, .INTEGER,     {.E8, .E16, .E32},       BOTH_SHAPES, false, .NEON},
	{.VMUL,     .U0,   0x9, 1, .INTEGER,     {.E8, .E16, .E32},       BOTH_SHAPES, false, .NEON},
	{.VMUL,     .U1,   0x9, 1, .POLYNOMIAL,  {.E8},                   BOTH_SHAPES, false, .NEON},
	{.VPMAX,    .BOTH, 0xA, 0, .SIGNED_BY_U, {.E8, .E16, .E32},       {.D},        false, .NEON},
	{.VPMIN,    .BOTH, 0xA, 1, .SIGNED_BY_U, {.E8, .E16, .E32},       {.D},        false, .NEON},
	{.VQDMULH,  .U0,   0xB, 0, .SIGNED,      {.E16, .E32},            BOTH_SHAPES, false, .NEON},
	{.VQRDMULH, .U1,   0xB, 0, .SIGNED,      {.E16, .E32},            BOTH_SHAPES, false, .NEON},
	{.VPADD,    .U0,   0xB, 1, .INTEGER,     {.E8, .E16, .E32},       {.D},        false, .NEON},
	{.VQRDMLAH, .U1,   0xB, 1, .SIGNED,      {.E16, .E32},            BOTH_SHAPES, false, .V8},
	{.VQRDMLSH, .U1,   0xC, 1, .SIGNED,      {.E16, .E32},            BOTH_SHAPES, false, .V8},
}

// The floating-point half: bit 21 is the opcode's, bit 20 the size.
Same_Length_Float :: struct {
	mnemonic: Mnemonic,
	u:        u32,
	opcode:   u32,
	o1:       u32,
	op:       u32,     // bit 21
	shapes:   Shapes,
	feature:  Feature, // of the .f32 rows; .f16 is always NEON_HALF_FP
}

@(rodata)
SAME_LENGTH_FLOAT := []Same_Length_Float{
	{.VFMA,    0, 0xC, 1, 0, BOTH_SHAPES, .VFPV4},
	{.VFMS,    0, 0xC, 1, 1, BOTH_SHAPES, .VFPV4},
	{.VADD,    0, 0xD, 0, 0, BOTH_SHAPES, .NEON},
	{.VSUB,    0, 0xD, 0, 1, BOTH_SHAPES, .NEON},
	{.VPADD,   1, 0xD, 0, 0, {.D},        .NEON},
	{.VABD,    1, 0xD, 0, 1, BOTH_SHAPES, .NEON},
	{.VMLA,    0, 0xD, 1, 0, BOTH_SHAPES, .NEON},
	{.VMLS,    0, 0xD, 1, 1, BOTH_SHAPES, .NEON},
	{.VMUL,    1, 0xD, 1, 0, BOTH_SHAPES, .NEON},
	{.VCEQ,    0, 0xE, 0, 0, BOTH_SHAPES, .NEON},
	{.VCGE,    1, 0xE, 0, 0, BOTH_SHAPES, .NEON},
	{.VCGT,    1, 0xE, 0, 1, BOTH_SHAPES, .NEON},
	{.VACGE,   1, 0xE, 1, 0, BOTH_SHAPES, .NEON},
	{.VACGT,   1, 0xE, 1, 1, BOTH_SHAPES, .NEON},
	{.VMAX,    0, 0xF, 0, 0, BOTH_SHAPES, .NEON},
	{.VMIN,    0, 0xF, 0, 1, BOTH_SHAPES, .NEON},
	{.VPMAX,   1, 0xF, 0, 0, {.D},        .NEON},
	{.VPMIN,   1, 0xF, 0, 1, {.D},        .NEON},
	{.VRECPS,  0, 0xF, 1, 0, BOTH_SHAPES, .NEON},
	{.VRSQRTS, 0, 0xF, 1, 1, BOTH_SHAPES, .NEON},
	{.VMAXNM,  1, 0xF, 1, 0, BOTH_SHAPES, .V8},
	{.VMINNM,  1, 0xF, 1, 1, BOTH_SHAPES, .V8},
}

// The logical operations: no element size, and bits 21:20 are the opcode.
Same_Length_Logical :: struct {
	mnemonic: Mnemonic,
	u:        u32,
	op:       u32,     // bits 21-20
}

@(rodata)
SAME_LENGTH_LOGICAL := []Same_Length_Logical{
	{.VAND, 0, 0}, {.VBIC, 0, 1}, {.VORR, 0, 2}, {.VORN, 0, 3},
	{.VEOR, 1, 0}, {.VBSL, 1, 1}, {.VBIT, 1, 2}, {.VBIF, 1, 3},
}

// The comparisons an assembler writes the other way round: `vcle d0, d1, d2`
// is `vcge d0, d2, d1`. They are encode-only; the decoder gives the other.
Reversed_Comparison :: struct {
	mnemonic: Mnemonic,
	of:       Mnemonic,
}

@(rodata)
REVERSED_COMPARISONS := []Reversed_Comparison{
	{.VCLE, .VCGE}, {.VCLT, .VCGT}, {.VACLE, .VACGE}, {.VACLT, .VACGT},
}

@(private="file")
expand_same_length :: proc(rows: ^[dynamic]Encoding) {
	for class in SAME_LENGTH {
		for u in u_values(class.u) {
			for size in class.sizes {
				for shape in class.shapes {
					q := u32(shape == .Q ? 1 : 0)
					bits := 0xF200_0000 | u << 24 | u32(size) << 20 | class.opcode << 8 | q << 6 | class.o1 << 4
					ops, enc := three_registers(shape, class.swapped)
					append_row(rows, class.mnemonic, ops, enc, bits, 0xFFB0_0F50, class.feature, {data_type(class.kind, size, u), .NONE})
				}
			}
		}
	}
	for class in SAME_LENGTH_FLOAT {
		for size in (Element_Sizes{.E32, .E16}) {
			size_bit := u32(size == .E16 ? 1 : 0)
			feature := size == .E16 ? Feature.NEON_HALF_FP : class.feature
			for shape in class.shapes {
				q := u32(shape == .Q ? 1 : 0)
				bits := 0xF200_0000 | class.u << 24 | class.op << 21 | size_bit << 20 | class.opcode << 8 | q << 6 | class.o1 << 4
				ops, enc := three_registers(shape)
				append_row(rows, class.mnemonic, ops, enc, bits, 0xFFB0_0F50, feature, {data_type(.FLOAT, size, 0), .NONE})
			}
		}
	}
	for class in SAME_LENGTH_LOGICAL {
		for shape in BOTH_SHAPES {
			q := u32(shape == .Q ? 1 : 0)
			bits := 0xF200_0100 | class.u << 24 | class.op << 20 | q << 6 | 1 << 4
			ops, enc := three_registers(shape)
			append_row(rows, class.mnemonic, ops, enc, bits, 0xFFB0_0F50, .NEON, {})
		}
	}
	// The reversed comparisons take the forms of the ones they reverse, with
	// the sources swapped.
	for reversed in REVERSED_COMPARISONS {
		count := len(rows)
		for k in 0 ..< count {
			row := rows[k]
			if row.mnemonic != reversed.of || row.mask != 0xFFB0_0F50 {
				continue
			}
			row.mnemonic = reversed.mnemonic
			row.enc[1], row.enc[2] = row.enc[2], row.enc[1]
			row.flags.encode_only = true
			append(rows, row)
		}
	}
}

// =============================================================================
// Three registers of different lengths
// =============================================================================
//
//   1111 001U 1Dzz nnnn dddd oooo N0M0 mmmm      zz != 11
//
// Long: Qd, Dn, Dm. Wide: Qd, Qn, Dm. Narrow: Dd, Qn, Qm, typed by the wide
// source.

Length_Shape :: enum u8 { LONG, WIDE, NARROW }

Different_Length :: struct {
	mnemonic: Mnemonic,
	u:        U_Bit,
	opcode:   u32,
	kind:     Type_Kind,
	sizes:    Element_Sizes,   // of the narrow elements, or for NARROW the wide
	shape:    Length_Shape,
	feature:  Feature,
}

@(rodata)
DIFFERENT_LENGTH := []Different_Length{
	{.VADDL,   .BOTH, 0x0, .SIGNED_BY_U, {.E8, .E16, .E32},  .LONG,   .NEON},
	{.VADDW,   .BOTH, 0x1, .SIGNED_BY_U, {.E8, .E16, .E32},  .WIDE,   .NEON},
	{.VSUBL,   .BOTH, 0x2, .SIGNED_BY_U, {.E8, .E16, .E32},  .LONG,   .NEON},
	{.VSUBW,   .BOTH, 0x3, .SIGNED_BY_U, {.E8, .E16, .E32},  .WIDE,   .NEON},
	{.VADDHN,  .U0,   0x4, .INTEGER,     {.E16, .E32, .E64}, .NARROW, .NEON},
	{.VRADDHN, .U1,   0x4, .INTEGER,     {.E16, .E32, .E64}, .NARROW, .NEON},
	{.VABAL,   .BOTH, 0x5, .SIGNED_BY_U, {.E8, .E16, .E32},  .LONG,   .NEON},
	{.VSUBHN,  .U0,   0x6, .INTEGER,     {.E16, .E32, .E64}, .NARROW, .NEON},
	{.VRSUBHN, .U1,   0x6, .INTEGER,     {.E16, .E32, .E64}, .NARROW, .NEON},
	{.VABDL,   .BOTH, 0x7, .SIGNED_BY_U, {.E8, .E16, .E32},  .LONG,   .NEON},
	{.VMLAL,   .BOTH, 0x8, .SIGNED_BY_U, {.E8, .E16, .E32},  .LONG,   .NEON},
	{.VQDMLAL, .U0,   0x9, .SIGNED,      {.E16, .E32},       .LONG,   .NEON},
	{.VMLSL,   .BOTH, 0xA, .SIGNED_BY_U, {.E8, .E16, .E32},  .LONG,   .NEON},
	{.VQDMLSL, .U0,   0xB, .SIGNED,      {.E16, .E32},       .LONG,   .NEON},
	{.VMULL,   .BOTH, 0xC, .SIGNED_BY_U, {.E8, .E16, .E32},  .LONG,   .NEON},
	{.VQDMULL, .U0,   0xD, .SIGNED,      {.E16, .E32},       .LONG,   .NEON},
	{.VMULL,   .U0,   0xE, .POLYNOMIAL,  {.E8},              .LONG,   .NEON},
	// .p64 has size field 10, the place of a 32-bit element.
	{.VMULL,   .U0,   0xE, .POLYNOMIAL,  {.E64},             .LONG,   .CRYPTO},
}

@(private="file")
expand_different_length :: proc(rows: ^[dynamic]Encoding) {
	@(rodata, static) LONG_TYPES    := []Operand_Type{.QPR, .DPR, .DPR}
	@(rodata, static) LONG_FIELDS   := []Operand_Encoding{.VD_Q, .VN_D, .VM_D}
	@(rodata, static) WIDE_TYPES    := []Operand_Type{.QPR, .QPR, .DPR}
	@(rodata, static) WIDE_FIELDS   := []Operand_Encoding{.VD_Q, .VN_Q, .VM_D}
	@(rodata, static) NARROW_TYPES  := []Operand_Type{.DPR, .QPR, .QPR}
	@(rodata, static) NARROW_FIELDS := []Operand_Encoding{.VD_D, .VN_Q, .VM_Q}
	for class in DIFFERENT_LENGTH {
		for u in u_values(class.u) {
			for size in class.sizes {
				// The field holds the narrow element's size.
				field := u32(size)
				if class.shape == .NARROW { field -= 1 }
				if size == .E64 && class.kind == .POLYNOMIAL { field = 2 }
				bits := 0xF280_0000 | u << 24 | field << 20 | class.opcode << 8
				ops: []Operand_Type
				enc: []Operand_Encoding
				switch class.shape {
				case .LONG:   ops, enc = LONG_TYPES, LONG_FIELDS
				case .WIDE:   ops, enc = WIDE_TYPES, WIDE_FIELDS
				case .NARROW: ops, enc = NARROW_TYPES, NARROW_FIELDS
				}
				append_row(rows, class.mnemonic, ops, enc, bits, 0xFFB0_0F50, class.feature, {data_type(class.kind, size, u), .NONE})
			}
		}
	}
}

// =============================================================================
// Two registers and a scalar
// =============================================================================
//
//   1111 001Q 1Dzz nnnn dddd oooo N1M0 mmmm      zz != 11
//
// Bit 24 is Q for the operations whose result is as wide as the source, and U
// for the long ones. The scalar is a lane of Dm: for 16-bit elements Dm is
// D0-D7 and the lane M:bit 3, for 32-bit D0-D15 and the lane M.

By_Scalar :: struct {
	mnemonic: Mnemonic,
	opcode:   u32,
	kind:     Type_Kind,
	sizes:    Element_Sizes,
	long:     bool,            // bit 24 is U, and the result is Qd
	u:        U_Bit,           // for the long ones
	feature:  Feature,
}

@(rodata)
BY_SCALAR := []By_Scalar{
	{.VMLA,     0x0, .INTEGER,     {.E16, .E32}, false, .U0,   .NEON},
	{.VMLA,     0x1, .FLOAT,       {.E16, .E32}, false, .U0,   .NEON},
	{.VMLAL,    0x2, .SIGNED_BY_U, {.E16, .E32}, true,  .BOTH, .NEON},
	{.VQDMLAL,  0x3, .SIGNED,      {.E16, .E32}, true,  .U0,   .NEON},
	{.VMLS,     0x4, .INTEGER,     {.E16, .E32}, false, .U0,   .NEON},
	{.VMLS,     0x5, .FLOAT,       {.E16, .E32}, false, .U0,   .NEON},
	{.VMLSL,    0x6, .SIGNED_BY_U, {.E16, .E32}, true,  .BOTH, .NEON},
	{.VQDMLSL,  0x7, .SIGNED,      {.E16, .E32}, true,  .U0,   .NEON},
	{.VMUL,     0x8, .INTEGER,     {.E16, .E32}, false, .U0,   .NEON},
	{.VMUL,     0x9, .FLOAT,       {.E16, .E32}, false, .U0,   .NEON},
	{.VMULL,    0xA, .SIGNED_BY_U, {.E16, .E32}, true,  .BOTH, .NEON},
	{.VQDMULL,  0xB, .SIGNED,      {.E16, .E32}, true,  .U0,   .NEON},
	{.VQDMULH,  0xC, .SIGNED,      {.E16, .E32}, false, .U0,   .NEON},
	{.VQRDMULH, 0xD, .SIGNED,      {.E16, .E32}, false, .U0,   .NEON},
	{.VQRDMLAH, 0xE, .SIGNED,      {.E16, .E32}, false, .U0,   .V8},
	{.VQRDMLSH, 0xF, .SIGNED,      {.E16, .E32}, false, .U0,   .V8},
}

@(private="file")
expand_by_scalar :: proc(rows: ^[dynamic]Encoding) {
	for class in BY_SCALAR {
		for size in class.sizes {
			scalar: Operand_Encoding = size == .E16 ? .NEON_VM_SCALAR_16 : .NEON_VM_SCALAR_32
			feature := class.feature
			if class.kind == .FLOAT && size == .E16 { feature = .NEON_HALF_FP }
			if class.long {
				for u in u_values(class.u) {
					bits := 0xF280_0040 | u << 24 | u32(size) << 20 | class.opcode << 8
					append_row(rows, class.mnemonic, {.QPR, .DPR, .DPR_ELEM}, {.VD_Q, .VN_D, scalar}, bits, 0xFFB0_0F50, feature, {data_type(class.kind, size, u), .NONE})
				}
				continue
			}
			for shape in BOTH_SHAPES {
				q := u32(shape == .Q ? 1 : 0)
				bits := 0xF280_0040 | q << 24 | u32(size) << 20 | class.opcode << 8
				dt := Data_Types{data_type(class.kind, size, 0), .NONE}
				switch shape {
				case .D: append_row(rows, class.mnemonic, {.DPR, .DPR, .DPR_ELEM}, {.VD_D, .VN_D, scalar}, bits, 0xFFB0_0F50, feature, dt)
				case .Q: append_row(rows, class.mnemonic, {.QPR, .QPR, .DPR_ELEM}, {.VD_Q, .VN_Q, scalar}, bits, 0xFFB0_0F50, feature, dt)
				}
			}
		}
	}
}

// =============================================================================
// Two registers and a shift amount
// =============================================================================
//
//   1111 001U 1Dii iiii dddd oooo LQM1 mmmm
//
// L:imm6 holds the element size and the shift together: its leading one is
// the size -- 0001xxx for 8 bits, 001xxxx for 16, 01xxxxx for 32, 1xxxxxx for
// 64 -- and the bits below it the shift. Each row pins the leading one, and
// NEON_SHIFT_RIGHT and NEON_SHIFT_LEFT read the shift from what is left.

Shift_Direction :: enum u8 { RIGHT, LEFT }

By_Shift :: struct {
	mnemonic:  Mnemonic,
	u:         U_Bit,
	opcode:    u32,            // bits 11-8
	kind:      Type_Kind,
	sizes:     Element_Sizes,
	direction: Shift_Direction,
}

@(rodata)
BY_SHIFT := []By_Shift{
	{.VSHR,   .BOTH, 0x0, .SIGNED_BY_U, {.E8, .E16, .E32, .E64}, .RIGHT},
	{.VSRA,   .BOTH, 0x1, .SIGNED_BY_U, {.E8, .E16, .E32, .E64}, .RIGHT},
	{.VRSHR,  .BOTH, 0x2, .SIGNED_BY_U, {.E8, .E16, .E32, .E64}, .RIGHT},
	{.VRSRA,  .BOTH, 0x3, .SIGNED_BY_U, {.E8, .E16, .E32, .E64}, .RIGHT},
	{.VSRI,   .U1,   0x4, .BARE,        {.E8, .E16, .E32, .E64}, .RIGHT},
	{.VSHL,   .U0,   0x5, .INTEGER,     {.E8, .E16, .E32, .E64}, .LEFT},
	{.VSLI,   .U1,   0x5, .BARE,        {.E8, .E16, .E32, .E64}, .LEFT},
	{.VQSHLU, .U1,   0x6, .SIGNED,      {.E8, .E16, .E32, .E64}, .LEFT},
	{.VQSHL,  .BOTH, 0x7, .SIGNED_BY_U, {.E8, .E16, .E32, .E64}, .LEFT},
}

// The narrowing shifts take Qm to Dd, typed by Qm's elements. L is 0 and bit
// 6 is part of the opcode.
Narrowing_Shift :: struct {
	mnemonic: Mnemonic,
	u:        U_Bit,
	opcode:   u32,
	op:       u32,             // bit 6
	kind:     Type_Kind,
}

@(rodata)
NARROWING_SHIFTS := []Narrowing_Shift{
	{.VSHRN,    .U0,   0x8, 0, .INTEGER},
	{.VRSHRN,   .U0,   0x8, 1, .INTEGER},
	{.VQSHRUN,  .U1,   0x8, 0, .SIGNED},
	{.VQRSHRUN, .U1,   0x8, 1, .SIGNED},
	{.VQSHRN,   .BOTH, 0x9, 0, .SIGNED_BY_U},
	{.VQRSHRN,  .BOTH, 0x9, 1, .SIGNED_BY_U},
}

// The leading one of L:imm6 for an element size, as bits and as a mask:
// L is bit 7, imm6 bits 21-16.
@(private="file")
shift_size_pattern :: proc(size: Element_Size) -> (bits, mask: u32) {
	switch size {
	case .E8:  return 0x0008_0000, 0x0038_0080
	case .E16: return 0x0010_0000, 0x0030_0080
	case .E32: return 0x0020_0000, 0x0020_0080
	case .E64: return 0x0000_0080, 0x0000_0080
	}
	return
}

@(private="file")
expand_by_shift :: proc(rows: ^[dynamic]Encoding) {
	for class in BY_SHIFT {
		field: Operand_Encoding = class.direction == .RIGHT ? .NEON_SHIFT_RIGHT : .NEON_SHIFT_LEFT
		for u in u_values(class.u) {
			for size in class.sizes {
				size_bits, size_mask := shift_size_pattern(size)
				for shape in BOTH_SHAPES {
					q := u32(shape == .Q ? 1 : 0)
					bits := 0xF280_0010 | u << 24 | class.opcode << 8 | q << 6 | size_bits
					ops, enc := two_registers(shape)
					append_row(rows, class.mnemonic, {ops[0], ops[1], .IMM}, {enc[0], enc[1], field}, bits, 0xFE80_0F50 | 1 << 24 | size_mask, .NEON, {data_type(class.kind, size, u), .NONE})
				}
			}
		}
	}
	for class in NARROWING_SHIFTS {
		for u in u_values(class.u) {
			// The pattern is the narrow result's size; the type names the wide source.
			for size in (Element_Sizes{.E8, .E16, .E32}) {
				size_bits, size_mask := shift_size_pattern(size)
				bits := 0xF280_0010 | u << 24 | class.opcode << 8 | class.op << 6 | size_bits
				wide := Element_Size(u32(size) + 1)
				append_row(rows, class.mnemonic, {.DPR, .QPR, .IMM}, {.VD_D, .VM_Q, .NEON_SHIFT_RIGHT}, bits, 0xFE80_0FD0 | 1 << 24 | size_mask, .NEON, {data_type(class.kind, wide, u), .NONE})
			}
		}
	}
	// VSHLL by less than the element size; by nothing at all it is VMOVL.
	for u in u32(0) ..= 1 {
		for size in (Element_Sizes{.E8, .E16, .E32}) {
			size_bits, size_mask := shift_size_pattern(size)
			bits := 0xF280_0A10 | u << 24 | size_bits
			dt := Data_Types{data_type(.SIGNED_BY_U, size, u), .NONE}
			// VMOVL is the shift by nothing: imm6 is the size's leading one alone.
			append_row(rows, .VSHLL, {.QPR, .DPR, .IMM}, {.VD_Q, .VM_D, .NEON_SHIFT_LEFT}, bits, 0xFE80_0FD0 | 1 << 24 | size_mask, .NEON, dt)
			movl_mask: u32 = 0xFE80_0FD0 | 1 << 24 | 0x003F_0080
			append_row(rows, .VMOVL, {.QPR, .DPR}, {.VD_Q, .VM_D}, bits, movl_mask, .NEON, dt, {preferred = true})
		}
	}
	// Conversion between floating point and fixed point: #fbits is 64 - imm6.
	// 111o for 32-bit elements, 110o for 16-bit ones; o says which way.
	Fixed_Conversion :: struct { u, op: u32, to, from: Data_Type, half: bool }
	@(rodata, static) FIXED_CONVERSIONS := []Fixed_Conversion{
		{0, 0, .F32, .S32, false}, {1, 0, .F32, .U32, false}, {0, 1, .S32, .F32, false}, {1, 1, .U32, .F32, false},
		{0, 0, .F16, .S16, true},  {1, 0, .F16, .U16, true},  {0, 1, .S16, .F16, true},  {1, 1, .U16, .F16, true},
	}
	for conversion in FIXED_CONVERSIONS {
		opcode := u32(conversion.half ? 0xC : 0xE) | conversion.op
		feature: Feature = conversion.half ? .NEON_HALF_FP : .NEON
		for shape in BOTH_SHAPES {
			q := u32(shape == .Q ? 1 : 0)
			bits := 0xF2A0_0010 | conversion.u << 24 | opcode << 8 | q << 6
			ops, enc := two_registers(shape)
			append_row(rows, .VCVT, {ops[0], ops[1], .IMM}, {enc[0], enc[1], .NEON_FBITS}, bits, 0xFEA0_0FD0 | 1 << 24, feature, {conversion.to, conversion.from})
		}
	}
}

// =============================================================================
// Two registers, miscellaneous
// =============================================================================
//
//   1111 0011 1D11 zzaa dddd 0bbb bQM0 mmmm
//
// aa (bits 17-16) and bbbb (10-7) are the opcode; zz the element size, or for
// the floating-point ones 10 for .f32 and 01 for .f16.

Misc_Shape :: enum u8 {
	SAME,          // Vd, Vm of one shape
	NARROWING,     // Dd, Qm
	WIDENING,      // Qd, Dm
	COMPARE_ZERO,  // Vd, Vm, #0
	PAIR,          // Vd, Vm, both written: VSWP, VTRN, VZIP, VUZP
}

Misc :: struct {
	mnemonic: Mnemonic,
	a:        u32,             // bits 17-16
	b:        u32,             // bits 10-7
	kind:     Type_Kind,
	sizes:    Element_Sizes,
	shapes:   Shapes,          // where the instruction has a Q bit
	q_fixed:  i8,              // -1: bit 6 is Q; 0 or 1: bit 6 is fixed
	shape:    Misc_Shape,
	feature:  Feature,
	type_u:   u32,             // the U a SIGNED_BY_U type reads, from bit 7
}

@(rodata)
MISC := []Misc{
	{.VREV64,  0, 0x0, .BARE,        {.E8, .E16, .E32},  BOTH_SHAPES, -1, .SAME,         .NEON, 0},
	{.VREV32,  0, 0x1, .BARE,        {.E8, .E16},        BOTH_SHAPES, -1, .SAME,         .NEON, 0},
	{.VREV16,  0, 0x2, .BARE,        {.E8},              BOTH_SHAPES, -1, .SAME,         .NEON, 0},
	{.VPADDL,  0, 0x4, .SIGNED_BY_U, {.E8, .E16, .E32},  BOTH_SHAPES, -1, .SAME,         .NEON, 0},
	{.VPADDL,  0, 0x5, .SIGNED_BY_U, {.E8, .E16, .E32},  BOTH_SHAPES, -1, .SAME,         .NEON, 1},
	{.VCLS,    0, 0x8, .SIGNED,      {.E8, .E16, .E32},  BOTH_SHAPES, -1, .SAME,         .NEON, 0},
	{.VCLZ,    0, 0x9, .INTEGER,     {.E8, .E16, .E32},  BOTH_SHAPES, -1, .SAME,         .NEON, 0},
	{.VCNT,    0, 0xA, .BARE,        {.E8},              BOTH_SHAPES, -1, .SAME,         .NEON, 0},
	{.VMVN,    0, 0xB, .NO_TYPE,     {.E8},              BOTH_SHAPES, -1, .SAME,         .NEON, 0},
	{.VPADAL,  0, 0xC, .SIGNED_BY_U, {.E8, .E16, .E32},  BOTH_SHAPES, -1, .SAME,         .NEON, 0},
	{.VPADAL,  0, 0xD, .SIGNED_BY_U, {.E8, .E16, .E32},  BOTH_SHAPES, -1, .SAME,         .NEON, 1},
	{.VQABS,   0, 0xE, .SIGNED,      {.E8, .E16, .E32},  BOTH_SHAPES, -1, .SAME,         .NEON, 0},
	{.VQNEG,   0, 0xF, .SIGNED,      {.E8, .E16, .E32},  BOTH_SHAPES, -1, .SAME,         .NEON, 0},
	{.VCGT,    1, 0x0, .SIGNED,      {.E8, .E16, .E32},  BOTH_SHAPES, -1, .COMPARE_ZERO, .NEON, 0},
	{.VCGE,    1, 0x1, .SIGNED,      {.E8, .E16, .E32},  BOTH_SHAPES, -1, .COMPARE_ZERO, .NEON, 0},
	{.VCEQ,    1, 0x2, .INTEGER,     {.E8, .E16, .E32},  BOTH_SHAPES, -1, .COMPARE_ZERO, .NEON, 0},
	{.VCLE,    1, 0x3, .SIGNED,      {.E8, .E16, .E32},  BOTH_SHAPES, -1, .COMPARE_ZERO, .NEON, 0},
	{.VCLT,    1, 0x4, .SIGNED,      {.E8, .E16, .E32},  BOTH_SHAPES, -1, .COMPARE_ZERO, .NEON, 0},
	{.VABS,    1, 0x6, .SIGNED,      {.E8, .E16, .E32},  BOTH_SHAPES, -1, .SAME,         .NEON, 0},
	{.VNEG,    1, 0x7, .SIGNED,      {.E8, .E16, .E32},  BOTH_SHAPES, -1, .SAME,         .NEON, 0},
	{.VCGT,    1, 0x8, .FLOAT,       {.E16, .E32},       BOTH_SHAPES, -1, .COMPARE_ZERO, .NEON, 0},
	{.VCGE,    1, 0x9, .FLOAT,       {.E16, .E32},       BOTH_SHAPES, -1, .COMPARE_ZERO, .NEON, 0},
	{.VCEQ,    1, 0xA, .FLOAT,       {.E16, .E32},       BOTH_SHAPES, -1, .COMPARE_ZERO, .NEON, 0},
	{.VCLE,    1, 0xB, .FLOAT,       {.E16, .E32},       BOTH_SHAPES, -1, .COMPARE_ZERO, .NEON, 0},
	{.VCLT,    1, 0xC, .FLOAT,       {.E16, .E32},       BOTH_SHAPES, -1, .COMPARE_ZERO, .NEON, 0},
	{.VABS,    1, 0xE, .FLOAT,       {.E16, .E32},       BOTH_SHAPES, -1, .SAME,         .NEON, 0},
	{.VNEG,    1, 0xF, .FLOAT,       {.E16, .E32},       BOTH_SHAPES, -1, .SAME,         .NEON, 0},
	{.VSWP,    2, 0x0, .NO_TYPE,     {.E8},              BOTH_SHAPES, -1, .PAIR,         .NEON, 0},
	{.VTRN,    2, 0x1, .BARE,        {.E8, .E16, .E32},  BOTH_SHAPES, -1, .PAIR,         .NEON, 0},
	{.VUZP,    2, 0x2, .BARE,        {.E8, .E16},        BOTH_SHAPES, -1, .PAIR,         .NEON, 0},
	{.VUZP,    2, 0x2, .BARE,        {.E32},             {.Q},        -1, .PAIR,         .NEON, 0},
	{.VZIP,    2, 0x3, .BARE,        {.E8, .E16},        BOTH_SHAPES, -1, .PAIR,         .NEON, 0},
	{.VZIP,    2, 0x3, .BARE,        {.E32},             {.Q},        -1, .PAIR,         .NEON, 0},
	{.VMOVN,   2, 0x4, .INTEGER,     {.E16, .E32, .E64}, {.D},         0, .NARROWING,    .NEON, 0},
	{.VQMOVUN, 2, 0x4, .SIGNED,      {.E16, .E32, .E64}, {.D},         1, .NARROWING,    .NEON, 0},
	{.VQMOVN,  2, 0x5, .SIGNED,      {.E16, .E32, .E64}, {.D},         0, .NARROWING,    .NEON, 0},
	{.VQMOVN,  2, 0x5, .UNSIGNED,    {.E16, .E32, .E64}, {.D},         1, .NARROWING,    .NEON, 0},
	{.VRINTN,  2, 0x8, .FLOAT,       {.E16, .E32},       BOTH_SHAPES, -1, .SAME,         .V8,   0},
	{.VRINTX,  2, 0x9, .FLOAT,       {.E16, .E32},       BOTH_SHAPES, -1, .SAME,         .V8,   0},
	{.VRINTA,  2, 0xA, .FLOAT,       {.E16, .E32},       BOTH_SHAPES, -1, .SAME,         .V8,   0},
	{.VRINTZ,  2, 0xB, .FLOAT,       {.E16, .E32},       BOTH_SHAPES, -1, .SAME,         .V8,   0},
	{.VRINTM,  2, 0xD, .FLOAT,       {.E16, .E32},       BOTH_SHAPES, -1, .SAME,         .V8,   0},
	{.VRINTP,  2, 0xF, .FLOAT,       {.E16, .E32},       BOTH_SHAPES, -1, .SAME,         .V8,   0},
	{.VRECPE,  3, 0x8, .UNSIGNED,    {.E32},             BOTH_SHAPES, -1, .SAME,         .NEON, 0},
	{.VRSQRTE, 3, 0x9, .UNSIGNED,    {.E32},             BOTH_SHAPES, -1, .SAME,         .NEON, 0},
	{.VRECPE,  3, 0xA, .FLOAT,       {.E16, .E32},       BOTH_SHAPES, -1, .SAME,         .NEON, 0},
	{.VRSQRTE, 3, 0xB, .FLOAT,       {.E16, .E32},       BOTH_SHAPES, -1, .SAME,         .NEON, 0},
}

@(private="file")
expand_misc :: proc(rows: ^[dynamic]Encoding) {
	for class in MISC {
		for size in class.sizes {
			// A float's size field: 10 for .f32, 01 for .f16.
			field := u32(size)
			feature := class.feature
			if class.kind == .FLOAT {
				field = size == .E32 ? 2 : 1
				if size == .E16 { feature = .NEON_HALF_FP }
			}
			// The narrowing ones are typed by the wide source.
			type_size := size
			if class.shape == .NARROWING { field = u32(size) - 1 }
			dt := Data_Types{data_type(class.kind, type_size, class.type_u), .NONE}
			for shape in class.shapes {
				q := u32(shape == .Q ? 1 : 0)
				if class.q_fixed >= 0 { q = u32(class.q_fixed) }
				bits := 0xF3B0_0000 | field << 18 | class.a << 16 | class.b << 7 | q << 6
				mask: u32 = 0xFFB3_0FD0 | 0x000C_0000
				ops, enc := two_registers(shape)
				switch class.shape {
				case .SAME, .PAIR:
					append_row(rows, class.mnemonic, ops, enc, bits, mask, feature, dt)
				case .COMPARE_ZERO:
					append_row(rows, class.mnemonic, {ops[0], ops[1], .IMM}, {enc[0], enc[1], .NONE}, bits, mask, feature, dt)
				case .NARROWING:
					append_row(rows, class.mnemonic, {.DPR, .QPR}, {.VD_D, .VM_Q}, bits, mask, feature, dt)
				case .WIDENING:
					append_row(rows, class.mnemonic, {.QPR, .DPR}, {.VD_Q, .VM_D}, bits, mask, feature, dt)
				}
			}
		}
	}
	// VSHLL by exactly the element size, which is a different word from the
	// shift form, typed .i: Qd, Dm, #8.
	for size in (Element_Sizes{.E8, .E16, .E32}) {
		bits := 0xF3B2_0300 | u32(size) << 18
		append_row(rows, .VSHLL, {.QPR, .DPR, .IMM}, {.VD_Q, .VM_D, .NEON_SHLL}, bits, 0xFFB3_0FD0 | 0x000C_0000, .NEON, {data_type(.INTEGER, size, 0), .NONE})
	}
	// Half-precision conversions, f16 <-> f32: one side a D register, the
	// other a Q. And the BFloat16 narrowing.
	append_row(rows, .VCVT, {.DPR, .QPR}, {.VD_D, .VM_Q}, 0xF3B6_0600, 0xFFBF_0FD0, .HALF_FP, {.F16, .F32})
	append_row(rows, .VCVT, {.QPR, .DPR}, {.VD_Q, .VM_D}, 0xF3B6_0700, 0xFFBF_0FD0, .HALF_FP, {.F32, .F16})
	append_row(rows, .VCVT, {.DPR, .QPR}, {.VD_D, .VM_Q}, 0xF3B6_0640, 0xFFBF_0FD0, .BF16, {.BF16, .F32})
	// Conversion between floating point and integer: bits 8-7 say which way,
	// and the size field which float.
	Integer_Conversion :: struct { op: u32, to, from: Data_Type }
	@(rodata, static) INTEGER_CONVERSIONS := []Integer_Conversion{
		{0, .F32, .S32}, {1, .F32, .U32}, {2, .S32, .F32}, {3, .U32, .F32},
	}
	for conversion in INTEGER_CONVERSIONS {
		for half in ([]bool{false, true}) {
			field := u32(half ? 1 : 2)
			to, from := conversion.to, conversion.from
			if half {
				to = half_of(to)
				from = half_of(from)
			}
			feature: Feature = half ? .NEON_HALF_FP : .NEON
			for shape in BOTH_SHAPES {
				q := u32(shape == .Q ? 1 : 0)
				bits := 0xF3BB_0600 | field << 18 | conversion.op << 7 | q << 6
				ops, enc := two_registers(shape)
				append_row(rows, .VCVT, ops, enc, bits & ~u32(0x000C_0000) | field << 18, 0xFFB3_0FD0 | 0x000C_0000, feature, {to, from})
			}
		}
	}
	// The v8 conversions with a rounding mode of their own: bits 9-8 name it,
	// bit 7 the signedness.
	Rounding_Conversion :: struct { mnemonic: Mnemonic, rounding: u32 }
	@(rodata, static) ROUNDING_CONVERSIONS := []Rounding_Conversion{
		{.VCVTA, 0}, {.VCVTN, 1}, {.VCVTP, 2}, {.VCVTM, 3},
	}
	for conversion in ROUNDING_CONVERSIONS {
		for u in u32(0) ..= 1 {
			for half in ([]bool{false, true}) {
				field := u32(half ? 1 : 2)
				to: Data_Type = u == 0 ? (half ? .S16 : .S32) : (half ? .U16 : .U32)
				from: Data_Type = half ? .F16 : .F32
				feature: Feature = half ? .NEON_HALF_FP : .V8
				for shape in BOTH_SHAPES {
					q := u32(shape == .Q ? 1 : 0)
					bits := 0xF3B3_0000 | field << 18 | conversion.rounding << 8 | u << 7 | q << 6
					ops, enc := two_registers(shape)
					append_row(rows, conversion.mnemonic, ops, enc, bits, 0xFFB3_0FD0 | 0x000C_0000, feature, {to, from})
				}
			}
		}
	}
}

@(private="file")
half_of :: proc(t: Data_Type) -> Data_Type {
	if t == .F32 { return .F16 }
	if t == .S32 { return .S16 }
	if t == .U32 { return .U16 }
	panic("no half-width type")
}

// =============================================================================
// One register and a modified immediate
// =============================================================================
//
//   1111 001a 1D00 0bcd dddd cmod 0Qo1 efgh
//
// cmode and op say what abcdefgh expands to and which operation takes it.

Modified_Immediate :: struct {
	mnemonic: Mnemonic,
	cmode:    u32,
	op:       u32,
	dt:       Data_Type,
}

@(rodata)
MODIFIED_IMMEDIATES := []Modified_Immediate{
	{.VMOV, 0x0, 0, .I32}, {.VORR, 0x1, 0, .I32}, {.VMOV, 0x2, 0, .I32}, {.VORR, 0x3, 0, .I32},
	{.VMOV, 0x4, 0, .I32}, {.VORR, 0x5, 0, .I32}, {.VMOV, 0x6, 0, .I32}, {.VORR, 0x7, 0, .I32},
	{.VMOV, 0x8, 0, .I16}, {.VORR, 0x9, 0, .I16}, {.VMOV, 0xA, 0, .I16}, {.VORR, 0xB, 0, .I16},
	{.VMOV, 0xC, 0, .I32}, {.VMOV, 0xD, 0, .I32}, {.VMOV, 0xE, 0, .I8},  {.VMOV, 0xF, 0, .F32},
	{.VMVN, 0x0, 1, .I32}, {.VBIC, 0x1, 1, .I32}, {.VMVN, 0x2, 1, .I32}, {.VBIC, 0x3, 1, .I32},
	{.VMVN, 0x4, 1, .I32}, {.VBIC, 0x5, 1, .I32}, {.VMVN, 0x6, 1, .I32}, {.VBIC, 0x7, 1, .I32},
	{.VMVN, 0x8, 1, .I16}, {.VBIC, 0x9, 1, .I16}, {.VMVN, 0xA, 1, .I16}, {.VBIC, 0xB, 1, .I16},
	{.VMVN, 0xC, 1, .I32}, {.VMVN, 0xD, 1, .I32}, {.VMOV, 0xE, 1, .I64},
}

@(private="file")
expand_modified_immediate :: proc(rows: ^[dynamic]Encoding) {
	for form in MODIFIED_IMMEDIATES {
		for shape in BOTH_SHAPES {
			q := u32(shape == .Q ? 1 : 0)
			bits := 0xF280_0010 | form.cmode << 8 | q << 6 | form.op << 5
			register: Operand_Type = shape == .Q ? .QPR : .DPR
			field: Operand_Encoding = shape == .Q ? .VD_Q : .VD_D
			append_row(rows, form.mnemonic, {register, .IMM}, {field, .NEON_IMM8_ABCDEFGH}, bits, 0xFEB8_0FF0, .NEON, {form.dt, .NONE})
		}
	}
}

// =============================================================================
// The rest of the data-processing space
// =============================================================================

@(private="file")
expand_permutes :: proc(rows: ^[dynamic]Encoding) {
	// VEXT: 1111 0010 1D11 nnnn dddd iiii NQM0 mmmm, imm4 the byte index. An
	// assembler takes a larger element and scales; the word holds bytes, and
	// that is how it decodes.
	append_row(rows, .VEXT, {.DPR, .DPR, .DPR, .IMM}, {.VD_D, .VN_D, .VM_D, .NEON_VEXT_IMM4}, 0xF2B0_0000, 0xFFB0_0850, .NEON, {.SZ8, .NONE})
	append_row(rows, .VEXT, {.QPR, .QPR, .QPR, .IMM}, {.VD_Q, .VN_Q, .VM_Q, .NEON_VEXT_IMM4}, 0xF2B0_0040, 0xFFB0_0050, .NEON, {.SZ8, .NONE})
	// VTBL, VTBX: 1111 0011 1D11 nnnn dddd 10ll NoM0 mmmm -- a table of one to
	// four D registers from Dn, by len.
	for mnemonic, op in ([]Mnemonic{.VTBL, .VTBX}) {
		bits := 0xF3B0_0800 | u32(op) << 6
		append_row(rows, mnemonic, {.DPR, .DPR_LIST, .DPR}, {.VD_D, .NEON_VN_TABLE, .VM_D}, bits, 0xFFB0_0C50, .NEON, {.SZ8, .NONE})
	}
	// VDUP from a lane: 1111 0011 1D11 iiii dddd 1100 0QM0 mmmm, imm4 the size
	// and the lane at once.
	for shape in BOTH_SHAPES {
		q := u32(shape == .Q ? 1 : 0)
		register: Operand_Type = shape == .Q ? .QPR : .DPR
		field: Operand_Encoding = shape == .Q ? .VD_Q : .VD_D
		Lane_Size :: struct { pattern, mask: u32, dt: Data_Type }
		@(rodata, static) LANE_SIZES := []Lane_Size{
			{0x0001_0000, 0x0001_0000, .SZ8}, {0x0002_0000, 0x0003_0000, .SZ16}, {0x0004_0000, 0x0007_0000, .SZ32},
		}
		for lane_size in LANE_SIZES {
			bits := 0xF3B0_0C00 | q << 6 | lane_size.pattern
			append_row(rows, .VDUP, {register, .DPR_ELEM}, {field, .NEON_VDUP_LANE}, bits, 0xFFB0_0FD0 | lane_size.mask, .NEON, {lane_size.dt, .NONE})
		}
	}
}

// =============================================================================
// Cryptography
// =============================================================================

@(private="file")
expand_crypto :: proc(rows: ^[dynamic]Encoding) {
	Two_Register_Crypto :: struct { mnemonic: Mnemonic, bits: u32, dt: Data_Type }
	@(rodata, static) TWO_REGISTER := []Two_Register_Crypto{
		{.AESE, 0xF3B0_0300, .SZ8},       {.AESD, 0xF3B0_0340, .SZ8},
		{.AESMC, 0xF3B0_0380, .SZ8},      {.AESIMC, 0xF3B0_03C0, .SZ8},
		{.SHA1H, 0xF3B9_02C0, .SZ32},     {.SHA1SU1, 0xF3BA_0380, .SZ32},
		{.SHA256SU0, 0xF3BA_03C0, .SZ32},
	}
	for form in TWO_REGISTER {
		append_row(rows, form.mnemonic, {.QPR, .QPR}, {.VD_Q, .VM_Q}, form.bits, 0xFFBF_0FD0, .CRYPTO, {form.dt, .NONE})
	}
	Three_Register_Crypto :: struct { mnemonic: Mnemonic, u, size: u32 }
	@(rodata, static) THREE_REGISTER := []Three_Register_Crypto{
		{.SHA1C, 0, 0}, {.SHA1P, 0, 1}, {.SHA1M, 0, 2}, {.SHA1SU0, 0, 3},
		{.SHA256H, 1, 0}, {.SHA256H2, 1, 1}, {.SHA256SU1, 1, 2},
	}
	for form in THREE_REGISTER {
		bits := 0xF200_0C40 | form.u << 24 | form.size << 20
		append_row(rows, form.mnemonic, {.QPR, .QPR, .QPR}, {.VD_Q, .VN_Q, .VM_Q}, bits, 0xFFB0_0F50, .CRYPTO, {.SZ32, .NONE})
	}
}

// =============================================================================
// The v8.x additions, in the unconditional coprocessor space
// =============================================================================
//
// Dot products, complex arithmetic, the half-precision long multiplies and
// the BFloat16 and 8-bit integer matrix operations.

@(private="file")
expand_extensions :: proc(rows: ^[dynamic]Encoding) {
	// The integer dot products and matrix multiplies: three registers, or
	// for the dot products by element, a 32-bit lane of Dm.
	Dot :: struct { mnemonic: Mnemonic, bits: u32, dt: Data_Type, feature: Feature, shapes: Shapes, by_element: bool }
	@(rodata, static) DOTS := []Dot{
		{.VSDOT,   0xFC20_0D00, .S8,   .DOT,  BOTH_SHAPES, false},
		{.VUDOT,   0xFC20_0D10, .U8,   .DOT,  BOTH_SHAPES, false},
		{.VSDOT,   0xFE20_0D00, .S8,   .DOT,  BOTH_SHAPES, true},
		{.VUDOT,   0xFE20_0D10, .U8,   .DOT,  BOTH_SHAPES, true},
		{.VUSDOT,  0xFCA0_0D00, .S8,   .V8,   BOTH_SHAPES, false},
		{.VUSDOT,  0xFE80_0D00, .S8,   .V8,   BOTH_SHAPES, true},
		{.VSUDOT,  0xFE80_0D10, .U8,   .V8,   BOTH_SHAPES, true},
		{.VDOT,    0xFC00_0D00, .BF16, .BF16, BOTH_SHAPES, false},
		{.VDOT,    0xFE00_0D00, .BF16, .BF16, BOTH_SHAPES, true},
		{.VSMMLA,  0xFC20_0C40, .S8,   .V8,   {.Q},        false},
		{.VUMMLA,  0xFC20_0C50, .U8,   .V8,   {.Q},        false},
		{.VUSMMLA, 0xFCA0_0C40, .S8,   .V8,   {.Q},        false},
		{.VMMLA,   0xFC00_0C40, .BF16, .BF16, {.Q},        false},
	}
	for form in DOTS {
		for shape in form.shapes {
			q := u32(shape == .Q ? 1 : 0)
			bits := form.bits | q << 6
			dt := Data_Types{form.dt, .NONE}
			if form.by_element {
				switch shape {
				case .D: append_row(rows, form.mnemonic, {.DPR, .DPR, .DPR_ELEM}, {.VD_D, .VN_D, .NEON_VM_SCALAR_32}, bits, 0xFFB0_0F50, form.feature, dt)
				case .Q: append_row(rows, form.mnemonic, {.QPR, .QPR, .DPR_ELEM}, {.VD_Q, .VN_Q, .NEON_VM_SCALAR_32}, bits, 0xFFB0_0F50, form.feature, dt)
				}
				continue
			}
			ops, enc := three_registers(shape)
			append_row(rows, form.mnemonic, ops, enc, bits, 0xFFB0_0F50, form.feature, dt)
		}
	}

	// VCMLA, VCADD: 1111 110r r D1S nnnn dddd 1000 NQM0 mmmm for VCMLA, with
	// the rotation at 24-23; VCADD has bit 23 set, bit 21 clear and a two-way
	// rotation at 24. S is the size: 0 for .f16, 1 for .f32.
	for size in (Element_Sizes{.E16, .E32}) {
		s := u32(size == .E32 ? 1 : 0)
		dt := Data_Types{data_type(.FLOAT, size, 0), .NONE}
		for shape in BOTH_SHAPES {
			q := u32(shape == .Q ? 1 : 0)
			ops, enc := three_registers(shape)
			append_row(rows, .VCMLA, {ops[0], ops[1], ops[2], .IMM}, {enc[0], enc[1], enc[2], .NEON_ROT_4_HI}, 0xFC20_0800 | s << 20 | q << 6, 0xFE30_0F50, .FCMA, dt)
			append_row(rows, .VCADD, {ops[0], ops[1], ops[2], .IMM}, {enc[0], enc[1], enc[2], .NEON_ROT_2}, 0xFC80_0800 | s << 20 | q << 6, 0xFEB0_0F50, .FCMA, dt)
		}
	}
	// VCMLA by element: 1111 1110 SD rr nnnn dddd 1000 NQM0 mmmm, the rotation
	// at 21-20. A .f16 takes a lane of D0-D15 by M; a .f32 any D register,
	// lane 0.
	for shape in BOTH_SHAPES {
		q := u32(shape == .Q ? 1 : 0)
		vector: Operand_Type = shape == .Q ? .QPR : .DPR
		destination: Operand_Encoding = shape == .Q ? .VD_Q : .VD_D
		source: Operand_Encoding = shape == .Q ? .VN_Q : .VN_D
		append_row(rows, .VCMLA, {vector, vector, .DPR_ELEM, .IMM}, {destination, source, .NEON_VM_SCALAR_32, .NEON_ROT_4}, 0xFE00_0800 | q << 6, 0xFFC0_0F50, .FCMA, {.F16, .NONE})
		append_row(rows, .VCMLA, {vector, vector, .DPR_ELEM, .IMM}, {destination, source, .NEON_VM_D_LANE0, .NEON_ROT_4}, 0xFE80_0800 | q << 6, 0xFFC0_0F50, .FCMA, {.F32, .NONE})
	}

	// VFMAL, VFMSL: half-precision products accumulated in single precision.
	// The D form is Dd, Sn, Sm; the Q form Qd, Dn, Dm. By element the D form
	// takes a lane of S0-S15, the Q form a lane of D0-D7.
	for mnemonic, k in ([]Mnemonic{.VFMAL, .VFMSL}) {
		subtract := u32(k)
		append_row(rows, mnemonic, {.DPR, .SPR, .SPR}, {.VD_D, .VN_S, .VM_S}, 0xFC20_0810 | subtract << 23, 0xFFB0_0F50, .FHM, {.F16, .NONE})
		append_row(rows, mnemonic, {.QPR, .DPR, .DPR}, {.VD_Q, .VN_D, .VM_D}, 0xFC20_0850 | subtract << 23, 0xFFB0_0F50, .FHM, {.F16, .NONE})
		append_row(rows, mnemonic, {.DPR, .SPR, .SPR_ELEM}, {.VD_D, .VN_S, .NEON_VM_S_SCALAR}, 0xFE00_0810 | subtract << 20, 0xFFB0_0F50, .FHM, {.F16, .NONE})
		append_row(rows, mnemonic, {.QPR, .DPR, .DPR_ELEM}, {.VD_Q, .VN_D, .NEON_VM_SCALAR_16}, 0xFE00_0850 | subtract << 20, 0xFFB0_0F50, .FHM, {.F16, .NONE})
	}

	// VFMAB, VFMAT: BFloat16 products of the bottom or top halves, bit 6.
	for mnemonic, top in ([]Mnemonic{.VFMAB, .VFMAT}) {
		t := u32(top)
		append_row(rows, mnemonic, {.QPR, .QPR, .QPR}, {.VD_Q, .VN_Q, .VM_Q}, 0xFC30_0810 | t << 6, 0xFFB0_0F50, .BF16, {.BF16, .NONE})
		append_row(rows, mnemonic, {.QPR, .QPR, .DPR_ELEM}, {.VD_Q, .VN_Q, .NEON_VM_SCALAR_16}, 0xFE30_0810 | t << 6, 0xFFB0_0F50, .BF16, {.BF16, .NONE})
	}
}

// =============================================================================
// Element and structure loads and stores
// =============================================================================
//
//   multiple    1111 0100 0D L0 nnnn dddd tttt zzaa mmmm
//   one lane    1111 0100 1D L0 nnnn dddd zzNN iiii mmmm      zz != 11
//   all lanes   1111 0100 1D 10 nnnn dddd 11NN zzTa mmmm
//
// L is 1 for a load. Rm is the writeback: 1111 none, 1101 by what was
// transferred (`[r0]!`), anything else by that register (`[r0], r2`); one row
// covers all three, and NEON_ADDRESS reads which. The alignment comes in a
// few bits whose meaning differs by class, number and size, and some values
// are reserved -- so each row pins one alignment, and only the valid ones
// have rows.

@(private="file")
STRUCTURE_LOADS  := [4]Mnemonic{.VLD1, .VLD2, .VLD3, .VLD4}
@(private="file")
STRUCTURE_STORES := [4]Mnemonic{.VST1, .VST2, .VST3, .VST4}

@(private="file")
structure_mnemonic :: proc(load: bool, elements: int) -> Mnemonic {
	return load ? STRUCTURE_LOADS[elements - 1] : STRUCTURE_STORES[elements - 1]
}

@(private="file")
expand_structure_load_store :: proc(rows: ^[dynamic]Encoding) {
	@(rodata, static) BARE_SIZES := [Element_Size]Data_Type{.E8 = .SZ8, .E16 = .SZ16, .E32 = .SZ32, .E64 = .SZ64}
	for load in ([]bool{true, false}) {
		l := u32(load ? 1 : 0)
		// Multiple structures: the type field says how many registers, of how
		// many elements each, and spaced by how much.
		Multiple :: struct { type: u32, elements: int, alignments: u32 }    // alignments: which of aa's values are valid
		@(rodata, static) MULTIPLE := []Multiple{
			{0x7, 1, 0b0011}, {0xA, 1, 0b0111}, {0x6, 1, 0b0011}, {0x2, 1, 0b1111},
			{0x8, 2, 0b0111}, {0x9, 2, 0b0111}, {0x3, 2, 0b1111},
			{0x4, 3, 0b0011}, {0x5, 3, 0b0011},
			{0x0, 4, 0b1111}, {0x1, 4, 0b1111},
		}
		for form in MULTIPLE {
			for size in Element_Size {
				if size == .E64 && form.elements != 1 { continue }
				for alignment in u32(0) ..< 4 {
					if form.alignments & (1 << alignment) == 0 { continue }
					bits := 0xF400_0000 | l << 21 | form.type << 8 | u32(size) << 6 | alignment << 4
					append_row(rows, structure_mnemonic(load, form.elements), {.DPR_LIST, .MEM}, {.NEON_MULTIPLE_LIST, .NEON_ADDRESS}, bits, 0xFFB0_0FF0, .NEON, {BARE_SIZES[size], .NONE})
				}
			}
		}
		// One lane: NN is how many elements less one; the index_align field
		// holds the lane, a spacing bit for the larger sizes, and the alignment.
		// `fixed` is what of index_align a row pins, `values` the pinned bits.
		Lane :: struct { elements: int, size: Element_Size, fixed, value: u32 }
		@(rodata, static) LANES := []Lane{
			// VLD1/VST1: .8 iii0; .16 ii0a; .32 i0aa with aa 00 or 11.
			{1, .E8, 0x1, 0x0}, {1, .E16, 0x3, 0x0}, {1, .E16, 0x3, 0x1}, {1, .E32, 0x7, 0x0}, {1, .E32, 0x7, 0x3},
			// VLD2: .8 iiia; .16 iisa; .32 is0a.
			{2, .E8, 0x1, 0x0}, {2, .E8, 0x1, 0x1},
			{2, .E16, 0x3, 0x0}, {2, .E16, 0x3, 0x1}, {2, .E16, 0x3, 0x2}, {2, .E16, 0x3, 0x3},
			{2, .E32, 0x7, 0x0}, {2, .E32, 0x7, 0x1}, {2, .E32, 0x7, 0x4}, {2, .E32, 0x7, 0x5},
			// VLD3: no alignment. .8 iii0; .16 iis0; .32 is00.
			{3, .E8, 0x1, 0x0},
			{3, .E16, 0x3, 0x0}, {3, .E16, 0x3, 0x2},
			{3, .E32, 0x7, 0x0}, {3, .E32, 0x7, 0x4},
			// VLD4: .8 iiia; .16 iisa; .32 isaa with aa 00, 01 or 10.
			{4, .E8, 0x1, 0x0}, {4, .E8, 0x1, 0x1},
			{4, .E16, 0x3, 0x0}, {4, .E16, 0x3, 0x1}, {4, .E16, 0x3, 0x2}, {4, .E16, 0x3, 0x3},
			{4, .E32, 0x7, 0x0}, {4, .E32, 0x7, 0x1}, {4, .E32, 0x7, 0x2},
			{4, .E32, 0x7, 0x4}, {4, .E32, 0x7, 0x5}, {4, .E32, 0x7, 0x6},
		}
		for lane in LANES {
			bits := 0xF480_0000 | l << 21 | u32(lane.size) << 10 | u32(lane.elements - 1) << 8 | lane.value << 4
			mask := 0xFFB0_0F00 | lane.fixed << 4
			append_row(rows, structure_mnemonic(load, lane.elements), {.DPR_LIST, .MEM}, {.NEON_LANE_LIST, .NEON_ADDRESS}, bits, mask, .NEON, {BARE_SIZES[lane.size], .NONE})
		}
		if !load {
			continue
		}
		// All lanes, loads only: T is the second register for VLD1 and the
		// spacing for the rest; a is the alignment, which VLD3 cannot have
		// and which VLD4 at size 11 must, as a .32 aligned to 128 bits.
		All_Lanes :: struct { elements: int, size: u32, t: u32, a: u32, dt: Element_Size }
		@(rodata, static) ALL_LANES := []All_Lanes{
			{1, 0, 0, 0, .E8},  {1, 0, 1, 0, .E8},
			{1, 1, 0, 0, .E16}, {1, 1, 1, 0, .E16}, {1, 1, 0, 1, .E16}, {1, 1, 1, 1, .E16},
			{1, 2, 0, 0, .E32}, {1, 2, 1, 0, .E32}, {1, 2, 0, 1, .E32}, {1, 2, 1, 1, .E32},
			{2, 0, 0, 0, .E8},  {2, 0, 1, 0, .E8},  {2, 0, 0, 1, .E8},  {2, 0, 1, 1, .E8},
			{2, 1, 0, 0, .E16}, {2, 1, 1, 0, .E16}, {2, 1, 0, 1, .E16}, {2, 1, 1, 1, .E16},
			{2, 2, 0, 0, .E32}, {2, 2, 1, 0, .E32}, {2, 2, 0, 1, .E32}, {2, 2, 1, 1, .E32},
			{3, 0, 0, 0, .E8},  {3, 0, 1, 0, .E8},
			{3, 1, 0, 0, .E16}, {3, 1, 1, 0, .E16},
			{3, 2, 0, 0, .E32}, {3, 2, 1, 0, .E32},
			{4, 0, 0, 0, .E8},  {4, 0, 1, 0, .E8},  {4, 0, 0, 1, .E8},  {4, 0, 1, 1, .E8},
			{4, 1, 0, 0, .E16}, {4, 1, 1, 0, .E16}, {4, 1, 0, 1, .E16}, {4, 1, 1, 1, .E16},
			{4, 2, 0, 0, .E32}, {4, 2, 1, 0, .E32}, {4, 2, 0, 1, .E32}, {4, 2, 1, 1, .E32},
			{4, 3, 0, 1, .E32}, {4, 3, 1, 1, .E32},
		}
		for form in ALL_LANES {
			bits := 0xF4A0_0C00 | u32(form.elements - 1) << 8 | form.size << 6 | form.t << 5 | form.a << 4
			append_row(rows, structure_mnemonic(true, form.elements), {.DPR_LIST, .MEM}, {.NEON_ALL_LANES_LIST, .NEON_ADDRESS}, bits, 0xFFB0_0FF0, .NEON, {BARE_SIZES[form.dt], .NONE})
		}
	}
}

// =============================================================================

// Every Advanced SIMD A32 form, appended to `rows`.
advanced_simd_forms :: proc(rows: ^[dynamic]Encoding) {
	expand_same_length(rows)
	expand_different_length(rows)
	expand_by_scalar(rows)
	expand_by_shift(rows)
	expand_misc(rows)
	expand_modified_immediate(rows)
	expand_permutes(rows)
	expand_crypto(rows)
	expand_extensions(rows)
	expand_structure_load_store(rows)
}
