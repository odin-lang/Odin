package odin_frontend

import "core:sync"

Scope_Flag :: enum i32 {

}

Scope_Flags :: distinct bit_set[Scope_Flag; i32]

Scope :: struct {
	node      : ^Node,
	parent    : ^Scope,
	next      : ^Scope,
	head_child: ^Scope,

	mutex: sync.RW_Mutex,
	elements: map[string]^Entity,

	imported: map[^Scope]bool,

	flags: Scope_Flags,

	variant: union {
		^Package,
		^File,
		^Entity, // procedure_entry
	}
}

