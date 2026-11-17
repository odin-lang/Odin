/*
Encodes and decodes PEM formatted data.

`decode` only accepts the strict format of RFC 7468 (Figure 3): the base64 text is split
into lines of exactly 64 characters, except the last, which may be shorter.  Padding may
only end the last line, and trailing bits must be zero.  Inside a block, blank lines,
whitespace other than line endings, and RFC 1421 headers are rejected.  Labels must follow
the RFC 7468 grammar, and the END label must match the BEGIN label.  Lines may end in CRLF,
CR or LF, and the newline after the END line is optional.  Text before a block is skipped.

See:
- [[ https://www.rfc-editor.org/rfc/rfc7468.html ]]
*/
package pem
