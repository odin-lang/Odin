package _weierstrass

import subtle "core:crypto/_subtle"
import "core:mem"

pt_scalar_mul :: proc "contextless" (
	p, a: ^$T,
	sc: ^$S,
	unsafe_is_vartime: bool = false,
) {
	when T == Point_p256r1 && S == Scalar_p256r1 {
		p_tbl: Multiply_Table_p256r1 = ---
		q, tmp: Point_p256r1 = ---, ---
		SC_SZ :: SC_SIZE_P256R1
	} else {
		#panic("weierstrass: invalid curve")
	}

	mul_tbl_set(&p_tbl, a, unsafe_is_vartime)

	b: [SC_SZ]byte = ---
	sc_bytes(b[:], sc)

	pt_identity(&q)
	for limb_byte, i in b {
		hi, lo := (limb_byte >> 4) & 0x0f, limb_byte & 0x0f

		if i != 0 {
			pt_double(&q, &q)
			pt_double(&q, &q)
			pt_double(&q, &q)
			pt_double(&q, &q)
		}
		mul_tbl_lookup_add(&q, &tmp, &p_tbl, u64(hi), unsafe_is_vartime)

		pt_double(&q, &q)
		pt_double(&q, &q)
		pt_double(&q, &q)
		pt_double(&q, &q)
		mul_tbl_lookup_add(&q, &tmp, &p_tbl, u64(lo), unsafe_is_vartime)
	}

	pt_set(p, &q)

	if !unsafe_is_vartime {
		mem.zero_explicit(&b, size_of(b))
		mem.zero_explicit(&p_tbl, size_of(p_tbl))
		pt_clear_vec([]^T{&q, &tmp})
	}
}

pt_scalar_mul_generator :: proc "contextless" (
	p: ^$T,
	sc: ^$S,
	unsafe_is_vartime: bool = false,
) {
	when T == Point_p256r1 && S == Scalar_p256r1 {
		p_tbl := &Gen_Multiply_Table_p256r1
		tmp: Point_p256r1 = ---
		SC_SZ :: SC_SIZE_P256R1
	} else {
		#panic("weierstrass: invalid curve")
	}

	b: [SC_SZ]byte
	sc_bytes(b[:], sc)

	// Note: The point doublings can be eliminated entirely
	// at the cost of having 64 Gen_Multiply_Table's, but
	// that's a considerable amount of data.
	pt_identity(p)
	for limb_byte, i in b {
		hi, lo := (limb_byte >> 4) & 0x0f, limb_byte & 0x0f

		if i != 0 {
			pt_double(p, p)
			pt_double(p, p)
			pt_double(p, p)
			pt_double(p, p)
		}
		mul_affine_tbl_lookup_add(p, &tmp, p_tbl, u64(hi), unsafe_is_vartime)

		pt_double(p, p)
		pt_double(p, p)
		pt_double(p, p)
		pt_double(p, p)
		mul_affine_tbl_lookup_add(p, &tmp, p_tbl, u64(lo), unsafe_is_vartime)
	}

	if !unsafe_is_vartime {
		mem.zero_explicit(&b, size_of(b))
		pt_clear(&tmp)
	}
}

@(private="file")
Multiply_Table_p256r1 :: [15]Point_p256r1

@(private="file")
mul_tbl_set :: proc "contextless"(
	tbl: ^$T,
	point: ^$U,
	unsafe_is_vartime: bool,
) {
	when T == Multiply_Table_p256r1 && U == Point_p256r1{
		tmp: Point_p256r1
		pt_set(&tmp, point)
	} else {
		#panic("weierstrass: invalid curve")
	}

	pt_set(&tbl[0], &tmp)
	for i in 1 ..<15 {
		pt_add(&tmp, &tmp, point)
		pt_set(&tbl[i], &tmp)
	}

	if !unsafe_is_vartime {
		pt_clear(&tmp)
	}
}

@(private="file")
mul_tbl_lookup_add :: proc "contextless" (
	point, tmp: ^$T,
	tbl: ^$U,
	idx: u64,
	unsafe_is_vartime: bool,
 ) {
	if unsafe_is_vartime {
		switch idx {
		case 0:
		case:
			pt_add(point, point, &tbl[idx - 1])
		}
		return
	}

	pt_identity(tmp)
	for i in u64(1)..<16 {
		ctrl := subtle.eq(i, idx)
		pt_cond_select(tmp, tmp, &tbl[i - 1], int(ctrl))
	}

	pt_add(point, point, tmp)
}

@(private="file")
Affine_Point_p256r1 :: struct {
	_x: Field_Element_p256r1,
	_y: Field_Element_p256r1,
}

@(private="file")
mul_affine_tbl_lookup_add :: proc "contextless" (
	point, tmp: ^$T,
	tbl: ^$U,
	idx: u64,
	unsafe_is_vartime: bool,
) {
	if unsafe_is_vartime {
		switch idx {
		case 0:
		case:
			pt_add_mixed(point, point, &tbl[idx - 1]._x, &tbl[idx - 1]._y)
		}
		return
	}

	pt_identity(tmp)
	for i in u64(1)..<16 {
		ctrl := int(subtle.eq(i, idx))
		fe_cond_select(&tmp._x, &tmp._x, &tbl[i - 1]._x, ctrl)
		fe_cond_select(&tmp._y, &tmp._y, &tbl[i - 1]._y, ctrl)
	}

	// The mixed addition formula assumes that the addend is not
	// the neutral element.  Do the addition regardless, and then
	// conditionally select the right result.
	pt_add_mixed(tmp, point, &tmp._x, &tmp._y)

	ctrl := subtle.u64_is_non_zero(idx)
	pt_cond_select(point, point, tmp, int(ctrl))
}

@(private="file",rodata)
Gen_Multiply_Table_p256r1 := [15]Affine_Point_p256r1 {
	{
		{8784043285714375740, 8483257759279461889, 8789745728267363600, 1770019616739251654},
		{15992936863339206154, 10037038012062884956, 15197544864945402661, 9615747158586711429},
	},
	{
		{9583737883674400333, 12279877754802111101, 8296198976379850969, 17778859909846088251},
		{3401986641240187301, 1525831644595056632, 1849003687033449918, 8702493044913179195},
	},
	{
		{18423170064697770279, 12693387071620743675, 7398701556189346968, 2779682216903406718},
		{12703629940499916779, 6358598532389273114, 8683512038509439374, 15415938252666293255},
	},
	{
		{8408419572923862476, 5066733120953500019, 926242532005776114, 6301489109130024811},
		{3285079390283344806, 1685054835664548935, 7740622190510199342, 9561507292862134371},
	},
	{
		{13698695174800826869, 10442832251048252285, 10672604962207744524, 14485711676978308040},
		{16947216143812808464, 8342189264337602603, 3837253281927274344, 8331789856935110934},
	},
	{
		{4627808394696681034, 6174000022702321214, 15351247319787348909, 1371147458593240691},
		{10651965436787680331, 2998319090323362997, 17592419471314886417, 11874181791118522207},
	},
	{
		{524165018444839759, 3157588572894920951, 17599692088379947784, 1421537803477597699},
		{2902517390503550285, 7440776657136679901, 17263207614729765269, 16928425260420958311},
	},
	{
		{2878166099891431311, 5056053391262430293, 10345032411278802027, 13214556496570163981},
		{17698482058276194679, 2441850938900527637, 1314061001345252336, 6263402014353842038},

	},
	{
		{8487436533858443496, 12386798851261442113, 3224748875345095424, 16166568617729909099},
		{2213369110503306004, 6246347469485852131, 3129440554298978074, 605269941184323483},
	},
	{
		{3177531230451277512, 11022989490494865721, 8321856985295555401, 14727273563873821327},
		{876865438755954294, 14139765236890058248, 6880705719513638354, 8678887646434118325},

	},
	{
		{16896703203004244996, 11377226897030111200, 2302364246994590389, 4499255394192625779},
		{1906858144627445384, 2670515414718439880, 868537809054295101, 7535366755622172814},
	},
	{
		{339769604981749608, 12384581172556225075, 2596838235904096350, 5684069910326796630},
		{913125548148611907, 1661497269948077623, 2892028918424825190, 9220412792897768138},
	},
	{
		{14754959387565938441, 1023838193204581133, 13599978343236540433, 8323909593307920217},
		{3852032956982813055, 7526785533690696419, 8993798556223495105, 18140648187477079959},
	},
	{
		{11692087196810962506, 1328079167955601379, 1664008958165329504, 18063501818261063470},
		{2861243404839114859, 13702578580056324034, 16781565866279299035, 1524194541633674171},
	},
	{
		{8267721299596412251, 273633183929630283, 17164190306640434032, 16332882679719778825},
		{4663567915067622493, 15521151801790569253, 7273215397645141911, 2324445691280731636},
	},
}
