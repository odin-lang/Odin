#!/usr/bin/env luajit
-- rexcode  ·  Brendan Punsky (dotbmp@github), original author

--[[============================================================================
 rexcode build driver

 Drives the pre-build metaprograms (table generation), validations, and tests
 for every `core:rexcode` ISA, with cross-platform (Linux / macOS / Windows)
 gating and a clear report.

 USAGE
   luajit build.lua                       # no flags -> this help screen
   luajit build.lua all                   # do everything (gen + check + test), all ISAs
   luajit build.lua --gen --isa x86       # only (re)generate x86's tables
   luajit build.lua --builders --isa arm64  # only regenerate arm64's mnemonic builders
   luajit build.lua --check --test        # validate + test all ISAs (using committed blobs)
   luajit build.lua --verify --isa mips   # external-tool verification where available
   luajit build.lua --list                # ISA x task availability for THIS platform

 TASKS
   --gen         run the two metaprograms: ENCODING_TABLE -> generated Odin -> tables/*.bin
   --builders    regenerate each ISA's typed mnemonic builders (mnemonic_builders.odin)
   --check       `odin check` (compiles against the #loaded blobs) + structural invariants
   --test        run each ISA's test suite
   --verify      round-trip against an external assembler/disassembler (llvm-mc, da65, ...)
   --idempotent  re-run --gen + --builders and confirm all generated files are byte-stable
   all           shorthand for `--gen --builders --check --test`

 OPTIONS
   --isa <list>  comma/space-separated ISAs (default: all). e.g. --isa x86,arm64
   --odin <path> compiler to use (default: the in-repo ./odin — it has fixes not in
                 a released/system odin, so prefer it)
   --root <path> rexcode root (default: auto-detected from this script's location)
   --no-color    disable ANSI color
   -h, --help    this screen
   --list        availability matrix for the current platform

 PLATFORM NOTES
   * The in-repo compiler must be built first (./build_odin.sh, or build.bat on Windows).
   * `--test` for x86 JIT-executes x86-64 machine code, so it only runs on an x86-64
     host; it is skipped (with a message) elsewhere. All other ISAs' tests are portable.
   * `--verify` needs the matching external tool in PATH; the retro ISAs use shell
     scripts and are skipped on Windows. Missing tools are skipped, never fatal.
============================================================================]]--

-- ----------------------------------------------------------------------------
-- platform
-- ----------------------------------------------------------------------------
local OS    = jit.os                 -- "Linux" | "OSX" | "Windows" | "BSD" | ...
local ARCH  = jit.arch               -- "x64" | "x86" | "arm64" | "arm" | ...
local WIN   = (OS == "Windows")
local HOST_X64 = (ARCH == "x64")
local EXE   = WIN and ".exe" or ""

local use_color = not WIN or os.getenv("WT_SESSION") ~= nil or os.getenv("ANSICON") ~= nil

local function paint(code, s) return use_color and ("\27["..code.."m"..s.."\27[0m") or s end
local function bold(s)  return paint("1", s)  end
local function green(s) return paint("32", s) end
local function red(s)   return paint("31", s) end
local function yellow(s)return paint("33", s) end
local function dim(s)   return paint("2", s)  end

-- ----------------------------------------------------------------------------
-- small utilities
-- ----------------------------------------------------------------------------
local function q(s) return '"' .. s .. '"' end

-- Run a command; capture combined output; success via a shell-portable sentinel
-- (works in both POSIX sh and Windows cmd, regardless of popen close() quirks).
local function run(cmd)
  local p = io.popen(cmd .. " 2>&1 && echo __RX_OK__ || echo __RX_FAIL__")
  local out = p:read("*a") or ""
  p:close()
  local ok = out:match("__RX_OK__%s*$") ~= nil
  out = out:gsub("__RX_OK__%s*$", ""):gsub("__RX_FAIL__%s*$", "")
  return ok, out
end

local function file_exists(path)
  local f = io.open(path, "rb"); if f then f:close(); return true end; return false
end

local function read_file(path)
  local f = io.open(path, "rb"); if not f then return nil end
  local d = f:read("*a"); f:close(); return d
end

local function cwd()
  local p = io.popen(WIN and "cd" or "pwd")
  local d = p:read("*l"); p:close()
  return (d or "."):gsub("\\", "/")
end

-- Is a tool present in PATH?
local function have_tool(name)
  local probe = WIN and ("where " .. q(name)) or ("command -v " .. q(name))
  local ok = run(probe)
  return ok
end

-- ----------------------------------------------------------------------------
-- locate the rexcode root and the in-repo compiler
-- ----------------------------------------------------------------------------
local function script_dir()
  local s = (arg and arg[0] or ""):gsub("\\", "/")
  return s:match("^(.*)/[^/]*$") or "."
end

local function find_root(override)
  local function ok_root(d) return d and file_exists(d .. "/isa/labels.odin") end
  if override then return override end
  local sd, here = script_dir(), cwd()
  local cands = { sd, here, here .. "/" .. sd, here .. "/core/rexcode", "core/rexcode", "." }
  for _, d in ipairs(cands) do if ok_root(d) then return (d:gsub("/%.$","")) end end
  return sd  -- best effort
end

-- ----------------------------------------------------------------------------
-- ISA catalog
-- ----------------------------------------------------------------------------
-- test_x64:  test suite JIT-executes target code -> needs an x86-64 host (x86 only).
-- verify:    {tool=<PATH binary>, kind="odin"|"sh", harness=<file under tools/>}
local ISAS = {
  { name="x86",      test_x64=true,  verify={tool="llvm-mc",             kind="odin", harness="verify_against_llvm.odin"} },
  { name="arm32",    test_x64=false, verify={tool="llvm-mc",             kind="odin", harness="verify_against_llvm.odin"} },
  { name="arm64",    test_x64=false, verify={tool="llvm-mc",             kind="odin", harness="verify_against_llvm.odin"} },
  { name="mips",     test_x64=false, verify={tool="llvm-mc",             kind="odin", harness="verify_against_llvm.odin"} },
  { name="riscv",    test_x64=false, verify={tool="llvm-mc",             kind="odin", harness="verify_against_llvm.odin"} },
  { name="ppc",      test_x64=false, verify={tool="llvm-mc",             kind="odin", harness="verify_against_llvm.odin"} },
  { name="ppc_vle",  test_x64=false, verify={tool="powerpc-eabivle-as", kind="sh",   harness="verify_against_vle_as.sh"} },
  { name="rsp",      test_x64=false, verify={tool="armips",             kind="sh",   harness="verify_against_armips.sh"} },
  { name="mos6502",  test_x64=false, verify={tool="xa",                 kind="sh",   harness="verify_against_xa.sh"} },
  { name="mos65816", test_x64=false, verify={tool="ca65",               kind="sh",   harness="verify_against_ca65.sh"} },
}
local ISA_BY_NAME = {}; for _, a in ipairs(ISAS) do ISA_BY_NAME[a.name] = a end

-- IR packages live under <root>/ir/<name>. Unlike the ISAs they have a single-
-- stage generator (gen.odin emits Odin source directly) and no mnemonic builders
-- or external-assembler verify -- only gen / check / test apply.
local IRS = {
  { name="spirv", dir="ir/spirv" },
}

-- ----------------------------------------------------------------------------
-- argument parsing
-- ----------------------------------------------------------------------------
local function parse_args(argv)
  local o = { tasks={}, isas=nil, odin=nil, root=nil, help=false, list=false }
  local i = 1
  local function val(flag)
    i = i + 1
    if not argv[i] then io.stderr:write("error: "..flag.." needs a value\n"); os.exit(2) end
    return argv[i]
  end
  while argv[i] do
    local a = argv[i]
    if     a == "-h" or a == "--help" then o.help = true
    elseif a == "--list"        then o.list = true
    elseif a == "all" or a == "--all" then o.tasks.gen=true; o.tasks.builders=true; o.tasks.check=true; o.tasks.test=true
    elseif a == "--gen" or a == "--generate" then o.tasks.gen = true
    elseif a == "--builders" or a == "--mnemonics" then o.tasks.builders = true
    elseif a == "--check" or a == "--validate" then o.tasks.check = true
    elseif a == "--test"        then o.tasks.test = true
    elseif a == "--verify"      then o.tasks.verify = true
    elseif a == "--idempotent" or a == "--idem" then o.tasks.idempotent = true
    elseif a == "--no-color"    then use_color = false
    elseif a == "--isa"         then o.isas = val("--isa")
    elseif a == "--odin"        then o.odin = val("--odin")
    elseif a == "--root"        then o.root = val("--root")
    elseif a:match("^%-%-isa=")  then o.isas = a:sub(7)
    elseif a:match("^%-%-odin=") then o.odin = a:sub(8)
    elseif a:match("^%-%-root=") then o.root = a:sub(8)
    else io.stderr:write("error: unknown argument '"..a.."' (try --help)\n"); os.exit(2) end
    i = i + 1
  end
  return o
end

local function selected_isas(spec)
  if not spec then local t={}; for _,a in ipairs(ISAS) do t[#t+1]=a end; return t end
  local t = {}
  for name in spec:gmatch("[%w_]+") do
    local a = ISA_BY_NAME[name]
    if not a then io.stderr:write("error: unknown ISA '"..name.."'\n"); os.exit(2) end
    t[#t+1] = a
  end
  return t
end

-- ----------------------------------------------------------------------------
-- availability for the current platform
-- ----------------------------------------------------------------------------
-- returns ok(bool), reason(string|nil)
local function avail(isa, task, ctx)
  if task == "test" and isa.test_x64 and not HOST_X64 then
    return false, "needs x86-64 host (this is "..ARCH..")"
  end
  if task == "verify" then
    local v = isa.verify
    if v.kind == "sh" and WIN then return false, v.harness.." (shell script) unsupported on Windows" end
    if not ctx.tools[v.tool] then return false, v.tool.." not in PATH" end
  end
  return true, nil
end

-- ----------------------------------------------------------------------------
-- tasks
-- ----------------------------------------------------------------------------
local ODIN, ROOT, OUT  -- set in main

-- ISA packages live under <root>/isa/<name> (the shared isa package is <root>/isa).
local function pkg(isa, sub) return ROOT .. "/isa/" .. isa.name .. (sub and ("/"..sub) or "") end

local function odin_run(target)  return q(ODIN).." run "..q(target).." -out:"..q(OUT) end
local function odin_check(target)return q(ODIN).." check "..q(target).." -no-entry-point" end

-- structural invariants for the migrated layout
local function structural(isa)
  local p, bad = pkg(isa), {}
  local function must(rel)    if not file_exists(p.."/"..rel) then bad[#bad+1]="missing "..rel end end
  local function absent(rel)  if file_exists(p.."/"..rel)     then bad[#bad+1]="stray "..rel   end end
  must("tables.odin"); must("tablegen/encoding_table.odin"); must("tablegen/gen.odin")
  must("tablegen/generated/encode_tables.odin"); must("tablegen/generated/decode_tables.odin")
  must("tablegen/generated/writer.odin")
  must("mnemonic_builders.odin"); must("tools/gen_mnemonic_builders.odin")
  absent("encoding_table.odin"); absent("decoding_tables.odin"); absent("tools/gen_decode_tables.odin")
  if #bad == 0 then return true end
  return false, table.concat(bad, "; ")
end

-- blob paths an ISA's tables.odin #loads (parsed from the loader)
local function blob_paths(isa)
  local txt = read_file(pkg(isa).."/tables.odin") or ""
  local t = {}
  for name in txt:gmatch('#load%("(tables/[%w%._%-]+)"') do t[#t+1] = pkg(isa).."/"..name end
  return t
end

local function gen_files(isa)
  local t = { pkg(isa).."/tables.odin",
              pkg(isa).."/mnemonic_builders.odin",
              pkg(isa).."/tablegen/generated/encode_tables.odin",
              pkg(isa).."/tablegen/generated/decode_tables.odin" }
  for _, b in ipairs(blob_paths(isa)) do t[#t+1] = b end
  return t
end

local function do_gen(isa)
  local okA, outA = run(odin_run(pkg(isa, "tablegen")))
  if not okA then return false, "Stage A failed:\n"..outA end
  local okB, outB = run(odin_run(pkg(isa, "tablegen/generated")))
  if not okB then return false, "Stage B failed:\n"..outB end
  -- counts line from Stage A (e.g. "x86 tablegen: 2355 encode forms, ...")
  return true, (outA:match("tablegen:%s*(.-)\n") or ""):gsub("%s+$","")
end

-- regenerate the typed mnemonic builders (mnemonic_builders.odin). The generator
-- anchors its output via #directory, so it runs correctly from any CWD.
local function do_builders(isa)
  local gen = pkg(isa, "tools/gen_mnemonic_builders.odin")
  if not file_exists(gen) then return false, "missing tools/gen_mnemonic_builders.odin" end
  local ok, out = run(q(ODIN).." run "..q(gen).." -file -out:"..q(OUT))
  if not ok then return false, "generator failed:\n"..out:sub(-400) end
  if not file_exists(pkg(isa).."/mnemonic_builders.odin") then
    return false, "generator ran but produced no mnemonic_builders.odin"
  end
  local n = out:match("procedures generated:%s*(%d+)")
        or out:match("[Bb]uilder procedures:%s*(%d+)")
        or out:match("inst_/emit_ pairs:%s*(%d+)")
        or out:match("[Pp]rocedures generated:%s*(%d+)")
        or out:match("inst_ procedures:%s*(%d+)")
        or out:match("total builder procs:%s*(%d+)")
  return true, (n and (n.." builders") or "regenerated")
end

local function do_check(isa)
  local s_ok, s_why = structural(isa)
  if not s_ok then return false, "structure: "..s_why end
  local c_ok, c_out = run(odin_check(pkg(isa)))
  if not c_ok then return false, "odin check failed:\n"..(c_out:match("(.-Error:.-)\n") or c_out) end
  return true, "structure + compile"
end

local function do_test(isa)
  local ok, out = run(odin_run(pkg(isa, "tests")))
  local fails = out:match("([1-9]%d* failed)")
  if not ok or fails then return false, (fails or "test run failed").."\n"..out:sub(-400) end
  local cases = out:match("(%d+ cases? validated)")
  if not cases then
    local n = 0; for p in out:gmatch("(%d+) passed") do n = n + tonumber(p) end
    if n > 0 then cases = n .. " passed" end
  end
  return true, cases or "passed"
end

local function do_verify(isa)
  local v = isa.verify
  local cmd
  if v.kind == "odin" then
    cmd = q(ODIN).." run "..q(pkg(isa, "tools/"..v.harness)).." -file -out:"..q(OUT)
  else
    cmd = "sh "..q(pkg(isa, "tools/"..v.harness))
  end
  local ok, out = run(cmd)
  if not ok then return false, "verify failed:\n"..out:sub(-400) end
  return true, "matched "..v.tool
end

local function do_idempotent(isa)
  local files = gen_files(isa)
  local before = {}
  for _, f in ipairs(files) do before[f] = read_file(f) end
  local ok, why = do_gen(isa)
  if not ok then return false, "re-gen failed: "..why end
  local okb, whyb = do_builders(isa)
  if not okb then return false, "re-gen builders failed: "..whyb end
  local changed = {}
  for _, f in ipairs(files) do
    if read_file(f) ~= before[f] then changed[#changed+1] = f:match("[^/]+$") end
  end
  if #changed == 0 then return true, "byte-stable ("..#files.." artifacts)" end
  return false, "changed on re-gen: "..table.concat(changed, ", ")
end

-- IR package tasks (ir/<name>): single-stage gen, plain check, plain test.
local function ir_pkg(ir, sub) return ROOT .. "/" .. ir.dir .. (sub and ("/"..sub) or "") end
local function do_ir_gen(ir)
  local ok, out = run(odin_run(ir_pkg(ir, "tablegen")))
  if not ok then return false, "gen failed:\n"..out:sub(-400) end
  return true, (out:match("tablegen:%s*(.-)\n") or "generated"):gsub("%s+$","")
end
local function do_ir_check(ir)
  local ok, out = run(odin_check(ir_pkg(ir)))
  if not ok then return false, "odin check failed:\n"..(out:match("(.-Error:.-)\n") or out) end
  return true, "compile"
end
local function do_ir_test(ir)
  local ok, out = run(odin_run(ir_pkg(ir, "tests")))
  local fails = out:match("([1-9]%d* failed)")
  if not ok or fails then return false, (fails or "test run failed").."\n"..out:sub(-400) end
  local n = 0; for p in out:gmatch("(%d+) passed") do n = n + tonumber(p) end
  return true, (n > 0 and (n.." passed") or "passed")
end
local IR_TASK_FN = { gen=do_ir_gen, check=do_ir_check, test=do_ir_test }

local TASK_FN = { gen=do_gen, builders=do_builders, check=do_check, test=do_test, verify=do_verify, idempotent=do_idempotent }
local TASK_ORDER = { "gen", "builders", "check", "test", "verify", "idempotent" }
local TASK_LABEL = { gen="generate", builders="builders", check="validate", test="test", verify="verify", idempotent="idempotent" }

-- ----------------------------------------------------------------------------
-- help / list
-- ----------------------------------------------------------------------------
local function platform_line()
  return ("%s / %s   (luajit %s)"):format(OS, ARCH, (jit.version:match("LuaJIT (%S+)") or "?"))
end

local function print_help(ctx)
  print(bold("rexcode build driver") .. " — generate tables, validate, and test the core:rexcode ISAs")
  print()
  print("  Platform : " .. platform_line())
  local cstat = ctx.odin_ok and green("[found] "..ODIN) or red("[NOT BUILT] expected "..ODIN.." — run ./build_odin.sh")
  print("  Compiler : " .. cstat)
  print()
  print(bold("USAGE"))
  print("  luajit build.lua                 " .. dim("# no flags -> this help"))
  print("  luajit build.lua all             " .. dim("# everything (gen + builders + check + test)"))
  print("  luajit build.lua --gen --isa x86 " .. dim("# only regenerate x86's tables"))
  print("  luajit build.lua --check --test  " .. dim("# validate + test (using committed blobs)"))
  print("  luajit build.lua --list          " .. dim("# availability matrix for this platform"))
  print()
  print(bold("TASKS") .. dim("  (availability on " .. OS .. "/" .. ARCH .. ")"))
  print("  --gen          metaprograms: ENCODING_TABLE -> generated Odin -> tables/*.bin   " .. green("all ISAs"))
  print("  --builders     regenerate typed mnemonic builders (mnemonic_builders.odin)      " .. green("all ISAs"))
  print("  --check        odin check (compiles vs #loaded blobs) + structural invariants   " .. green("all ISAs"))
  local tnote = HOST_X64 and green("all ISAs") or yellow("x86 skipped (needs x86-64 host)")
  print("  --test         run each ISA's test suite                                        " .. tnote)
  print("  --verify       round-trip vs external assembler/disassembler                    " .. yellow("per-tool (see --list)"))
  print("  --idempotent   re-run --gen and confirm byte-stable output                      " .. green("all ISAs"))
  print("  all            = --gen --builders --check --test")
  print()
  print(bold("OPTIONS"))
  print("  --isa <list>   comma/space ISAs (default: all): " .. dim("x86 arm32 arm64 mips riscv ppc ppc_vle rsp mos6502 mos65816"))
  print("  --odin <path>  compiler (default: in-repo ./odin)   --root <path>  rexcode root")
  print("  --no-color     plain output            -h, --help   this screen      --list  availability matrix")
  print()
  print(dim("The in-repo ./odin is required (it has fixes not in released/system odin)."))
end

local function print_list(ctx)
  print(bold("ISA availability on ") .. bold(OS .. "/" .. ARCH))
  print(dim(("  %-10s %-7s %-7s %-18s %s"):format("ISA","gen","check","test","verify")))
  for _, isa in ipairs(ISAS) do
    local t_ok, t_why = avail(isa, "test", ctx)
    local v_ok, v_why = avail(isa, "verify", ctx)
    local tcol = t_ok and green("yes") or yellow("skip")
    local vcol = v_ok and green("yes ("..isa.verify.tool..")") or yellow("skip: "..(v_why or "?"))
    print(("  %-10s %-7s %-7s %-18s %s"):format(
      isa.name, green("yes"), green("yes"), tcol .. (t_ok and "" or "  "..dim(t_why or "")), vcol))
  end
end

-- ----------------------------------------------------------------------------
-- main
-- ----------------------------------------------------------------------------
local function main()
  local o = parse_args(arg)

  ROOT = (find_root(o.root)):gsub("/+$","")
  ODIN = o.odin or (ROOT .. "/../.." .. "/odin" .. EXE)
  -- normalize ../.. once for tidy messages
  ODIN = ODIN:gsub("/core/rexcode/%.%./%.%./", "/")
  local ctx = { odin_ok = file_exists(ODIN) or o.odin ~= nil, tools = {} }
  -- probe each distinct verify tool once
  local probed = {}
  for _, isa in ipairs(ISAS) do
    local tname = isa.verify.tool
    if probed[tname] == nil then probed[tname] = have_tool(tname) end
    ctx.tools[tname] = probed[tname]
  end

  local temp = (WIN and (os.getenv("TEMP") or os.getenv("TMP")) or (os.getenv("TMPDIR") or "/tmp")) or "."
  OUT = (temp:gsub("\\","/"):gsub("/+$","")) .. "/rexcode_build" .. EXE

  if o.help then print_help(ctx); return 0 end
  if o.list then print_list(ctx); return 0 end

  local tasks = {}
  for _, t in ipairs(TASK_ORDER) do if o.tasks[t] then tasks[#tasks+1] = t end end
  if #tasks == 0 then print_help(ctx); return 0 end

  if not ctx.odin_ok then
    print(red("error: the in-repo compiler was not found at:\n  ") .. ODIN)
    print("Build it first:  " .. (WIN and "build.bat" or "./build_odin.sh") ..
          "   (or pass --odin <path>).")
    return 2
  end

  local isas = selected_isas(o.isas)
  print(bold("rexcode") .. "  " .. dim(platform_line()) .. "  odin=" .. dim(ODIN))
  print(dim(("tasks: %s   isas: %d"):format(table.concat(tasks, " "), #isas)))

  local t0 = os.time()
  local results, nfail, nskip = {}, 0, 0
  for _, task in ipairs(tasks) do
    print()
    print(bold("== " .. TASK_LABEL[task]:upper() .. " =="))
    for _, isa in ipairs(isas) do
      results[isa.name] = results[isa.name] or {}
      local ok_av, why = avail(isa, task, ctx)
      io.write(("  %-10s %-11s "):format(isa.name, task))
      io.flush()
      if not ok_av then
        results[isa.name][task] = "skip"; nskip = nskip + 1
        print(yellow("skip") .. "  " .. dim(why))
      else
        local ok, detail = TASK_FN[task](isa)
        results[isa.name][task] = ok and "ok" or "fail"
        if ok then print(green("ok") .. "    " .. dim(detail or ""))
        else nfail = nfail + 1; print(red("FAIL") .. "  " .. (detail or ""):gsub("\n", "\n            ")) end
      end
    end
    for _, ir in ipairs(IRS) do
      local fn = IR_TASK_FN[task]
      if fn then
        results[ir.name] = results[ir.name] or {}
        io.write(("  %-10s %-11s "):format(ir.name, task)); io.flush()
        local ok, detail = fn(ir)
        results[ir.name][task] = ok and "ok" or "fail"
        if ok then print(green("ok") .. "    " .. dim(detail or ""))
        else nfail = nfail + 1; print(red("FAIL") .. "  " .. (detail or ""):gsub("\n", "\n            ")) end
      end
    end
  end

  -- summary matrix
  print()
  print(bold("== REPORT ==") .. dim(("   %ds"):format(os.time() - t0)))
  io.write(dim(("  %-10s"):format("ISA")))
  for _, t in ipairs(tasks) do io.write(dim(("%-12s"):format(t))) end
  print()
  for _, isa in ipairs(isas) do
    io.write(("  %-10s"):format(isa.name))
    for _, t in ipairs(tasks) do
      local s = results[isa.name][t] or "--"
      local c = (s == "ok" and green("ok")) or (s == "fail" and red("FAIL")) or (s == "skip" and yellow("skip")) or dim("--")
      io.write(c .. string.rep(" ", math.max(2, 12 - #s)))
    end
    print()
  end
  for _, ir in ipairs(IRS) do
    io.write(("  %-10s"):format(ir.name))
    for _, t in ipairs(tasks) do
      local s = (results[ir.name] or {})[t] or "--"
      local c = (s == "ok" and green("ok")) or (s == "fail" and red("FAIL")) or (s == "skip" and yellow("skip")) or dim("--")
      io.write(c .. string.rep(" ", math.max(2, 12 - #s)))
    end
    print()
  end
  print()
  if nfail == 0 then
    print(green(bold("PASS")) .. ("  (%d skipped)"):format(nskip))
    return 0
  else
    print(red(bold("FAIL")) .. ("  %d failed, %d skipped"):format(nfail, nskip))
    return 1
  end
end

os.exit(main())
