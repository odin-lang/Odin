// An #soa array of an #soa array of any kind is an error, through aliases and generics too
package test_issue_soa_of_soa

import "base:intrinsics"

P :: struct {
	x, y: f32,
}

Block          :: #soa[4]P
Distinct_Block :: distinct #soa[4]P

Holder :: struct {
	block: #soa[4]P,
	n:     int,
}

Wrapper :: struct($T: typeid) {
	s: #soa[]T,
}

// Errors
a: #soa[4]#soa[4]P
b: #soa[]#soa[4]P
c: #soa[dynamic]#soa[]P
d: #soa[dynamic; 4]#soa[dynamic]P
e: #soa[]Block
f: #soa[]Distinct_Block
g: Wrapper(Block)
h: intrinsics.soa_struct(4, Block)

// Not errors
blocks:  [4]#soa[4]P
growing: [dynamic]#soa[8]P
holders: #soa[]Holder
lanes:   #soa[][2]#soa[4]P
wrapped: Wrapper(P)

main :: proc() {
}
