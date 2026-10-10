package pkg_b

import "../pkg_a"

total :: proc() -> int {
	return pkg_a.use_all() + pkg_a.FIVE
}
