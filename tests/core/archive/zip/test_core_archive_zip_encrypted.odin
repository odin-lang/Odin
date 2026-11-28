package test_core_archive_zip

import "core:archive"
import "core:archive/zip"
import "core:bytes"
import "core:io"
import "core:os"
import "core:strings"
import "core:testing"

Encrypted_Pair :: struct {
	encrypted: string,
	plain:     string,
	aes:       bool,
}

ENCRYPTED_PAIRS :: [?]Encrypted_Pair{
	{"archives/7z-aes128.zip",                  "archives/7z-lzma.zip",               true},
	{"archives/7z-aes192-stored.zip",           "archives/7z-lzma.zip",               true},
	{"archives/7z-aes256.zip",                  "archives/7z-lzma.zip",               true},
	{"archives/libarchive-mac-aes256.zip",      "archives/libarchive-mac-store.zip",  true},
	{"archives/libarchive-win-aes256.zip",      "archives/libarchive-win-store.zip",  true},
	{"archives/7z-zipcrypto.zip",               "archives/7z-lzma.zip",               false},
	{"archives/iz-zipcrypto.zip",               "archives/iz-store.zip",              false},
	{"archives/libarchive-mac-zipcrypto.zip",   "archives/libarchive-mac-store.zip",  false},
	{"archives/libarchive-win-zipcrypto.zip",   "archives/libarchive-win-store.zip",  false},
	{"archives/pkzip110-zipcrypto-implode.zip", "archives/7z-lzma.zip",               false},
	{"archives/pkzip110-zipcrypto-shrink.zip",  "archives/7z-lzma.zip",               false},
	{"archives/pkzip204-zipcrypto-deflate.zip", "archives/7z-lzma.zip",               false},
	{"archives/pkzip204-zipcrypto-store.zip",   "archives/7z-lzma.zip",               false},
}

WRONG_PASSWORDS :: [?]string{"odin", "ODIN ", "ODI", "password", "\x00"}

@(test)
test_encrypted_plain :: proc(t: ^testing.T) {
	for pair in ENCRYPTED_PAIRS {
		r, plain: zip.Reader
		if err := zip.open(&r, asset(pair.encrypted)); !testing.expectf(t, err == nil, "%s: open %v", pair.encrypted, err) {
			continue
		}
		defer zip.close(&r)
		if err := zip.open(&plain, asset(pair.plain)); !testing.expectf(t, err == nil, "%s: open %v", pair.plain, err) {
			continue
		}
		defer zip.close(&plain)

		it := zip.iterator_create(&r)
		defer zip.iterator_destroy(&it)
		compared := 0
		for fi in zip.iterate(&it) {
			if !fi.encrypted || fi.type != .Regular {
				continue
			}
			data, err := extract_to_bytes(&it, {password = PASSWORD})
			defer delete(data)
			if !testing.expectf(t, err == nil, "%s/%s: %v", pair.encrypted, fi.path, err) {
				continue
			}
			_, handle, ok, _ := zip.find(&plain, fi.path)
			if !testing.expectf(t, ok, "%s/%s: not in %s", pair.encrypted, fi.path, pair.plain) {
				continue
			}
			want := strings.builder_make()
			defer strings.builder_destroy(&want)
			plain_err := zip.extract(&plain, handle, strings.to_writer(&want))
			testing.expectf(t, plain_err == nil && bytes.equal(data[:], want.buf[:]), "%s/%s: differs from %s", pair.encrypted, fi.path, pair.plain)
			compared += 1
		}
		testing.expectf(t, compared > 0, "%s: nothing compared", pair.encrypted)
	}
}

@(test)
test_encrypted_wrong_password :: proc(t: ^testing.T) {
	for pair in ENCRYPTED_PAIRS {
		r: zip.Reader
		if err := zip.open(&r, asset(pair.encrypted)); !testing.expectf(t, err == nil, "%s: open %v", pair.encrypted, err) {
			continue
		}
		defer zip.close(&r)
		it := zip.iterator_create(&r)
		defer zip.iterator_destroy(&it)
		checked, rejected := 0, 0
		for fi in zip.iterate(&it) {
			if !fi.encrypted || fi.type != .Regular {
				continue
			}
			for password in WRONG_PASSWORDS {
				checked += 1
				data, err := extract_to_bytes(&it, {password = password})
				if err == archive.General_Error.Wrong_Password {
					rejected += 1
					testing.expectf(t, len(data) == 0, "%s/%s: %d bytes written with a wrong password", pair.encrypted, fi.path, len(data))
				} else {
					testing.expectf(t, !pair.aes && err != nil, "%s/%s with %q: %v", pair.encrypted, fi.path, password, err)
				}
				delete(data)
				_, open_err := zip.open_current(&it, {password = password})
				testing.expectf(t, open_err != nil || !pair.aes, "%s/%s with %q: open_current accepted", pair.encrypted, fi.path, password)
			}
		}
		testing.expectf(t, checked > 0 && rejected * 2 > checked, "%s: %d of %d wrong passwords rejected up front", pair.encrypted, rejected, checked)
	}
}

@(test)
test_encrypted_tamper :: proc(t: ^testing.T) {
	for pair in ENCRYPTED_PAIRS {
		if !pair.aes {
			continue
		}
		data, read_err := os.read_entire_file(asset(pair.encrypted), context.allocator)
		if !testing.expectf(t, read_err == nil, "%s: %v", pair.encrypted, read_err) {
			continue
		}
		defer delete(data)
		targets := encrypted_targets(t, data)
		defer delete(targets)
		testing.expectf(t, len(targets) > 0, "%s: no AES members with data", pair.encrypted)
		for target in targets {
			for spot in ([2]int{target.payload + target.payload_size / 2, target.payload + target.payload_size}) {
				data[spot] ~= 0x01
				tamper_check(t, pair.encrypted, target.path, data, target.index)
				data[spot] ~= 0x01
			}
		}
	}
}

@(test)
test_encrypted_unsupported :: proc(t: ^testing.T) {
	data, read_err := os.read_entire_file(asset("archives/pkzip204-zipcrypto-store.zip"), context.allocator)
	if !testing.expect_value(t, read_err, nil) {
		return
	}
	defer delete(data)
	for i := 0; i + 4 <= len(data); i += 1 {
		if data[i] != 'P' || data[i + 1] != 'K' {
			continue
		}
		switch {
		case data[i + 2] == 3 && data[i + 3] == 4:
			data[i + 6] |= 0x40
		case data[i + 2] == 1 && data[i + 3] == 2:
			data[i + 8] |= 0x40
		}
	}
	r: zip.Reader
	if err := zip.open(&r, data); !testing.expect_value(t, err, nil) {
		return
	}
	defer zip.close(&r)
	it := zip.iterator_create(&r)
	defer zip.iterator_destroy(&it)
	count := 0
	for fi in zip.iterate(&it) {
		count += 1
		out, err := extract_to_bytes(&it, {password = PASSWORD})
		delete(out)
		testing.expectf(t, err == archive.General_Error.Unsupported_Method && fi.encrypted && !fi.supported, "%s: %v", fi.path, err)
	}
	testing.expect_value(t, count, 5)
}

@(test)
test_encrypted_extract_all :: proc(t: ^testing.T) {
	base, dir_err := os.make_directory_temp("", "odin_zip_encrypted_*", context.temp_allocator)
	if dir_err == .Unsupported {
		return
	}
	if !testing.expect_value(t, dir_err, nil) {
		return
	}
	defer os.remove_all(base)

	for pair in ENCRYPTED_PAIRS {
		name := pair.encrypted[len("archives/"):]
		right, _ := os.join_path({base, "right", name}, context.temp_allocator)
		wrong, _ := os.join_path({base, "wrong", name}, context.temp_allocator)
		a, err := archive.open(asset(pair.encrypted))
		if !testing.expectf(t, err == nil, "%s: open %v", pair.encrypted, err) {
			continue
		}
		right_err := archive.extract_all(&a, right, {password = PASSWORD})
		wrong_err := archive.extract_all(&a, wrong, {password = "odin"})
		archive.close(&a)
		testing.expectf(t, right_err == nil || right_err == archive.General_Error.Skipped_Entry_Type, "%s: %v", pair.encrypted, right_err)
		testing.expectf(t, wrong_err != nil, "%s: wrong password extracted", pair.encrypted)
		testing.expectf(t, count_files(t, right) > 0, "%s: no files", pair.encrypted)
		testing.expectf(t, count_unencrypted(t, pair.encrypted) == count_files(t, wrong), "%s: files left by a wrong password", pair.encrypted)
	}
}

Encrypted_Target :: struct {
	index:        int,
	path:         string,
	payload:      int,
	payload_size: int,
}

encrypted_targets :: proc(t: ^testing.T, data: []u8) -> (targets: [dynamic]Encrypted_Target) {
	r: zip.Reader
	if err := zip.open(&r, data); !testing.expect_value(t, err, nil) {
		return
	}
	defer zip.close(&r)
	it := zip.iterator_create(&r)
	defer zip.iterator_destroy(&it)
	for fi, index in zip.iterate(&it) {
		entry := zip.current_entry(&it)
		if entry == nil || entry.method != .AES || fi.size == 0 {
			continue
		}
		salt  := 0
		extra := entry.central_extra
		for len(extra) >= 4 {
			id   := int(extra[0]) | int(extra[1]) << 8
			size := min(int(extra[2]) | int(extra[3]) << 8, len(extra) - 4)
			if id == 0x9901 && size >= 5 {
				salt = 4 + 4 * int(extra[8])
			}
			extra = extra[4 + size:]
		}
		payload := int(entry.data_offset) + salt + 2
		size    := int(fi.compressed_size) - salt - 2 - 10
		if size > 0 {
			append(&targets, Encrypted_Target{index, strings.clone(fi.path, context.temp_allocator), payload, size})
		}
	}
	return
}

tamper_check :: proc(t: ^testing.T, name, path: string, data: []u8, index: int) {
	r: zip.Reader
	if err := zip.open(&r, data); !testing.expectf(t, err == nil, "%s: open %v", name, err) {
		return
	}
	defer zip.close(&r)
	_, handle, found, _ := zip.find(&r, path)
	if !testing.expectf(t, found && handle.index == index, "%s/%s: find", name, path) {
		return
	}

	sink := strings.builder_make()
	defer strings.builder_destroy(&sink)
	err := zip.extract(&r, handle, strings.to_writer(&sink), {password = PASSWORD})
	testing.expectf(t, err == archive.General_Error.Authentication_Failed, "%s/%s: extract %v", name, path, err)

	m, open_err := zip.open_member(&r, handle, {password = PASSWORD})
	if !testing.expectf(t, open_err == nil, "%s/%s: open_member %v", name, path, open_err) {
		return
	}
	defer zip.close_member(m)
	streamed, read_err := read_stream(m)
	defer delete(streamed)
	testing.expectf(t, read_err != nil && read_err != io.Error.EOF, "%s/%s: member reader %v", name, path, read_err)

	a, archive_err := archive.open(data)
	if !testing.expectf(t, archive_err == nil, "%s: archive.open %v", name, archive_err) {
		return
	}
	defer archive.close(&a)
	buf: [dynamic]u8
	defer delete(buf)
	targets := [1]archive.Target{{path = path, to = &buf}}
	many_err := archive.extract_many(&a, targets[:], {password = PASSWORD})
	testing.expectf(t, many_err != nil && len(buf) == 0, "%s/%s: extract_many %v kept %d bytes", name, path, many_err, len(buf))
}

count_unencrypted :: proc(t: ^testing.T, name: string) -> (count: int) {
	r: zip.Reader
	if err := zip.open(&r, asset(name)); !testing.expect_value(t, err, nil) {
		return
	}
	defer zip.close(&r)
	it := zip.iterator_create(&r)
	defer zip.iterator_destroy(&it)
	for fi in zip.iterate(&it) {
		if fi.type == .Regular && !fi.encrypted {
			count += 1
		}
	}
	return
}
