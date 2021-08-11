//+ignore
package math_big

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
`
Configuration:
	_DIGIT_BITS                           %v
	_MIN_DIGIT_COUNT                      %v
	_MAX_DIGIT_COUNT                      %v
	_DEFAULT_DIGIT_COUNT                  %v
	_MAX_COMBA                            %v
	_WARRAY                               %v
Runtime tunable:
	MUL_KARATSUBA_CUTOFF                  %v
	SQR_KARATSUBA_CUTOFF                  %v
	MUL_TOOM_CUTOFF                       %v
	SQR_TOOM_CUTOFF                       %v
	MAX_ITERATIONS_ROOT_N                 %v
	FACTORIAL_MAX_N                       %v
	FACTORIAL_BINARY_SPLIT_CUTOFF         %v
	FACTORIAL_BINARY_SPLIT_MAX_RECURSIONS %v

`, _DIGIT_BITS,
_MIN_DIGIT_COUNT,
_MAX_DIGIT_COUNT,
_DEFAULT_DIGIT_COUNT,
_MAX_COMBA,
_WARRAY,
MUL_KARATSUBA_CUTOFF,
SQR_KARATSUBA_CUTOFF,
MUL_TOOM_CUTOFF,
SQR_TOOM_CUTOFF,
MAX_ITERATIONS_ROOT_N,
FACTORIAL_MAX_N,
FACTORIAL_BINARY_SPLIT_CUTOFF,
FACTORIAL_BINARY_SPLIT_MAX_RECURSIONS,
);

}

print :: proc(name: string, a: ^Int, base := i8(10), print_name := true, newline := true, print_extra_info := false) {
	assert_if_nil(a);

	as, err := itoa(a, base);
	defer delete(as);

	cb := internal_count_bits(a);
	if print_name {
		fmt.printf("%v", name);
	}
	if err != nil {
		fmt.printf("%v (error: %v | %v)", name, err, a);
	}
	fmt.printf("%v", as);
	if print_extra_info {
		fmt.printf(" (base: %v, bits: %v (digits: %v), flags: %v)", base, cb, a.used, a.flags);
	}
	if newline {
		fmt.println();
	}
}

demo :: proc() {
	a, b, c, d, e, f := &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{};
	defer destroy(a, b, c, d, e, f);

	err: Error;
	bs: string;

	// if err = factorial(a, 850); err != nil { fmt.printf("factorial err: %v\n", err); return; }

	foo := "54fc32611b510b653a608aaf41ca6d8e6a927520c87124d6bc9df29e29dcafbb0096428ca4a48905a3b6c9f02c56983d6d14711e7f5ce433feca8fcf382cdbd76cd627c45bc55423b8aea7f1bf638e81a3182ccd8b937467ca3916b37e67d0d4a1f3a0400360e8b02211a61071549525c4a1d4b32bfc83381e00d7d977bcf8f76e74d7a5a9532b75adfe67b6511cb377fa2828f3d9f989b3a532e2ded695796052ec3073267c11270fd393087a0ddf02f480f31149ee0c889811a8e43c25b906c9be5627bab8ba8eeba80ebdbfa0c6fe988542398d17f9df13887ddf5b109fc70033b325ec79340bd3e8d0e9217d0095fa1d5ed8750b479e2f85dd15bba5ce8ab9376d7fba183435d6d7b67e244358464efea9f5f3311efca81e36a5875e484cba3bce9536c87a038a16b85817812afde4ac8592af4f0a34ecb2e35ec160755ae17c9ad5ebee8f8a3687a06ce6a8385c161c275d1f1c1e10b64eeab5a56d76d5574c7a19a177c4018ec61f85f636697f177160452535de3a751c61f2156cd33a61e4b290b79429286397f6e58ee4936d4f1fd911b6511215fc9690e21b6f0f0c315341d5a192c40d6543c330a92c2161639f915ae50751ecdfcf6b5a489b4a874867a559e962c5464f69e50916c7621d8c7941357883e0ac5ba44dcf5cfccaa6a83ae035d66d9f00de1f115ceae4bb87133ab03d960b1c29ec801c2ac880b65d6ffd676b2c0a0f32282c47cfa977fa03ba94939cc6ec8666be46e8ce6d8a473089fd313dad75bdf99b024ad2b2bec434a2bde6102adee4c10fc53836fcade7e5eeef09a1dbeec913e535ba39b05035316e81723b93d465bd952bf1faada1564111836f022c482be52568f0c061bf0666db8c33e7a4f05c5792d0914b4ef7b654735bc1d363ca15af78ad32c0db6247b5721517393d47ce267f3a7e888642c7f595d7c8e84f680d766551bde0f9002f040a688973d3498c0ab4443b33652639018d33e0e9fe97831ba1bf7531b4d69f84e1a99cd58105756dd78ba9524ed4d236387ce9211ecab98048a728f5526c44372e44ed7a6853eeacda09d659119b0082cec1c1a6295fd9c6439f95dc60a9467e4296c0babb0138dae22ef64716fbaf0cbcd4c3047b976ae923f75fc6f4303e2ffe2792ff367d48b82b162182700bd08622a0b3304a6b0e1154ae66dc3a1607fc03026a1b81a7ec904aa98c201551baf5da48d78916ab5acb88df7bc57d7b4f1e96716dbfe56366c20cd28c2ae9d007c7c65c7fb4b6ccf108d6f23215f27913bb57ed13f9a75fb017ca5242a46ef2248da0b60ca1cb5cd80219367ed61082b3ca6c07ae581430c334de073e241993cc7458be8017c4d8c1a2b9d9d2e4e72fff048c2a70b2f57e8259a0dac6cdab9dd4d7bcf69b401d52a67a656d62730672fa3b05aa83fbc97a2362bb6c218d9c659dbfd64e20cc7f0977ba2c2ad695202fee68aca07698d3e4a9677d8ea69099d1ccb113ddb695017d6ce0da36fa3c8f3fd22ad400f53335e1e965d3f3323575927273987cb9e798b222e125c4290a4bf751b8e5329a6690b32bedf6f90786511d55da1dabe963cff83686f454b1b1fa28c46abc20c4b500d9ecad4b3f3c446fb74eebb596aea1c6f079b43f167f228cab3ceab8965c34d5b0c760221ca441b6d1d75b5c39d7443fc58933bc2cadb1c5d1b92ac70179677feef4ee63a8f8fb76eeb20e705b58f138867db80bfaf4e2edba0a7f68e56e4650b2d6e8fdf634d74f7ba8df527fd3c3a03a987e9b73d2e50aea3020251c06d5629dd32790bc36f02c638b757441a813c101f3d81eb6a4d1edd147ba9dbbc2d3c419fa11bda7f3602dda5dc2f9a19fc7306660d20ecb1da3bb87b8415e340f2a3d1e843bc19059734e2417f1783c7859f00c6801dc51acf068d57777de7d100ae77bca7614a69efe557d574abb2b79d5d90ba621aa2b6460cdce64012cad33bf374989044bba0d280c26b71a1a2d7abf7bd75009a71db9f488c4b3b58db217689bc355d68817f6153736f597e3586780175960edf4fded6513aa8c6154cee94e278e9967d0f256a4b14a2cd188e4800f146118a35633476c665edc7460658dc7877f107bcd3108d";
	if err = atoi(a, foo, 16); err != nil { return; }
	//print("a: ", a, 16, true, true, true);
	//fmt.println();

	{
		SCOPED_TIMING(.sqr);
		if err = _private_int_sqr_toom(b, a); err != nil { fmt.printf("sqr err: %v\n", err); return; }
	}
	fmt.println();

	bs, err = itoa(b, 16);
	defer delete(bs);

	if bs[:50] != "1C367982F3050A8A3C62A8A7906D165438B54B287AF3F15D36" {
	 	fmt.println("sqr failed");
	}
}

main :: proc() {
	ta := mem.Tracking_Allocator{};
	mem.tracking_allocator_init(&ta, context.allocator);
	context.allocator = mem.tracking_allocator(&ta);

	demo();

	print_configation();

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