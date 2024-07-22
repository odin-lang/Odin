/*
package regex implements a complete suite for using Regular Expressions to
match and capture text.

Regular expressions are used to describe how a piece of text can match to
another, using a pattern language.

Odin's regex library implements the following features:

	Alternation:           `apple|cherry`
	Classes:               `[0-9_]`
	Wildcards:             `.`
	Repeat, optional:      `a*`
	Repeat, at least once: `a+`
	Optional:              `a?`
	Group Capture:         `([0-9])`
	Group Non-Capture:     `(?:[0-9])`
	Start & End Anchors:   `^hello$`
	Word Boundaries:       `\bhello\b`
	Non-Word Boundaries:   `hello\B`

These specifiers can be composed together, such as an optional group:
`(?:hello)?`

This package also supports the non-greedy variants of the repeating and
optional specifiers by appending a `?` to them.



	``Some people, when confronted with a problem, think
	  "I know, I'll use regular expressions." Now they have two problems.''

	     - Jamie Zawinski


Regular expressions have gathered a reputation over the decades for often being
chosen as the wrong tool for the job. Here, we will clarify a few cases in
which RegEx might be good or bad.


**When is it a good time to use RegEx?**

- You don't know at compile-time what patterns of text the program will need to
  match when it's running.
- As an example, you are making a client which can be configured by the user to
  trigger on certain text patterns received from a server.
- For another example, you need a way for users of a text editor to compose
  matching strings that are more intricate than a simple substring lookup.
- The text you're matching against is small (< 64 KiB) and your patterns aren't
  overly complicated with branches (alternations, repeats, and optionals).
- If none of the above general impressions apply but your project doesn't
  warrant long-term maintenance.

**When is it a bad time to use RegEx?**

- You know at compile-time the grammar you're parsing; a hand-made parser has
  the potential to be more maintainable and readable.
- The grammar you're parsing has certain validation steps that lend itself to
  forming complicated expressions, such as e-mail addresses, URIs, dates,
  postal codes, credit cards, et cetera. Using RegEx to validate these
  structures is almost always a bad sign.
- The text you're matching against is big (> 1 MiB); you would be better served
  by first dividing the text into manageable chunks and using some heuristic to
  locate the most likely location of a match before applying RegEx against it.
- You value high performance and low memory usage; RegEx will always have a
  certain overhead which increases with the complexity of the pattern.


The implementation of this package has been optimized, but it will never be as
thoroughly performant as a hand-made parser. In comparison, there are just too
many intermediate steps, assumptions, and generalizations in what it takes to
handle a regular expression.

*/
package regex
