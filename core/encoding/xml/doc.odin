/*
XML 1.0 / 1.1 parser

A from-scratch XML implementation, loosely modelled on the [[ spec; https://www.w3.org/TR/2006/REC-xml11-20060816 ]].

Features:
- Supports enough of the XML 1.0/1.1 spec to handle the 99.9% of XML documents in common current usage.
- Simple to understand and use. Small.

Caveats:
- We do NOT support HTML in this package, as that may or may not be valid XML.
  If it works, great. If it doesn't, that's not considered a bug.

- We do NOT support UTF-16. If you have a UTF-16 XML file, please convert it to UTF-8 first. Also, our condolences.
- <[!ELEMENT and <[!ATTLIST are not supported, and will be either ignored or return an error depending on the parser options.

MAYBE:
- XML writer?
- Serialize/deserialize Odin types?

For a full example, see: [[ core/encoding/xml/example; https://github.com/odin-lang/Odin/tree/master/core/encoding/xml/example ]]
*/
package encoding_xml
