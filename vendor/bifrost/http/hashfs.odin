package bifrost_http

import "base:runtime"
import "core:crypto/sha2"
import "core:encoding/hex"
import os "core:os/os2"
import filepath "core:path/filepath"
import slashpath "core:path/slashpath"
import "core:strconv"
import "core:strings"
import "core:sync"

HashFS :: struct {
	Root: string,
	mu: sync.RW_Mutex,
	m: map[string]string,
	r: map[string][2]string,
}

hashfs_destroy :: proc(fsys: ^HashFS) {
	if fsys == nil {
		return
	}
	for k in fsys.m {
		hashfs_free_string(k)
	}
	for k, pair in fsys.r {
		hashfs_free_string(k)
		hashfs_free_string(pair[1])
	}
	delete(fsys.m)
	delete(fsys.r)
	hashfs_free_string(fsys.Root)
	fsys.Root = ""
	fsys.m = nil
	fsys.r = nil
}

hashfs_new :: proc(root: string) -> HashFS {
	cleaned := root
	if cleaned == "" {
		cleaned = "."
	}
	cleaned = filepath.clean(cleaned, allocator = context.allocator)
	return HashFS{
		Root = cleaned,
		m = make(map[string]string),
		r = make(map[string][2]string),
	}
}

hashfs_free_string :: proc(s: string) {
	if len(s) == 0 {
		return
	}
	buf := transmute([]u8)s
	delete(buf)
}

hashfs_fullpath :: proc(fsys: ^HashFS, name: string, allocator := context.allocator) -> string {
	if fsys == nil {
		return name
	}
	root := fsys.Root
	if root == "" || root == "." {
		return name
	}
	return filepath.join({root, name}, allocator = allocator)
}

hashfs_hash_name :: proc(fsys: ^HashFS, name: string) -> string {
	if fsys == nil || name == "" {
		return name
	}
	if sync.shared_guard(&fsys.mu) {
		if cached, ok := fsys.m[name]; ok && cached != "" {
			return cached
		}
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	fullpath := hashfs_fullpath(fsys, name, context.temp_allocator)
	data, err := os.read_entire_file_from_path(fullpath, context.temp_allocator)
	if err != nil {
		return name
	}

	ctx: sha2.Context_256
	sha2.init_256(&ctx)
	sha2.update(&ctx, data)
	digest: [sha2.DIGEST_SIZE_256]u8
	sha2.final(&ctx, digest[:])

	hash_bytes := hex.encode(digest[:], context.allocator)
	hashhex := string(hash_bytes)
	hashname := hashfs_format_name(name, hashhex, allocator = context.allocator)
	if hashname == "" {
		return name
	}

	name_copy := name
	if cloned, cerr := strings.clone(name, context.allocator); cerr == nil {
		name_copy = cloned
	}

	if sync.guard(&fsys.mu) {
		fsys.m[name_copy] = hashname
		fsys.r[hashname] = {name_copy, hashhex}
	}

	return hashname
}

hashfs_format_name :: proc(filename, hash: string, allocator := context.allocator) -> string {
	if filename == "" {
		return ""
	}
	if hash == "" {
		return filename
	}

	dir, base := slashpath.split(filename)
	i := strings.index_byte(base, '.')

	if i >= 0 {
		hashed, err := strings.join({base[:i], "-", hash, base[i:]}, "", allocator)
		if err != nil {
			return filename
		}
		out := slashpath.join({dir, hashed}, allocator)
		if allocator == context.allocator {
			hashfs_free_string(hashed)
		}
		return out
	}

	hashed, err := strings.join({base, "-", hash}, "", allocator)
	if err != nil {
		return filename
	}
	out := slashpath.join({dir, hashed}, allocator)
	if allocator == context.allocator {
		hashfs_free_string(hashed)
	}
	return out
}

hashfs_parse_name :: proc(filename: string, allocator := context.allocator) -> (base, hash: string) {
	if filename == "" {
		return "", ""
	}

	dir, base_name := slashpath.split(filename)
	pre := base_name
	ext := ""
	if i := strings.index_byte(base_name, '.'); i >= 0 {
		pre = base_name[:i]
		ext = base_name[i:]
	}

	if len(pre) < 65 || pre[len(pre)-65] != '-' {
		return filename, ""
	}
	hash = pre[len(pre)-64:]
	for i in 0..<len(hash) {
		ch := hash[i]
		if (ch < '0' || ch > '9') && (ch < 'a' || ch > 'f') {
			return filename, ""
		}
	}

	base_join, err := strings.join({pre[:len(pre)-65], ext}, "", allocator)
	if err != nil {
		return filename, ""
	}
	out := slashpath.join({dir, base_join}, allocator)
	if allocator == context.allocator {
		hashfs_free_string(base_join)
	}
	return out, hash
}

hashfs_parse_name_cached :: proc(fsys: ^HashFS, filename: string, allocator := context.allocator) -> (base, hash: string) {
	if fsys != nil {
		if sync.shared_guard(&fsys.mu) {
			if cached, ok := fsys.r[filename]; ok {
				return cached[0], cached[1]
			}
		}
	}
	return hashfs_parse_name(filename, allocator)
}

hashfs_open :: proc(fsys: ^HashFS, name: string) -> (f: ^os.File, hash: string, err: os.Error) {
	if fsys == nil {
		return nil, "", .Invalid_Path
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	resolved := name
	base, parsed_hash := hashfs_parse_name_cached(fsys, name, context.temp_allocator)
	if parsed_hash != "" && hashfs_hash_name(fsys, base) == name {
		resolved = base
	}
	fullpath := hashfs_fullpath(fsys, resolved, context.temp_allocator)
	f, err = os.open(fullpath, {.Read})
	hash = parsed_hash
	return
}

hashfs_serve :: proc(fsys: ^HashFS, req: ^Request, res: ^ResponseWriter) {
	if fsys == nil || req == nil || res == nil {
		return
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	target := req.Target
	if idx := strings.index_byte(target, '?'); idx >= 0 {
		target = target[:idx]
	}
	if idx := strings.index_byte(target, '#'); idx >= 0 {
		target = target[:idx]
	}
	if target == "" {
		target = "/"
	}

	filename := slashpath.clean(target, allocator = context.temp_allocator)
	if filename == "/" {
		filename = "."
	} else {
		filename = strings.trim_left(filename, "/")
		if filename == "" {
			filename = "."
		}
	}

	f, hash, err := hashfs_open(fsys, filename)
	if err == .Not_Exist {
		res.Status = Status_Not_Found
		response_write_string(res, "404 page not found")
		response_end(res)
		return
	}
	if err != nil {
		res.Status = Status_Internal_Server_Error
		response_write_string(res, "500 Internal Server Error")
		response_end(res)
		return
	}
	defer os.close(f)

	fi, ferr := os.fstat(f, context.temp_allocator)
	if ferr != nil {
		res.Status = Status_Internal_Server_Error
		response_write_string(res, "500 Internal Server Error")
		response_end(res)
		return
	}
	if fi.type == os.File_Type.Directory {
		res.Status = Status_Forbidden
		response_write_string(res, "403 Forbidden")
		response_end(res)
		return
	}

	if hash != "" {
		header_set(&res.Header, "cache-control", "public, max-age=31536000")
		etag, _ := strings.join({"\"", hash, "\""}, "", context.temp_allocator)
		header_set(&res.Header, "etag", etag)
	}

	len_buf: [32]u8
		header_set(&res.Header, "content-length", strconv.write_int(len_buf[:], fi.size, 10))
	if strings.equal_fold(req.Method, "HEAD") {
		res.Status = Status_OK
		response_end(res)
		return
	}

	data, rerr := os.read_entire_file_from_file(f, context.temp_allocator)
	if rerr != nil {
		res.Status = Status_Internal_Server_Error
		response_write_string(res, "500 Internal Server Error")
		response_end(res)
		return
	}
	res.Status = Status_OK
	response_write(res, data)
	response_end(res)
}
