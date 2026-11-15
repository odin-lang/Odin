/*
A parser for XML 1.0 (5th edition) documents: [[ spec; https://www.w3.org/TR/xml/ ]].
Documents that declare another `1.x` version are parsed as XML 1.0, as §2.8 allows.

Features:
- Checks the well-formedness of names, the XML declaration, comments, CDATA sections,
  processing instructions, references and the legal character range.
- Decodes bodies and attribute values as the spec says. See `Option_Flag`.
- Simple to understand and use. Small.

Caveats:
- We do NOT support HTML in this package, as that may or may not be valid XML.
  If it works, great. If it doesn't, that's not considered a bug.

- The input must be `UTF-8`. The XML declaration's `encoding` is only recorded in `Document.encoding`;
  the bytes are never converted. Convert `UTF-16` and other encodings to `UTF-8` first. For `UTF-16`, our condolences.
- The DOCTYPE's internal subset (`<!ENTITY`, `<!ELEMENT`, `<!ATTLIST` and the rest) is skipped.
  With `.Ignore_Unsupported` (part of `DEFAULT_OPTIONS`), a DOCTYPE with an internal subset or external ID
  keeps unknown references as written, since it may declare them; otherwise they're `.Unknown_Entity`.

MAYBE:
- XML writer?
- Serialize/deserialize Odin types?

For a full example, see: [[ core/encoding/xml/example; https://github.com/odin-lang/Odin/tree/master/core/encoding/xml/example ]]
*/
package encoding_xml
