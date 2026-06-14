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

  - RSA & ECDSA P-521 signatures are not implemented in core, these paths 
    return .Unsupported_Algorithm. 
  - Name constraints are NOT enforced yet; verify_chain fails CLOSED on
    them (a chain through a name-constrained CA is automatically rejected. 
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

Name constraints (Future PR):

  verify_chain does not yet DECODE name constraints, and it fails CLOSED
  on them: any CA, intermediate or trust anchor, that asserts a
  nameConstraints extension, critical or not, is refused as an issuer,
  so a chain through a name-constrained CA is rejected, never accepted
  unchecked. RFC 5280 section 6.1.4(g) requires a validator that
  processes name constraints to enforce them regardless of criticality;
  until we do, refusing is the only safe stand-in.

  Planned order:
    1. Enforce dNSName and iPAddress constraints, the forms real
       name-constrained CAs almost always use, still failing closed
       when a constraint uses a form we do not evaluate (directoryName,
       rfc822Name, URI, otherName). A name-form constraint restricts
       only names of that form (RFC 5280 section 4.2.1.10), so dNSName
       constraints can be checked against dNSName SANs with no
       distinguished-name decoding; this recovers the large majority of
       name-constrained chains.
    2. Full section 4.2.1.10 enforcement: the remaining GeneralName
       forms plus distinguished-name parsing and comparison, built and
       validated test-first against the x509-limbo / BetterTLS
       name-constraints corpus.

Parsing is deliberately lenient wherever strictness is a validation
concern rather than a structural one. Exception: Parser rejects
duplicate extension OIDs (Duplicate_Extension, RFC 5280 section 4.2).

  - Only dNSName and iPAddress subject alternative names are decoded
    (into `dns_names` / `ip_addresses`). Other GeneralName forms (URI,
    rfc822Name, directoryName, otherName) are skipped; the raw SAN
    extension is still available via `extensions`.
  - Only the extensions path validation needs are decoded
    (BasicConstraints, KeyUsage, ExtKeyUsage, SubjectAltName,
    Subject/Authority Key Identifier). All others (AIA, CRL
    distribution points, certificate policies, name constraints, …)
    are left raw in `extensions`.
  - Subject and issuer are exposed only as raw DER (`raw_subject` /
    `raw_issuer`); distinguished-name attribute decoding (CN, O, …) is
    not performed.
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
