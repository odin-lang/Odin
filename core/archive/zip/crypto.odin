package archive_zip

import "base:runtime"
import "core:archive"
import "core:compress"
import "core:crypto"
import "core:crypto/aes"
import crypto_hash "core:crypto/hash"
import "core:crypto/hmac"
import "core:crypto/pbkdf2"
import "core:encoding/endian"
import "core:hash"
import "core:io"

ZIPCRYPTO_HEADER_SIZE :: 12
AES_EXTRA_SIZE        :: 7
AES_VERIFIER_SIZE     :: 2
AES_MAC_SIZE          :: 10
AES_ITERATIONS        :: 1000

Cipher_Kind :: enum u8 {
	None,
	ZipCrypto,
	AES,
}

Cipher :: struct {
	kind:    Cipher_Kind,
	keyed:   bool,
	done:    bool,
	result:  Error,
	keys:    [3]u32,
	block:   aes.Context_ECB,
	mac:     hmac.Context,
	counter: u64,
	stream:  [aes.BLOCK_SIZE]u8,
	used:    int,
	tag:     i64,
}

@(private)
_member_payload :: proc(r: ^Reader, rec: ^Record, header: Central_Header, extra: []u8, data_offset: i64, password: string, cipher: ^Cipher) -> (method: Method, section: Section, check_crc: bool, err: Error) {
	cipher^   = {}
	method    = header.method
	check_crc = true
	section   = {store = &r.store, offset = data_offset, end = data_offset + rec.compressed_size}
	if header.flags & {.Strong_Encryption, .Masked_Headers} != {} {
		return method, section, check_crc, archive.General_Error.Unsupported_Method
	}
	strength := 0
	if method == .AES {
		data, found := find_extra(extra, .AES)
		if !found || len(data) < AES_EXTRA_SIZE || data[2] != 'A' || data[3] != 'E' {
			return method, section, check_crc, Zip_Error.Invalid_Extra_Field
		}
		version := _u16(data, 0)
		strength = int(data[4])
		if version < 1 || version > 2 || strength < 1 || strength > 3 {
			return method, section, check_crc, Zip_Error.Invalid_Extra_Field
		}
		method    = Method(_u16(data, 5))
		check_crc = version == 1
	}
	if !method_supported(method) {
		return method, section, check_crc, archive.General_Error.Unsupported_Method
	}
	if strength == 0 && .Encrypted not_in header.flags {
		return
	}
	if password == "" {
		return method, section, check_crc, archive.General_Error.Encrypted
	}
	if strength > 0 {
		err = _aes_init(cipher, &section, strength, password)
	} else {
		err = _zipcrypto_init(cipher, &section, header, password)
	}
	return
}

@(private)
_aes_init :: proc(c: ^Cipher, s: ^Section, strength: int, password: string) -> (err: Error) {
	key_size  := 8 + 8 * strength
	salt_size := key_size / 2
	if s.end - s.offset < i64(salt_size + AES_VERIFIER_SIZE + AES_MAC_SIZE) {
		return Zip_Error.Truncated
	}
	head: [aes.KEY_SIZE_256 / 2 + AES_VERIFIER_SIZE]u8
	_store_read(s.store, head[:salt_size + AES_VERIFIER_SIZE], s.offset) or_return

	derived: [2 * aes.KEY_SIZE_256 + AES_VERIFIER_SIZE]u8
	defer crypto.zero_explicit(&derived, size_of(derived))
	keys := derived[:2 * key_size + AES_VERIFIER_SIZE]
	pbkdf2.derive(.Insecure_SHA1, transmute([]u8)password, head[:salt_size], AES_ITERATIONS, keys)
	if crypto.compare_constant_time(keys[2 * key_size:], head[salt_size:][:AES_VERIFIER_SIZE]) != 1 {
		return archive.General_Error.Wrong_Password
	}

	aes.init_ecb(&c.block, keys[:key_size])
	hmac.init(&c.mac, .Insecure_SHA1, keys[key_size:][:key_size])
	c.kind  = .AES
	c.keyed = true
	c.used  = aes.BLOCK_SIZE
	s.offset += i64(salt_size + AES_VERIFIER_SIZE)
	s.end    -= AES_MAC_SIZE
	c.tag     = s.end
	s.cipher  = c
	return nil
}

@(private)
_zipcrypto_init :: proc(c: ^Cipher, s: ^Section, header: Central_Header, password: string) -> (err: Error) {
	if s.end - s.offset < ZIPCRYPTO_HEADER_SIZE {
		return Zip_Error.Truncated
	}
	c.keys = {0x12345678, 0x23456789, 0x34567890}
	for b in transmute([]u8)password {
		_zipcrypto_update(&c.keys, b)
	}
	head: [ZIPCRYPTO_HEADER_SIZE]u8
	_store_read(s.store, head[:], s.offset) or_return
	_zipcrypto_decrypt(&c.keys, head[:])
	defer crypto.zero_explicit(&head, size_of(head))

	check := u8(header.crc32 >> 24)
	if .Data_Descriptor in header.flags {
		check = u8(header.dos_time >> 8)
	}
	if head[ZIPCRYPTO_HEADER_SIZE - 1] != check {
		crypto.zero_explicit(&c.keys, size_of(c.keys))
		return archive.General_Error.Wrong_Password
	}
	c.kind    = .ZipCrypto
	s.offset += ZIPCRYPTO_HEADER_SIZE
	s.cipher  = c
	return nil
}

@(private)
_zipcrypto_crc :: #force_inline proc "contextless" (crc: u32, b: u8) -> u32 {
	b := b
	return ~hash.crc32(([^]u8)(&b)[:1], ~crc)
}

@(private)
_zipcrypto_update :: #force_inline proc "contextless" (keys: ^[3]u32, b: u8) {
	keys[0] = _zipcrypto_crc(keys[0], b)
	keys[1] = (keys[1] + (keys[0] & 0xff)) * 134775813 + 1
	keys[2] = _zipcrypto_crc(keys[2], u8(keys[1] >> 24))
}

@(private)
_zipcrypto_decrypt :: proc "contextless" (keys: ^[3]u32, p: []u8) {
	for &b in p {
		t := (keys[2] | 2) & 0xffff
		b ~= u8((t * (t ~ 1)) >> 8)
		_zipcrypto_update(keys, b)
	}
}

@(private)
_aes_decrypt :: proc(c: ^Cipher, p: []u8) {
	hmac.update(&c.mac, p)
	_aes_ctr(c, p)
}

@(private)
_aes_encrypt :: proc(c: ^Cipher, p: []u8) {
	_aes_ctr(c, p)
	hmac.update(&c.mac, p)
}

@(private)
_aes_ctr :: proc(c: ^Cipher, p: []u8) {
	block: [aes.BLOCK_SIZE]u8
	rest := p
	for len(rest) > 0 && c.used < aes.BLOCK_SIZE {
		rest[0] ~= c.stream[c.used]
		c.used += 1
		rest = rest[1:]
	}
	for len(rest) >= aes.BLOCK_SIZE {
		c.counter += 1
		endian.unchecked_put_u64le(block[:8], c.counter)
		aes.encrypt_ecb(&c.block, c.stream[:], block[:])
		chunk := (^[aes.BLOCK_SIZE]u8)(raw_data(rest))
		chunk^ = chunk^ ~ c.stream
		rest = rest[aes.BLOCK_SIZE:]
	}
	for &b in rest {
		if c.used == aes.BLOCK_SIZE {
			c.counter += 1
			endian.unchecked_put_u64le(block[:8], c.counter)
			aes.encrypt_ecb(&c.block, c.stream[:], block[:])
			c.used = 0
		}
		b ~= c.stream[c.used]
		c.used += 1
	}
}

@(private)
_section_read :: proc(s: ^Section, p: []u8) -> (n: int, err: Error) {
	remaining := s.end - s.offset
	if remaining <= 0 {
		return 0, nil
	}
	n = int(min(i64(len(p)), remaining))
	_store_read(s.store, p[:n], s.offset) or_return
	if c := s.cipher; c != nil {
		switch c.kind {
		case .None:
		case .ZipCrypto:
			_zipcrypto_decrypt(&c.keys, p[:n])
		case .AES:
			_aes_decrypt(c, p[:n])
		}
	}
	s.offset += i64(n)
	return n, nil
}

@(private)
_section_read_full :: proc(s: ^Section, p: []u8) -> (err: Error) {
	if s.end - s.offset < i64(len(p)) {
		return Zip_Error.Truncated
	}
	_section_read(s, p) or_return
	return nil
}

@(private)
_cipher_finish :: proc(s: ^Section) -> (err: Error) {
	c := s.cipher
	if c == nil || c.kind != .AES {
		return nil
	}
	if c.done {
		return c.result
	}
	c.done = true
	buf: [4096]u8
	for s.offset < s.end {
		n := int(min(s.end - s.offset, i64(len(buf))))
		if c.result = _store_read(s.store, buf[:n], s.offset); c.result != nil {
			return c.result
		}
		hmac.update(&c.mac, buf[:n])
		s.offset += i64(n)
	}
	tag: [AES_MAC_SIZE]u8
	if c.result = _store_read(s.store, tag[:], c.tag); c.result != nil {
		return c.result
	}
	sum: [crypto_hash.MAX_DIGEST_SIZE]u8
	hmac.final(&c.mac, sum[:crypto_hash.DIGEST_SIZES[.Insecure_SHA1]])
	if crypto.compare_constant_time(sum[:AES_MAC_SIZE], tag[:]) != 1 {
		c.result = archive.General_Error.Authentication_Failed
	}
	return c.result
}

@(private)
_cipher_error :: proc(s: ^Section, err: Error) -> Error {
	if s.cipher == nil || s.cipher.kind != .AES {
		return err
	}
	if codec_err, is_codec := err.(compress.Error); is_codec && codec_err == compress.General_Error.Canceled {
		return err
	}
	if _cipher_finish(s) == archive.General_Error.Authentication_Failed {
		return archive.General_Error.Authentication_Failed
	}
	return err
}

@(private)
_cipher_destroy :: proc(c: ^Cipher) {
	if c.keyed {
		aes.reset_ecb(&c.block)
		hmac.reset(&c.mac)
	}
	crypto.zero_explicit(c, size_of(c^))
}

@(private)
_check_password :: proc(password: string, deterministic: bool) -> (err: Error) {
	if password == "" {
		return nil
	}
	if deterministic {
		return archive.General_Error.Incompatible_Options
	}
	if !crypto.HAS_RAND_BYTES {
		return archive.General_Error.Unsupported_Method
	}
	return nil
}

@(private)
_entry_password :: proc(zw: ^Writer, options: Entry_Options) -> (password: string, err: Error) {
	password = options.password.? or_else zw.password
	_check_password(password, zw.options.deterministic) or_return
	return
}

@(private)
_secret_clone :: proc(secret: string, allocator: runtime.Allocator) -> (clone: string, err: runtime.Allocator_Error) {
	if secret == "" {
		return "", nil
	}
	buf := make([]u8, len(secret), allocator) or_return
	copy(buf, secret)
	return string(buf), nil
}

@(private)
_secret_delete :: proc(secret: string, allocator: runtime.Allocator) {
	if secret == "" {
		return
	}
	crypto.zero_explicit(raw_data(secret), len(secret))
	delete(secret, allocator)
}

@(private)
_encrypt_begin :: proc(zw: ^Writer, c: ^Cipher, password: string) -> (err: Error) {
	_cipher_destroy(c)
	if password == "" {
		return nil
	}
	if zw.cipher_buffer == nil {
		zw.cipher_buffer = make([]u8, CIPHER_BUFFER_SIZE, zw.allocator) or_return
	}
	head: [AES_SALT_SIZE + AES_VERIFIER_SIZE]u8
	crypto.rand_bytes(head[:AES_SALT_SIZE])

	derived: [2 * aes.KEY_SIZE_256 + AES_VERIFIER_SIZE]u8
	defer crypto.zero_explicit(&derived, size_of(derived))
	pbkdf2.derive(.Insecure_SHA1, transmute([]u8)password, head[:AES_SALT_SIZE], AES_ITERATIONS, derived[:])
	copy(head[AES_SALT_SIZE:], derived[2 * aes.KEY_SIZE_256:])

	aes.init_ecb(&c.block, derived[:aes.KEY_SIZE_256])
	hmac.init(&c.mac, .Insecure_SHA1, derived[aes.KEY_SIZE_256:][:aes.KEY_SIZE_256])
	c.kind  = .AES
	c.keyed = true
	c.used  = aes.BLOCK_SIZE
	return _emit(zw, head[:])
}

@(private)
_encrypt_emit :: proc(zw: ^Writer, c: ^Cipher, p: []u8) -> (err: Error) {
	if c.kind != .AES {
		return _emit(zw, p)
	}
	if _, write_err := _encrypt_write(zw, c, p); write_err != nil {
		zw.err = write_err
		return write_err
	}
	return nil
}

@(private)
_encrypt_write :: proc(zw: ^Writer, c: ^Cipher, p: []u8) -> (written: int, err: io.Error) {
	for written < len(p) {
		n := copy(zw.cipher_buffer, p[written:])
		_aes_encrypt(c, zw.cipher_buffer[:n])
		k, write_err := io.write_full(zw.stream, zw.cipher_buffer[:n])
		zw.offset += i64(k)
		zw.end     = max(zw.end, zw.offset)
		written   += k
		if write_err != nil {
			return written, write_err
		}
	}
	return written, nil
}

@(private)
_encrypt_end :: proc(zw: ^Writer, c: ^Cipher) -> (err: Error) {
	if c.kind != .AES {
		return nil
	}
	sum: [crypto_hash.MAX_DIGEST_SIZE]u8
	hmac.final(&c.mac, sum[:crypto_hash.DIGEST_SIZES[.Insecure_SHA1]])
	return _emit(zw, sum[:AES_MAC_SIZE])
}
