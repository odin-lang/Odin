// Tests issue #5043 https://github.com/odin-lang/Odin/issues/5043
package test_issues

Table :: map [string] Type
List  :: [dynamic] Type

Type :: union {
	^Table,
	^List,
	i64,
}


main :: proc() {
	v: Type = 5

	switch t in v {
	case ^Table: // or case ^map [string] Type:
	case ^List:
	case i64:

	}
}
