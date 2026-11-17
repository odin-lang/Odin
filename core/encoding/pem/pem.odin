package pem

import "base:runtime"
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
LABEL_X509_CRL :: "X509 CRL" // RFC 5280
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
// Lines before the block that start with "-----BEGIN " but are not a
// valid boundary are skipped.  If no valid block follows, the error from
// the first such line is returned.
//
// Note: No PEM blocks will result in this procedure returning all nils,
// and is not considered an error.
@(require_results)
decode :: proc(data: []byte, allocator := context.allocator) -> (blk: ^Block, remaining: []byte, err: Error) {
	line: []byte
	rest := data

	// Search for the first `preeb`.
	label: string
	found := false // Label is allowed to be empty.
	for len(rest) > 0 {
		line, rest = get_line(rest)

		eb_err: Error
		label, found, eb_err = parse_eb(line, true)
		if found {
			break
		}
		if err == nil {
			err = eb_err
		}
	}
	if !found {
		return nil, nil, err
	}
	err = nil

	// RFC 1421: Parse header block.
	// RFC 7468 (lax): Skip whitespace.

	// Parse the `strictbase64text`.
	body := rest
	out_len := 0
	base64text_loop: for {
		if len(rest) == 0 {
			return nil, nil, .Missing_End_Boundary
		}
		body_end := len(body) - len(rest)
		line, rest = get_line(rest)
		l := len(line)
		switch {
		case l == 0:
			return nil, nil, .Bad_Data
		case line[0] == '-':
			// Looks like we hit the `posteb`, break.
			body = body[:body_end]
			break base64text_loop
		case l > BASE64_FULL_LINE_LENGTH || l & 3 != 0:
			// Padding is mandatory, so the line length will always
			// be a multiple of 4.
			return nil, nil, .Bad_Data
		}

		padding := 0
		if line[l - 1] == '=' {
			padding = 2 if line[l - 2] == '=' else 1
		}
		out_len += l / 4 * 3 - padding

		// As `strictbase64text = *base64fullline strictbase64finl`,
		// a line that is shorter than a full line, or that ends in
		// padding, must be `strictbase64finl`.  Grab what should be
		// the `posteb` and break.
		if l < BASE64_FULL_LINE_LENGTH || padding > 0 {
			body = body[:len(body) - len(rest)]
			line, rest = get_line(rest)
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
		return nil, nil, err
	}

	// Initialize the block.
	blk = new(Block, allocator) or_return
	if blk.data, err = make([dynamic]byte, out_len, allocator); err != nil {
		free(blk, allocator)
		return nil, nil, err
	}
	if blk.label, err = strings.clone(label, allocator); err != nil {
		block_delete(blk)
		return nil, nil, err
	}

	dst := blk.data[:]
	for len(body) > 0 {
		line, body = get_line(body)
		decoded, dec_err := base64.decode_into_buf(dst, transmute(string)(line), options = {.Strict})
		if dec_err != nil {
			block_delete(blk)
			return nil, nil, .Bad_Data
		}
		dst = dst[len(decoded):]
	}

	return blk, rest, nil
}

// encode encodes the specified label and data into PEM format.  It
// returns .Bad_Label if the label does not follow the RFC 7468 label
// grammar.  With newline set (the default), the output ends with a
// newline after the END line, as the strict format requires.
@(require_results)
encode :: proc(label: string, data: []byte, newline := true, allocator := context.allocator) -> (res: []byte, err: Error) {
	full_lines := len(data) / BASE64_FULL_LINE_BYTES
	tail := len(data) % BASE64_FULL_LINE_BYTES
	if full_lines > (max(int) - 2 * (BASE64_FULL_LINE_LENGTH + len(LF))) / (BASE64_FULL_LINE_LENGTH + len(LF)) {
		return nil, .Out_Of_Memory
	}
	body_len := full_lines * (BASE64_FULL_LINE_LENGTH + len(LF))
	if tail > 0 {
		body_len += (tail + 2) / 3 * 4 + len(LF)
	}
	overhead := PREEB_OVERHEAD + POSTEB_OVERHEAD + len(LF)
	if len(label) > (max(int) - overhead - body_len) / 2 {
		return nil, .Out_Of_Memory
	}
	out_len := PREEB_OVERHEAD + POSTEB_OVERHEAD + 2 * len(label) + body_len
	if newline {
		out_len += len(LF)
	}

	if !valid_label(transmute([]byte)(label)) {
		return nil, .Bad_Label
	}

	res = make([]byte, out_len, allocator) or_return

	// Write `preeb`.
	n := copy(res, PREFIX_BEGIN)
	n += copy(res[n:], label)
	n += copy(res[n:], SUFFIX)
	n += copy(res[n:], LF)

	// RFC 1421: Write header block.

	// Write `base64text`.
	d := data
	for len(d) > 0 {
		chunk := min(len(d), BASE64_FULL_LINE_BYTES)
		encoded, _ := base64.encode_into_buf(res[n:], d[:chunk])
		d = d[chunk:]
		n += len(encoded)
		n += copy(res[n:], LF)
	}

	// Write `posteb`.
	n += copy(res[n:], PREFIX_END)
	n += copy(res[n:], label)
	n += copy(res[n:], SUFFIX)
	if newline {
		n += copy(res[n:], LF)
	}
	assert(n == out_len)

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
	if blk == nil {
		return
	}

	allocator := ((^runtime.Raw_Dynamic_Array)(&blk.data)).allocator

	delete(blk.label, allocator)
	sanitize_and_delete(blk.data)
	free(blk, allocator)
}

@(private)
get_line :: proc(data: []byte) -> (line, rest: []byte) {
	for b, i in data {
		switch b {
		case '\n':
			return data[:i], data[i + 1:]
		case '\r':
			if i + 1 < len(data) && data[i + 1] == '\n' {
				return data[:i], data[i + 2:]
			}
			return data[:i], data[i + 1:]
		}
	}

	return data, data[len(data):]
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

	if len(line) < len(prefix) || transmute(string)(line[:len(prefix)]) != prefix {
		return "", false, nil
	}
	line = line[len(prefix):]

	if len(line) < len(SUFFIX) || transmute(string)(line[len(line) - len(SUFFIX):]) != SUFFIX {
		return "", false, .Bad_Boundary
	}
	line = line[:len(line) - len(SUFFIX)]

	// labelchar  = %x21-2C / %x2E-7E ; any printable character,
	//                                ; except hyphen-minus
	// label      = [ labelchar *( ["-" / SP] labelchar ) ] ; empty ok
	if !valid_label(line) {
		return "", false, .Bad_Label
	}

	found = true
	label = transmute(string)(line)

	return
}

@(private)
valid_label :: proc(label: []byte) -> bool {
	for b, i in label {
		if b == '-' || b == ' ' {
			if i == 0 || i == len(label) - 1 || label[i - 1] == '-' || label[i - 1] == ' ' {
				return false
			}
		} else if b < 0x21 || b > 0x7e {
			return false
		}
	}

	return true
}

@(private)
sanitize_and_delete :: proc(data: [dynamic]byte) {
	b, l := raw_data(data), len(data)
	crypto.zero_explicit(b, l)

	delete(data)
}
