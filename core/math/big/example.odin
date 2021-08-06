//+ignore
package big

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-2 license.

	A BigInt implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.
*/

import "core:fmt"
import "core:mem"

print_configation :: proc() {
	fmt.printf(
`Configuration:
	DIGIT_BITS           %v
	MIN_DIGIT_COUNT      %v
	MAX_DIGIT_COUNT      %v
	DEFAULT_DIGIT_COUNT  %v
	MAX_COMBA            %v
	WARRAY               %v
	MUL_KARATSUBA_CUTOFF %v
	SQR_KARATSUBA_CUTOFF %v
	MUL_TOOM_CUTOFF      %v
	SQR_TOOM_CUTOFF      %v

`, _DIGIT_BITS,
_MIN_DIGIT_COUNT,
_MAX_DIGIT_COUNT,
_DEFAULT_DIGIT_COUNT,
_MAX_COMBA,
_WARRAY,
_MUL_KARATSUBA_CUTOFF,
_SQR_KARATSUBA_CUTOFF,
_MUL_TOOM_CUTOFF,
_SQR_TOOM_CUTOFF,
);

}

print :: proc(name: string, a: ^Int, base := i8(10), print_name := true, newline := true, print_extra_info := false) {
	as, err := itoa(a, base);

	defer delete(as);
	cb, _ := count_bits(a);
	if print_name {
		fmt.printf("%v", name);
	}
	if err != nil {
		fmt.printf("%v (error: %v | %v)", name, err, a);
	}
	fmt.printf("%v", as);
	if print_extra_info {
		fmt.printf(" (base: %v, bits used: %v, flags: %v)", base, cb, a.flags);
	}
	if newline {
		fmt.println();
	}
}

demo :: proc() {
	a, b, c, d, e, f := &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{};
	defer destroy(a, b, c, d, e, f);

	foo := "686885735734829009541949746871140768343076607029752932751182108475420900392874228486622313727012705619148037570309621219533087263900443932890792804879473795673302686046941536636874184361869252299636701671980034458333859202703255467709267777184095435235980845369829397344182319113372092844648570818726316581751114346501124871729572474923695509057166373026411194094493240101036672016770945150422252961487398124677567028263059046193391737576836378376192651849283925197438927999526058932679219572030021792914065825542626400207956134072247020690107136531852625253942429167557531123651471221455967386267137846791963149859804549891438562641323068751514370656287452006867713758971418043865298618635213551059471668293725548570452377976322899027050925842868079489675596835389444833567439058609775325447891875359487104691935576723532407937236505941186660707032433807075470656782452889754501872408562496805517394619388777930253411467941214807849472083814447498068636264021405175653742244368865090604940094889189800007448083930490871954101880815781177612910234741529950538835837693870921008635195545246771593130784786737543736434086434015200264933536294884482218945403958647118802574342840790536176272341586020230110889699633073513016344826709214";
	err := atoi(a, foo, 10);

	if err != nil do fmt.printf("atoi returned %v\n", err);

	print("foo: ", a);

}

main :: proc() {
	ta := mem.Tracking_Allocator{};
	mem.tracking_allocator_init(&ta, context.allocator);
	context.allocator = mem.tracking_allocator(&ta);

	demo();

	print_timings();

	if len(ta.allocation_map) > 0 {
		for _, v in ta.allocation_map {
			fmt.printf("Leaked %v bytes @ %v\n", v.size, v.location);
		}
	}
	if len(ta.bad_free_array) > 0 {
		fmt.println("Bad frees:");
		for v in ta.bad_free_array {
			fmt.println(v);
		}
	}
}