package base32

// @note(zh): Encoding utility for Base32
// A secondary param can be used to supply a custom alphabet to
// @link(encode) and a matching decoding table to @link(decode). 
// If none is supplied it just uses the standard Base32 alphabet.
// Incase your specific version does not use padding, you may
// truncate it from the encoded output.

ENC_TABLE := [32]byte {
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
    'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 
    'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 
    'Y', 'Z', '2', '3', '4', '5', '6', '7'
};

PADDING :: '=';

DEC_TABLE := [?]u8 {
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
     0,  0, 26, 27, 28, 29, 30, 31,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 
    15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,  0,  0,  0,  0,  0,
     0,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 
    15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
};

encode :: proc(data: []byte, ENC_TBL := ENC_TABLE, allocator := context.allocator) -> string {
    out_length := (len(data) + 4) / 5 * 8;
    out := make([]byte, out_length);
    _encode(out, data);
    return string(out);
}

@private
_encode :: inline proc "contextless"(out, data: []byte, ENC_TBL := ENC_TABLE, allocator := context.allocator) {
    out := out;
    data := data;

    for len(data) > 0 {
        carry: byte;
        switch len(data) {
            case:
                out[7] = ENC_TABLE[data[4] & 0x1f];
                carry = data[4] >> 5;
                fallthrough;
            case 4:
                out[6] = ENC_TABLE[carry | (data[3] << 3) & 0x1f];
                out[5] = ENC_TABLE[(data[3] >> 2) & 0x1f];
                carry = data[3] >> 7;
                fallthrough;
            case 3:
                out[4] = ENC_TABLE[carry | (data[2] << 1) & 0x1f];
                carry = (data[2] >> 4) & 0x1f;
                fallthrough;
            case 2:
                out[3] = ENC_TABLE[carry | (data[1] << 4) & 0x1f];
                out[2] = ENC_TABLE[(data[1] >> 1) & 0x1f];
                carry = (data[1] >> 6) & 0x1f;
                fallthrough;
            case 1:
                out[1] = ENC_TABLE[carry | (data[0] << 2) & 0x1f];
                out[0] = ENC_TABLE[data[0] >> 3];
        }

        if len(data) < 5 {
            out[7] = byte(PADDING);
            if len(data) < 4 {
                out[6] = byte(PADDING);
                out[5] = byte(PADDING);
                if len(data) < 3 {
                    out[4] = byte(PADDING);
                    if len(data) < 2 {
                        out[3] = byte(PADDING);
                        out[2] = byte(PADDING);
                    }
                }
            }
            break;
        }
        data = data[5:];
        out = out[8:];
    }
}

decode :: proc(data: string, DEC_TBL := DEC_TABLE, allocator := context.allocator) -> []byte #no_bounds_check{
    if len(data) == 0 do return []byte{};

    outi := 0;
    olen := len(data);
    data := data;

    out := make([]byte, len(data) / 8 * 5, allocator);
    end := false;
    for len(data) > 0 && !end {
        dbuf : [8]byte;
        dlen := 8;

        for j := 0; j < 8; {
            if len(data) == 0 {
                dlen, end = j, true;
                break;
            }
            input := data[0];
            data = data[1:];
            if input == byte(PADDING) && j >= 2 && len(data) < 8 {
                assert(!(len(data) + j < 8 - 1), "Corrupted input");
                for k := 0; k < 8-1-j; k +=1 do assert(len(data) < k || data[k] == byte(PADDING), "Corrupted input");
                dlen, end = j, true;
                assert(dlen != 1 && dlen != 3 && dlen != 6, "Corrupted input");
                break;
            }
            dbuf[j] = DEC_TABLE[input];
            assert(dbuf[j] != 0xff, "Corrupted input");
            j += 1;
        }

        switch dlen {
            case 8:
                out[outi + 4] = dbuf[6] << 5 | dbuf[7];
                fallthrough;
            case 7:
                out[outi + 3] = dbuf[4] << 7 | dbuf[5] << 2 | dbuf[6] >> 3;
                fallthrough;
            case 5:
                out[outi + 2] = dbuf[3] << 4 | dbuf[4] >> 1;
                fallthrough;
            case 4:
                out[outi + 1] = dbuf[1] << 6 | dbuf[2] << 1 | dbuf[3] >> 4;
                fallthrough;
            case 2:
                out[outi + 0] = dbuf[0] << 3 | dbuf[1] >> 2;
        }
        outi += 5;
    }
    return out;
}