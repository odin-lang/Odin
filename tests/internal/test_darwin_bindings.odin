#+build darwin
package test_internal

import "core:c"
import "core:log"
import "core:testing"
import si   "core:sys/info"
import ObjC "core:sys/darwin/ObjectiveC"
import NS   "core:sys/darwin/Foundation"
import MTL  "vendor:darwin/Metal"

// Methods with an `NSError**` out-parameter return the error as a second value.
@(test)
darwin_error_wrappers :: proc(t: ^testing.T) {
	NS.scoped_autoreleasepool()

	missing := NS.AT("/nonexistent/odin-darwin-bindings-test")

	str, err := NS.String.stringWithContentsOfFile(missing, NS.UTF8StringEncoding)
	testing.expect(t, str == nil)
	testing.expect(t, err != nil)
	if err != nil {
		testing.expect(t, err->code() != 0)
		testing.expect(t, err->localizedDescription() != nil)
	}

	raw_err: ^NS.Error
	raw := NS.String.stringWithContentsOfFile_encoding_error(missing, NS.UTF8StringEncoding, &raw_err)
	testing.expect(t, raw == nil)
	testing.expect(t, raw_err != nil)

	ok, remove_err := NS.FileManager.defaultManager()->removeItemAtPath(missing)
	testing.expect(t, !ok)
	testing.expect(t, remove_err != nil)
}

// `Type.method()`, `Type_method()` and `pkg.Type_method()` all send to the right class and return its type.
@(test)
darwin_class_method_calls :: proc(t: ^testing.T) {
	NS.scoped_autoreleasepool()

	hello := NS.AT("hello")

	a := NS.String.stringWithString(hello)
	b := NS.String_stringWithString(hello)
	testing.expect_value(t, a->odinString(), "hello")
	testing.expect_value(t, b->odinString(), "hello")

	// sent to `NSMutableString` rather than `NSString`, so the result is mutable
	m := NS.MutableString.stringWithString(hello)
	m->appendString(NS.AT(", world"))
	testing.expect_value(t, m->odinString(), "hello, world")

	n := NS.Number_numberWithInt(-7)
	testing.expect_value(t, n->intValue(), -7)
}

@(test)
darwin_autorelease_pools :: proc(t: ^testing.T) {
	outer := NS.scoped_autoreleasepool()
	testing.expect(t, outer != nil)
	for i in 0..<4 {
		inner := NS.scoped_autoreleasepool()
		testing.expect(t, inner != nil)
		s := NS.String.stringWithString(NS.AT("autoreleased"))
		testing.expect_value(t, s->length(), 12)
		_ = i
	}
}

@(test)
darwin_foundation_helpers :: proc(t: ^testing.T) {
	NS.scoped_autoreleasepool()

	testing.expect_value(t, NS.AT("abc")->length(), 3)

	testing.expect_value(t, NS.Number.number(i8(-5))->i8Value(), -5)
	testing.expect_value(t, NS.Number.number(max(u64))->u64Value(), max(u64))
	testing.expect_value(t, NS.Number.number(min(i64))->i64Value(), min(i64))
	testing.expect_value(t, NS.Number.number(int(-42))->odinIntValue(), -42)
	testing.expect_value(t, NS.Number.number(f64(0.5))->f64Value(), 0.5)
	testing.expect(t, NS.Number.number(true)->boolValue())

	r := NS.Range_Make(2, 3)
	testing.expect_value(t, NS.Range_Max(r), 5)
	testing.expect(t, !NS.Range_LocationInRange(r, 1))
	testing.expect(t,  NS.Range_LocationInRange(r, 2))
	testing.expect(t,  NS.Range_LocationInRange(r, 4))
	testing.expect(t, !NS.Range_LocationInRange(r, 5))

	rect := NS.Rect{{1, 2}, {3, 4}}
	testing.expect_value(t, NS.MaxX(rect), 4)
	testing.expect_value(t, NS.MidY(rect), 4)

	array := NS.Array.arrayWithObject(NS.AT("x"))
	testing.expect_value(t, array->objectAs(0, ^NS.String)->odinString(), "x")
	count := 0
	enumerator := array->objectEnumerator()
	for item in enumerator->iterator(^NS.String) {
		testing.expect_value(t, item->odinString(), "x")
		count += 1
		if count > 1 {
			break // fail rather than loop forever
		}
	}
	testing.expect_value(t, count, 1)

	// a bit_set passed to a method
	testing.expect_value(t, NS.AT("ABC")->compare_options(NS.AT("abc"), {.CaseInsensitiveSearch}), NS.ComparisonResult.OrderedSame)
}

// Flag enums converted to bit_sets keep the C values and sizes.
@(test)
darwin_flag_constants :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(MTL.TextureUsage), size_of(c.ulong))
	testing.expect_value(t, transmute(c.ulong)MTL.TextureUsage{.ShaderRead, .RenderTarget}, 0x5)
	testing.expect_value(t, transmute(c.ulong)MTL.TextureUsage_Unknown, 0)
	testing.expect_value(t, transmute(c.ulong)MTL.Stages_All, 0x7fffffffffffffff)
	testing.expect_value(t, transmute(c.ulong)NS.ISO8601DateFormatOptions_InternetDateTime, 0x773)
	testing.expect_value(t, transmute(c.ulong)NS.StringCompareOptions{.CaseInsensitiveSearch}, 0x1)

	// flag enums with multi-bit fields: the field values are constants, read back through their mask
	writing := NS.DataWritingOptions{.Atomic} | NS.DataWritingOptions_FileProtectionComplete
	testing.expect_value(t, transmute(c.ulong)writing, 0x20000001)
	testing.expect(t, writing & NS.DataWritingOptions_FileProtectionMask == NS.DataWritingOptions_FileProtectionComplete)
	testing.expect(t, .Atomic in writing)
	testing.expect_value(t, transmute(c.ulong)(NS.StringEnumerationOptions{.Reverse} | NS.StringEnumerationOptions_ByWords), 0x103)
	testing.expect_value(t, NS.StringEnumerationOptions_ByLines, NS.StringEnumerationOptions{})
}

@(test)
darwin_objc_runtime :: proc(t: ^testing.T) {
	cls := ObjC.register_subclass("OdinDarwinBindingsTestClass", ObjC.objc_lookUpClass("NSObject"))
	testing.expect(t, cls != nil)
	testing.expect_value(t, string(ObjC.class_getName(cls)), "OdinDarwinBindingsTestClass")

	obj := ObjC.alloc_user_object(cls)
	testing.expect(t, obj != nil)
	testing.expect_value(t, ObjC.object_getClass(obj), cls)
}

@(test)
darwin_sys_info_os_version :: proc(t: ^testing.T) {
	version, ok := si.os_version(context.allocator)
	testing.expect(t, ok)
	if ok {
		defer si.destroy_os_version(version, context.allocator)
		testing.expect(t, version.os.major >= 10)
		testing.expect(t, len(version.full) > 0)
	}
	total_ram, _, _, _, ram_ok := si.ram_stats()
	testing.expect(t, ram_ok)
	testing.expect(t, total_ram > 0)
}

@(test)
darwin_metal_device :: proc(t: ^testing.T) {
	NS.scoped_autoreleasepool()

	device := MTL.CreateSystemDefaultDevice()
	if device == nil {
		log.info("No Metal device available, skipping")
		return
	}
	defer device->release()
	testing.expect(t, device->name() != nil)

	library, err := device->newLibraryWithSource(NS.AT("kernel void k(device float *x [[buffer(0)]]) { x[0] = 1; }"), nil)
	testing.expect(t, err == nil)
	testing.expect(t, library != nil)
	if library != nil {
		library->release()
	}

	bad_library, bad_err := device->newLibraryWithSource(NS.AT("this is not Metal"), nil)
	testing.expect(t, bad_library == nil)
	testing.expect(t, bad_err != nil)

	values := []f32{1, 2, 3}
	buffer := device->newBufferWithSlice(values, {})
	testing.expect(t, buffer != nil)
	if buffer != nil {
		defer buffer->release()
		testing.expect_value(t, buffer->length(), 12)
		testing.expect_value(t, buffer->contentsAsSlice([]f32)[1], 2)
	}
}
