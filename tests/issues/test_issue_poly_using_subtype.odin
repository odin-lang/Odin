// A pointer to a `using` subtype satisfies a `$T/^Base` constraint, with `T` as the argument's type
package test_issues

import "core:testing"

Node  :: struct { id: int }
Expr  :: struct { using node: Node, e: int }
Ident :: struct { using expr: Expr, name: string }

slice_of :: proc(nodes: []$T/^Node) -> typeid { return T }
ptr_of   :: proc(node: $T/^Node) -> typeid { return T }
multi_of :: proc(node: $T/[^]Node) -> typeid { return T }

group_node :: proc(node: $T/^Node) -> string { return "node" }
group_int  :: proc(node: ^int) -> string { return "int" }
group      :: proc{group_node, group_int}

@(test)
test_poly_using_subtype :: proc(t: ^testing.T) {
	exprs:  []^Expr
	idents: []^Ident
	e:      ^Expr
	m:      [^]Expr
	i:      ^int
	testing.expect_value(t, slice_of(exprs),  typeid_of(^Expr))
	testing.expect_value(t, slice_of(idents), typeid_of(^Ident))
	testing.expect_value(t, ptr_of(e),        typeid_of(^Expr))
	testing.expect_value(t, multi_of(m),      typeid_of([^]Expr))
	testing.expect_value(t, group(e), "node")
	testing.expect_value(t, group(i), "int")
}
