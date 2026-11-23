#+feature dynamic-literals
package test_issue_3973

Tile :: struct {
	name: string,
}

Tile_Ground :: struct {
	using tile:       Tile,
	some_ground_prop: int,
}

Tile_Tree :: struct {
	using tile:     Tile,
	some_tree_prop: int,
}

Tile_Forest :: struct {
	using tree: Tile_Tree,
	density:    int,
}

Tile_Kind :: enum {
	Ground,
	Tree,
}

Tile_Holder :: struct {
	tile:  Tile,
	maybe: Maybe(Tile),
}

Tile_Pair :: struct {
	a, b: Tile,
}

Tile_Overlay :: struct #raw_union {
	tile:  Tile,
	value: int,
}

two_tiles :: proc() -> (Tile_Ground, Tile_Tree) {
	return {}, {}
}

take_tiles :: proc(tiles: ..Tile) -> int {
	return len(tiles)
}

take_ground :: proc(ground: Tile_Ground) -> int {
	return ground.some_ground_prop
}

take :: proc{take_tiles, take_ground}

main :: proc() {
	ground := Tile_Ground{name = "green grass", some_ground_prop = 7}

	_ = []Tile{
		Tile{},
		Tile_Ground{name = "green grass", some_ground_prop = 7},
		Tile_Tree{name = "tall tree", some_tree_prop = 9},
		ground,
	}
	_ = [3]Tile{Tile{}, Tile_Ground{}, Tile_Forest{}}
	_ = [?]Tile{ground, Tile{}}
	_ = [4]Tile{0 = ground, 1 ..= 2 = Tile_Tree{}, 3 = Tile{}}
	_ = [dynamic]Tile{Tile{}, ground}
	_ = [dynamic; 4]Tile{ground, Tile{}}
	_ = #soa[2]Tile{Tile{}, ground}
	_ = [Tile_Kind]Tile{.Ground = ground, .Tree = Tile_Tree{}}
	_ = map[string]Tile{"ground" = ground}
	_ = map[Tile]int{Tile_Ground{} = 1}
	_ = []Maybe(Tile){Tile{}, ground}
	_ = []Tile{two_tiles()}

	_ = Tile_Holder{tile = ground, maybe = Tile_Tree{}}
	_ = Tile_Holder{Tile_Forest{}, ground}
	_ = Tile_Pair{two_tiles()}
	_ = Tile_Ground{tile = Tile_Forest{}}
	_ = Tile_Overlay{tile = ground}

	_ = take_tiles(Tile{}, ground, Tile_Tree{})
	_ = take(ground, ground)
}
