#+build windows
package test_vendor_lz4

import "core:c"
import "core:testing"
import lz4 "vendor:compress/lz4"

make_compressible :: proc(size: int) -> []byte {
	data := make([]byte, size)
	state := u32(0x2545F491)
	for &b, i in data {
		state ~= state << 13
		state ~= state >> 17
		state ~= state << 5
		b = i % 5 == 0 ? byte(state) : byte(i / 64)
	}
	return data
}

make_random :: proc(size: int) -> []byte {
	data := make([]byte, size)
	state := u32(0x9E3779B9)
	for &b in data {
		state ~= state << 13
		state ~= state >> 17
		state ~= state << 5
		b = byte(state)
	}
	return data
}

@(test)
test_version :: proc(t: ^testing.T) {
	testing.expect(t, lz4.versionNumber() >= 11_000)
	testing.expect(t, lz4.versionString() != nil)
	testing.expect_value(t, lz4.getVersion(), c.uint(lz4.FRAME_VERSION))
}

@(test)
test_block_round_trip :: proc(t: ^testing.T) {
	source := make_compressible(256 * 1024)
	defer delete(source)

	bound := lz4.compressBound(c.int(len(source)))
	testing.expect_value(t, bound, lz4.COMPRESSBOUND(c.int(len(source))))

	compressed := make([]byte, bound)
	defer delete(compressed)
	restored := make([]byte, len(source))
	defer delete(restored)

	fast := lz4.compress_default(raw_data(source), raw_data(compressed), c.int(len(source)), bound)
	testing.expect(t, fast > 0 && int(fast) < len(source))
	decoded := lz4.decompress_safe(raw_data(compressed), raw_data(restored), fast, c.int(len(restored)))
	testing.expect_value(t, int(decoded), len(source))
	testing.expect(t, string(restored) == string(source))

	for &b in restored { b = 0 }
	hc := lz4.compress_HC(raw_data(source), raw_data(compressed), c.int(len(source)), bound, lz4.CLEVEL_MAX)
	testing.expect(t, hc > 0 && hc <= fast)
	decoded = lz4.decompress_safe(raw_data(compressed), raw_data(restored), hc, c.int(len(restored)))
	testing.expect_value(t, int(decoded), len(source))
	testing.expect(t, string(restored) == string(source))
}

@(test)
test_block_acceleration :: proc(t: ^testing.T) {
	testing.expect_value(t, lz4.ACCELERATION_DEFAULT, 1)
	testing.expect_value(t, lz4.ACCELERATION_MAX, 65537)

	source := make_compressible(64 * 1024)
	defer delete(source)
	compressed := make([]byte, lz4.compressBound(c.int(len(source))))
	defer delete(compressed)

	for acceleration in ([?]c.int{-5, 0, 1, 8, 100_000}) {
		n := lz4.compress_fast(raw_data(source), raw_data(compressed), c.int(len(source)), c.int(len(compressed)), acceleration)
		testing.expectf(t, n > 0, "compress_fast failed with acceleration %v", acceleration)
	}
}

@(test)
test_block_bad_input :: proc(t: ^testing.T) {
	source := make_random(1024)
	defer delete(source)
	restored := make([]byte, len(source))
	defer delete(restored)

	n := lz4.decompress_safe(raw_data(source), raw_data(restored), c.int(len(source)), c.int(len(restored)))
	testing.expect(t, n < 0, "garbage was accepted as a compressed block")

	tiny: [4]byte
	n = lz4.compress_default(raw_data(source), &tiny[0], c.int(len(source)), c.int(len(tiny)))
	testing.expect_value(t, n, 0)
}

@(test)
test_block_dest_size :: proc(t: ^testing.T) {
	source := make_compressible(64 * 1024)
	defer delete(source)

	target := 4096
	compressed := make([]byte, target)
	defer delete(compressed)

	consumed := c.int(len(source))
	written := lz4.compress_destSize(raw_data(source), raw_data(compressed), &consumed, c.int(target))
	testing.expect(t, written > 0 && int(written) <= target)
	testing.expect(t, consumed > 0 && int(consumed) < len(source))

	restored := make([]byte, consumed)
	defer delete(restored)
	decoded := lz4.decompress_safe(raw_data(compressed), raw_data(restored), written, consumed)
	testing.expect_value(t, decoded, consumed)
	testing.expect(t, string(restored) == string(source[:consumed]))
}

@(test)
test_block_streaming_with_dictionary :: proc(t: ^testing.T) {
	dictionary := make_compressible(32 * 1024)
	defer delete(dictionary)
	source := make([]byte, 16 * 1024)
	defer delete(source)
	copy(source, dictionary[4096:])

	compressed := make([]byte, lz4.compressBound(c.int(len(source))))
	defer delete(compressed)
	plain := lz4.compress_default(raw_data(source), raw_data(compressed), c.int(len(source)), c.int(len(compressed)))

	stream := lz4.createStream()
	defer lz4.freeStream(stream)
	testing.expect(t, stream != nil)
	loaded := lz4.loadDict(stream, raw_data(dictionary), c.int(len(dictionary)))
	testing.expect_value(t, int(loaded), len(dictionary))
	with_dict := lz4.compress_fast_continue(stream, raw_data(source), raw_data(compressed), c.int(len(source)), c.int(len(compressed)), 1)
	testing.expect(t, with_dict > 0 && with_dict < plain, "dictionary didn't help")

	restored := make([]byte, len(source))
	defer delete(restored)
	decoded := lz4.decompress_safe_usingDict(raw_data(compressed), raw_data(restored), with_dict, c.int(len(restored)), raw_data(dictionary), c.int(len(dictionary)))
	testing.expect_value(t, int(decoded), len(source))
	testing.expect(t, string(restored) == string(source))
}

@(test)
test_hc_stream :: proc(t: ^testing.T) {
	testing.expect(t, size_of(lz4.streamHC_t) == lz4.STREAMHC_MINSIZE)
	testing.expect(t, lz4.STREAMHC_EXTSIZE > lz4.STREAMHC_MINSIZE)

	source := make_compressible(128 * 1024)
	defer delete(source)
	compressed := make([]byte, lz4.compressBound(c.int(len(source))))
	defer delete(compressed)

	stream := lz4.createStreamHC()
	defer lz4.freeStreamHC(stream)
	testing.expect(t, stream != nil)
	lz4.resetStreamHC_fast(stream, lz4.CLEVEL_DEFAULT)
	n := lz4.compress_HC_continue(stream, raw_data(source), raw_data(compressed), c.int(len(source)), c.int(len(compressed)))
	testing.expect(t, n > 0)

	restored := make([]byte, len(source))
	defer delete(restored)
	decoded := lz4.decompress_safe(raw_data(compressed), raw_data(restored), n, c.int(len(restored)))
	testing.expect_value(t, int(decoded), len(source))
	testing.expect(t, string(restored) == string(source))
}

frame_compress :: proc(t: ^testing.T, source: []byte, prefs: ^lz4.preferences_t) -> []byte {
	bound := lz4.compressFrameBound(c.size_t(len(source)), prefs)
	out := make([]byte, bound)
	n := lz4.compressFrame(raw_data(out), bound, raw_data(source), c.size_t(len(source)), prefs)
	if !testing.expectf(t, lz4.isError(n) == 0, "compressFrame failed: %v", lz4.getErrorName(n)) {
		delete(out)
		return nil
	}
	return out[:n]
}

frame_decompress :: proc(t: ^testing.T, frame: []byte, expected: int, options: ^lz4.decompressOptions_t = nil) -> []byte {
	context_: ^lz4.dctx
	testing.expect(t, lz4.isError(lz4.createDecompressionContext(&context_, lz4.FRAME_VERSION)) == 0)
	defer lz4.freeDecompressionContext(context_)

	out := make([]byte, expected)
	src_pos, dst_pos: int
	for src_pos < len(frame) {
		src_size: c.size_t = c.size_t(len(frame)) - c.size_t(src_pos)
		dst_size: c.size_t = c.size_t(len(out)) - c.size_t(dst_pos)
		hint := lz4.decompress(context_, raw_data(out[dst_pos:]), &dst_size, raw_data(frame[src_pos:]), &src_size, options)
		if !testing.expectf(t, lz4.isError(hint) == 0, "decompress failed: %v", lz4.getErrorName(hint)) {
			break
		}
		src_pos += int(src_size)
		dst_pos += int(dst_size)
		if hint == 0 {
			break
		}
	}
	testing.expect_value(t, dst_pos, expected)
	return out
}

@(test)
test_frame_one_shot :: proc(t: ^testing.T) {
	source := make_compressible(1024 * 1024 + 321)
	defer delete(source)

	prefs := lz4.preferences_t{
		frameInfo = {
			blockSizeID         = .max256KB,
			contentChecksumFlag = .contentChecksumEnabled,
			blockChecksumFlag   = .blockChecksumEnabled,
			contentSize         = c.ulonglong(len(source)),
		},
		compressionLevel = 3,
	}
	frame := frame_compress(t, source, &prefs)
	defer delete(frame)
	testing.expect(t, len(frame) > 0 && len(frame) < len(source))

	restored := frame_decompress(t, frame, len(source))
	defer delete(restored)
	testing.expect(t, string(restored) == string(source))

	plain := frame_compress(t, source, nil)
	defer delete(plain)
	restored_plain := frame_decompress(t, plain, len(source))
	defer delete(restored_plain)
	testing.expect(t, string(restored_plain) == string(source))
}

@(test)
test_frame_info :: proc(t: ^testing.T) {
	source := make_compressible(2_500_000)
	defer delete(source)

	prefs := lz4.preferences_t{
		frameInfo = {
			blockSizeID         = .max1MB,
			blockMode           = .blockIndependent,
			contentChecksumFlag = .contentChecksumEnabled,
			contentSize         = c.ulonglong(len(source)),
		},
	}
	frame := frame_compress(t, source, &prefs)
	defer delete(frame)

	header := lz4.headerSize(raw_data(frame), c.size_t(len(frame)))
	testing.expect(t, lz4.isError(header) == 0)
	testing.expect(t, header >= lz4.HEADER_SIZE_MIN && header <= lz4.HEADER_SIZE_MAX)

	context_: ^lz4.dctx
	testing.expect(t, lz4.isError(lz4.createDecompressionContext(&context_, lz4.FRAME_VERSION)) == 0)
	defer lz4.freeDecompressionContext(context_)

	info: lz4.frameInfo_t
	src_size := c.size_t(len(frame))
	hint := lz4.getFrameInfo(context_, &info, raw_data(frame), &src_size)
	testing.expect(t, lz4.isError(hint) == 0)
	testing.expect_value(t, info.blockSizeID, lz4.blockSizeID_t.max1MB)
	testing.expect_value(t, info.blockMode, lz4.blockMode_t.blockIndependent)
	testing.expect_value(t, info.contentChecksumFlag, lz4.contentChecksum_t.contentChecksumEnabled)
	testing.expect_value(t, int(info.contentSize), len(source))
	testing.expect_value(t, lz4.getBlockSize(.max1MB), c.size_t(1024 * 1024))
}

@(test)
test_frame_streaming :: proc(t: ^testing.T) {
	source := make_compressible(700_000)
	defer delete(source)

	prefs := lz4.preferences_t{
		frameInfo = {blockSizeID = .max64KB, contentChecksumFlag = .contentChecksumEnabled},
	}

	cctx_: ^lz4.cctx
	testing.expect(t, lz4.isError(lz4.createCompressionContext(&cctx_, lz4.FRAME_VERSION)) == 0)
	defer lz4.freeCompressionContext(cctx_)

	chunk := 50_000
	capacity := int(lz4.frame_compressBound(c.size_t(chunk), &prefs)) + lz4.HEADER_SIZE_MAX + lz4.ENDMARK_SIZE + lz4.CONTENT_CHECKSUM_SIZE
	out := make([dynamic]byte)
	defer delete(out)
	scratch := make([]byte, capacity)
	defer delete(scratch)

	n := lz4.compressBegin(cctx_, raw_data(scratch), c.size_t(len(scratch)), &prefs)
	testing.expect(t, lz4.isError(n) == 0)
	append(&out, ..scratch[:n])

	for offset := 0; offset < len(source); offset += chunk {
		end := min(offset + chunk, len(source))
		n = lz4.compressUpdate(cctx_, raw_data(scratch), c.size_t(len(scratch)), raw_data(source[offset:end]), c.size_t(end - offset), nil)
		testing.expectf(t, lz4.isError(n) == 0, "compressUpdate failed: %v", lz4.getErrorName(n))
		append(&out, ..scratch[:n])
	}
	n = lz4.flush(cctx_, raw_data(scratch), c.size_t(len(scratch)), nil)
	testing.expect(t, lz4.isError(n) == 0)
	append(&out, ..scratch[:n])
	n = lz4.compressEnd(cctx_, raw_data(scratch), c.size_t(len(scratch)), nil)
	testing.expect(t, lz4.isError(n) == 0)
	append(&out, ..scratch[:n])

	restored := frame_decompress(t, out[:], len(source))
	defer delete(restored)
	testing.expect(t, string(restored) == string(source))
}

@(test)
test_frame_dictionary :: proc(t: ^testing.T) {
	dictionary := make_compressible(32 * 1024)
	defer delete(dictionary)
	source := make([]byte, 20_000)
	defer delete(source)
	copy(source, dictionary[1000:])

	plain := frame_compress(t, source, nil)
	defer delete(plain)

	cdict := lz4.createCDict(raw_data(dictionary), c.size_t(len(dictionary)))
	testing.expect(t, cdict != nil)
	defer lz4.freeCDict(cdict)

	cctx_: ^lz4.cctx
	testing.expect(t, lz4.isError(lz4.createCompressionContext(&cctx_, lz4.FRAME_VERSION)) == 0)
	defer lz4.freeCompressionContext(cctx_)

	bound := lz4.compressFrameBound(c.size_t(len(source)), nil)
	frame := make([]byte, bound)
	defer delete(frame)
	n := lz4.compressFrame_usingCDict(cctx_, raw_data(frame), bound, raw_data(source), c.size_t(len(source)), cdict, nil)
	testing.expect(t, lz4.isError(n) == 0)
	testing.expect(t, int(n) < len(plain), "dictionary didn't help")

	dctx_: ^lz4.dctx
	testing.expect(t, lz4.isError(lz4.createDecompressionContext(&dctx_, lz4.FRAME_VERSION)) == 0)
	defer lz4.freeDecompressionContext(dctx_)

	restored := make([]byte, len(source))
	defer delete(restored)
	src_size := n
	dst_size := c.size_t(len(restored))
	hint := lz4.decompress_usingDict(dctx_, raw_data(restored), &dst_size, raw_data(frame), &src_size, raw_data(dictionary), c.size_t(len(dictionary)), nil)
	testing.expect(t, lz4.isError(hint) == 0)
	testing.expect_value(t, int(dst_size), len(source))
	testing.expect(t, string(restored) == string(source))
}

@(test)
test_frame_errors :: proc(t: ^testing.T) {
	source := make_compressible(10_000)
	defer delete(source)

	tiny: [8]byte
	n := lz4.compressFrame(&tiny[0], c.size_t(len(tiny)), raw_data(source), c.size_t(len(source)), nil)
	testing.expect(t, lz4.isError(n) != 0)
	testing.expect_value(t, lz4.getErrorCode(n), lz4.errorCodes.ERROR_dstCapacity_tooSmall)

	garbage := make_random(256)
	defer delete(garbage)
	context_: ^lz4.dctx
	testing.expect(t, lz4.isError(lz4.createDecompressionContext(&context_, lz4.FRAME_VERSION)) == 0)
	defer lz4.freeDecompressionContext(context_)
	out: [256]byte
	src_size := c.size_t(len(garbage))
	dst_size := c.size_t(len(out))
	hint := lz4.decompress(context_, &out[0], &dst_size, raw_data(garbage), &src_size, nil)
	testing.expect(t, lz4.isError(hint) != 0, "garbage was accepted as a frame")

	prefs := lz4.preferences_t{frameInfo = {contentChecksumFlag = .contentChecksumEnabled}}
	corrupt := frame_compress(t, source, &prefs)
	defer delete(corrupt)
	corrupt[len(corrupt) / 2] ~= 0xFF
	lz4.resetDecompressionContext(context_)
	out_big := make([]byte, len(source))
	defer delete(out_big)
	src_size = c.size_t(len(corrupt))
	dst_size = c.size_t(len(out_big))
	hint = lz4.decompress(context_, raw_data(out_big), &dst_size, raw_data(corrupt), &src_size, nil)
	testing.expect(t, lz4.isError(hint) != 0, "corruption wasn't detected")
}

@(test)
test_frame_multithreaded :: proc(t: ^testing.T) {
	testing.expect(t, lz4.getMaxNbWorkers() > 0, "lz4 was built without LZ4F_MULTITHREAD")

	source := make_compressible(9 * 1024 * 1024 + 12345)
	defer delete(source)

	prefs := lz4.preferences_t{
		frameInfo = {
			blockSizeID         = .max1MB,
			blockMode           = .blockIndependent,
			contentChecksumFlag = .contentChecksumEnabled,
		},
	}
	single := frame_compress(t, source, &prefs)
	defer delete(single)
	testing.expect(t, len(single) > 0 && len(single) < len(source))

	for workers in ([?]c.uint{1, 2, 4, 16}) {
		prefs.nbWorkers = workers
		multi := frame_compress(t, source, &prefs)
		defer delete(multi)
		testing.expectf(t, string(multi) == string(single), "%v workers: output differs from single-threaded output", workers)

		restored := frame_decompress(t, multi, len(source))
		defer delete(restored)
		testing.expectf(t, string(restored) == string(source), "%v workers: round trip changed the data", workers)
	}

	prefs.frameInfo.blockMode = .blockLinked
	prefs.nbWorkers = 4
	linked := frame_compress(t, source, &prefs)
	defer delete(linked)
	restored := frame_decompress(t, linked, len(source))
	defer delete(restored)
	testing.expect(t, string(restored) == string(source), "linked blocks with 4 workers: round trip changed the data")
}

@(test)
test_frame_multithreaded_streaming :: proc(t: ^testing.T) {
	source := make_compressible(5 * 1024 * 1024)
	defer delete(source)

	prefs := lz4.preferences_t{
		frameInfo = {blockSizeID = .max256KB, blockMode = .blockIndependent, contentChecksumFlag = .contentChecksumEnabled},
		nbWorkers = 4,
	}

	cctx_: ^lz4.cctx
	testing.expect(t, lz4.isError(lz4.createCompressionContext(&cctx_, lz4.FRAME_VERSION)) == 0)
	defer lz4.freeCompressionContext(cctx_)

	chunk := 300_000
	scratch := make([]byte, int(lz4.frame_compressBound(c.size_t(chunk), &prefs)) * 16)
	defer delete(scratch)
	out := make([dynamic]byte)
	defer delete(out)

	n := lz4.compressBegin(cctx_, raw_data(scratch), c.size_t(len(scratch)), &prefs)
	testing.expect(t, lz4.isError(n) == 0)
	append(&out, ..scratch[:n])

	for offset := 0; offset < len(source); offset += chunk {
		end := min(offset + chunk, len(source))
		n = lz4.compressUpdate(cctx_, raw_data(scratch), c.size_t(len(scratch)), raw_data(source[offset:end]), c.size_t(end - offset), nil)
		testing.expectf(t, lz4.isError(n) == 0, "compressUpdate failed: %v", lz4.getErrorName(n))
		append(&out, ..scratch[:n])
	}
	n = lz4.compressEnd(cctx_, raw_data(scratch), c.size_t(len(scratch)), nil)
	testing.expectf(t, lz4.isError(n) == 0, "compressEnd failed: %v", lz4.getErrorName(n))
	append(&out, ..scratch[:n])

	restored := frame_decompress(t, out[:], len(source))
	defer delete(restored)
	testing.expect(t, string(restored) == string(source))
}
