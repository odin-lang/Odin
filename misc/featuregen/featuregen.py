import subprocess
import tempfile
import os
import sys

archs = [
	("amd64",     "linux_amd64",   "x86_64-pc-linux-gnu", [], []),
	("i386",      "linux_i386",    "i386-pc-linux-gnu",   [], []),
	("arm32",     "linux_arm32",   "arm-linux-gnu",       [], []),
	("arm64",     "linux_arm64",   "aarch64-linux-elf",   [], []),
	("wasm32",    "js_wasm32",     "wasm32-js-js",        [], []),
	("wasm64p32", "js_wasm64p32",  "wasm32-js-js",        [], []),
	("riscv64",   "linux_riscv64", "riscv64-linux-gnu",   [], []),
];

SEEKING_CPUS     = 0
PARSING_CPUS     = 1
PARSING_FEATURES = 2

with tempfile.NamedTemporaryFile(suffix=".odin", delete=True) as temp_file:
	temp_file.write(b"package main\n")

	for arch, target, triple, cpus, features in archs:
		cmd = ["odin", "build", temp_file.name, "-file", "-use-single-module", "-build-mode:asm", "-out:temp", "-target-features:\"help\"", f"-target:\"{target}\""]
		process = subprocess.Popen(cmd, stderr=subprocess.PIPE, text=True)

		state = SEEKING_CPUS
		for line in process.stderr:

			if state == SEEKING_CPUS:
				if line == "Available CPUs for this target:\n":
					state = PARSING_CPUS
			
			elif state == PARSING_CPUS:
				if line == "Available features for this target:\n":
					state = PARSING_FEATURES
					continue
			
				parts = line.split(" -", maxsplit=1)
				if len(parts) < 2:
					continue

				cpu = parts[0].strip()
				cpus.append(cpu)

			elif state == PARSING_FEATURES:
				if line == "\n" and len(features) > 0:
					break

				parts = line.split(" -", maxsplit=1)
				if len(parts) < 2:
					continue

				feature = parts[0].strip()
				features.append(feature)

		process.wait()
		if process.returncode != 0:
			print(f"odin build returned with non-zero exit code {process.returncode}")
			sys.exit(1)

		os.remove("temp.S")

def print_default_features(triple, microarch):
	cmd = ["./featuregen", triple, microarch]
	process = subprocess.Popen(cmd, stdout=subprocess.PIPE, text=True)
	first = True
	for line in process.stdout:
		print("" if first else ",", line.strip(), sep="", end="")
		first = False
	process.wait()
	if process.returncode != 0:
		print(f"featuregen returned with non-zero exit code {process.returncode}")
		sys.exit(1)

print("// Generated with the featuregen script in `misc/featuregen`")
print("gb_global String target_microarch_list[TargetArch_COUNT] = {")
print("\t// TargetArch_Invalid:")
print('\tstr_lit(""),')
for arch, target, triple, cpus, features in archs:
	print(f"\t// TargetArch_{arch}:")
	cpus_str = ','.join(cpus)
	print(f'\tstr_lit("{cpus_str}"),')
print("};")

print("")

print("// Generated with the featuregen script in `misc/featuregen`")
print("gb_global String target_features_list[TargetArch_COUNT] = {")
print("\t// TargetArch_Invalid:")
print('\tstr_lit(""),')
for arch, target, triple, cpus, features in archs:
	print(f"\t// TargetArch_{arch}:")
	features_str = ','.join(features)
	print(f'\tstr_lit("{features_str}"),')
print("};")

print("")

print("// Generated with the featuregen script in `misc/featuregen`")
print("gb_global int target_microarch_counts[TargetArch_COUNT] = {")
print("\t// TargetArch_Invalid:")
print("\t0,")
for arch, target, triple, cpus, feature in archs:
	print(f"\t// TargetArch_{arch}:")
	print(f"\t{len(cpus)},")
print("};")

print("")

print("// Generated with the featuregen script in `misc/featuregen`")
print("gb_global MicroarchFeatureList microarch_features_list[] = {")
for arch, target, triple, cpus, features in archs:
	print(f"\t// TargetArch_{arch}:")
	for cpu in cpus:
		print(f'\t{{ str_lit("{cpu}"), str_lit("', end="")
		print_default_features(triple, cpu)
		print('") },')
print("};")
