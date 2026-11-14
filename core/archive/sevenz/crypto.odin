package archive_sevenz

import "base:runtime"
import "core:archive"
import "core:compress"
import "core:crypto"
import "core:crypto/aes"
import "core:crypto/sha2"
import "core:io"
import "core:slice"
import "core:sync"

@(private)
_aes_start :: proc(node: ^Node, properties: []u8) -> (err: Error) {
	d := node.decoder
	power     := 0
	salt_size := 0
	iv_size   := 0
	if len(properties) > 0 {
		b0 := properties[0]
		power = int(b0 & 0x3F)
		if b0 & 0xC0 == 0 {
			if len(properties) != 1 {
				return SevenZ_Error.Invalid_Folder
			}
		} else {
			if len(properties) < 2 {
				return SevenZ_Error.Invalid_Folder
			}
			b1 := properties[1]
			salt_size = int(b0 >> 7 & 1) + int(b1 >> 4)
			iv_size   = int(b0 >> 6 & 1) + int(b1 & 0x0F)
			if len(properties) != 2 + salt_size + iv_size {
				return SevenZ_Error.Invalid_Folder
			}
		}
	}
	if power > AES_POWER_MAX && power != AES_POWER_RAW {
		return archive.General_Error.Limit_Exceeded
	}
	if node.input_sizes[0] < 0 || node.input_sizes[0] % aes.BLOCK_SIZE != 0 {
		return SevenZ_Error.Invalid_Folder
	}
	if d.password == "" {
		return archive.General_Error.Encrypted
	}
	salt := properties[2:][:salt_size] if salt_size > 0 else nil
	key: [AES_KEY_SIZE]u8
	defer crypto.zero_explicit(&key, size_of(key))
	_aes_key(d.keys, d.password, power, salt, &key) or_return
	aes.init_ecb(&node.cipher, key[:])
	node.keyed = true
	node.iv    = {}
	if iv_size > 0 {
		copy(node.iv[:], properties[2 + salt_size:][:iv_size])
	}
	node.buffer = make([]u8, FILTER_BUFFER_SIZE, d.allocator) or_return
	return
}

@(private)
_aes_destroy :: proc(node: ^Node) {
	if node.keyed {
		aes.reset_ecb(&node.cipher)
		crypto.zero_explicit(&node.iv, size_of(node.iv))
		node.keyed = false
	}
}

@(private)
_cbc_decrypt :: proc(ctx: ^aes.Context_ECB, iv: ^[aes.BLOCK_SIZE]u8, data: []u8) {
	chain := iv^
	saved: [aes.BLOCK_SIZE]u8
	for offset := 0; offset + aes.BLOCK_SIZE <= len(data); offset += aes.BLOCK_SIZE {
		block := (^[aes.BLOCK_SIZE]u8)(&data[offset])
		saved = block^
		aes.decrypt_ecb(ctx, block[:], saved[:])
		block^ = block^ ~ chain
		chain = saved
	}
	iv^ = chain
}

@(private)
_aes_key :: proc(keys: ^Key_Cache, password: string, power: int, salt: []u8, key: ^[AES_KEY_SIZE]u8) -> (err: Error) {
	sync.mutex_lock(&keys.lock)
	defer sync.mutex_unlock(&keys.lock)

	encoded := _password_utf16(password, keys.allocator) or_return
	for &entry in keys.entries {
		if len(entry.password) > 0 && entry.power == power && slice.equal(entry.salt[:entry.salt_size], salt) && slice.equal(entry.password, encoded) {
			key^ = entry.key
			_secret_delete(encoded, keys.allocator)
			return
		}
	}
	if err = _derive_key(key, power, salt, encoded, keys.allocator); err != nil {
		_secret_delete(encoded, keys.allocator)
		return
	}
	slot := &keys.entries[keys.next]
	keys.next = (keys.next + 1) % KEY_CACHE_SIZE
	_cached_key_destroy(slot, keys.allocator)
	slot.password  = encoded
	slot.salt_size = copy(slot.salt[:], salt)
	slot.power     = power
	slot.key       = key^
	return
}

@(private)
_derive_key :: proc(key: ^[AES_KEY_SIZE]u8, power: int, salt, password: []u8, allocator: runtime.Allocator) -> (err: Error) {
	if power == AES_POWER_RAW {
		key^ = {}
		n := copy(key[:], salt)
		copy(key[n:], password)
		return
	}
	buf := make([]u8, len(salt) + len(password) + 8, allocator) or_return
	defer _secret_delete(buf, allocator)
	copy(buf, salt)
	copy(buf[len(salt):], password)
	counter := buf[len(buf) - 8:]
	ctx: sha2.Context_256
	sha2.init_256(&ctx)
	for _ in 0..<u64(1) << uint(power) {
		sha2.update(&ctx, buf)
		for &b in counter {
			b += 1
			if b != 0 {
				break
			}
		}
	}
	sha2.final(&ctx, key[:])
	return
}

@(private)
_password_utf16 :: proc(password: string, allocator: runtime.Allocator) -> (encoded: []u8, err: runtime.Allocator_Error) {
	out := make([dynamic]u8, 0, 2 * len(password) + 2, allocator) or_return
	defer {
		crypto.zero_explicit(raw_data(out), cap(out))
		delete(out)
	}
	_append_name(&out, transmute([]u8)password) or_return
	encoded = make([]u8, len(out) - 2, allocator) or_return
	copy(encoded, out[:])
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
_secret_delete :: proc(secret: []u8, allocator: runtime.Allocator) {
	if secret == nil {
		return
	}
	crypto.zero_explicit(raw_data(secret), len(secret))
	delete(secret, allocator)
}

@(private)
_cached_key_destroy :: proc(entry: ^Cached_Key, allocator: runtime.Allocator) {
	_secret_delete(entry.password, allocator)
	crypto.zero_explicit(entry, size_of(entry^))
}

@(private)
_key_cache_destroy :: proc(keys: ^Key_Cache) {
	for &entry in keys.entries {
		_cached_key_destroy(&entry, keys.allocator)
	}
	keys.next = 0
}

@(private)
_password_error :: proc(err: Error) -> Error {
	#partial switch e in err {
	case SevenZ_Error:
		return archive.General_Error.Wrong_Password
	case compress.Error:
		#partial switch c in e {
		case compress.General_Error:
			#partial switch c {
			case .Canceled, .Memory_Limit_Exceeded, .Allocation_Failed, .Incompatible_Options, .Unimplemented:
				return err
			}
		case io.Error, runtime.Allocator_Error:
			return err
		}
		return archive.General_Error.Wrong_Password
	}
	return err
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
_entry_password :: proc(sw: ^Writer, options: Entry_Options) -> (password: string, err: Error) {
	password = options.password.? or_else sw.password
	_check_password(password, sw.options.deterministic) or_return
	return
}

@(private)
_header_encrypted :: proc "contextless" (sw: ^Writer) -> bool {
	return sw.password != "" && !sw.options.unencrypted_header
}

@(private)
_writer_key :: proc(sw: ^Writer, password: string, key: ^[AES_KEY_SIZE]u8) -> (err: Error) {
	if !sw.salted {
		crypto.rand_bytes(sw.salt[:])
		sw.salted = true
	}
	if sw.cipher_buffer == nil {
		sw.cipher_buffer = make([]u8, CIPHER_BUFFER_SIZE, sw.allocator) or_return
	}
	return _aes_key(&sw.keys, password, sw.kdf_power, sw.salt[:], key)
}

@(private)
_aes_properties :: proc "contextless" (out: []u8, power: int, salt, iv: []u8) -> (size: int) {
	b0 := u8(power)
	b1 := u8(0)
	if len(salt) > 0 {
		b0 |= 0x80
		b1 |= u8(len(salt) - 1) << 4
	}
	if len(iv) > 0 {
		b0 |= 0x40
		b1 |= u8(len(iv) - 1)
	}
	out[0] = b0
	out[1] = b1
	size  = 2
	size += copy(out[size:], salt)
	size += copy(out[size:], iv)
	return
}

@(private)
_cipher_init :: proc(c: ^Pack_Cipher, key: ^[AES_KEY_SIZE]u8) {
	aes.init_ecb(&c.ctx, key[:])
	c.keyed = true
}

@(private)
_cipher_begin :: proc(c: ^Pack_Cipher, iv: ^[aes.BLOCK_SIZE]u8) {
	crypto.rand_bytes(iv[:])
	c.iv      = iv^
	c.block   = {}
	c.pending = 0
	c.plain   = 0
}

@(private)
_cipher_destroy :: proc(c: ^Pack_Cipher) {
	if c.keyed {
		aes.reset_ecb(&c.ctx)
	}
	crypto.zero_explicit(c, size_of(c^))
}

@(private)
_cbc_encrypt :: proc(ctx: ^aes.Context_ECB, iv: ^[aes.BLOCK_SIZE]u8, dst, src: []u8) {
	block: [aes.BLOCK_SIZE]u8
	chain := iv^
	for offset := 0; offset + aes.BLOCK_SIZE <= len(src); offset += aes.BLOCK_SIZE {
		block = (^[aes.BLOCK_SIZE]u8)(&src[offset])^ ~ chain
		aes.encrypt_ecb(ctx, chain[:], block[:])
		(^[aes.BLOCK_SIZE]u8)(&dst[offset])^ = chain
	}
	iv^ = chain
	crypto.zero_explicit(&block, size_of(block))
}

@(private)
_cipher_write :: proc(sink: ^Pack_Sink, p: []u8) -> (err: io.Error) {
	c   := sink.cipher
	out := sink.writer.cipher_buffer
	c.plain += i64(len(p))
	rest := p
	for len(rest) > 0 {
		n := 0
		if c.pending > 0 || len(rest) < aes.BLOCK_SIZE {
			k := copy(c.block[c.pending:], rest)
			c.pending += k
			rest = rest[k:]
			if c.pending < aes.BLOCK_SIZE {
				break
			}
			_cbc_encrypt(&c.ctx, &c.iv, out[:aes.BLOCK_SIZE], c.block[:])
			c.pending = 0
			n = aes.BLOCK_SIZE
		}
		whole := min(len(rest) &~ (aes.BLOCK_SIZE - 1), len(out) - n)
		_cbc_encrypt(&c.ctx, &c.iv, out[n:][:whole], rest[:whole])
		rest = rest[whole:]
		n += whole
		_sink_emit(sink, out[:n]) or_return
	}
	return nil
}

@(private)
_cipher_finish :: proc(sink: ^Pack_Sink) -> (err: io.Error) {
	c := sink.cipher
	if c.pending == 0 {
		return nil
	}
	for &b in c.block[c.pending:] {
		b = 0
	}
	out: [aes.BLOCK_SIZE]u8
	_cbc_encrypt(&c.ctx, &c.iv, out[:], c.block[:])
	c.pending = 0
	c.block   = {}
	return _sink_emit(sink, out[:])
}
