package b

import "../a"

call :: proc() -> [3]int {
	h := a.H
	return h[0]()
}
