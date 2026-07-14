/*
Strict DER (Distinguished Encoding Rules) reader and writer for the PKIX
subset of ASN.1, the substrate for X.509 certificates and related structures.

Reader: a `Cursor` over the input; `read_*` procs return VIEWS into it (only
`oid_components` / `oid_to_string` take an allocator). The input must outlive
the results.

Writer: build a declarative tree of `Value` nodes with the constructors, then
`encoded_len` + `encode` (no allocation, into a caller buffer) or `marshal`
(one allocation). Constructors BORROW their inputs, so build and encode
within one expression (or back children with a slice that outlives the call); 
the encoded output is self-contained and aliases nothing.

Scope & limitations:

- DER only (no BER/CER); strict (minimal lengths, minimal integers, ...).
- PKIX subset: no typed readers for STRING/REAL/... (walk with `read_any`);
  the writer emits low-tag-number identifiers only (tag number <= 30).

Times use core:time.Time per the RFC 5280 DER profile (Zulu, seconds present,
no fractional seconds). time.Time is i64 nanoseconds (tops out near year 2262)
while UTCTime/GeneralizedTime reach 9999; on read, dates beyond that saturate.

See:
- [[ https://www.itu.int/rec/T-REC-X.690 ]]
- [[ https://www.rfc-editor.org/rfc/rfc5280 ]]
*/
package asn1
