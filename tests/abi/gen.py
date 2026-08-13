#!/usr/bin/env python3
"""Generates abi_corpus.odin and abi_corpus.c from one description.

The two files are checked in; this only needs running when the corpus changes.
Writing them by hand is what the generator exists to avoid: the whole test is
the claim that the Odin and C declarations describe the SAME type, and two
hand-maintained files drift.

The corpus encodes NO ABI. Every check is "Odin and the platform C compiler
agree", so one corpus is valid on every target without knowing whether it is
SysV, AAPCS64 or Win64.
"""

import io

# ---------------------------------------------------------------- scalars

# tag -> (odin, c, is_float)
SCALARS = {
    "i8":  ("i8",  "int8_t",   False),
    "i16": ("i16", "int16_t",  False),
    "i32": ("i32", "int32_t",  False),
    "i64": ("i64", "int64_t",  False),
    "u8":  ("u8",  "uint8_t",  False),
    "u16": ("u16", "uint16_t", False),
    "u32": ("u32", "uint32_t", False),
    "u64": ("u64", "uint64_t", False),
    "bool":("bool","_Bool",    False),
    "f16": ("f16", "_Float16", True),
    "i128":("i128","__int128", False),
    "enum":("E32", "enum E32", False),
    "c64": ("complex64",  "float _Complex",  False),
    "c128":("complex128", "double _Complex", False),
    "bset":("BS", "unsigned", False),
    "f32": ("f32", "float",    True),
    "f64": ("f64", "double",   True),
    "ptr": ("rawptr", "void *", False),
}

# Tiers keep a target that lacks an extension from losing the whole corpus.
TIER_CORE = "core"
TIER_GNU  = "gnu"    # zero-length arrays, empty structs -- __GNUC__
TIER_F16  = "f16"    # _Float16
TIER_I128 = "i128"   # __int128, 64-bit targets only


# A scalar can carry a tier, and any type built from it inherits it: `_Float16`
# is not available everywhere, and a family is only as portable as its members.
SCALAR_TIER = {"f16": TIER_F16, "i128": TIER_I128}


def tier_of(*tags, base=TIER_CORE):
    for t in tags:
        if t in SCALAR_TIER:
            return SCALAR_TIER[t]
    return base


class Ty:
    def __init__(self, name, odin, c, fields, tier=TIER_CORE, odin_set=None, odin_get=None):
        self.name, self.odin, self.c, self.fields, self.tier = name, odin, c, fields, tier
        # Escape hatch for members with no lvalue path on the Odin side. A #simd
        # lane is read with `simd.extract` and written only as a whole vector,
        # so the C side still checks every lane while Odin uses these.
        # odin_set: statements, `{}` is the variable. odin_get: (expr, expected).
        self.odin_set, self.odin_get = odin_set, odin_get


def val(i, tag):
    """A distinct value per field position, so a shifted read is detectable."""
    if SCALARS[tag][2]:
        return f"{i * 7 + 3}.5"
    return str(i * 7 + 3)


def c_val(tag, v):
    if tag == "ptr":  return f"(void *)(intptr_t)({v})"
    if tag == "bool": return "1"
    if tag == "enum": return f"(enum E32)({v})"
    if tag == "c64":  return f"({v}.0f + {v}.0if)"
    if tag == "c128": return f"({v}.0 + {v}.0i)"
    if tag == "bset": return f"({(1 << (int(v) % 31)) | 1}u)"
    return v


def odin_val(tag, v):
    if tag == "ptr":  return f"rawptr(uintptr({v}))"
    if tag == "bool": return "true"
    if tag == "enum": return f"E32({v})"
    if tag == "c64":  return f"complex64(complex({v}, {v}))"
    if tag == "c128": return f"complex128(complex({v}, {v}))"
    if tag == "bset": return "(BS{0, " + str(int(v) % 31) + "})"
    return v


def c_ref(cp, var):
    """A C member reference. `{}` lets a member be an EXPRESSION rather than a
    path, which is what `__real__ x` needs -- it is a prefix operator."""
    return cp.format(var) if "{}" in cp else f"{var}.{cp}"


def c_conds(t, var):
    parts = [f"{c_ref(cp, var)} == ({c_val(k, v)})" for _op, cp, k, v in t.fields]
    return " && ".join(parts) or "1"


def odin_setters(t, var):
    if t.odin_set is not None:
        return [x.replace("{}", var) for x in t.odin_set]
    return [f"{var}.{op} = {odin_val(tag, v)}" for op, _cp, tag, v in t.fields]


def odin_getters(t, var):
    if t.odin_get is not None:
        return [(e.replace("{}", var), ev) for e, ev in t.odin_get]
    out = []
    for op, _cp, tag, v in t.fields:
        ot = SCALARS[tag][0] if tag in SCALARS else "f16"
        ev = odin_val(tag, v) if tag in ("ptr", "bool", "enum", "c64", "c128", "bset") else f"{ot}({v})"
        out.append((f"{var}.{op}", ev))
    return out


def mutated(tag, v):
    """A value the checks MUST reject, for the mutation control."""
    if tag == "bool": return "false"
    if tag == "ptr":  return "rawptr(uintptr(999))"
    if tag == "enum": return f"E32({int(v) + 1})"
    if tag == "c64":  return f"complex64(complex({int(v) + 1}, {v}))"
    if tag == "c128": return f"complex128(complex({int(v) + 1}, {v}))"
    if tag == "bset": return "(BS{2})"
    return f"{float(v) + 1}" if "." in str(v) else f"{int(v) + 1}"


def leaf(path, tag, i):
    return (path, path, tag, val(i, tag))


def leaf2(odin_path, c_path, tag, v):
    """A member spelled differently in the two languages -- matrix indexing,
    or complex, where there is no common accessor."""
    return (odin_path, c_path, tag, v)


# ---------------------------------------------------------------- corpus

def build():
    out = []

    def add(*a, **k):
        out.append(Ty(*a, **k))

    # --- scalar arity 1..4, the merge and by-value/memory boundaries
    combos = [
        ("i32",), ("i64",), ("f32",), ("f64",), ("i8",), ("ptr",),
        ("i32", "i32"), ("f32", "f32"), ("f64", "f64"), ("i64", "f64"),
        ("f64", "i64"), ("i32", "f32"), ("f32", "i32"), ("i8", "i64"),
        ("f32", "f32", "f32"), ("i32", "i32", "i32"), ("f64", "f64", "f64"),
        ("i64", "i64", "i64"), ("f32", "i32", "f32"), ("i8", "f64", "i8"),
        ("f32", "f32", "f32", "f32"), ("f64", "f64", "f64", "f64"),
        ("i32", "i32", "i32", "i32"), ("i64", "i64", "i64", "i64"),
        ("f32", "f32", "f32", "i32"),
        # half, at each arity and mixed: the merge rules turn on the WIDTH of a
        # float member, not just on its being one
        ("f16",), ("f16", "f16"), ("f16", "i16"), ("f16", "f32"),
        ("f16", "f16", "f16"), ("f16", "f16", "f16", "f16"),
        ("f32", "f16"), ("f64", "f16"),
        # an enum is only under test if it is explicitly backed: Odin's default
        # is `int`, which is register-sized against C's 4
        ("enum",), ("enum", "enum"), ("enum", "f32"), ("i8", "enum"),
        # the only scalar that spans two eightbytes, and the one that reaches
        # AAPCS64's even-register-pair rule
        ("i128",), ("i128", "i64"), ("i8", "i128"), ("i128", "f64"),
        ("c64",), ("c128",), ("c64", "c64"), ("c64", "f32"), ("c128", "i64"),
        ("bset",), ("bset", "bset"), ("bset", "f32"),
    ]
    for tags in combos:
        n = "s_" + "_".join(tags)
        od = "struct { " + ", ".join(f"f{i}: {SCALARS[t][0]}" for i, t in enumerate(tags)) + " }"
        cd = "struct { " + " ".join(f"{SCALARS[t][1]} f{i};" for i, t in enumerate(tags)) + " }"
        add(n, od, cd, [leaf(f"f{i}", t, i) for i, t in enumerate(tags)], tier=tier_of(*tags))

    # --- arrays: the same eightbytes from one declaration
    for tag in ("f32", "f64", "i32", "i64", "i8", "f16", "enum", "i128"):
        for cnt in (1, 2, 3, 4, 5):
            n = f"a{cnt}_{tag}"
            od = f"struct {{ a: [{cnt}]{SCALARS[tag][0]} }}"
            cd = f"struct {{ {SCALARS[tag][1]} a[{cnt}]; }}"
            add(n, od, cd, [leaf(f"a[{i}]", tag, i) for i in range(cnt)], tier=tier_of(tag))

    # --- nesting: same leaves reached through another level
    for a, b in (("f32", "f32"), ("f64", "f64"), ("i32", "f32"), ("f32", "i64"),
                 ("f16", "f16"), ("f16", "i32")):
        add(f"n_{a}_{b}",
            f"struct {{ i: struct {{ x: {SCALARS[a][0]}, y: {SCALARS[b][0]} }} }}",
            f"struct {{ struct {{ {SCALARS[a][1]} x; {SCALARS[b][1]} y; }} i; }}",
            [leaf("i.x", a, 0), leaf("i.y", b, 1)], tier=tier_of(a, b))
        add(f"n2_{a}_{b}",
            f"struct {{ i: struct {{ x: {SCALARS[a][0]} }}, y: {SCALARS[b][0]} }}",
            f"struct {{ struct {{ {SCALARS[a][1]} x; }} i; {SCALARS[b][1]} y; }}",
            [leaf("i.x", a, 0), leaf("y", b, 1)], tier=tier_of(a, b))

    # --- unions, and a union below the top level
    for a, b in (("f32", "i32"), ("f64", "i64"), ("f32", "f32"), ("f64", "f32"),
                 ("f16", "i16"), ("f16", "f32")):
        add(f"u_{a}_{b}",
            f"struct #raw_union {{ x: {SCALARS[a][0]}, y: {SCALARS[b][0]} }}",
            f"union {{ {SCALARS[a][1]} x; {SCALARS[b][1]} y; }}",
            [leaf("x", a, 0)], tier=tier_of(a, b))
        add(f"su_{a}_{b}",
            f"struct {{ u: struct #raw_union {{ x: {SCALARS[a][0]} }}, y: {SCALARS[b][0]} }}",
            f"struct {{ union {{ {SCALARS[a][1]} x; }} u; {SCALARS[b][1]} y; }}",
            [leaf("u.x", a, 0), leaf("y", b, 1)], tier=tier_of(a, b))

    # --- homogeneous float aggregates and the shapes that disqualify them
    for tag in ("f32", "f64", "f16"):
        w = SCALARS[tag][0]
        cw = SCALARS[tag][1]
        add(f"hfa4_{tag}",
            f"struct {{ a, b, c, d: {w} }}",
            f"struct {{ {cw} a, b, c, d; }}",
            [leaf("a", tag, 0), leaf("b", tag, 1), leaf("c", tag, 2), leaf("d", tag, 3)],
            tier=tier_of(tag))
        add(f"hfa5_{tag}",
            f"struct {{ a, b, c, d, e: {w} }}",
            f"struct {{ {cw} a, b, c, d, e; }}",
            [leaf(x, tag, i) for i, x in enumerate("abcde")], tier=tier_of(tag))
        # zero-length array member -- disqualifies the HFA
        add(f"zla_{tag}",
            f"struct {{ z: [0]f32, a, b, c, d: {w} }}",
            f"struct {{ float z[0]; {cw} a, b, c, d; }}",
            [leaf("a", tag, 0), leaf("b", tag, 1), leaf("c", tag, 2), leaf("d", tag, 3)],
            tier=TIER_GNU)
        add(f"zlat_{tag}",
            f"struct {{ a, b, c, d: {w}, z: [0]f32 }}",
            f"struct {{ {cw} a, b, c, d; float z[0]; }}",
            [leaf("a", tag, 0), leaf("b", tag, 1), leaf("c", tag, 2), leaf("d", tag, 3)],
            tier=TIER_GNU)
        # empty struct member -- does NOT disqualify it
        add(f"esm_{tag}",
            f"struct {{ e: struct {{}}, a, b, c, d: {w} }}",
            f"struct {{ struct {{}} e; {cw} a, b, c, d; }}",
            [leaf("a", tag, 0), leaf("b", tag, 1), leaf("c", tag, 2), leaf("d", tag, 3)],
            tier=TIER_GNU)

    # --- alignment: changes size and placement without changing any field type
    for al in (16, 32):
        add(f"al{al}",
            f"struct #align({al}) {{ a, b, c: f64 }}",
            f"struct __attribute__((aligned({al}))) {{ double a, b, c; }}",
            [leaf("a", "f64", 0), leaf("b", "f64", 1), leaf("c", "f64", 2)],
            tier=TIER_GNU)
    add("pk", "struct #packed { a: i8, b: i32, c: i64 }",
        "struct __attribute__((packed)) { int8_t a; int32_t b; int64_t c; }",
        [leaf("a", "i8", 0), leaf("b", "i32", 1), leaf("c", "i64", 2)], tier=TIER_GNU)

    # --- explicit padding, the shape that started this file
    add("pad_i64_f32", "struct { a: i64, b: f32 }",
        "struct { int64_t a; float b; }",
        [leaf("a", "i64", 0), leaf("b", "f32", 1)])
    add("pad_f32_f64", "struct { a: f32, b: f64 }",
        "struct { float a; double b; }",
        [leaf("a", "f32", 0), leaf("b", "f64", 1)])

    # --- #simd vectors. Three ABIs disagree completely: x86-64 puts a 16-byte
    # one in a single xmm (SSE then SSEUP), AAPCS64 gives it a Q register and
    # lets several form a homogeneous VECTOR aggregate, Win64 passes every
    # vector by reference, and i386 has a separate xmm argument file.
    VEC = [("f32", 4, 16), ("f32", 2, 8), ("f64", 2, 16), ("i32", 4, 16), ("i8", 16, 16)]
    for tag, n, _sz in VEC:
        ct, cc = SCALARS[tag][0], SCALARS[tag][1]
        add(f"v{n}_{tag}",
            f"struct {{ v: #simd[{n}]{ct} }}",
            f"struct {{ {cc} v __attribute__((vector_size({n} * sizeof({cc})))); }}",
            [leaf(f"v[{i}]", tag, i) for i in range(n)], tier=TIER_GNU,
            odin_set=["{}.v = " + "{" + ", ".join(val(i, tag) for i in range(n)) + "}"],
            odin_get=[(f"simd.extract({{}}.v, {i})", f"{ct}({val(i, tag)})") for i in range(n)])
    # two vectors: an HVA on AAPCS64, memory on x86-64
    add("v4f32x2",
        "struct { a, b: #simd[4]f32 }",
        "struct { float a __attribute__((vector_size(16))), b __attribute__((vector_size(16))); }",
        [leaf(f"a[{i}]", "f32", i) for i in range(4)] +
        [leaf(f"b[{i}]", "f32", i + 4) for i in range(4)], tier=TIER_GNU,
        odin_set=["{}.a = " + "{" + ", ".join(val(i, "f32") for i in range(4)) + "}",
                  "{}.b = " + "{" + ", ".join(val(i + 4, "f32") for i in range(4)) + "}"],
        odin_get=[(f"simd.extract({{}}.a, {i})", f"f32({val(i, 'f32')})") for i in range(4)] +
                 [(f"simd.extract({{}}.b, {i})", f"f32({val(i + 4, 'f32')})") for i in range(4)])
    # a vector beside a scalar: homogeneous no longer
    add("v4f32_i64",
        "struct { a: #simd[4]f32, b: i64 }",
        "struct { float a __attribute__((vector_size(16))); int64_t b; }",
        [leaf(f"a[{i}]", "f32", i) for i in range(4)] + [leaf("b", "i64", 4)],
        tier=TIER_GNU,
        odin_set=["{}.a = " + "{" + ", ".join(val(i, "f32") for i in range(4)) + "}",
                  f"{{}}.b = {val(4, 'i64')}"],
        odin_get=[(f"simd.extract({{}}.a, {i})", f"f32({val(i, 'f32')})") for i in range(4)] +
                 [("{}.b", f"i64({val(4, 'i64')})")])

    # --- bit-fields. A member measured in BITS is neither an integer nor
    # padding: x86-64 merges its eightbyte to INTEGER, and RISC-V's hardware
    # float rule names it explicitly. The BACKING must match C's allocation
    # unit -- `bit_field u8` against `unsigned a:3` is a different type.
    for w1, w2 in ((3, 5), (1, 31), (17, 15)):
        # the value has to fit the declared width, so it is derived from it
        # the value must fit the width AND leave room for the mutation control
        va, vb = str(min(5, (1 << w1) - 1) if w1 > 1 else 0), str(min(9, (1 << w2) - 1))
        add(f"bf_{w1}_{w2}",
            f"bit_field u32 {{ a: u32 | {w1}, b: u32 | {w2} }}",
            f"struct {{ unsigned a : {w1}; unsigned b : {w2}; }}",
            [leaf2("a", "a", "u32", va), leaf2("b", "b", "u32", vb)])
    add("bff_f32",
        "struct { f: f32, b: bit_field u32 { a: u32 | 3 } }",
        "struct { float f; struct { unsigned a : 3; } b; }",
        [leaf("f", "f32", 0), leaf2("b.a", "b.a", "u32", "5")])

    # --- matrix, which lowers to an array with its own alignment
    add("m22_f32", "struct { m: matrix[2,2]f32 }",
        "struct { float m[4] __attribute__((aligned(16))); }",
        [leaf2(f"m[{i % 2}, {i // 2}]", f"m[{i}]", "f32", val(i, "f32")) for i in range(4)],
        tier=TIER_GNU)

    # NOTE: `complex64`/`complex128` are deliberately absent. Their members have
    # no common accessor -- Odin spells it `real(x)`, C spells it `__real__ x`, a
    # prefix operator rather than a member -- so a per-field check cannot be
    # generated from one path. Measured separately as agreeing with clang on
    # x86-64, aarch64 and riscv64; add them if the accessor problem is solved.

    # --- array OF struct: the array rule and the struct rule compose, and a
    # stride bug lives in the composition
    add("aos", "struct { a: [2]struct{ x, y: f32 } }",
        "struct { struct { float x, y; } a[2]; }",
        [leaf("a[0].x", "f32", 0), leaf("a[0].y", "f32", 1),
         leaf("a[1].x", "f32", 2), leaf("a[1].y", "f32", 3)])
    add("aos2", "struct { a: [2][2]f32 }", "struct { float a[2][2]; }",
        [leaf("a[0][0]", "f32", 0), leaf("a[0][1]", "f32", 1),
         leaf("a[1][0]", "f32", 2), leaf("a[1][1]", "f32", 3)])

    # --- an over-aligned MEMBER, which leaves an interior gap. A layout walk
    # that sums field sizes gets this wrong and a per-field check catches it.
    add("oam", "struct #min_field_align(16) { a: i8, b: f32 }",
        "struct { int8_t a; float b __attribute__((aligned(16))); }",
        [leaf("a", "i8", 0), leaf("b", "f32", 1)], tier=TIER_GNU)

    # --- a union whose MEMBERS are aggregates: the merge has two composite
    # candidates for one byte, not two scalars
    add("ua_s2_f64",
        "struct #raw_union { a: struct{ x, y: f32 }, b: f64 }",
        "union { struct { float x, y; } a; double b; }",
        [leaf("a.x", "f32", 0), leaf("a.y", "f32", 1)])
    add("ua_arr",
        "struct #raw_union { a: [4]f32, b: [2]f64 }",
        "union { float a[4]; double b[2]; }",
        [leaf(f"a[{i}]", "f32", i) for i in range(4)])

    # --- three levels of nesting: SysV flattens, and anything that classifies
    # per top-level member stops early
    add("n3_deep",
        "struct { a: struct{ b: struct{ c: f32, d: f32 } } }",
        "struct { struct { struct { float c, d; } b; } a; }",
        [leaf("a.b.c", "f32", 0), leaf("a.b.d", "f32", 1)])
    add("n3_mix",
        "struct { a: struct{ b: struct{ c: i64 }, d: f32 }, e: f64 }",
        "struct { struct { struct { int64_t c; } b; float d; } a; double e; }",
        [leaf("a.b.c", "i64", 0), leaf("a.d", "f32", 1), leaf("e", "f64", 2)])

    # NOTE: `#packed` with `#align(N)` is rejected by Odin ("'#align' cannot be
    # applied with '#packed'") though C accepts the combination, so there is no
    # shape to compare.

    # --- zero-sized on its own, in argument and return position
    add("empty", "struct { e: struct{} }", "struct { struct {} e; }", [], tier=TIER_GNU)
    add("zarr",  "struct { z: [0]f32 }",   "struct { float z[0]; }",  [], tier=TIER_GNU)

    # --- an array OF vectors, and a vector wider than one register
    # The C paths index the vector array directly; only the ODIN side needs the
    # hatch.
    add("av2_f32",
        "struct { a: [2]#simd[4]f32 }",
        "struct { rx_v4f a[2]; }",
        [leaf2("", f"a[{i // 4}][{i % 4}]", "f32", f"{i + 1}.5") for i in range(8)],
        tier=TIER_GNU,
        odin_set=["{}.a[0] = {1.5, 2.5, 3.5, 4.5}", "{}.a[1] = {5.5, 6.5, 7.5, 8.5}"],
        odin_get=[("simd.extract({}.a[0], 0)", "f32(1.5)"),
                  ("simd.extract({}.a[1], 3)", "f32(8.5)")])
    add("v8_f32",
        "struct { v: #simd[8]f32 }",
        "struct { float v __attribute__((vector_size(32))); }",
        [leaf(f"v[{i}]", "f32", i) for i in range(8)], tier=TIER_GNU,
        odin_set=["{}.v = " + "{" + ", ".join(val(i, "f32") for i in range(8)) + "}"],
        odin_get=[(f"simd.extract({{}}.v, {i})", f"f32({val(i, 'f32')})") for i in range(8)])

    # --- large, past every by-value threshold
    add("big", "struct { a: [8]i64 }", "struct { int64_t a[8]; }",
        [leaf(f"a[{i}]", "i64", i) for i in range(8)])

    return out


# ---------------------------------------------------------------- emit

GUARD = {TIER_CORE: None, TIER_GNU: "ABI_TIER_GNU", TIER_F16: "ABI_TIER_F16",
         TIER_I128: "ABI_TIER_I128"}

# The tier conditions live here. The corpus is guarded by them, `tiers.c` reports them.
TIER_COND = {
    TIER_GNU:  "defined(__GNUC__)",
    TIER_F16:  "defined(__FLT16_MANT_DIG__) && !defined(_MSC_VER)",
    TIER_I128: "defined(__SIZEOF_INT128__)",
}


def emit_tiers_c():
    o = io.StringIO()
    o.write("/* GENERATED by tests/abi/gen.py -- do not edit.\n"
            "   Preprocess this and grep the markers: it answers which tiers the C\n"
            "   compiler actually has, so the Odin side can be gated by the same\n"
            "   answer rather than by a restatement of the condition. */\n")
    for tier, cond in TIER_COND.items():
        o.write(f"#if {cond}\nABI_YES_{GUARD[tier].replace('ABI_TIER_', '')}\n#endif\n")
    return o.getvalue()


C_HEAD = """\
/* GENERATED by tests/abi/gen.py -- do not edit. */
#include <stdint.h>
#include <stdarg.h>

/* Tier guards. A target whose C compiler lacks an extension still runs the
   core corpus; the Odin side is gated by the matching -define. */
@TIER_DEFINES@

/* An enum with an explicit wide enumerator, so it is int-sized rather than
   whatever the compiler picks for a small one. */
enum E32 { E32_LO = 0, E32_HI = 0x7fffffff };

/* `vector_size` attaches to the ELEMENT, so an array of vectors needs a name. */
#if defined(__GNUC__)
typedef float rx_v4f __attribute__((vector_size(16)));
#endif
"""

ODIN_HEAD = """\
// GENERATED by tests/abi/gen.py -- do not edit.
//
// Every procedure below asks one question: does Odin place this value where the
// platform C compiler expects it? No ABI is encoded here, so the same corpus is
// valid on SysV, AAPCS64 and Win64 without changing a line.
//
// Three checks per type, because they fail for different reasons:
//   _arg   the value AFTER the aggregate comes back -- catches a wrong size or
//          a wrong number of consumed registers, deterministically rather than
//          by scratch-register luck
//   _chk   every field of the aggregate itself -- catches a wrong offset
//   _ret   the aggregate in return position -- a separate classifier path
package test_abi

import "core:simd"
import "core:testing"
_ :: simd

ABI_TIER_GNU :: #config(ABI_TIER_GNU, true)
ABI_TIER_F16 :: #config(ABI_TIER_F16, true)
ABI_TIER_I128 :: #config(ABI_TIER_I128, true)

// The mutation control. With `-define:ABI_MUTATE=true` every type feeds a value
// the C side must reject, so the suite MUST go red. A suite that cannot fail is
// not evidence, and once the defects it currently catches are fixed this is the
// only thing left proving the checks still bite.
ABI_MUTATE :: #config(ABI_MUTATE, false)

// Variadic coverage, OFF by default.
//
// Odin does not ABI-classify a variadic argument at all -- it hands LLVM the
// raw aggregate where clang coerces per the psABI -- so 111 of the types here
// fail. That is one defect, not 111, and leaving it on would drown every other
// signal. Turn it on with `-define:ABI_VARARGS=true` to measure it.
ABI_VARARGS :: #config(ABI_VARARGS, false)


E32 :: enum i32 { LO = 0, HI = 0x7fffffff }
BS  :: bit_set[0..<31; u32]

foreign import lib "abi_corpus_c.o"
"""


def emit_c(types):
    o = io.StringIO()
    defines = "".join(f"#if {c}\n#define {GUARD[t]} 1\n#endif\n" for t, c in TIER_COND.items())
    o.write(C_HEAD.replace("@TIER_DEFINES@", defines.rstrip()))
    for t in types:
        g = GUARD[t.tier]
        if g:
            o.write(f"\n#ifdef {g}\n")
        o.write(f"\ntypedef {t.c} {t.name};\n")
        # _arg: return the argument that FOLLOWS the aggregate
        o.write(f"double {t.name}_arg({t.name} s, double next) {{ (void)s; return next; }}\n")
        # _chk: every field, so a wrong offset is caught as well as a wrong register
        o.write(f"int {t.name}_chk({t.name} s) {{ return ({c_conds(t, 's')}) ? 0 : 1; }}\n")
        # _ret: return position
        o.write(f"{t.name} {t.name}_ret(void) {{ {t.name} s; ")
        o.write("".join(f"{c_ref(cp, 's')} = ({c_val(k, v)}); " for _op, cp, k, v in t.fields))
        o.write("return s; }\n")
        # _ex: the aggregate after the argument registers are gone
        o.write(f"double {t.name}_ex(int64_t a, int64_t b, int64_t c, int64_t d, int64_t e,"
                f" int64_t f, int64_t o, double g, double h, double i, double j, double k,"
                f" double l, double m, double n, {t.name} s, double next) {{\n")
        o.write("\t(void)a;(void)b;(void)c;(void)d;(void)e;(void)f;(void)o;(void)g;(void)h;\n")
        o.write("\t(void)i;(void)j;(void)k;(void)l;(void)m;(void)n;(void)s;\n\treturn next;\n}\n")
        # _ex2: SysV has six integer registers but AAPCS64 and RISC-V have eight,
        # so `_ex` only partially fills those. Nine of each exhausts all three.
        ints = ", ".join(f"int64_t q{i}" for i in range(9))
        dbls = ", ".join(f"double w{i}" for i in range(9))
        o.write(f"double {t.name}_ex2({ints}, {dbls}, {t.name} s, double next) {{\n\t")
        o.write("".join(f"(void)q{i};" for i in range(9)))
        o.write("".join(f"(void)w{i};" for i in range(9)))
        o.write("(void)s;\n\treturn next;\n}\n")
        # _two: the FIRST aggregate's register consumption decides the second's
        # placement, which nothing with a single aggregate can observe
        o.write(f"double {t.name}_two({t.name} s1, {t.name} s2, double next) {{\n")
        o.write(f"\tif (!({c_conds(t, 's1')})) return -1;\n")
        o.write(f"\tif (!({c_conds(t, 's2')})) return -2;\n\treturn next;\n}}\n")
        # _back: the other direction -- C calls an exported Odin callee, which is
        # what a callback does and what nothing else here covers
        o.write(f"extern double o_{t.name}_take({t.name} s, double next);\n")
        o.write(f"extern {t.name} o_{t.name}_make(void);\n")
        o.write(f"int {t.name}_back(void) {{\n\t{t.name} s; ")
        o.write("".join(f"{c_ref(cp, 's')} = ({c_val(k, v)}); " for _op, cp, k, v in t.fields))
        o.write(f"\n\tif (o_{t.name}_take(s, 7) != 7) return 1;\n")
        o.write(f"\t{t.name} r = o_{t.name}_make();\n")
        o.write(f"\tif (!({c_conds(t, 'r')})) return 2;\n\treturn 0;\n}}\n")
        # _va: the variadic path, which is a separate set of rules -- SysV's AL
        # register count, Win64 duplicating a float into the matching GPR,
        # Darwin-arm64 stacking every variadic argument. A zero-sized type has
        # no meaningful `va_arg`, so it is skipped.
        if t.fields:
            o.write(f"double {t.name}_va(int n, ...) {{\n\tva_list ap; va_start(ap, n);\n")
            o.write(f"\t{t.name} s = va_arg(ap, {t.name});\n")
            o.write("\tdouble next = va_arg(ap, double);\n\tva_end(ap);\n")
            o.write(f"\treturn ({c_conds(t, 's')}) ? next : -1;\n}}\n")
        if g:
            o.write(f"\n#endif /* {g} */\n")
    return o.getvalue()


def emit_odin(types):
    o = io.StringIO()
    o.write(ODIN_HEAD)
    for t in types:
        g = GUARD[t.tier]
        w = f"when {g} {{\n" if g else ""
        ind = "\t" if g else ""
        o.write("\n" + w)
        o.write(f"{ind}{t.name} :: {t.odin}\n")
        o.write(f'{ind}@(default_calling_convention="c")\n{ind}foreign lib {{\n')
        o.write(f"{ind}\t{t.name}_arg :: proc(s: {t.name}, next: f64) -> f64 ---\n")
        o.write(f"{ind}\t{t.name}_chk :: proc(s: {t.name}) -> i32 ---\n")
        o.write(f"{ind}\t{t.name}_ret :: proc() -> {t.name} ---\n")
        o.write(f"{ind}\t{t.name}_ex  :: proc(a, b, c, d, e, f, o: i64, g, h, i, j, k, l, m, n: f64,"
                f" s: {t.name}, next: f64) -> f64 ---\n")
        o.write(f"{ind}\t{t.name}_ex2 :: proc(q0, q1, q2, q3, q4, q5, q6, q7, q8: i64,"
                f" w0, w1, w2, w3, w4, w5, w6, w7, w8: f64, s: {t.name}, next: f64) -> f64 ---\n")
        o.write(f"{ind}\t{t.name}_two :: proc(s1, s2: {t.name}, next: f64) -> f64 ---\n")
        o.write(f"{ind}\t{t.name}_back :: proc() -> i32 ---\n")
        if t.fields:
            o.write(f"{ind}\t{t.name}_va  :: proc(n: i32, #c_vararg args: ..any) -> f64 ---\n")
        o.write(f"{ind}}}\n")
        # the callees C calls back into: the direction a callback uses
        o.write(f"{ind}@(export) o_{t.name}_take :: proc \"c\" (s: {t.name}, next: f64) -> f64 {{\n")
        for expr, ev in odin_getters(t, "s"):
            o.write(f"{ind}\tif {expr} != {ev} {{ return -1 }}\n")
        o.write(f"{ind}\treturn next\n{ind}}}\n")
        o.write(f"{ind}@(export) o_{t.name}_make :: proc \"c\" () -> {t.name} {{\n{ind}\ts: {t.name}\n")
        for st in odin_setters(t, "s"):
            o.write(f"{ind}\t{st}\n")
        o.write(f"{ind}\treturn s\n{ind}}}\n")
        o.write(f"{ind}@(test)\n{ind}test_{t.name} :: proc(t: ^testing.T) {{\n")
        o.write(f"{ind}\ts: {t.name}\n")
        for st in odin_setters(t, "s"):
            o.write(f"{ind}\t{st}\n")
        # types whose members have no lvalue path (#simd) are set as a whole and
        # cannot be perturbed field-wise, so the control skips them
        if t.fields and t.odin_set is None:
            op, _cp, tag, v = t.fields[0]
            o.write(f"{ind}\twhen ABI_MUTATE {{ s.{op} = {mutated(tag, v)} }}\n")
        o.write(f"{ind}\ttesting.expect_value(t, {t.name}_arg(s, 7), f64(7))\n")
        o.write(f"{ind}\ttesting.expect_value(t, {t.name}_chk(s), i32(0))\n")
        o.write(f"{ind}\ttesting.expect_value(t, {t.name}_ex(1,2,3,4,5,6,7, 1,2,3,4,5,6,7,8, s, 7), f64(7))\n")
        o.write(f"{ind}\ttesting.expect_value(t, {t.name}_ex2(1,2,3,4,5,6,7,8,9, 1,2,3,4,5,6,7,8,9, s, 7), f64(7))\n")
        o.write(f"{ind}\ttesting.expect_value(t, {t.name}_two(s, s, 7), f64(7))\n")
        o.write(f"{ind}\ttesting.expect_value(t, {t.name}_back(), i32(0))\n")
        if t.fields:
            o.write(f"{ind}\twhen ABI_VARARGS {{\n")
            o.write(f"{ind}\t\ttesting.expect_value(t, {t.name}_va(1, s, f64(7)), f64(7))\n")
            o.write(f"{ind}\t}}\n")
        o.write(f"{ind}\tr := {t.name}_ret()\n")
        if not odin_getters(t, "r"):
            o.write(f"{ind}\t_ = r\n")
        for expr, ev in odin_getters(t, "r"):
            o.write(f"{ind}\ttesting.expect_value(t, {expr}, {ev})\n")
        o.write(f"{ind}}}\n")
        if g:
            o.write("}\n")
    return o.getvalue()


MAIN_HEAD = """\
// GENERATED by tests/abi/gen.py -- do not edit.
//
// The same corpus as a freestanding driver, for a target with no test runner.
// Exits with the number of failing types, so a cross target can be checked
// under an emulator in CI without core:testing or a thread.
package abi_main

import "core:simd"
_ :: simd

ABI_TIER_GNU :: #config(ABI_TIER_GNU, true)
ABI_TIER_F16 :: #config(ABI_TIER_F16, true)
ABI_TIER_I128 :: #config(ABI_TIER_I128, true)

E32 :: enum i32 { LO = 0, HI = 0x7fffffff }
BS  :: bit_set[0..<31; u32]

// Types at or below this index are skipped, so a runner can enumerate every
// failure by re-running from the last one rather than only seeing a count.
ABI_SKIP :: #config(ABI_SKIP, 0)

// Variadic coverage, OFF by default.
//
// Odin does not ABI-classify a variadic argument at all -- it hands LLVM the
// raw aggregate where clang coerces per the psABI -- so 111 of the types here
// fail. That is one defect, not 111, and leaving it on would drown every other
// signal. Turn it on with `-define:ABI_VARARGS=true` to measure it.
ABI_VARARGS :: #config(ABI_VARARGS, false)


foreign import lib "../abi_corpus_c.o"
"""


def emit_main(types):
    o = io.StringIO()
    o.write(MAIN_HEAD)
    body = io.StringIO()
    seen = []
    for t in types:
        g = GUARD[t.tier]
        w = f"when {g} {{\n" if g else ""
        ind = "\t" if g else ""
        o.write("\n" + w)
        o.write(f"{ind}{t.name} :: {t.odin}\n")
        o.write(f'{ind}@(default_calling_convention="c")\n{ind}foreign lib {{\n')
        o.write(f"{ind}\t{t.name}_arg :: proc(s: {t.name}, next: f64) -> f64 ---\n")
        o.write(f"{ind}\t{t.name}_chk :: proc(s: {t.name}) -> i32 ---\n")
        o.write(f"{ind}\t{t.name}_ret :: proc() -> {t.name} ---\n")
        o.write(f"{ind}\t{t.name}_ex  :: proc(a, b, c, d, e, f, o: i64, g, h, i, j, k, l, m, n: f64,"
                f" s: {t.name}, next: f64) -> f64 ---\n")
        o.write(f"{ind}\t{t.name}_ex2 :: proc(q0, q1, q2, q3, q4, q5, q6, q7, q8: i64,"
                f" w0, w1, w2, w3, w4, w5, w6, w7, w8: f64, s: {t.name}, next: f64) -> f64 ---\n")
        o.write(f"{ind}\t{t.name}_two :: proc(s1, s2: {t.name}, next: f64) -> f64 ---\n")
        o.write(f"{ind}\t{t.name}_back :: proc() -> i32 ---\n")
        if t.fields:
            o.write(f"{ind}\t{t.name}_va  :: proc(n: i32, #c_vararg args: ..any) -> f64 ---\n")
        o.write(f"{ind}}}\n")
        # the callees C calls back into: the direction a callback uses
        o.write(f"{ind}@(export) o_{t.name}_take :: proc \"c\" (s: {t.name}, next: f64) -> f64 {{\n")
        for expr, ev in odin_getters(t, "s"):
            o.write(f"{ind}\tif {expr} != {ev} {{ return -1 }}\n")
        o.write(f"{ind}\treturn next\n{ind}}}\n")
        o.write(f"{ind}@(export) o_{t.name}_make :: proc \"c\" () -> {t.name} {{\n{ind}\ts: {t.name}\n")
        for st in odin_setters(t, "s"):
            o.write(f"{ind}\t{st}\n")
        o.write(f"{ind}\treturn s\n{ind}}}\n")
        o.write(f"{ind}check_{t.name} :: proc \"contextless\" () -> i32 {{\n")
        o.write(f"{ind}\ts: {t.name}\n")
        for st in odin_setters(t, "s"):
            o.write(f"{ind}\t{st}\n")
        o.write(f"{ind}\tif {t.name}_arg(s, 7) != 7 {{ return 1 }}\n")
        o.write(f"{ind}\tif {t.name}_chk(s) != 0 {{ return 1 }}\n")
        o.write(f"{ind}\tif {t.name}_ex(1,2,3,4,5,6,7, 1,2,3,4,5,6,7,8, s, 7) != 7 {{ return 1 }}\n")
        o.write(f"{ind}\tr := {t.name}_ret()\n")
        if not odin_getters(t, "r"):
            o.write(f"{ind}\t_ = r\n")
        for expr, ev in odin_getters(t, "r"):
            o.write(f"{ind}\tif {expr} != {ev} {{ return 1 }}\n")
        o.write(f"{ind}\treturn 0\n{ind}}}\n")
        if g:
            o.write("}\n")
        idx = len(seen) + 1
        seen.append(t.name)
        chk = f"if {idx} > ABI_SKIP && check_{t.name}() != 0 {{ return {idx} }}"
        body.write(f"\t{'when ' + g + ' { ' if g else ''}{chk}{' }' if g else ''}\n")
    o.write("\n@(export)\nprobe_main :: proc \"c\" () -> i32 {\n")
    o.write(body.getvalue())
    o.write("\treturn 0\n}\n")
    o.write("\n// index -> name\n")
    for i, n in enumerate(seen):
        o.write(f"// {i+1}\t{n}\n")
    return o.getvalue()


if __name__ == "__main__":
    import os, sys
    # Written into the caller's build directory, not the source tree: nothing
    # generated is checked in, so the two languages cannot drift apart.
    here = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.abspath(__file__))
    ts = build()
    open(os.path.join(here, "abi_corpus.c"), "w").write(emit_c(ts))
    open(os.path.join(here, "abi_corpus.odin"), "w").write(emit_odin(ts))
    open(os.path.join(here, "abi_main.odin"), "w").write(emit_main(ts))
    open(os.path.join(here, "tiers.c"), "w").write(emit_tiers_c())
    print(f"{len(ts)} types, {sum(7 + (1 if t.fields else 0) for t in ts)} C functions, {len(ts) * 2} Odin callees")
