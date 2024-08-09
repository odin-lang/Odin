/*
package regex_vm implements a threaded virtual machine for interpreting
regular expressions, based on the designs described by Russ Cox and attributed
to both Ken Thompson and Rob Pike.

The virtual machine executes all threads in lock step, i.e. the string pointer
does not advance until all threads have finished processing the current rune.
The algorithm does not look backwards.

Threads merge when splitting or jumping to positions already visited by another
thread, based on the observation that each thread having visited one PC
(Program Counter) state will execute identically to the previous thread.

Each thread keeps a save state of its capture groups, and thread priority is
used to allow higher precedence operations to complete first with correct save
states, such as greedy versus non-greedy repetition.

For more information, see: https://swtch.com/~rsc/regexp/regexp2.html


**Implementation Details:**

- Each opcode is 8 bits in size, and most instructions have no operands.

- All operands larger than `u8` are read in system endian order.

- Jump and Split instructions operate on absolute positions in `u16` operands.

- Classes such as `[0-9]` are stored in a RegEx-specific slice of structs which
  are then dereferenced by a `u8` index from the `Rune_Class` instructions.

- Each Byte and Rune opcode have their operands stored inline after the opcode,
  sized `u8` and `i32` respectively.

- A bitmap is used to determine which PC positions are occupied by a thread to
  perform merging. The bitmap is cleared with every new frame.

- The VM supports two modes: ASCII and Unicode, decided by a compile-time
  boolean constant argument provided to `run`. The procedure differs only in
  string decoding. This was done for the sake of performance.

- No allocations are ever freed; the VM expects an arena or temporary allocator
  to be used in the context preceding it.


**Opcode Reference:**

	(0x00) Match

	The terminal opcode which ends a thread. This always comes at the end of
	the program.

	(0x01) Match_And_Exit

	A modified version of Match which stops the virtual machine entirely. It is
	only compiled for `No_Capture` expressions, as those expressions do not
	need to determine which thread may have saved the most appropriate capture
	groups.

	(0x02) Byte

	Consumes one byte from the text using its operand, which is also a byte.

	(0x03) Rune

	Consumes one Unicode codepoint from the text using its operand, which is
	four bytes long in a system-dependent endian order.

	(0x04) Rune_Class

	Consumes one character (which may be an ASCII byte or Unicode codepoint,
	wholly dependent on which mode the virtual machine is running in) from the
	text.

	The actual data storing what runes and ranges of runes apply to the class
	are stored alongside the program in the Regular_Expression structure and
	the operand for this opcode is a single byte which indexes into a
	collection of these data structures.

	(0x05) Rune_Class_Negated

	A modified version of Rune_Class that functions the same, save for how it
	returns the opposite of what Rune_Class matches.

	(0x06) Wildcard

	Consumes one byte or one Unicode codepoint, depending on the VM mode.

	(0x07) Jump

	Sets the Program Counter of a VM thread to the operand, which is a u16.
	This opcode is used to implement Alternation (coming at the end of the left
	choice) and Repeat_Zero (to cause the thread to loop backwards).

	(0x08) Split

	Spawns a new thread for the X operand and causes the current thread to jump
	to the Y operand. This opcode is used to implement Alternation, all the
	Repeat variations, and the Optional nodes.

	Splitting threads is how the virtual machine is able to execute optional
	control flow paths, letting it evaluate different possible ways to match
	text.

	(0x09) Save

	Saves the current string index to a slot on the thread dictated by the
	operand. These values will be used later to reconstruct capture groups.

	(0x0A) Assert_Start

	Asserts that the thread is at the beginning of a string.

	(0x0B) Assert_End

	Asserts that the thread is at the end of a string.

	(0x0C) Assert_Word_Boundary

	Asserts that the thread is on a word boundary, which can be the start or
	end of the text. This examines both the current rune and the next rune.

	(0x0D) Assert_Non_Word_Boundary

	A modified version of Assert_Word_Boundary that returns the opposite value.

	(0x0E) Multiline_Open

	This opcode is compiled in only when the `Multiline` flag is present, and
	it replaces both `^` and `$` text anchors.

	It asserts that either the current thread is on one of the string
	boundaries, or it consumes a `\n` or `\r` character.

	If a `\r` character is consumed, the PC will be advanced to the sibling
	`Multiline_Close` opcode to optionally consume a `\n` character on the next
	frame.

	(0x0F) Multiline_Close

	This opcode is always present after `Multiline_Open`.

	It handles consuming the second half of a complete newline, if necessary.
	For example, Windows newlines are represented by the characters `\r\n`,
	whereas UNIX newlines are `\n` and Macintosh newlines are `\r`.

	(0x10) Wait_For_Byte
	(0x11) Wait_For_Rune
	(0x12) Wait_For_Rune_Class
	(0x13) Wait_For_Rune_Class_Negated

	These opcodes are an optimization around restarting threads on failed
	matches when the beginning to a pattern is predictable and the Global flag
	is set.

	They will cause the VM to wait for the next rune to match before splitting,
	as would happen in the un-optimized version.

	(0x14) Match_All_And_Escape

	This opcode is an optimized version of `.*$` or `.+$` that causes the
	active thread to immediately work on escaping the program by following all
	Jumps out to the end.

	While running through the rest of the program, the thread will trigger on
	every Save instruction it passes to store the length of the string.

	This way, any time a program hits one of these `.*$` constructs, the
	virtual machine can exit early, vastly improving processing times.

	Be aware, this opcode is not compiled in if the `Multiline` flag is on, as
	the meaning of `$` changes with that flag.

*/
package regex_vm
