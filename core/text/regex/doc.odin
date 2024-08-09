/*
package regex implements a complete suite for using Regular Expressions to
match and capture text.

Regular expressions are used to describe how a piece of text can match to
another, using a pattern language.

Odin's regex library implements the following features:

	Alternation:           `apple|cherry`
	Classes:               `[0-9_]`
	Classes, negated:      `[^0-9_]`
	Shorthands:            `\d\s\w`
	Shorthands, negated:   `\D\S\W`
	Wildcards:             `.`
	Repeat, optional:      `a*`
	Repeat, at least once: `a+`
	Repetition:            `a{1,2}`
	Optional:              `a?`
	Group, capture:        `([0-9])`
	Group, non-capture:    `(?:[0-9])`
	Start & End Anchors:   `^hello$`
	Word Boundaries:       `\bhello\b`
	Non-Word Boundaries:   `hello\B`

These specifiers can be composed together, such as an optional group:
`(?:hello)?`

This package also supports the non-greedy variants of the repeating and
optional specifiers by appending a `?` to them.

Of the shorthand classes that are supported, they are all ASCII-based, even
when compiling in Unicode mode. This is for the sake of general performance and
simplicity, as there are thousands of Unicode codepoints which would qualify as
either a digit, space, or word character which could be irrelevant depending on
what is being matched.

Here are the shorthand class equivalencies:
	\d: [0-9]
	\s: [\t\n\f\r ]
	\w: [0-9A-Z_a-z]

If you need your own shorthands, you can compose strings together like so:
	MY_HEX :: "[0-9A-Fa-f]"
	PATTERN :: MY_HEX + "-" + MY_HEX

The compiler will handle turning multiple identical classes into references to
the same set of matching runes, so there's no penalty for doing it like this.



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
