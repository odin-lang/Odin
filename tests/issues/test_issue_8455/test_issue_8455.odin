package test_issue_8455

main :: proc() {
	a := #load("assets")
	b := #load("assets", string)
	h := #load_hash("assets", "crc32")
	f := #load("assets/file.txt")
	d := #load_directory("assets")
	_, _, _, _, _ = a, b, h, f, d
}
