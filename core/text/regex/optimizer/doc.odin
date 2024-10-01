/*
package regex_optimizer implements an optimizer which acts upon the AST of a
parsed regular expression pattern, transforming it in-place without moving to a
compilation step.

Where possible, it aims to reduce branching as much as possible in the
expression by reducing usage of `|`.


Here is a summary of the optimizations that it will do:

* Class Simplification               : `[aab]` => `[ab]`
                                       `[aa]`  => `[a]`

* Class Reduction                    : `[a]`    => `a`
* Range Construction                 : `[abc]`  => `[a-c]`
* Rune Merging into Range            : `[aa-c]` => `[a-c]`

* Range Merging                      : `[a-cc-e]` => `[a-e]`
                                       `[a-cd-e]` => `[a-e]`
                                       `[a-cb-e]` => `[a-e]`

* Alternation to Optional            : `a|`  => `a?`
* Alternation to Optional Non-Greedy : `|a`  => `a??`
* Alternation Reduction              : `a|a` => `a`
* Alternation to Class               : `a|b` => `[ab]`
* Class Union                        : `[a0]|[b1]` => `[a0b1]`
                                       `[a-b]|c`   => `[a-bc]`
                                       `a|[b-c]`   => `[b-ca]`

* Wildcard Reduction                 : `a|.`    => `.`
                                       `.|a`    => `.`
                                       `[ab]|.` => `.`
                                       `.|[ab]` => `.`

* Common Suffix Elimination : `blueberry|strawberry` => `(?:blue|straw)berry`
* Common Prefix Elimination : `abi|abe` => `ab(?:i|e)`

* Composition: Consume All to Anchored End
	`.*$` =>     <special opcode>
	`.+$` => `.` <special opcode>


Possible future improvements:

- Change the AST of alternations to be a list instead of a tree, so that
  constructions such as `(ab|bb|cb)` can be considered in whole by the affix
  elimination optimizations.

- Introduce specialized opcodes for certain classes of repetition.

- Add Common Infix Elimination.

- Measure the precise finite minimum and maximum of a pattern, if available,
  and check against that on any strings before running the virtual machine.

*/
package regex_optimizer
