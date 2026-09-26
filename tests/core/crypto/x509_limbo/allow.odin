package test_x509_limbo

// Reviewed & documented divergences from the x509-limbo corpus, keyed by
// testcase id. Any diverging case NOT listed here is treated as a REGRESSION
// and fails the test (see x509_limbo.odin).
//
// ACCEPT_ALLOW: cases limbo marks FAILURE that we ACCEPT. Every one is a policy
// layer OUTSIDE RFC 5280 path validation that this package intentionally does
// not enforce — revocation (crl::*), CABF Baseline Requirements issuance
// conformance (webpki::cn/eku/forbidden-rsa/san/aki, ca-as-leaf), per-extension
// criticality and presence policy (aki/ski/pc/san, nc must-be-critical), lenient
// serials / dNSName syntax, and the name-constraint DoS bailout. None is a
// path-validation integrity bug (no accepted bad signature or broken chain).
ACCEPT_ALLOW := []string {
	"crl::crlnumber-critical",
	"crl::crlnumber-missing",
	"crl::issuer-missing-crlsign",
	"crl::revoked-certificate-with-crl",
	"pathlen::max-chain-depth-0-exhausted",
	"pathlen::max-chain-depth-1-exhausted",
	"pathological::nc-dos-1",
	"pathological::nc-dos-2",
	"rfc5280::aki::critical-aki",
	"rfc5280::aki::cross-signed-root-missing-aki",
	"rfc5280::aki::intermediate-missing-aki",
	"rfc5280::aki::leaf-missing-aki",
	"rfc5280::ca-empty-subject",
	"rfc5280::leaf-ku-keycertsign",
	"rfc5280::nc::invalid-dnsname-leading-period",
	"rfc5280::nc::permitted-dns-match-noncritical",
	"rfc5280::pc::ica-noncritical-pc",
	"rfc5280::root-inconsistent-ca-extensions",
	"rfc5280::root-missing-basic-constraints",
	"rfc5280::root-non-critical-basic-constraints",
	"rfc5280::san::noncritical-with-empty-subject",
	"rfc5280::san::underscore-dns",
	"rfc5280::serial::too-long",
	"rfc5280::serial::zero",
	"rfc5280::ski::critical-ski",
	"rfc5280::ski::intermediate-missing-ski",
	"rfc5280::ski::root-missing-ski",
	"webpki::aki::root-with-aki-all-fields",
	"webpki::aki::root-with-aki-authoritycertissuer",
	"webpki::aki::root-with-aki-authoritycertserialnumber",
	"webpki::aki::root-with-aki-missing-keyidentifier",
	"webpki::aki::root-with-aki-ski-mismatch",
	"webpki::ca-as-leaf",
	"webpki::cn::case-mismatch",
	"webpki::cn::ipv4-hex-mismatch",
	"webpki::cn::ipv4-leading-zeros-mismatch",
	"webpki::cn::ipv6-non-rfc5952-mismatch",
	"webpki::cn::ipv6-uncompressed-mismatch",
	"webpki::cn::ipv6-uppercase-mismatch",
	"webpki::cn::not-in-san",
	"webpki::cn::punycode-not-in-san",
	"webpki::cn::utf8-vs-punycode-mismatch",
	"webpki::ee-basicconstraints-ca",
	"webpki::eku::ee-anyeku",
	"webpki::eku::ee-critical-eku",
	"webpki::eku::ee-without-eku",
	"webpki::eku::root-has-eku",
	"webpki::forbidden-rsa-key-not-divisible-by-8-in-leaf",
	"webpki::forbidden-rsa-not-divisible-by-8-in-root",
	"webpki::forbidden-weak-rsa-in-leaf",
	"webpki::forbidden-weak-rsa-key-in-root",
	"webpki::malformed-aia",
	"webpki::san::public-suffix-multi-label-wildcard-san",
	"webpki::san::public-suffix-private-namespace-wildcard-san",
	"webpki::san::public-suffix-wildcard-san",
	"webpki::san::san-critical-with-nonempty-subject",
}

// REJECT_ALLOW: cases limbo ACCEPTS that we REJECT.
// All use a name-constraint GeneralName form we fail closed on:
// directoryName, rfc822Name (email), or otherName (These types are not implemented)
REJECT_ALLOW := []string {
	"rfc5280::nc::nc-forbids-othername-noop",
	"rfc5280::nc::nc-permits-email-domain",
	"rfc5280::nc::nc-permits-email-exact",
	"rfc5280::nc::nc-permits-email-literal-asterisk-exact-match",
	"rfc5280::nc::nc-permits-email-literal-double-asterisk",
	"rfc5280::nc::nc-permits-email-literal-mid-asterisk",
	"rfc5280::nc::permitted-dn-match",
}
