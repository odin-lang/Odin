# botan
A wrapper for the Botan crypto library

## Supported
This library offers full bindings for everything exposed by Botan's FFI.
Wrappers for hashing algorithms have been added to match the API within the Odin `core:crypto` library.  

## Hashing algorithms
| Algorithm                                                                                                    |                  |
|:-------------------------------------------------------------------------------------------------------------|:-----------------|
| [BLAKE2B](https://datatracker.ietf.org/doc/html/rfc7693)                                                     | &#10004;&#65039; |
| [GOST](https://datatracker.ietf.org/doc/html/rfc5831)                                                        | &#10004;&#65039; |
| [Keccak](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf)                                           | &#10004;&#65039; |
| [MD4](https://datatracker.ietf.org/doc/html/rfc1320)                                                         | &#10004;&#65039; |
| [MD5](https://datatracker.ietf.org/doc/html/rfc1321)                                                         | &#10004;&#65039; |
| [RIPEMD-160](https://homes.esat.kuleuven.be/~bosselae/ripemd160.html)                                        | &#10004;&#65039; |
| [SHA-1](https://datatracker.ietf.org/doc/html/rfc3174)                                                       | &#10004;&#65039; |
| [SHA-2](https://csrc.nist.gov/csrc/media/publications/fips/180/2/archive/2002-08-01/documents/fips180-2.pdf) | &#10004;&#65039; |
| [SHA-3](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf)                                            | &#10004;&#65039; |
| [SHAKE](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf)                                            | &#10004;&#65039; |
| [Skein-512](https://www.schneier.com/academic/skein/)                                                        | &#10004;&#65039; |
| [SM3](https://datatracker.ietf.org/doc/html/draft-sca-cfrg-sm3-02)                                           | &#10004;&#65039; |
| [Streebog](https://datatracker.ietf.org/doc/html/rfc6986)                                                    | &#10004;&#65039; |
| [Tiger](https://www.cs.technion.ac.il/~biham/Reports/Tiger/)                                                 | &#10004;&#65039; |
| [Whirlpool](https://web.archive.org/web/20171129084214/http://www.larc.usp.br/~pbarreto/WhirlpoolPage.html)  | &#10004;&#65039; |

#### High level API
Each hash algorithm contains a procedure group named `hash`, or if the algorithm provides more than one digest size `hash_<size>`.  
Included in these groups are six procedures.
* `hash_string` - Hash a given string and return the computed hash. Just calls `hash_bytes` internally
* `hash_bytes` - Hash a given byte slice and return the computed hash
* `hash_string_to_buffer` - Hash a given string and put the computed hash in the second proc parameter. Just calls `hash_bytes_to_buffer` internally
* `hash_bytes_to_buffer` - Hash a given string and put the computed hash in the second proc parameter. The destination buffer has to be at least as big as the digest size of the hash
* `hash_stream` - Takes a stream from io.Stream and returns the computed hash from it
* `hash_file` - Takes a file handle and returns the computed hash from it. A second optional boolean parameter controls if the file is streamed (this is the default) or read at once (set to true)

#### Low level API
The above mentioned procedures internally call three procedures: `init`, `update` and `final`.
You may also directly call them, if you wish.

#### Example
```odin
package crypto_example

// Import the desired package
import "vendor:botan/md4"

main :: proc() {
    input := "foo"

    // Compute the hash, using the high level API
    computed_hash := md4.hash(input)

    // Variant that takes a destination buffer, instead of returning the computed hash
    hash := make([]byte, md4.DIGEST_SIZE) // @note: Destination buffer has to be at least as big as the digest size of the hash
    md4.hash(input, hash[:])

    // Compute the hash, using the low level API
    // @note: Botan's structs are opaque by design, they don't expose any fields
    ctx: md4.Md4_Context
    computed_hash_low: [16]byte
    md4.init(&ctx)
    md4.update(&ctx, transmute([]byte)input)
    md4.final(&ctx, computed_hash_low[:])
}
```
For example uses of all available algorithms, please see the tests within `tests/vendor/botan`.

### License
This library is made available under the BSD-3 license.