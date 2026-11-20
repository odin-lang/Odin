// A call's result stored back into the union it was given, in nested loops, while the call moves a variant into a
// field of another, must not grow the paths the analysis keeps without end; the warning stays
package test_issues

None :: struct {}

Style_Seen :: struct {
	style: ^int,
}

List_Seen :: struct {
	number: int,
}

Both :: struct {
	style: Style_Seen,
	list:  List_Seen,
}

Look :: union #no_nil {
	None,
	Style_Seen,
	List_Seen,
	Both,
}

with_list :: proc(look: Look, list: List_Seen) -> Look {
	switch seen in look {
	case None:
		return list
	case Style_Seen:
		return Both{style = seen, list = list}
	case List_Seen:
		return list
	case Both:
		return Both{style = seen.style, list = list}
	}
	unreachable()
}

look_of :: proc(styles: []^int, numbers: []int) -> Look {
	look: Look = None{}
	for _ in numbers {
		for style in styles {
			look = Style_Seen{style = style}
		}
		for _ in numbers {
			for number in numbers {
				look = with_list(look, List_Seen{number = number})
			}
		}
	}
	return look
}

local_look_of :: proc(numbers: []int) -> Look {
	style := 1
	look: Look = None{}
	for _ in numbers {
		for _ in numbers {
			look = Style_Seen{style = &style}
		}
		for _ in numbers {
			for number in numbers {
				look = with_list(look, List_Seen{number = number})
			}
		}
	}
	return look // warning
}
