### x509-limbo — core/crypto/x509 path-validation conformance

Differential-tests `core:crypto/x509` `verify_chain` against the
[x509-limbo][1] corpus (~9.8k adversarial path-validation testcases,
~30k certificates). Structured like `tests/core/crypto/wycheproof`: a
dedicated package whose corpus lives, gitignored, under
`tests/core/assets/`.

Fetch the corpus:

```
curl -sL https://raw.githubusercontent.com/C2SP/x509-limbo/main/limbo.json \
  -o tests/core/assets/X509-Limbo/limbo.json
```

Run:

```
odin test tests/core/crypto/x509_limbo -o:speed
```

When the corpus is absent the suite logs a notice and passes, so a plain
`odin test` sweep never breaks.

Each case carries its own `expected_result`, so the harness needs no
external oracle. Reviewed, documented divergences are listed by testcase id
in `allow.odin`:

  - `ACCEPT_ALLOW` — cases limbo marks FAILURE that we accept. All are policy
    layers outside RFC 5280 path validation that this package intentionally
    does not enforce (revocation, CABF Baseline Requirements issuance
    conformance, per-extension criticality/presence policy, lenient
    serials/dNSName syntax, name-constraint DoS bailout).
  - `REJECT_ALLOW` — cases limbo accepts that we reject (the safe, stricter
    direction), all using a name-constraint form we fail closed on
    (directoryName / rfc822Name / otherName).

Any diverging case NOT allow-listed fails the test — the on-change
regression gate, in particular for the security-critical "we accept a chain
limbo rejects" direction. When bumping the corpus, run once, review each new
divergence, and add it to the appropriate list (or fix the finding).

Covered: RSA (PKCS#1 v1.5 + PSS), ECDSA P-256/P-384, Ed25519, and dNSName /
iPAddress name constraints. Chains using P-521 / Ed448 / DSA are skipped.

[1]: https://github.com/C2SP/x509-limbo
