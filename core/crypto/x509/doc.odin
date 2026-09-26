/*
X.509 v3 certificate parsing, signature verification, and chain (path)
validation.

The parser is built on the strict DER reader in core:encoding/asn1 and
is zero-copy where possible: the returned Certificate's byte-slice
fields are views into the input DER, which must outlive it.  The few
allocated fields (the extension/SAN tables) are released with
`destroy`.

Input is DER. To parse a PEM certificate, decode it first with
core:encoding/pem (label "CERTIFICATE") and pass the resulting bytes.

A successful `parse` means the bytes were well-formed, NOT that the
certificate is valid or trusted. The Certificate carries everything 
the verifier needs: `raw_tbs` (the exact byte range a signature covers), 
`raw_spki` (the range hashed for tls-server-end-point channel binding, 
RFC 5929, and SPKI pinning), and `raw_issuer`/`raw_subject` (for the RFC 
5280 binary-comparison rule).

Hostname verification (`verify_hostname`) implements the RFC 6125
subset modern clients use: subject alternative names only (no
CommonName fallback), with at most one wildcard as the entire
left-most label.

Trust is established by `verify_chain`, which builds a path from a leaf
to a supplied trust anchor through supplied intermediates and checks,
for each certificate, validity, signature, name chaining, and the CA /
keyCertSign / pathLenConstraint rules; `verify_signature` exposes the
single-edge signature check on its own.

LIMITATIONS:

  - Signature verification covers RSA PKCS#1 v1.5 and RSA-PSS
    (SHA-256/384/512), ECDSA P-256/P-384, and Ed25519. These paths return
    .Unsupported_Algorithm: SHA-1 (deprecated and rejected, RFC 9155), ECDSA
    P-521 (effectively dead in web PKI), and RSA-PSS naming a digest or MGF
    this package does not recognize.
  - Name constraints (RFC 5280 4.2.1.10) are enforced for the dNSName and
    iPAddress forms: a CA's permitted/excluded subtrees are checked against
    every subordinate certificate's SANs, regardless of the extension's
    criticality. A NameConstraints that uses any other base form
    (directoryName, rfc822Name, URI, otherName), a minimum/maximum, or that
    is malformed cannot be fully evaluated, so the whole chain is rejected
    (fail closed) rather than accepted unchecked. NOT enforced: the RFC 5280
    rule that the extension be critical, and dNSName syntax validation (a
    leading-period constraint is accepted, as OpenSSL does).
  - REVOCATION IS NOT CHECKED. verify_chain performs NO CRL or OCSP
    revocation checking. Callers that need revocation (e.g. TLS clients) 
    MUST supply it separately (OCSP stapling, CRLite, …). 
  - Certificate policies / policy constraints are not evaluated, and
    there is no Public Suffix List: a (CABF-forbidden) wildcard such as
    "*.com" would match "host.com". As a backstop, verify_chain still
    fails closed on any uninterpreted CRITICAL extension
    (.Unhandled_Critical_Extension).
  - EKU is checked only when opts.required_eku is set, and then by RFC
    5280 semantics: a certificate with no EKU extension is unrestricted
    (it is not required to assert the purpose); a certificate that DOES
    assert EKU must include the purpose, enforced across the leaf and
    every intermediate (EKU nesting). Leaf KeyUsage is not checked
    against the intended protocol use.

Parsing is deliberately lenient wherever strictness is a validation
concern rather than a structural one. Exception: Parser rejects
duplicate extension OIDs (Duplicate_Extension, RFC 5280 section 4.2).

  - Only dNSName and iPAddress subject alternative names are decoded
    (into `dns_names` / `ip_addresses`). Other GeneralName forms (URI,
    rfc822Name, directoryName, otherName) are skipped; the raw SAN
    extension is still available via `extensions`.
  - Only the extensions path validation needs are decoded
    (BasicConstraints, KeyUsage, ExtKeyUsage, SubjectAltName,
    Subject/Authority Key Identifier; NameConstraints is decoded at
    verification time). All others (AIA, CRL distribution points,
    certificate policies, …) are left raw in `extensions`.
  - Subject and issuer are kept as raw DER (`raw_subject` / `raw_issuer`),
    which is what name chaining compares (the RFC 5280 binary rule). The
    attributes (CN, O, …) are decoded on demand by `parse_dn`, not at parse
    time; `dn_get` / `dn_string` read them out and `serial_string` formats
    the serial.
  - Unsupported public-key curves yield Public_Key_Algorithm.Unknown.
  - Non-conformant-but-extractable values are preserved: negative or 
    over-long serials, and validity dates far in the future. Validity 
    is stored as core:time.Time, which tops out near year 2262; dates 
    beyond that (the RFC 5280 "99991231235959Z" no-expiration sentinel) 
    saturate to that bound at parse time rather than failing, so they 
    read as "effectively never expires".
  - Per-extension criticality rules (e.g. that subjectKeyIdentifier be
    non-critical) are left to the caller via `Extension.critical`, and
    a critical extension this package does not understand sets
    `unhandled_critical` rather than failing the parse.


See:
- [[ https://www.rfc-editor.org/rfc/rfc5280 ]]
- [[ https://www.rfc-editor.org/rfc/rfc6125 ]]
- [[ https://www.rfc-editor.org/rfc/rfc5929 ]]
*/
package x509
