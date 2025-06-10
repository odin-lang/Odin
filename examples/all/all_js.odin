#+build js
package all

// Imports "every" package
// This is useful for knowing what exists and producing documentation with `odin doc`

@(require) import "core:bufio"
@(require) import "core:bytes"
@(require) import "core:c"

@(require) import "core:compress"
@(require) import "core:compress/shoco"
@(require) import "core:compress/gzip"
@(require) import "core:compress/zlib"

@(require) import "core:container/avl"
@(require) import "core:container/bit_array"
@(require) import "core:container/priority_queue"
@(require) import "core:container/queue"
@(require) import "core:container/small_array"
@(require) import "core:container/lru"
@(require) import "core:container/intrusive/list"
@(require) import "core:container/rbtree"
@(require) import "core:container/topological_sort"

@(require) import "core:crypto"
@(require) import "core:crypto/aead"
@(require) import "core:crypto/aegis"
@(require) import "core:crypto/aes"
@(require) import "core:crypto/blake2b"
@(require) import "core:crypto/blake2s"
@(require) import "core:crypto/chacha20"
@(require) import "core:crypto/chacha20poly1305"
@(require) import chash "core:crypto/hash"
@(require) import "core:crypto/deoxysii"
@(require) import "core:crypto/ed25519"
@(require) import "core:crypto/hkdf"
@(require) import "core:crypto/hmac"
@(require) import "core:crypto/kmac"
@(require) import "core:crypto/legacy/keccak"
@(require) import "core:crypto/legacy/md5"
@(require) import "core:crypto/legacy/sha1"
@(require) import "core:crypto/pbkdf2"
@(require) import "core:crypto/poly1305"
@(require) import "core:crypto/ristretto255"
@(require) import "core:crypto/sha2"
@(require) import "core:crypto/sha3"
@(require) import "core:crypto/shake"
@(require) import "core:crypto/sm3"
@(require) import "core:crypto/tuplehash"
@(require) import "core:crypto/x25519"
@(require) import "core:crypto/x448"

@(require) import "core:debug/pe"
@(require) import "core:debug/trace"

@(require) import "core:dynlib"
@(require) import "core:net"

@(require) import "core:encoding/base32"
@(require) import "core:encoding/base64"
@(require) import "core:encoding/cbor"
@(require) import "core:encoding/csv"
@(require) import "core:encoding/endian"
@(require) import "core:encoding/hxa"
@(require) import "core:encoding/ini"
@(require) import "core:encoding/json"
@(require) import "core:encoding/varint"
@(require) import "core:encoding/xml"
@(require) import "core:encoding/uuid"
@(require) import "core:encoding/uuid/legacy"

@(require) import "core:fmt"
@(require) import "core:hash"
@(require) import "core:hash/xxhash"

@(require) import "core:image"
@(require) import "core:image/bmp"
@(require) import "core:image/netpbm"
@(require) import "core:image/png"
@(require) import "core:image/qoi"
@(require) import "core:image/tga"

@(require) import "core:io"
@(require) import "core:log"

@(require) import "core:math"
@(require) import "core:math/big"
@(require) import "core:math/bits"
@(require) import "core:math/fixed"
@(require) import "core:math/linalg"
@(require) import "core:math/linalg/glsl"
@(require) import "core:math/linalg/hlsl"
@(require) import "core:math/noise"
@(require) import "core:math/rand"
@(require) import "core:math/ease"
@(require) import "core:math/cmplx"

@(require) import "core:mem"
@(require) import "core:mem/tlsf"
@(require) import "core:mem/virtual"

@(require) import "core:odin/ast"
@(require) import doc_format "core:odin/doc-format"

@(require) import "core:odin/tokenizer"
@(require) import "core:os"
@(require) import "core:path/slashpath"

@(require) import "core:relative"

@(require) import "core:reflect"
@(require) import "base:runtime"
@(require) import "base:sanitizer"
@(require) import "core:simd"
@(require) import "core:simd/x86"
@(require) import "core:slice"
@(require) import "core:slice/heap"
@(require) import "core:sort"
@(require) import "core:strconv"
@(require) import "core:strings"
@(require) import "core:sync"

@(require) import "core:terminal"
@(require) import "core:terminal/ansi"

@(require) import "core:text/edit"
@(require) import "core:text/i18n"
@(require) import "core:text/match"
@(require) import "core:text/regex"
@(require) import "core:text/scanner"
@(require) import "core:text/table"

@(require) import "core:thread"
@(require) import "core:time"
@(require) import "core:time/datetime"
@(require) import "core:time/timezone"


@(require) import "core:sys/orca"
@(require) import "core:sys/info"

@(require) import "core:unicode"
@(require) import "core:unicode/utf8"
@(require) import "core:unicode/utf8/utf8string"
@(require) import "core:unicode/utf16"

main :: proc() {}