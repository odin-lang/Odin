package bindgen

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"

// Extract from start (included) to end (excluded) offsets
extract_string :: proc(data : ^ParserData, startOffset : u32, endOffset : u32) -> string {
    return strings.string_from_ptr(&data.bytes[startOffset], cast(int) (endOffset - startOffset));
}

// Peek the end offset of the next token
peek_token_end :: proc(data : ^ParserData) -> u32 {
    offset : u32;

    for true {
        eat_whitespaces_and_comments(data);
        if data.offset >= data.bytesLength {
            return data.bytesLength;
        }
        offset = data.offset;

        // Identifier
        if (data.bytes[offset] >= 'a' && data.bytes[offset] <= 'z') ||
            (data.bytes[offset] >= 'A' && data.bytes[offset] <= 'Z') ||
            (data.bytes[offset] == '_') {
            offset += 1;
            for (data.bytes[offset] >= 'a' && data.bytes[offset] <= 'z') ||
                (data.bytes[offset] >= 'A' && data.bytes[offset] <= 'Z') ||
                (data.bytes[offset] >= '0' && data.bytes[offset] <= '9') ||
                (data.bytes[offset] == '_') {
                offset += 1;
            }
        }
        if offset != data.offset {
            // Nothing to do: we found an identifier
        } // Number literal
        else if (data.bytes[offset] >= '0' && data.bytes[offset] <= '9') {
            offset += 1;
            // Hexademical literal
            if data.bytes[offset - 1] == '0' && data.bytes[offset] == 'x' {
                offset += 1;
                for (data.bytes[offset] >= '0' && data.bytes[offset] <= '9') ||
                    (data.bytes[offset] >= 'a' && data.bytes[offset] <= 'f') ||
                    (data.bytes[offset] >= 'A' && data.bytes[offset] <= 'F') {
                    offset += 1;
                }
            } // Basic number literal
            else {
                for (data.bytes[offset] >= '0' && data.bytes[offset] <= '9') ||
                    data.bytes[offset] == '.' {
                    offset += 1;
                }

                if (data.bytes[offset] == 'e' || data.bytes[offset] == 'E') {
                    offset += 1;
                    if data.bytes[offset] == '-' {
                        offset += 1;
                    }
                }

                for (data.bytes[offset] >= '0' && data.bytes[offset] <= '9') {
                    offset += 1;
                }
            }

            // Number suffix?
            for (data.bytes[offset] == 'u' || data.bytes[offset] == 'U') ||
                (data.bytes[offset] == 'l' || data.bytes[offset] == 'L') ||
                (data.bytes[offset] == 'f') {
                offset += 1;
            }
        } // String literal
        else if data.bytes[offset] == '"' {
            offset += 1;
            for data.bytes[offset-1] == '\\' || data.bytes[offset] != '"' {
                offset += 1;
            }
            offset += 1;
        } // Possible shifts
        else if data.bytes[offset] == '<' || data.bytes[offset] == '>' {
            offset += 1;
            if data.bytes[offset] == data.bytes[offset-1] {
                offset += 1;
            }
        } // Single character
        else {
            offset += 1;
        }

        token := extract_string(data, data.offset, offset);

        // Ignore __attribute__
        if token == "__attribute__" {
            print_warning("__attribute__ is ignored.");

            for data.bytes[offset] != '(' {
                offset += 1;
            }

            parenthesesCount := 1;
            for true {
                offset += 1;
                if data.bytes[offset] == '(' do parenthesesCount += 1;
                else if data.bytes[offset] == ')' do parenthesesCount -= 1;
                if parenthesesCount == 0 do break;
            }
            offset += 1;

            data.offset = offset;
        } // Ignore certain keywords
        else if (token == "inline" || token == "__inline" || token == "static"
                || token == "restrict" || token == "__restrict"
                || token == "volatile"
                || token == "__extension__") {
            data.offset = offset;
        } // Ignore ignored tokens ;)
        else {
            for ignoredToken in data.options.ignoredTokens {
                if token == ignoredToken {
                    data.offset = offset;
                    break;
                }
            }
        }

        if data.offset != offset {
            break;
        }
    }

    return offset;
}

// Peek the next token (just eating whitespaces and comment)
peek_token :: proc(data : ^ParserData) -> string {
    tokenEnd := peek_token_end(data);
    if tokenEnd == data.bytesLength {
        return "EOF";
    }
    return extract_string(data, data.offset, tokenEnd);
}

// Find the end of the define directive (understanding endline backslashes)
// @note Tricky cases like comments hiding a backslash effect are not handled.
peek_define_end :: proc(data : ^ParserData) -> u32 {
    defineEndOffset := data.offset;
    for data.bytes[defineEndOffset-1] == '\\' || data.bytes[defineEndOffset] != '\n'  {
        defineEndOffset += 1;
    }
    return defineEndOffset;
}

eat_comment :: proc(data : ^ParserData) {
    if data.offset >= data.bytesLength || data.bytes[data.offset] != '/' {
        return;
    }

    // Line comment
    if data.bytes[data.offset + 1] == '/' {
        eat_line(data);
    } // Range comment
    else if data.bytes[data.offset + 1] == '*' {
        data.offset += 2;
        for data.bytes[data.offset] != '*' || data.bytes[data.offset + 1] != '/' {
            data.offset += 1;
        }
        data.offset += 2;
    }
}

// Eat whitespaces
eat_whitespaces :: proc(data : ^ParserData) {
    // Effective whitespace
    for data.offset < data.bytesLength &&
        (data.bytes[data.offset] == ' ' || data.bytes[data.offset] == '\t' ||
        data.bytes[data.offset] == '\r' || data.bytes[data.offset] == '\n') {
        if data.bytes[data.offset] == '\n' && data.bytes[data.offset] != '\\' {
            data.foundFullReturn = true;
        }
        data.offset += 1;
    }
}

// Removes whitespaces and comments
eat_whitespaces_and_comments :: proc(data : ^ParserData) {
    startOffset : u32 = 0xFFFFFFFF;
    for startOffset != data.offset {
        startOffset = data.offset;
        eat_whitespaces(data);
        eat_comment(data);
    }
}

// Eat full line
eat_line :: proc(data : ^ParserData) {
    for ; data.bytes[data.offset] != '\n'; data.offset += 1 {
    }
}

// Eat a line, and repeat if it ends with a backslash
eat_define_lines :: proc(data : ^ParserData) {
    for data.bytes[data.offset-1] == '\\' || data.bytes[data.offset] != '\n'  {
        data.offset += 1;
    }
}

// Eat next token
eat_token :: proc(data : ^ParserData) {
    data.offset = peek_token_end(data);
}

// Eat next token
check_and_eat_token :: proc(data : ^ParserData, expectedToken : string, loc := #caller_location) {
    token := peek_token(data);
    if token != expectedToken {
        print_error(data, loc, "Expected ", expectedToken, " but found ", token, ".");
    }
    data.offset += cast(u32) len(token);
}

// Check whether the next token is outside #define range
is_define_end :: proc(data : ^ParserData) -> bool {
    defineEnd := peek_define_end(data);
    tokenEnd := peek_token_end(data);

    return (defineEnd < tokenEnd);
}

// Check if the current #define is a macro definition
is_define_macro :: proc(data : ^ParserData) -> bool {
    startOffset := data.offset;
    defer data.offset = startOffset;

    token := parse_any(data);
    if token != "(" do return false;

    // Find the other parenthesis
    parenthesesCount := 1;
    for parenthesesCount != 0 {
        token = parse_any(data);
        if token == "(" do parenthesesCount += 1;
        else if token == ")" do parenthesesCount -= 1;
    }

    // Its a macro if after the parentheses, it's not the end
    return !is_define_end(data);
}

// @note Very slow function to get line number,
// use only for errors.
// @todo Well, this does not seem to work properly, UTF-8 problem?
get_line_column :: proc(data : ^ParserData) -> (u32, u32) {
    line : u32 = 1;
    column : u32 = 0;
    for i : u32 = 0; i < data.offset; i += 1 {
        if data.bytes[i] == '\n' {
            column = 0;
            line += 1;
        }
        else {
            column += 1;
        }
    }
    return line, column;
}
