#+feature dynamic-literals
package test_issue_3973_valid

import "core:testing"

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

Tile_Handle :: struct {
	using tile: ^Tile,
}

Tile_Holder :: struct {
	tile:   Tile,
	maybe:  Maybe(Tile),
	ref:    ^Tile,
	ground: Tile_Ground,
}

count_tiles :: proc(tiles: ..Tile) -> int {
	return len(tiles)
}

first_ref :: proc(refs: ..^Tile) -> ^Tile {
	return refs[0]
}

count_anys :: proc(args: ..any) -> int {
	return len(args)
}

ground_prop :: proc(ground: Tile_Ground) -> int {
	return ground.some_ground_prop
}

pick :: proc{count_tiles, ground_prop}

Tile_Kind :: enum {
	Ground,
	Tree,
}

global_tile:          Tile = Tile_Ground{name = "global", some_ground_prop = 3}
global_forest:        Tile = Tile_Forest{name = "forest", some_tree_prop = 1, density = 2}
CONSTANT_TILE:        Tile : Tile_Ground{name = "constant", some_ground_prop = 4}
global_from_constant: Tile = CONSTANT_TILE

@(test)
test_issue_3973_containers :: proc(t: ^testing.T) {
	ground := Tile_Ground{name = "green grass", some_ground_prop = 7}
	tree   := Tile_Tree{name = "tall tree", some_tree_prop = 9}

	tiles := []Tile{Tile{name = "plain"}, {name = "untyped"}, ground.tile, tree.tile}
	testing.expect_value(t, tiles[0].name, "plain")
	testing.expect_value(t, tiles[1].name, "untyped")
	testing.expect_value(t, tiles[2].name, "green grass")
	testing.expect_value(t, tiles[3].name, "tall tree")

	pointers := []^Tile{&ground, &tree, &ground.tile}
	testing.expect_value(t, pointers[0].name, "green grass")
	testing.expect_value(t, pointers[1].name, "tall tree")
	testing.expect_value(t, pointers[2], &ground.tile)

	handle  := Tile_Handle{&ground.tile}
	handles := [?]^Tile{handle, &tree.tile}
	testing.expect_value(t, handles[0], &ground.tile)
	testing.expect_value(t, handles[1].name, "tall tree")

	grounds := [2]Tile_Ground{ground, Tile_Ground{name = "dirt", some_ground_prop = 1}}
	testing.expect_value(t, grounds[0].some_ground_prop, 7)
	testing.expect_value(t, grounds[1].name, "dirt")

	trees := [dynamic]Tile_Tree{tree}
	defer delete(trees)
	testing.expect_value(t, trees[0].some_tree_prop, 9)

	by_kind := [Tile_Kind]Tile{.Ground = ground.tile, .Tree = tree.tile}
	testing.expect_value(t, by_kind[.Tree].name, "tall tree")

	by_name := map[string]^Tile{"ground" = &ground}
	defer delete(by_name)
	testing.expect_value(t, by_name["ground"].name, "green grass")

	anys := []any{ground}
	testing.expect_value(t, anys[0].id, typeid_of(Tile_Ground))

	variants := []union{Tile, Tile_Ground}{ground, Tile{name = "plain"}}
	_, is_ground := variants[0].(Tile_Ground)
	testing.expect(t, is_ground)
}

@(test)
test_issue_3973_assignments :: proc(t: ^testing.T) {
	ground := Tile_Ground{name = "green grass", some_ground_prop = 7}

	assigned: Tile = ground
	testing.expect_value(t, assigned.name, "green grass")

	literal: Tile = Tile_Ground{name = "local", some_ground_prop = 2}
	testing.expect_value(t, literal.name, "local")

	local_constant := CONSTANT_TILE
	testing.expect_value(t, local_constant.name, "constant")
}

@(test)
test_issue_3973_struct_fields :: proc(t: ^testing.T) {
	ground := Tile_Ground{name = "green grass", some_ground_prop = 7}

	named := Tile_Holder{tile = ground.tile, maybe = ground.tile, ref = &ground, ground = ground}
	testing.expect_value(t, named.tile.name, "green grass")
	testing.expect_value(t, named.maybe.?.name, "green grass")
	testing.expect_value(t, named.ref, &ground.tile)
	testing.expect_value(t, named.ground.some_ground_prop, 7)

	positional := Tile_Holder{Tile{name = "plain"}, nil, Tile_Handle{&ground.tile}, ground}
	testing.expect_value(t, positional.tile.name, "plain")
	testing.expect_value(t, positional.ref, &ground.tile)

	embedded := Tile_Ground{tile = ground.tile, some_ground_prop = 1}
	testing.expect_value(t, embedded.name, "green grass")
}

@(test)
test_issue_3973_variadic :: proc(t: ^testing.T) {
	ground := Tile_Ground{name = "green grass", some_ground_prop = 7}
	tiles  := []Tile{ground.tile, Tile{name = "plain"}}

	testing.expect_value(t, count_tiles(ground.tile, Tile{}, {name = "untyped"}), 3)
	testing.expect_value(t, count_tiles(..tiles), 2)
	testing.expect_value(t, first_ref(&ground), &ground.tile)
	testing.expect_value(t, first_ref(Tile_Handle{&ground.tile}), &ground.tile)
	testing.expect_value(t, count_anys(ground, ground.tile), 2)
	testing.expect_value(t, pick(ground), 7)
	testing.expect_value(t, pick(ground.tile, ground.tile), 2)
}

@(test)
test_issue_3973_constant_globals :: proc(t: ^testing.T) {
	testing.expect_value(t, global_tile.name, "global")
	testing.expect_value(t, global_forest.name, "forest")
	testing.expect_value(t, global_from_constant.name, "constant")
	testing.expect_value(t, CONSTANT_TILE.name, "constant")
}
