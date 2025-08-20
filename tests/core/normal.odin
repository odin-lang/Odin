package tests_core

import rlibc "core:c/libc"

@(init)
download_assets :: proc "contextless" () {
	if rlibc.system("python3 " + ODIN_ROOT + "tests/core/download_assets.py " + ODIN_ROOT + "tests/core/assets") != 0 {
		panic_contextless("downloading test assets failed!")
	}
}

@(require) import "bytes"
@(require) import "c/libc"
@(require) import "compress"
@(require) import "container"
@(require) import "encoding/base64"
@(require) import "encoding/cbor"
@(require) import "encoding/hex"
@(require) import "encoding/hxa"
@(require) import "encoding/json"
@(require) import "encoding/uuid"
@(require) import "encoding/varint"
@(require) import "encoding/xml"
@(require) import "flags"
@(require) import "fmt"
@(require) import "io"
@(require) import "math"
@(require) import "math/big"
@(require) import "math/linalg/glsl"
@(require) import "math/noise"
@(require) import "math/rand"
@(require) import "mem"
@(require) import "net"
@(require) import "odin"
@(require) import "os"
@(require) import "os/os2"
@(require) import "path/filepath"
@(require) import "reflect"
@(require) import "runtime"
@(require) import "slice"
@(require) import "strconv"
@(require) import "strings"
@(require) import "sync"
@(require) import "sync/chan"
@(require) import "sys/posix"
@(require) import "sys/windows"
@(require) import "text/i18n"
@(require) import "text/match"
@(require) import "text/regex"
@(require) import "thread"
@(require) import "time"
@(require) import "unicode"
