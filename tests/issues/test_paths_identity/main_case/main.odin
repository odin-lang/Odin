package main

import "../pkg"
import other "../PKG"

main :: proc() {
	v: pkg.T = other.T{x = other.X}
	assert(v.x == 1)
}
