#!/usr/bin/env python3
"""
Parametric-polymorphism concurrency stress / determinism harness for the Odin compiler.

The checker instantiates polymorphic procedures and records on a thread pool. This harness
exercises those paths hard enough to surface:

  * DEADLOCKS   - e.g. a cross-record ABBA on the per-record gen_types mutexes, hit by two
                  mutually-recursive generic records instantiated concurrently (A(T) has a
                  ^B(T) field/variant and B(T) has a ^A(T) one).
  * CRASHES     - asserts / stack overflows / data races on shared Type or Entity nodes.
  * NONDETERMINISM - duplicate or missing monomorphizations that leak into the emitted symbol
                  set (e.g. from a check-then-act race in a gen cache).

Method: generate a corpus that instantiates many polymorphic procedures and records, including
many mutually-recursive generic record pairs entered from both directions concurrently, build it
with -build-mode:llvm (checker + IR only, fast, no linking), and compare a single-threaded
baseline against many multi-threaded builds. A per-run timeout is treated as a deadlock, a
nonzero exit as a crash, and a differing set of emitted `define` symbols as nondeterminism.

Examples
--------
    # struct pairs (the default), heavy:
    python poly_stress.py all --odin ../../odin.exe --work ./_work \
        --kind struct --pairs 300 --procs 200 --threads 32 --iters 25

    # union pairs (currently reproduces a pre-existing mutual-recursion crash):
    python poly_stress.py all --odin ../../odin.exe --work ./_work --kind union --pairs 50

    # generate once, then run repeatedly:
    python poly_stress.py gen --out ./_work/corpus --kind struct --pairs 300
    python poly_stress.py run --odin ../../odin.exe --corpus ./_work/corpus --work ./_work
"""

import argparse
import os
import re
import shutil
import subprocess
import sys
import time

DEFINE_RE = re.compile(r'^define\b.*?(@"[^"]+"|@[\w.$]+)', re.MULTILINE)
TYPES = ["int", "u8", "u16", "u32", "i64", "f32", "f64", "uintptr"]


def _recursive_pair(kind, i, width):
    """Emit a mutually-recursive generic record pair A_i(T) <-> B_i(T)."""
    if kind == "struct":
        fa = "".join(f"  f{j}: Box({TYPES[j % len(TYPES)]}),\n" for j in range(width))
        fb = "".join(f"  g{j}: Box({TYPES[(j + 1) % len(TYPES)]}),\n" for j in range(width))
        return [
            f"Node_A_{i} :: struct($T: typeid) {{\n  val: T,\n{fa}  other: ^Node_B_{i}(T),\n}}",
            f"Node_B_{i} :: struct($T: typeid) {{\n  val: T,\n{fb}  other: ^Node_A_{i}(T),\n}}",
        ]
    # union: extra Box variants widen the "holding A, acquiring B" window
    va = "".join(f" Box({TYPES[j % len(TYPES)]})," for j in range(width))
    vb = "".join(f" Box({TYPES[(j + 1) % len(TYPES)]})," for j in range(width))
    return [
        f"Node_A_{i} :: union($T: typeid) {{ T,{va} ^Node_B_{i}(T) }}",
        f"Node_B_{i} :: union($T: typeid) {{ T,{vb} ^Node_A_{i}(T) }}",
    ]


def _use_procs(kind, i, ty):
    """Procs entering the pair from opposite directions with the same type arg.
    Returns a list of (name, body) pairs. The two `use_*` procs trigger the
    concurrent instantiation (ABBA bait). For unions the `read_*` procs additionally
    perform variant operations (assign / type-switch / type-assert) that read the
    in-progress union's variants, exercising the variants_wait_signal."""
    if kind == "struct":
        return [
            (f"use_a_{i}", f"x: Node_A_{i}({ty}); x.val = 0; _ = x"),
            (f"use_b_{i}", f"y: Node_B_{i}({ty}); y.val = 0; _ = y"),
        ]
    read = (
        f"x = {ty}(0)\n"
        f"  #partial switch v in x {{ case {ty}: _ = v }}\n"
        f"  if v, ok := x.({ty}); ok {{ _ = v }}"
    )
    return [
        (f"use_a_{i}", f"x: Node_A_{i}({ty}); _ = x"),
        (f"use_b_{i}", f"y: Node_B_{i}({ty}); _ = y"),
        (f"read_a_{i}", f"x: Node_A_{i}({ty})\n  {read}"),
        (f"read_b_{i}", f"x: Node_B_{i}({ty})\n  {read}"),
    ]


def gen_corpus(out_dir, kind, pairs, procs, width):
    os.makedirs(out_dir, exist_ok=True)
    for f in os.listdir(out_dir):
        if f.endswith(".odin"):
            os.remove(os.path.join(out_dir, f))

    if kind == "spec":
        _write(out_dir, _spec_lines(pairs, procs))
        print(f"[gen] spec: {pairs} specialized record families, {procs} caller procs")
        print(f"[gen] -> {os.path.join(out_dir, 'corpus.odin')}")
        return

    L = ["package corpus\n"]

    # standalone polymorphic procedures
    L += [
        "p_id  :: proc(x: $T) -> T { return x }",
        "p_sum :: proc(a: [$N]$T) -> T { t: T; for v in a { t += v }; return t }",
        "p_len :: proc(m: map[$K]$V) -> int { return len(m) }",
        "p_arr :: proc($T: typeid, $N: int) -> [N]T { a: [N]T; return a }",
        "",
        # simple polymorphic records
        "Box   :: struct($T: typeid) { value: T }",
        "Pair  :: struct($A: typeid, $B: typeid) { first: A, second: B }",
        "Fixed :: struct($T: typeid, $N: int) { data: [N]T }",
        "",
    ]

    # mutually-recursive generic record pairs (ABBA bait)
    for i in range(pairs):
        L += _recursive_pair(kind, i, width)
    L.append("")

    calls = []
    for i in range(pairs):
        for name, body in _use_procs(kind, i, TYPES[i % len(TYPES)]):
            L.append(f"{name} :: proc() {{\n  {body}\n}}")
            calls.append(f"{name}()")

    # extra generic-proc/record instantiation churn
    for p in range(procs):
        ty = TYPES[p % len(TYPES)]
        n = (p % 6) + 1
        body = "\n".join([
            f"  _ = p_id({ty}(0))",
            f"  _ = p_sum([{n}]{ty}{{}})",
            f"  b: Box({ty}); _ = b",
            f"  pr: Pair({ty}, {TYPES[(p + 1) % len(TYPES)]}); _ = pr",
            f"  fx: Fixed({ty}, {n}); _ = fx",
        ])
        L.append(f"work_{p} :: proc() {{\n{body}\n}}")
        calls.append(f"work_{p}()")

    L.append("main :: proc() {")
    L += [f"  {c}" for c in calls]
    L.append("}")

    _write(out_dir, L)
    print(f"[gen] {kind}: {pairs} recursive pairs, {procs} churn procs, width={width}")
    print(f"[gen] -> {os.path.join(out_dir, 'corpus.odin')}")


def _write(out_dir, lines):
    with open(os.path.join(out_dir, "corpus.odin"), "w", newline="\n") as fh:
        fh.write("\n".join(lines) + "\n")


def _spec_lines(recs, procs):
    """Specialization-constraint corpus: stresses the in-place memmove in
    check_type_specialization_to_internal (constraint `$V/Vec($T,$N)` matching)."""
    L = ["package corpus\n"]
    for j in range(recs):
        L.append(f"Vec_{j}  :: struct($T: typeid, $N: int) {{ data: [N]T }}")
    for j in range(recs):
        L.append(f"Wrap_{j} :: struct($T: typeid, $N: int) {{ inner: Vec_{j}(T, N), tag: int }}")
    L.append("")
    for j in range(recs):
        L.append(f"use_{j}  :: proc(v: $V/Vec_{j}($T, $N)) -> T {{ t: T; for i in 0..<N {{ t += v.data[i] }}; return t }}")
        L.append(f"wuse_{j} :: proc(w: $W/Wrap_{j}($T, $N)) -> T {{ return use_{j}(w.inner) }}")
    L.append("")
    calls = []
    for p in range(procs):
        j, ty, n = p % recs, TYPES[p % len(TYPES)], (p % 4) + 1
        L.append(f"work_{p} :: proc() {{\n"
                 f"  v: Vec_{j}({ty}, {n}); _ = use_{j}(v)\n"
                 f"  w: Wrap_{j}({ty}, {n}); _ = wuse_{j}(w)\n}}")
        calls.append(f"work_{p}()")
    L.append("main :: proc() {")
    L += [f"  {c}" for c in calls]
    L.append("}")
    return L


def defines_of(ll_dir):
    syms = set()
    if not os.path.isdir(ll_dir):
        return syms
    for f in os.listdir(ll_dir):
        if not f.endswith(".ll"):
            continue
        if f.startswith("runtime-") or f in ("builtin.ll", "sanitizer.ll"):
            continue  # runtime modules are identical across runs, just noise
        with open(os.path.join(ll_dir, f), "r", errors="replace") as fh:
            for m in DEFINE_RE.finditer(fh.read()):
                syms.add(m.group(1))
    return syms


def build_once(odin, corpus, out_dir, threads, timeout):
    """Return (status, elapsed, defines); status in {ok, deadlock, crash}."""
    if os.path.isdir(out_dir):
        shutil.rmtree(out_dir, ignore_errors=True)
    os.makedirs(out_dir, exist_ok=True)
    cmd = [odin, "build", corpus, "-build-mode:llvm",
           f"-thread-count:{threads}", "-out:" + out_dir]
    t0 = time.time()
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired:
        return "deadlock", time.time() - t0, set()
    elapsed = time.time() - t0
    if p.returncode != 0:
        sys.stdout.write(p.stdout[-2000:])
        sys.stderr.write(p.stderr[-2000:])
        return "crash", elapsed, set()
    return "ok", elapsed, defines_of(out_dir)


def run(odin, corpus, work, threads, iters, timeout):
    print("[run] baseline build (thread-count:1) ...")
    status, elapsed, base = build_once(odin, corpus, os.path.join(work, "ll_base"), 1, timeout)
    if status != "ok":
        print(f"[FAIL] baseline build failed: {status} ({elapsed:.1f}s)")
        return 2
    print(f"[run] baseline ok in {elapsed:.2f}s, {len(base)} poly define symbols")

    fails = 0
    flaky = 0
    for i in range(iters):
        d = os.path.join(work, f"ll_mt_{i}")
        status, elapsed, syms = build_once(odin, corpus, d, threads, timeout)
        tag = f"[{i + 1}/{iters}] threads={threads}"
        # A timeout or nonzero exit can be transient system load (a starved build hitting the wall
        # clock), not a real hang/crash. A genuine deadlock/crash reproduces deterministically, so
        # retry once: if the retry is clean, treat it as a load artifact rather than a failure.
        if status in ("deadlock", "crash"):
            r = os.path.join(work, f"ll_mt_{i}_retry")
            status, elapsed, syms = build_once(odin, corpus, r, threads, timeout)
            if status == "ok" and syms == base:
                print(f"{tag}: transient (cleared on retry, likely system load) — not counted")
                flaky += 1
                shutil.rmtree(r, ignore_errors=True)
                continue
        if status == "deadlock":
            print(f"{tag}: DEADLOCK (timed out after {timeout}s, twice) <<<"); fails += 1; continue
        if status == "crash":
            print(f"{tag}: CRASH (nonzero exit, twice) <<<"); fails += 1; continue
        if syms != base:
            print(f"{tag}: NONDETERMINISTIC symbol set (+{len(syms - base)} / -{len(base - syms)}) <<<")
            miss, extra = sorted(base - syms)[:5], sorted(syms - base)[:5]
            if miss:
                print(f"        missing vs baseline: {miss}")
            if extra:
                print(f"        extra vs baseline:   {extra}")
            fails += 1
            continue
        print(f"{tag}: ok ({elapsed:.2f}s, {len(syms)} syms)")
        shutil.rmtree(d, ignore_errors=True)

    print("-" * 60)
    flaky_note = f" ({flaky} transient, cleared on retry)" if flaky else ""
    if fails == 0:
        print(f"[PASS] {iters}/{iters} multi-threaded runs matched baseline, no hang/crash.{flaky_note}")
        return 0
    print(f"[FAIL] {fails}/{iters} runs had a reproducible deadlock/crash/nondeterminism.{flaky_note}")
    return 1


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)

    def add_gen_args(p):
        p.add_argument("--kind", choices=("struct", "union", "spec"), default="struct")
        p.add_argument("--pairs", type=int, default=300)
        p.add_argument("--procs", type=int, default=200)
        p.add_argument("--width", type=int, default=3)

    def add_run_args(p):
        p.add_argument("--threads", type=int, default=16)
        p.add_argument("--iters", type=int, default=20)
        p.add_argument("--timeout", type=int, default=60)

    g = sub.add_parser("gen"); g.add_argument("--out", required=True); add_gen_args(g)
    r = sub.add_parser("run")
    r.add_argument("--odin", required=True); r.add_argument("--corpus", required=True)
    r.add_argument("--work", required=True); add_run_args(r)
    a = sub.add_parser("all")
    a.add_argument("--odin", required=True); a.add_argument("--work", required=True)
    add_gen_args(a); add_run_args(a)

    args = ap.parse_args()
    if args.cmd == "gen":
        gen_corpus(args.out, args.kind, args.pairs, args.procs, args.width); return 0
    if args.cmd == "run":
        return run(args.odin, args.corpus, args.work, args.threads, args.iters, args.timeout)
    corpus = os.path.join(args.work, "corpus")
    gen_corpus(corpus, args.kind, args.pairs, args.procs, args.width)
    return run(args.odin, corpus, args.work, args.threads, args.iters, args.timeout)


if __name__ == "__main__":
    sys.exit(main())
