package main

import "core:fmt"
import _c "core:c"
import "core:runtime"
import wren "shared:odin-wren"

module : cstring = "main"
script : cstring = "System.print(10)"

main :: proc() {
  config := wren.Configuration{}
  wren.InitConfiguration(&config)
  config.writeFn = write_fn
  config.errorFn = error_fn
  vm := wren.NewVM(&config)

  result := wren.Interpret(vm, module, script)
  switch result {
    case .WREN_RESULT_COMPILE_ERROR:
      fmt.println("Compile error")
    case .WREN_RESULT_RUNTIME_ERROR:
      fmt.println("Runtime error")
    case .WREN_RESULT_SUCCESS:
      fmt.println("Success!")
  }
}

write_fn :: proc "c" (vm: ^wren.VM, message: cstring) {
  context = runtime.default_context()
  fmt.print(message)
}

error_fn :: proc "c" (vm: ^wren.VM, type: wren.ErrorType, module: cstring, line: _c.int, message: cstring) {
  context = runtime.default_context()
  fmt.println("error")
}
