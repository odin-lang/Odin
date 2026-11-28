// Test for issue #8451 https://github.com/odin-lang/Odin/issues/8451
// An unlabelled 'or_break' or 'break' within a labelled statement suggests using its label
package test_issue_8451

main :: proc() {
	foobar: {
		true or_break // suggests 'or_break foobar'
		break         // suggests 'break foobar'
	}

	outer: {
		inner: if true {
			true or_break // suggests 'or_break inner'
		}
	}

	loop: for _ in 0..<2 {
		#unroll for _ in 0..<2 {
			true or_break // suggests 'or_break loop'
		}
	}

	{
		true or_break // suggests nothing
	}

	outside: {
		p :: proc() {
			break // suggests nothing: the label is in another procedure
		}
		p()
	}
}
