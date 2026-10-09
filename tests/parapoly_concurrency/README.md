# Parametric-polymorphism concurrency harness

`poly_stress.py` stress-tests the multithreaded checker's polymorphic instantiation paths and
checks that they are deterministic across thread counts.

The checker instantiates polymorphic procedures and records on a thread pool, mutating and
caching shared `Type`/`Entity` nodes. That machinery is delicate, so this harness looks for:

- **Deadlocks** — e.g. a cross-record ABBA on the per-record `gen_types` mutexes, hit when two
  mutually-recursive generic records (`A(T)` referencing `^B(T)` and `B(T)` referencing `^A(T)`)
  are instantiated concurrently.
- **Crashes** — asserts, stack overflows, or data races on shared nodes.
- **Nondeterminism** — duplicate or missing monomorphizations that leak into the emitted symbol
  set (e.g. from a check-then-act race in a generated-entity cache).

## How it works

It generates a corpus of many polymorphic procedures and records — including many
mutually-recursive generic pairs, each entered from both directions by different procedures so
worker threads race on the two records' caches in crossing order. It builds the corpus with
`-build-mode:llvm` (checker + IR only; fast, no linking), then compares a **single-threaded
baseline** against many **multi-threaded** builds:

- a per-run timeout is reported as a **deadlock**,
- a nonzero exit as a **crash**,
- a differing set of emitted `define` symbols as **nondeterminism**.

The emitted `define` set is an order-independent fingerprint of the polymorphic *procedure*
instantiations; procedures parameterized over the records surface record-instantiation
differences there too.

## Usage

From this directory (adjust `--odin` to your built compiler):

```sh
# struct pairs (default), heavy run:
python poly_stress.py all --odin ../../odin.exe --work ./_work \
    --kind struct --pairs 300 --procs 200 --threads 32 --iters 25

# union pairs:
python poly_stress.py all --odin ../../odin.exe --work ./_work --kind union --pairs 50

# specialization constraints ($V/Vec($T,$N)) — stresses the in-place memmove in
# check_type_specialization_to_internal:
python poly_stress.py all --odin ../../odin.exe --work ./_work --kind spec --pairs 120

# generate a corpus once, then run against it repeatedly:
python poly_stress.py gen --out ./_work/corpus --kind struct --pairs 300
python poly_stress.py run --odin ../../odin.exe --corpus ./_work/corpus --work ./_work
```

`--work` is a scratch directory for the generated corpus and the emitted `.ll` output; it can be
deleted between runs.

Exit code is `0` on pass, `1` on a deadlock/crash/nondeterminism, `2` if the baseline itself
fails to build.

## Notes

- `--kind union` currently exercises mutually-recursive generic *unions*, which reproduce a
  pre-existing compile-time stack overflow (unions lack the "variants ready" wait-signal that
  lets the struct version terminate its recursion through the instantiation cache). Use it to
  validate a fix for that.
- Increase `--pairs`, `--threads`, `--width`, and `--iters` to widen the race window and raise
  the chance of catching a rare interleaving.
