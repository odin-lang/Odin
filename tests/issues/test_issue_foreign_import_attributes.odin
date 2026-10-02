// 'foreign import' attributes may name constants declared after them
package test_issues

@(priority_index=PRIORITY, extra_linker_flags=FLAGS)
foreign import lib "system:foo"

foreign lib {
	foo :: proc "c" () ---
}

PRIORITY :: LATER + 1
FLAGS    :: "-L."
LATER    :: 1
