# crypto

A cryptography library for the Odin language.

## Supported

This package offers various algorithms implemented in Odin, along with
useful helpers such as access to the system entropy source, and a
constant-time byte comparison.

## Implementation considerations

- The crypto packages are not thread-safe.
- Best-effort is make to mitigate timing side-channels on reasonable
  architectures.  Architectures that are known to be unreasonable include
  but are not limited to i386, i486, and WebAssembly.
- Implementations assume a 64-bit architecture (64-bit integer arithmetic
  is fast, and includes add-with-carry, sub-with-borrow, and full-result
  multiply).
- Hardware sidechannels are explicitly out of scope for this package.
  Notable examples include but are not limited to:
  - Power/RF side-channels etc.
  - Fault injection attacks etc.
  - Hardware vulnerabilities ("apply mitigations or buy a new CPU").
- The packages attempt to santize sensitive data, however this is, and
  will remain a "best-effort" implementation decision.  As Thomas Pornin
  puts it "In general, such memory cleansing is a fool's quest."
- All of these packages have not received independent third party review.

## License

This library is made available under the BSD-3 license.