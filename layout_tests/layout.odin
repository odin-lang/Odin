package layout
import "core:fmt"

handle: uintptr = 0xdeadbeef;

Builder::struct {
  x0: i32,
  x1: uintptr,
  x2: i32,
}

main::proc() {
  info := Builder {
    x1 = handle,
    x2 = 1,
  };

  fmt.printf("%v\n", info);
}
