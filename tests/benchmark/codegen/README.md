# Codegen benchmark

A run-time benchmark for compiler changes.
Each workload does a fixed amount of work with core packages and prints a checksum.
The checksums must match between compilers: they double as a correctness check.

| Workload            | What it runs                                                       |
|---------------------|--------------------------------------------------------------------|
| `json_parse`        | `core:encoding/json` parsing a 6000-record document                |
| `json_marshal`      | `json.marshal` and `json.unmarshal` round trips of those records   |
| `odin_parse`        | `core:odin/parser` over 1.2 MB of core sources                     |
| `fmt`               | `fmt.sbprintf` with mixed verbs and a struct                       |
| `strings`           | splitting, searching, case mapping, and replacing lines            |
| `map`               | inserts, lookups, and deletes in string- and int-keyed maps        |
| `sort`              | `slice.sort_by` on structs and `slice.sort` on ints                |
| `raytrace`          | a small path tracer: floats and small structs by value             |
| `nbody`             | an n-body simulation: floats and multiple results                  |
| `regex`             | `core:text/regex` matching                                         |
| `big`               | `core:math/big` factorials, multiplication, and division           |
| `gzip`              | `core:compress/deflate` inflating the parser's sources             |
| `diff`              | `core:diff` Myers and histogram diffs of two texts                 |
| `sha256`            | `core:crypto/hash`: a leaf-heavy control                           |
| `log_off_in_callee` | filtered-out logging of a large parameter that is then passed on   |
| `linalg`            | `core:math/linalg` with `matrix`, quaternions, and an `#soa` slice |
| `csv`               | `core:encoding/csv` reading through `bufio`, then writing back     |
| `dijkstra`          | shortest paths on a grid with `core:container/priority_queue`      |
| `compress`          | deflate compression, plus LZ4 and QOI round trips                  |
| `datetime`          | `core:time/datetime` day-to-date conversions and date arithmetic   |
| `cbor`              | `core:encoding/cbor` round trips of the JSON records               |
| `unicode`           | rune classification and case mapping of mixed-script text          |

## Comparing two compilers

`compare` builds the benchmark with two compilers and runs the builds in interleaved rounds.
It prints the fastest time of each workload and the geometric mean of the ratios.
It fails when a checksum differs between the builds or between rounds.

```
odin run tests/benchmark/codegen/compare -- <odin A> <odin B> -o:speed -rounds:10 -cpu:2
```

| Flag          | Meaning                                                      |
|---------------|--------------------------------------------------------------|
| `-o:<mode>`   | Optimization mode of both builds. Default: `speed`.          |
| `-rounds:<n>` | Runs of each build. Default: 10.                             |
| `-cpu:<n>`    | Pin the benchmark to one logical CPU (Windows and Linux).    |
| `-root:<dir>` | `ODIN_ROOT` of both builds.                                  |
| `-out:<dir>`  | Directory for the two executables. Default: a temporary one. |

## Running it alone

```
odin build tests/benchmark/codegen -o:speed
./codegen -cpu:2 json_parse gzip
```

It prints `name milliseconds checksum` for each named workload, or for all of them.

## Notes

- **Library.** Each compiler builds against the library it finds: `ODIN_ROOT`, or its own folder.
  Two trees can then run different library code.
  `-root` builds both against one tree; its `base:runtime` must suit both compilers.
- **Corpus.** `odin_parse`, `gzip`, and `compress` embed ten `core` directories with `#load_directory`, relative to this folder.
  Both builds in a run see the same bytes.
  The corpus follows `core`: compare times within a run, not across commits.
- **Checksums** depend on the target and on the checkout's line endings.
  On 32-bit targets `rand.int_max` draws other values, and matrix-vector products sum in another order.
  Compare checksums within a run only.
  A compiler change to how matrix products sum can change `linalg`'s checksum without being wrong.
- **Noise.** On Windows the benchmark raises its priority class to high.
  `-cpu` pins it on Windows and Linux; macOS has no pinning API.
  Pick an idle performance core.
  On Linux, `nice -n -10` (as root) raises the priority.
  Compared with itself (10 rounds, `-o:speed`, pinned, idle Windows desktop), a compiler's geomean stayed within ±0.8% over five runs.
  Single workloads moved by up to 4%, and more again unpinned.
