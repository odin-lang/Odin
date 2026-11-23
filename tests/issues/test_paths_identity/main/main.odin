package main

import "../pkg"
import "../alias"

main :: proc() {
	v: pkg.T = alias.T{x = alias.X}
	assert(v.x == 1)
}
