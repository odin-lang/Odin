# WASM on the Web

This directory is for use when targeting the `js_wasm32` target and the packages that rely on it.

The `js_wasm32` target assumes that the WASM output will be ran within a web browser rather than a standalone VM. In the VM cases, either `wasi_wasm32` or `freestanding_wasm32` should be used accordingly.

## Example for `js_wasm32`

```html
<!-- Copy `core:sys/wasm/js/odin.js` into your web server -->
<script type="text/javascript" src="odin.js"></script>
<script type="text/javascript">
	odin.runWasm(pathToWasm, consolePreElement);
</script>
```
