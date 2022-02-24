package docsrv

import "core:os"
import "core:fmt"
import "core:strconv"
import "core:net/http"

main :: proc() {
	if len(os.args) < 3 {
		fmt.printf("docsrv requires 2 args, <doc_path> <port>\n")
		os.exit(1);
	}

	port, ok := strconv.parse_int(os.args[2])
	if !ok {
		fmt.printf("Unable to parse port!\n")
		os.exit(1);
	}

	dir := os.args[1]
	if !os.is_dir(dir) {
		fmt.printf("Doc path is invalid!\n")
		os.exit(1);
	}

	fmt.printf("Spinning up docs @ %s on port %d\n", dir, port)
	http.serve_files(dir, port)

	os.exit(0);
}
