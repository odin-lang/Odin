package sysinfo

CPU_Feature :: enum u64 {
	// Bit-Manipulation ISA Extensions v1.
	Zba = 3,
	Zbb,
	Zbs,

	// CMOs (ratified).
	Zicboz,

	// Bit-Manipulation ISA Extensions v1.
	Zbc,

	// Scalar Crypto ISA extensions v1.
	Zbkb,
	Zbkc,
	Zbkx,
	Zknd,
	Zkne,
	Zknh,
	Zksed,
	Zksh,
	Zkt,

	// Cryptography Extensions Volume II v1.
	Zvbb,
	Zvbc,
	Zvkb,
	Zvkg,
	Zvkned,
	Zvknha,
	Zvknhb,
	Zvksed,
	Zvksh,
	Zvkt,

	// ISA Manual v1.
	Zfh,
	Zfhmin,
	Zihintntl,

	// ISA manual (ratified).
	Zvfh,
	Zvfhmin,
	Zfa,
	Ztso,

	// Atomic Compare-and-Swap Instructions Manual (ratified).
	Zacas,
	Zicond,

	// ISA manual (ratified).
	Zihintpause,

	// Vector Extensions Manual v1.
	Zve32x,
	Zve32f,
	Zve64x,
	Zve64f,
	Zve64d,

	// ISA manual (ratified).
	Zimop,

	// Code Size Reduction (ratified).
	Zca,
	Zcb,
	Zcd,
	Zcf,

	// ISA manual (ratified).
	Zcmop,
	Zawrs,

 	// Base features, don't think this is ever not here.
	I,
 	// Integer multiplication and division, currently required by Odin.
	M,
 	// Atomics.
	A,
 	// Single precision floating point, currently required by Odin.
	F,
 	// Double precision floating point, currently required by Odin.
	D,
 	// Compressed instructions.
	C,
 	// Vector operations.
	V,

	// Indicates Misaligned Scalar Loads will not trap the program.
	Misaligned_Supported,
	// Indicates Hardware Support for Misaligned Scalar Loads.
	Misaligned_Fast,
}

CPU_Features :: distinct bit_set[CPU_Feature; u64]

cpu_features: Maybe(CPU_Features)
cpu_name: Maybe(string)
