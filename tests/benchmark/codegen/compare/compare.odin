package benchmark_codegen_compare

// Builds the codegen benchmark with two compilers, runs both builds in
// interleaved rounds, and compares the fastest time of each workload.
// Fails when a workload's checksum differs between the builds or between rounds.
//
// odin run tests/benchmark/codegen/compare -- <odin A> <odin B> [-o:speed] [-rounds:10] [-cpu:N] [-root:DIR] [-out:DIR]

import "core:flags"
import "core:fmt"
import "core:math"
import "core:os"
import "core:strconv"
import "core:strings"

Options :: struct {
	a:      string `args:"pos=0,required" usage:"Baseline compiler, e.g. a build of master."`,
	b:      string `args:"pos=1,required" usage:"Compiler to compare against the baseline."`,
	o:      string `usage:"Optimization mode of both builds. Default: speed."`,
	rounds: int    `usage:"Runs of each build. Default: 10."`,
	cpu:    int    `usage:"Pin the benchmark to this logical CPU (Windows and Linux)."`,
	root:   string `usage:"ODIN_ROOT of both builds. Default: whatever each compiler finds."`,
	out:    string `usage:"Directory for the two executables. Default: a temporary directory."`,
}

Result :: struct {
	name:     string,
	ms:       [2]f64,
	checksum: [2]string,
	runs:     [2]int,
	unstable: [2]bool,
}

EXE_SUFFIX :: ".exe" when ODIN_OS == .Windows else ""

main :: proc() {
	opt := Options{
		o      = "speed",
		rounds = 10,
		cpu    = -1,
	}
	flags.parse_or_exit(&opt, os.args, .Odin)

	if opt.rounds < 1 {
		fmt.eprintln("-rounds must be at least 1")
		os.exit(2)
	}

	if opt.cpu < -1 {
		fmt.eprintln("-cpu must be at least 0")
		os.exit(2)
	}

	out_dir := opt.out
	if out_dir == "" {
		tmp, err := os.temp_directory(context.allocator)
		if err != nil {
			fmt.eprintln("cannot find a temporary directory:", err)
			os.exit(1)
		}
		out_dir, _ = os.join_path({tmp, "odin-codegen-benchmark"}, context.allocator)
	}

	mkdir_err := os.make_directory_all(out_dir)
	if mkdir_err != nil && mkdir_err != .Exist {
		fmt.eprintfln("cannot make %s: %v", out_dir, mkdir_err)
		os.exit(1)
	}

	compilers := [2]string{opt.a, opt.b}
	names     := [2]string{"a" + EXE_SUFFIX, "b" + EXE_SUFFIX}
	exes: [2]string
	for compiler, side in compilers {
		exes[side], _ = os.join_path({out_dir, names[side]}, context.allocator)
		fmt.eprintfln("building %s with %s", exes[side], compiler)
		if !build(compiler, exes[side], opt) {
			os.exit(1)
		}
	}

	results: [dynamic]Result
	for round in 0..<opt.rounds {
		order := [2]int{0, 1}
		if round % 2 == 1 {
			order = {1, 0}
		}

		for side in order {
			if !run(exes[side], side, opt.cpu, &results) {
				os.exit(1)
			}
		}
		fmt.eprintf("\rround %d/%d", round+1, opt.rounds)
	}
	fmt.eprintln()

	if !report(results[:], opt) {
		os.exit(1)
	}
}

@(require_results)
build :: proc(compiler, exe: string, opt: Options) -> bool {
	benchmark_dir, _ := os.join_path({#directory, ".."}, context.temp_allocator)
	command := []string{
		compiler,
		"build",
		benchmark_dir,
		fmt.tprintf("-o:%s", opt.o),
		fmt.tprintf("-out:%s", exe),
	}

	env: []string // nil: inherit this process's environment
	if opt.root != "" {
		inherited, _ := os.environ(context.temp_allocator)
		list := make([dynamic]string, context.temp_allocator)
		for kv in inherited {
			key, _, _ := strings.partition(kv, "=")
			if !strings.equal_fold(key, "ODIN_ROOT") {
				append(&list, kv)
			}
		}
		append(&list, fmt.tprintf("ODIN_ROOT=%s", opt.root))
		env = list[:]
	}

	desc := os.Process_Desc{
		command = command,
		env     = env,
	}
	state, stdout, stderr, err := os.process_exec(desc, context.temp_allocator)
	switch {
	case err != nil:
		fmt.eprintfln("cannot run %s: %v", compiler, err)
		return false
	case state.exit_code != 0:
		fmt.eprintfln("build failed (exit code %d):\n%s%s", state.exit_code, stdout, stderr)
		return false
	}
	return true
}

@(require_results)
run :: proc(exe: string, side: int, cpu: int, results: ^[dynamic]Result) -> bool {
	defer free_all(context.temp_allocator)

	command := make([dynamic]string, context.temp_allocator)
	append(&command, exe)
	if cpu >= 0 {
		append(&command, fmt.tprintf("-cpu:%d", cpu))
	}

	desc := os.Process_Desc{
		command = command[:],
	}
	state, stdout, stderr, err := os.process_exec(desc, context.temp_allocator)
	switch {
	case err != nil:
		fmt.eprintfln("cannot run %s: %v", exe, err)
		return false
	case state.exit_code != 0:
		fmt.eprintfln("%s failed (exit code %d):\n%s%s", exe, state.exit_code, stdout, stderr)
		return false
	}

	text := string(stdout)
	for line in strings.split_lines_iterator(&text) {
		fields := strings.fields(line, context.temp_allocator)
		if len(fields) != 3 {
			continue
		}
		ms := strconv.parse_f64(fields[1]) or_continue
		name     := fields[0]
		checksum := fields[2]

		r := find_result(results, name)
		if r.runs[side] == 0 {
			r.ms[side]       = ms
			r.checksum[side] = strings.clone(checksum)
		} else {
			r.ms[side] = min(r.ms[side], ms)
			if checksum != r.checksum[side] {
				r.unstable[side] = true
			}
		}
		r.runs[side] += 1
	}
	return true
}

@(require_results)
find_result :: proc(results: ^[dynamic]Result, name: string) -> ^Result {
	for &r in results {
		if r.name == name {
			return &r
		}
	}
	append(results, Result{name = strings.clone(name)})
	return &results[len(results)-1]
}

// Prints the table. Returns false when a checksum differs or a workload is missing from a build.
@(require_results)
report :: proc(results: []Result, opt: Options) -> (ok: bool) {
	name_width := len("workload")
	for r in results {
		name_width = max(name_width, len(r.name))
	}

	fmt.printfln("codegen benchmark: -o:%s, fastest of %d rounds", opt.o, opt.rounds)
	fmt.printfln("A: %s", opt.a)
	fmt.printfln("B: %s", opt.b)
	fmt.println()
	fmt.printfln("%-*s %10s %10s %8s", name_width, "workload", "A (ms)", "B (ms)", "B vs A")

	ok = true
	log_sum := 0.0
	count   := 0
	for r in results {
		fmt.printf("%-*s", name_width, r.name)
		if r.runs[0] != opt.rounds || r.runs[1] != opt.rounds {
			fmt.printfln("  missing from some runs (A: %d, B: %d)", r.runs[0], r.runs[1])
			ok = false
			continue
		}

		ratio  := r.ms[1] / r.ms[0]
		change := (ratio - 1)*100
		fmt.printf(" %10.2f %10.2f %+7.2f%%", r.ms[0], r.ms[1], change)
		log_sum += math.ln(ratio)
		count   += 1

		switch {
		case r.unstable[0] || r.unstable[1]:
			fmt.print("  checksum varies between runs")
			ok = false
		case r.checksum[0] != r.checksum[1]:
			fmt.printf("  checksum differs: %s vs %s", r.checksum[0], r.checksum[1])
			ok = false
		}
		fmt.println()
	}

	if count > 0 {
		geomean := (math.exp(log_sum/f64(count)) - 1)*100
		fmt.printfln("%-*s %10s %10s %+7.2f%%", name_width, "geomean", "", "", geomean)
	}

	if !ok {
		fmt.eprintln("FAILED: the builds disagree.")
		fmt.eprintln("A checksum difference means a miscompile, or two library trees that behave differently (see -root).")
	}
	return
}
