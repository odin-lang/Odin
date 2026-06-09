package pem

import "base:runtime"
import "core:bufio"
import "core:bytes"
import "core:crypto"
import "core:encoding/base64"
import "core:strings"

@(private)
BASE64_FULL_LINE_LENGTH :: 64
@(private)
BASE64_FULL_LINE_BYTES :: (BASE64_FULL_LINE_LENGTH / 4) * 3
@(private)
PREFIX_BEGIN : string : "-----BEGIN "
@(private)
PREFIX_END : string : "-----END "
@(private)
SUFFIX : string : "-----"
@(private)
LF :: "\n"
@(private)
PREEB_OVERHEAD :: len(PREFIX_BEGIN) + len(SUFFIX) + len(LF)
@(private)
POSTEB_OVERHEAD :: len(PREFIX_END) + len(SUFFIX)

// Block is a block of PEM encoded data.
Block :: struct {
	label: string,
	data: [dynamic]byte,
}

LABEL_CERTIFICATE :: "CERTIFICATE" // RFC 5280
LABEL_X509_CRL :: "X509_CRL" // RFC 5280
LABEL_CERTIFICATE_REQUEST :: "CERTIFICATE REQUEST" // RFC 2986
LABEL_PKCS7 :: "PKCS7" // RFC 2315
LABEL_CMS :: "CMS" // RFC 5652
LABEL_PRIVATE_KEY :: "PRIVATE KEY" // RFC 5208/ RFC 5958
LABEL_ENCRYPTED_PRIVATE_KEY :: "ENCRYPTED PRIVATE KEY" // RFC 5958
LABEL_ATTRIBUTE_CERTIFICATE :: "ATTRIBUTE CERTIFICATE" // RFC 5755
LABEL_PUBLIC_KEY :: "PUBLIC KEY" // RFC 5280

Decode_Error :: enum {
	None,
	Bad_Boundary,          // Invalid boundary line.
	Bad_Label,             // Invalid label in BEGIN/END boundary line.
	Bad_Data,              // Invalid base64 data.
	Label_Mismatch,        // Label in END boundary line does not match.
	Missing_End_Boundary,  // End of data without END boundary.
}

Error :: union #shared_nil {
	runtime.Allocator_Error,
	Decode_Error,
}

// decode decodes the first encountered PEM block, returning the resulting
// block, remaining data, and nil if and only if (⟺) the process was
// successful.
//
// Note: No PEM blocks will result in this procedure returning all nils,
// and is not considered an error.
@(require_results)
decode :: proc(data: []byte, allocator := context.allocator) -> (blk: ^Block, remaining: []byte, err: Error) {
	line: []byte
	remaining = data

	// Search for the first `preeb`.
	label: string
	found := false // Label is allowed to be empty.
	for len(remaining) > 0 {
		line, remaining = get_line(remaining)

		label, found, err = parse_eb(line, true)
		if err != nil {
			return nil, nil, err
		}
		if found {
			break
		}
	}
	if !found {
		return nil, nil, nil
	}

	// RFC 1421: Parse header block.
	// RFC 7468 (lax): Skip whitespace.

	// Initialize the block.
	blk = new(Block, allocator) or_return
	if blk.data, err = make([dynamic]byte, 0, 32, allocator); err != nil {
		free(blk, allocator)
		return nil, nil, err
	}
	if blk.label, err = strings.clone(label, allocator); err != nil {
		block_delete(blk)
		return nil, nil, err
	}

	// Parse the `strictbase64text`.
	l_buf: [BASE64_FULL_LINE_BYTES]byte
	defer crypto.zero_explicit(&l_buf, size_of(l_buf))
	base64text_loop: for len(remaining) > 0 {
		line, remaining = get_line(remaining)
		l := len(line)
		switch {
		case l == 0:
			block_delete(blk)
			return nil, nil, .Bad_Data
		case line[0] == '-':
			// Looks like we hit the `posteb`, break.
			break base64text_loop
		case l > BASE64_FULL_LINE_LENGTH || l & 3 != 0:
			// Padding is mandatory, so the line length will always
			// be a multiple of 4.
			block_delete(blk)
			return nil, nil, .Bad_Data
		}

		decoded, dec_err := base64.decode_into_buf(l_buf[:], transmute(string)(line))
		if dec_err != nil {
			block_delete(blk)
			return nil, nil, .Bad_Data
		}

		if _, err = append(&blk.data, ..decoded); err != nil {
			block_delete(blk)
			return nil, nil, err
		}

		// As `strictbase64text = *base64fullline strictbase64finl`,
		// if we did not have a full line, we must have reached
		// `strictbase64finl`.  Grab what should be the `posteb`
		// and break.
		if l < BASE64_FULL_LINE_LENGTH {
			line, remaining = get_line(remaining)
			break
		}
	}

	// Validate the `posteb`.
	post_label: string
	post_label, found, err = parse_eb(line, false)
	if err == nil {
		switch {
		case !found:
			err = .Missing_End_Boundary
		case label != post_label:
			err = .Label_Mismatch
		}
	}
	if err != nil {
		block_delete(blk)
		blk, remaining = nil, nil
	}

	return
}

// encode encodes the specified label and data into PEM format.
@(require_results)
encode :: proc(label: string, data: []byte, newline := false, allocator := context.allocator) -> (res: []byte, err: runtime.Allocator_Error) #optional_allocator_error {
	sanitize_sb := proc(sb: ^strings.Builder) {
		buf := sb[:]
		b, l := raw_data(buf), len(buf)
		crypto.zero_explicit(b, l)
		strings.builder_destroy(sb)
	}

	sb := strings.builder_make_none(allocator) or_return
	defer sanitize_sb(&sb)

	label_len := len(label)

	// Write `preeb`.
	n := strings.write_string(&sb, PREFIX_BEGIN)
	n += strings.write_string(&sb, label)
	n += strings.write_string(&sb, SUFFIX)
	n += strings.write_string(&sb, LF)
	if n != PREEB_OVERHEAD + label_len {
		return nil, .Out_Of_Memory
	}

	// RFC 1421: Write header block.

	// Write `base64text`.
	l: [BASE64_FULL_LINE_LENGTH]byte
	defer crypto.zero_explicit(&l, size_of(l))

	d := data
	for len(d) > 0 {
		n = min(len(d), BASE64_FULL_LINE_BYTES)
		encoded, _ := base64.encode_into_buf(l[:], d[:n])
		d = d[n:]

		expected_len := len(encoded) + len(LF)
		n = strings.write_bytes(&sb, encoded)
		n += strings.write_string(&sb, LF)
		if n != expected_len {
			return nil, .Out_Of_Memory
		}
	}

	// Write `posteb`.
	expected_len := POSTEB_OVERHEAD + label_len + (len(LF) if newline else 0)
	n = strings.write_string(&sb, PREFIX_END)
	n += strings.write_string(&sb, label)
	n += strings.write_string(&sb, SUFFIX)
	if newline {
		n += strings.write_string(&sb, LF)
	}
	if n != expected_len {
		return nil, .Out_Of_Memory
	}

	res = transmute([]byte)(strings.clone(strings.to_string(sb), allocator) or_return)

	return
}

// block_bytes returns a slice to the Block's data.
block_bytes :: proc(blk: ^Block) -> []byte {
	return blk.data[:]
}

// block_delete frees a Block returned from decode.
//
// Note: No allocator is specified as decode uses the same allocator
// for everything.
block_delete :: proc(blk: ^Block) {
	allocator := ((^runtime.Raw_Dynamic_Array)(&blk.data)).allocator

	delete(blk.label, allocator)
	sanitize_and_delete(blk.data)
	free(blk, allocator)
}

@(private)
get_line :: proc(data: []byte) -> (line, rest: []byte) {
	adv: int
	adv, line, _, _ = bufio.scan_lines(data, true)
	rest = data[adv:]

	return
}

@(private)
parse_eb :: proc(line: []byte, is_pre: bool) -> (label: string, found: bool, err: Error) {
	line := line

	prefix: string
	switch is_pre {
	case true:
		prefix = PREFIX_BEGIN
	case false:
		prefix = PREFIX_END
	}

	l := len(line)
	line = bytes.trim_prefix(line, transmute([]byte)(prefix))
	if len(line) == l {
		return "", false, nil
	}

	l = len(line)
	line = bytes.trim_suffix(line, transmute([]byte)(SUFFIX))
	if len(line) == l {
		return "", false, .Bad_Boundary
	}

	// labelchar  = %x21-2C / %x2E-7E ; any printable character,
	//                                ; except hyphen-minus
	// label      = [ labelchar *( ["-" / SP] labelchar ) ] ; empty ok
	l = len(line)
	line = bytes.trim(line, []byte{'-', ' '})
	if len(line) != l {
		return "", false, .Bad_Label
	}
	for b in line {
		// We already ruled out non-labelchar start/end, so this
		// allows ' '/'-'.
		if b < 0x20 || b > 0x7e {
			return "", false, .Bad_Label
		}
	}

	found = true
	label = transmute(string)(line)

	return
}

@(private)
sanitize_and_delete :: proc(data: [dynamic]byte) {
	b, l := raw_data(data), len(data)
	crypto.zero_explicit(b, l)

	delete(data)
}
