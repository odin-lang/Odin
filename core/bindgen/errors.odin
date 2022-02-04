package bindgen

import "core:fmt"
import "core:os"

seenWarnings : map[string]bool;

print_warning :: proc(args : ..any) {
    message := tcat(..args);

    if !seenWarnings[message] {
        fmt.eprint("[bindgen] Warning: ", message, "\n");
        seenWarnings[message] = true;
    }
}

print_error :: proc(data : ^ParserData, loc := #caller_location, args : ..any) {
    message := tcat(..args);

    min : u32 = 0;
    for i := data.offset - 1; i > 0; i -= 1 {
        if data.bytes[i] == '\n' {
            min = i + 1;
            break;
        }
    }

    max := min + 200;
    for i := min + 1; i < max; i += 1 {
        if data.bytes[i] == '\n' {
            max = i;
            break;
        }
    }

    line, _ := get_line_column(data);

    fmt.eprint("[bindgen] Error: ", message, "\n");
    fmt.eprint("[bindgen] ... from ", loc.procedure, "\n");
    fmt.eprint("[bindgen] ... at line ", line, " within this context:\n");
    fmt.eprint("> ", extract_string(data, min, max), "\n");

    os.exit(1);
}
