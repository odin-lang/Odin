#!/usr/bin/env python3
import urllib.request
import urllib.error
import subprocess
import zipfile
import hashlib
import hmac
import sys
import os
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# The OpenSSL CLI tool installed can be used to easily generate digests:
# $ openssl sha3-512 -mac HMAC -macopt key:"$HMAC_KEY" $FILE_NAME
TEST_SUITES      = ['PNG', 'XML', 'BMP', 'JPG', 'BNG', 'Wycheproof', 'Noise', 'X509-Limbo', 'Fonts', 'ZIP', 'HXA', 'I18N', 'UCD']
ASSETS_COMMIT    = "839ce024b14e8662b6d2baa98f1fa181fd4e5203"
ASSETS_BASE_URL  = "https://raw.githubusercontent.com/odin-lang/test-assets/{}/{}/{}"
MANIFEST_DIR     = os.path.join(os.path.dirname(os.path.abspath(__file__)), "assets")
HMAC_KEY         = "https://odin-lang.org"
HMAC_HASH        = hashlib.sha3_512
REQUEST_OVERHEAD = 64 * 1024
CHUNK_SIZE       = 1024 * 1024

def manifest_path(suite):
	return os.path.join(MANIFEST_DIR, "{}.manifest".format(suite))

def read_manifest(suite):
	entries = []
	path    = manifest_path(suite)
	with open(path, "r", encoding="utf-8") as f:
		for number, line in enumerate(f, 1):
			line = line.strip()
			if line == "" or line.startswith("#"):
				continue
			parts = line.split(None, 2)
			if len(parts) != 3 or not parts[0].isdigit() or len(parts[1]) != 2 * HMAC_HASH().digest_size:
				print("❌ {}:{}: expected \"<size> <hmac> <path>\"".format(path, number))
				return None
			name = parts[2]
			if name.startswith("/") or "\\" in name or ":" in name or ".." in name.split("/"):
				print("❌ {}:{}: invalid path {}".format(path, number, name))
				return None
			entries.append((name, int(parts[0]), parts[1].lower()))
	return entries

HEADER_SIZE = "# Size"
HEADER_HMAC = "HMAC-SHA3-512 keyed with \"{}\"".format(HMAC_KEY)
HEADER_PATH = "Path relative to the suite directory"

def manifest_header(width):
	return "{} {} {}".format(HEADER_SIZE.ljust(width), HEADER_HMAC.ljust(2 * HMAC_HASH().digest_size), HEADER_PATH)

def size_width(entries):
	return max([len(str(entry[1])) for entry in entries] + [len(HEADER_SIZE)])

def format_entry(name, size, digest, width):
	return "{} {} {}".format(str(size).ljust(width), digest, name)

def digest_bytes(data):
	return hmac.new(HMAC_KEY.encode(), data, HMAC_HASH).hexdigest()

def digest_file(path):
	h    = hmac.new(HMAC_KEY.encode(), digestmod=HMAC_HASH)
	size = 0
	with open(path, "rb") as f:
		while True:
			chunk = f.read(CHUNK_SIZE)
			if not chunk:
				break
			h.update(chunk)
			size += len(chunk)
	return size, h.hexdigest()

def local_state(base_path, entry):
	name, size, digest = entry
	path = os.path.join(base_path, name)
	if not os.path.isfile(path):
		return "missing", 0, ""
	local_size, local_digest = digest_file(path)
	if local_size != size or not hmac.compare_digest(local_digest, digest):
		return "changed", local_size, local_digest
	return "ok", local_size, local_digest

def write_atomic(path, data):
	os.makedirs(os.path.dirname(path), exist_ok=True)
	tmp = path + ".part"
	with open(tmp, "wb") as f:
		f.write(data)
	os.replace(tmp, path)

def download(suite, name):
	url = ASSETS_BASE_URL.format(ASSETS_COMMIT, suite, name)
	try:
		with urllib.request.urlopen(url) as response:
			return response.read()
	except (urllib.error.URLError, OSError) as e:
		print("❌ Could not download {}: {}".format(url, e))
		return None

def verify_bytes(entry, data):
	name, size, digest = entry
	if len(data) != size:
		print("❌ Expected {} bytes, got {} for {}".format(size, len(data), name))
		return False
	actual = digest_bytes(data)
	if not hmac.compare_digest(actual, digest):
		print("❌ Expected {}, got {} for {}".format(digest, actual, name))
		return False
	return True

def fetch_individually(base_path, suite, needed, debug):
	for entry in needed:
		data = download(suite, entry[0])
		if data is None or not verify_bytes(entry, data):
			return 1
		write_atomic(os.path.join(base_path, entry[0]), data)
		if debug:
			print("✅ {} *{}".format(entry[2], entry[0]))
	return 0

def fetch_archive(base_path, suite, archive, needed, debug):
	data = download(suite, archive[0])
	if data is None or not verify_bytes(archive, data):
		return 1
	with zipfile.ZipFile(io.BytesIO(data)) as z:
		members = {info.filename: info for info in z.infolist() if not info.is_dir()}
		for entry in needed:
			if entry[0] not in members:
				print("❌ {} is not in {}".format(entry[0], archive[0]))
				return 3
			member = z.read(members[entry[0]])
			if not verify_bytes(entry, member):
				return 4
			write_atomic(os.path.join(base_path, entry[0]), member)
			if debug:
				print("✅ {} *{}".format(entry[2], entry[0]))
	return 0

def sync_suite(base_path, suite, debug, label_width, count_width):
	entries = read_manifest(suite)
	if entries is None:
		return 2
	archive_name = "{}.zip".format(suite)
	archive      = None
	files        = []
	for entry in entries:
		if entry[0] == archive_name:
			archive = entry
		else:
			files.append(entry)

	needed = []
	for entry in files:
		state, _, _ = local_state(base_path, entry)
		if state != "ok":
			needed.append(entry)

	if len(needed) == 0:
		print("{} all {} {} present and verified.".format((suite + ":").ljust(label_width), str(len(files)).rjust(count_width), "file" if len(files) == 1 else "files"))
		return 0

	individual_cost = sum(entry[1] + REQUEST_OVERHEAD for entry in needed)
	if archive is not None and archive[1] + REQUEST_OVERHEAD < individual_cost:
		print("{} {} of {} {} missing or changed, downloading {}.".format((suite + ":").ljust(label_width), str(len(needed)).rjust(count_width), str(len(files)).rjust(count_width), "file" if len(files) == 1 else "files", archive_name))
		sys.stdout.flush()
		return fetch_archive(base_path, suite, archive, needed, debug)

	print("{} {} of {} {} missing or changed, downloading {} individually.".format((suite + ":").ljust(label_width), str(len(needed)).rjust(count_width), str(len(files)).rjust(count_width), "file" if len(files) == 1 else "files", "it" if len(needed) == 1 else "them"))
	sys.stdout.flush()
	return fetch_individually(base_path, suite, needed, debug)

def tracked_files(base_path):
	try:
		result = subprocess.run(["git", "-C", base_path, "ls-files", "-z", "."], capture_output=True, check=True)
	except (OSError, subprocess.CalledProcessError):
		return set()
	return set(name for name in result.stdout.decode("utf-8").split("\0") if name != "")

def report_suite(base_path, suite, label_width):
	entries = read_manifest(suite)
	if entries is None:
		return 2
	archive_name = "{}.zip".format(suite)
	known        = set(entry[0] for entry in entries)
	changed      = []
	missing      = []
	added        = []

	for entry in entries:
		if entry[0] == archive_name:
			continue
		state, size, digest = local_state(base_path, entry)
		if state == "changed":
			changed.append((entry[0], size, digest))
		elif state == "missing":
			missing.append(entry[0])

	if os.path.isdir(base_path):
		tracked = tracked_files(base_path)
		for root, dirs, names in os.walk(base_path):
			dirs.sort()
			for name in sorted(names):
				relative = os.path.relpath(os.path.join(root, name), base_path).replace(os.sep, "/")
				if relative in known or relative in tracked or name == ".gitignore" or name.endswith(".part") or relative == archive_name:
					continue
				size, digest = digest_file(os.path.join(root, name))
				added.append((relative, size, digest))

	if len(changed) == 0 and len(missing) == 0 and len(added) == 0:
		print("{} matches {}".format((suite + ":").ljust(label_width), manifest_path(suite)))
		return 0

	width = max(size_width(entries), size_width(changed + added))
	print("{} differs from {}".format((suite + ":").ljust(label_width), manifest_path(suite)))
	if len(changed) > 0:
		print("  Changed:")
		for entry in changed:
			print(format_entry(entry[0], entry[1], entry[2], width))
	if len(added) > 0:
		print("  Not in manifest:")
		for entry in added:
			print(format_entry(entry[0], entry[1], entry[2], width))
	if len(missing) > 0 and len(missing) == len(entries) - (1 if archive_name in known else 0):
		print("  None of the {} {} on disk. Run without --update to download {}.".format(len(missing), "file is" if len(missing) == 1 else "files are", "it" if len(missing) == 1 else "them"))
	elif len(missing) > 0:
		print("  Missing on disk:")
		for name in missing:
			print(name)
	if archive_name in known and (len(changed) > 0 or len(added) > 0):
		print("  Rebuild {} and update its line as well.".format(archive_name))
	print()
	return 0

def main():
	args   = [arg for arg in sys.argv[1:] if not arg.startswith("--")]
	flags  = [arg for arg in sys.argv[1:] if arg.startswith("--")]
	update = "--update" in flags
	for flag in flags:
		if flag != "--update":
			print("Unknown option {}".format(flag))
			return 1

	if len(args) < 1:
		print("Usage: {} <path to assets> [debug] [--update]".format(sys.argv[0]))
		return 1

	debug = len(args) >= 2 and args[1] == "debug"

	label_width = max(len(suite) + 1 for suite in TEST_SUITES)
	count_width = 1
	for suite in TEST_SUITES:
		entries = read_manifest(suite)
		if entries is None:
			return 2
		count_width = max(count_width, len(str(len(entries))))

	if update:
		print("Comparing local assets against the manifests, nothing will be downloaded or written.\n")
		for suite in TEST_SUITES:
			r = report_suite(os.path.join(args[0], suite), suite, label_width)
			if r != 0:
				return r
		return 0

	for suite in TEST_SUITES:
		base_path = os.path.join(args[0], suite)
		os.makedirs(base_path, exist_ok=True)
		r = sync_suite(base_path, suite, debug, label_width, count_width)
		if r != 0:
			print("\nIf you changed these assets on purpose, run with --update to list the manifest lines to use.")
			return r
		sys.stdout.flush()

	return 0

if __name__ == '__main__':
	sys.exit(main())
