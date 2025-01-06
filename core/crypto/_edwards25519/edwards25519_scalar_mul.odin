package _edwards25519

import field "core:crypto/_fiat/field_scalar25519"
import "core:math/bits"
import "core:mem"

// GE_BASEPOINT_TABLE is 1 * G, ... 15 * G, in precomputed format.
//
// Note: When generating, the values were reduced to Tight_Field_Element
// ranges, even though that is not required.
@(private)
GE_BASEPOINT_TABLE := Multiply_Table {
	{
		{62697248952638, 204681361388450, 631292143396476, 338455783676468, 1213667448819585},
		{1288382639258501, 245678601348599, 269427782077623, 1462984067271730, 137412439391563},
		{301289933810280, 1259582250014073, 1422107436869536, 796239922652654, 1953934009299142},
		{2, 0, 0, 0, 0},
	},
	{
		{1519297034332653, 1098796920435767, 1823476547744119, 808144629470969, 2110930855619772},
		{338005982828284, 1667856962156925, 100399270107451, 1604566703601691, 1950338038771369},
		{1920505767731247, 1443759578976892, 1659852098357048, 1484431291070208, 275018744912646},
		{763163817085987, 2195095074806923, 2167883174351839, 1868059999999762, 911071066608705},
	},
	{
		{960627541894068, 1314966688943942, 1126875971034044, 2059608312958945, 605975666152586},
		{1714478358025626, 2209607666607510, 1600912834284834, 496072478982142, 481970031861896},
		{851735079403194, 1088965826757164, 141569479297499, 602804610059257, 2004026468601520},
		{197585529552380, 324719066578543, 564481854250498, 1173818332764578, 35452976395676},
	},
	{
		{1152980410747203, 2196804280851952, 25745194962557, 1915167295473129, 1266299690309224},
		{809905889679060, 979732230071345, 1509972345538142, 188492426534402, 818965583123815},
		{997685409185036, 1451818320876327, 2126681166774509, 2000509606057528, 235432372486854},
		{887734189279642, 1460338685162044, 877378220074262, 102436391401299, 153369156847490},
	},
	{
		{2056621900836770, 1821657694132497, 1627986892909426, 1163363868678833, 1108873376459226},
		{1187697490593623, 1066539945237335, 885654531892000, 1357534489491782, 359370291392448},
		{1509033452137525, 1305318174298508, 613642471748944, 1987256352550234, 1044283663101541},
		{220105720697037, 387661783287620, 328296827867762, 360035589590664, 795213236824054},
	},
	{
		{1820794733038396, 1612235121681074, 757405923441402, 1094031020892801, 231025333128907},
		{1639067873254194, 1484176557946322, 300800382144789, 1329915446659183, 1211704578730455},
		{641900794791527, 1711751746971612, 179044712319955, 576455585963824, 1852617592509865},
		{743549047192397, 685091042550147, 1952415336873496, 1965124675654685, 513364998442917},
	},
	{
		{1004557076870448, 1762911374844520, 1330807633622723, 384072910939787, 953849032243810},
		{2178275058221458, 257933183722891, 376684351537894, 2010189102001786, 1981824297484148},
		{1332915663881114, 1286540505502549, 1741691283561518, 977214932156314, 1764059494778091},
		{429702949064027, 1368332611650677, 2019867176450999, 2212258376161746, 526160996742554},
	},
	{
		{2098932988258576, 2203688382075948, 2120400160059479, 1748488020948146, 1203264167282624},
		{677131386735829, 1850249298025188, 672782146532031, 2144145693078904, 2088656272813787},
		{1065622343976192, 1573853211848116, 223560413590068, 333846833073379, 27832122205830},
		{1781008836504573, 917619542051793, 544322748939913, 882577394308384, 1720521246471195},
	},
	{
		{660120928379860, 2081944024858618, 1878411111349191, 424587356517195, 2111317439894005},
		{1834193977811532, 1864164086863319, 797334633289424, 150410812403062, 2085177078466389},
		{1438117271371866, 783915531014482, 388731514584658, 292113935417795, 1945855002546714},
		{1678140823166658, 679103239148744, 614102761596238, 1052962498997885, 1863983323810390},
	},
	{
		{1690309392496233, 1116333140326275, 1377242323631039, 717196888780674, 82724646713353},
		{1722370213432106, 74265192976253, 264239578448472, 1714909985012994, 2216984958602173},
		{2010482366920922, 1294036471886319, 566466395005815, 1631955803657320, 1751698647538458},
		{1073230604155753, 1159087041338551, 1664057985455483, 127472702826203, 1339591128522371},
	},
	{
		{478053307175577, 2179515791720985, 21146535423512, 1831683844029536, 462805561553981},
		{1945267486565588, 1298536818409655, 2214511796262989, 1904981051429012, 252904800782086},
		{268945954671210, 222740425595395, 1208025911856230, 1080418823003555, 75929831922483},
		{1884784014268948, 643868448202966, 978736549726821, 46385971089796, 1296884812292320},
	},
	{
		{1861159462859103, 7077532564710, 963010365896826, 1938780006785270, 766241051941647},
		{1778966986051906, 1713995999765361, 1394565822271816, 1366699246468722, 1213407027149475},
		{1978989286560907, 2135084162045594, 1951565508865477, 671788336314416, 293123929458176},
		{902608944504080, 2167765718046481, 1285718473078022, 1222562171329269, 492109027844479},
	},
	{
		{1820807832746213, 1029220580458586, 1101997555432203, 1039081975563572, 202477981158221},
		{1866134980680205, 2222325502763386, 1830284629571201, 1046966214478970, 418381946936795},
		{1783460633291322, 1719505443254998, 1810489639976220, 877049370713018, 2187801198742619},
		{197118243000763, 305493867565736, 518814410156522, 1656246186645170, 901894734874934},
	},
	{
		{225454942125915, 478410476654509, 600524586037746, 643450007230715, 1018615928259319},
		{1733330584845708, 881092297970296, 507039890129464, 496397090721598, 2230888519577628},
		{690155664737246, 1010454785646677, 753170144375012, 1651277613844874, 1622648796364156},
		{1321310321891618, 1089655277873603, 235891750867089, 815878279563688, 1709264240047556},
	},
	{
		{805027036551342, 1387174275567452, 1156538511461704, 1465897486692171, 1208567094120903},
		{2228417017817483, 202885584970535, 2182114782271881, 2077405042592934, 1029684358182774},
		{460447547653983, 627817697755692, 524899434670834, 1228019344939427, 740684787777653},
		{849757462467675, 447476306919899, 422618957298818, 302134659227815, 675831828440895},
	},
}

ge_scalarmult :: proc "contextless" (ge, p: ^Group_Element, sc: ^Scalar) {
	tmp: field.Non_Montgomery_Domain_Field_Element
	field.fe_from_montgomery(&tmp, sc)

	_ge_scalarmult(ge, p, &tmp)

	mem.zero_explicit(&tmp, size_of(tmp))
}

ge_scalarmult_basepoint :: proc "contextless" (ge: ^Group_Element, sc: ^Scalar) {
	// Something like the comb method from "Fast and compact elliptic-curve
	// cryptography" Section 3.3, would be more performant, but more
	// complex.
	//
	// - https://eprint.iacr.org/2012/309
	ge_scalarmult(ge, &GE_BASEPOINT, sc)
}

ge_scalarmult_vartime :: proc "contextless" (ge, p: ^Group_Element, sc: ^Scalar) {
	tmp: field.Non_Montgomery_Domain_Field_Element
	field.fe_from_montgomery(&tmp, sc)

	_ge_scalarmult(ge, p, &tmp, true)
}

ge_double_scalarmult_basepoint_vartime :: proc "contextless" (
	ge: ^Group_Element,
	a: ^Scalar,
	A: ^Group_Element,
	b: ^Scalar,
) {
	// Strauss-Shamir, commonly referred to as the "Shamir trick",
	// saves half the doublings, relative to doing this the naive way.
	//
	// ABGLSV-Pornin (https://eprint.iacr.org/2020/454) is faster,
	// but significantly more complex, and has incompatibilities with
	// mixed-order group elements.

	tmp_add: Add_Scratch = ---
	tmp_addend: Addend_Group_Element = ---
	tmp_dbl: Double_Scratch = ---
	tmp: Group_Element = ---

	A_tbl: Multiply_Table = ---
	mul_tbl_set(&A_tbl, A, &tmp_add)

	sc_a, sc_b: field.Non_Montgomery_Domain_Field_Element
	field.fe_from_montgomery(&sc_a, a)
	field.fe_from_montgomery(&sc_b, b)

	ge_identity(&tmp)
	for i := 31; i >= 0; i = i - 1 {
		limb := i / 8
		shift := uint(i & 7) * 8

		limb_byte_a := sc_a[limb] >> shift
		limb_byte_b := sc_b[limb] >> shift

		hi_a, lo_a := (limb_byte_a >> 4) & 0x0f, limb_byte_a & 0x0f
		hi_b, lo_b := (limb_byte_b >> 4) & 0x0f, limb_byte_b & 0x0f

		if i != 31 {
			ge_double(&tmp, &tmp, &tmp_dbl)
			ge_double(&tmp, &tmp, &tmp_dbl)
			ge_double(&tmp, &tmp, &tmp_dbl)
			ge_double(&tmp, &tmp, &tmp_dbl)
		}
		mul_tbl_add(&tmp, &A_tbl, hi_a, &tmp_add, &tmp_addend, true)
		mul_tbl_add(&tmp, &GE_BASEPOINT_TABLE, hi_b, &tmp_add, &tmp_addend, true)

		ge_double(&tmp, &tmp, &tmp_dbl)
		ge_double(&tmp, &tmp, &tmp_dbl)
		ge_double(&tmp, &tmp, &tmp_dbl)
		ge_double(&tmp, &tmp, &tmp_dbl)
		mul_tbl_add(&tmp, &A_tbl, lo_a, &tmp_add, &tmp_addend, true)
		mul_tbl_add(&tmp, &GE_BASEPOINT_TABLE, lo_b, &tmp_add, &tmp_addend, true)
	}

	ge_set(ge, &tmp)
}

@(private)
_ge_scalarmult :: proc "contextless" (
	ge, p: ^Group_Element,
	sc: ^field.Non_Montgomery_Domain_Field_Element,
	unsafe_is_vartime := false,
) {
	// Do the simplest possible thing that works and provides adequate,
	// performance, which is windowed add-then-multiply.

	tmp_add: Add_Scratch = ---
	tmp_addend: Addend_Group_Element = ---
	tmp_dbl: Double_Scratch = ---
	tmp: Group_Element = ---

	p_tbl: Multiply_Table = ---
	mul_tbl_set(&p_tbl, p, &tmp_add)

	ge_identity(&tmp)
	for i := 31; i >= 0; i = i - 1 {
		limb := i / 8
		shift := uint(i & 7) * 8
		limb_byte := sc[limb] >> shift

		hi, lo := (limb_byte >> 4) & 0x0f, limb_byte & 0x0f

		if i != 31 {
			ge_double(&tmp, &tmp, &tmp_dbl)
			ge_double(&tmp, &tmp, &tmp_dbl)
			ge_double(&tmp, &tmp, &tmp_dbl)
			ge_double(&tmp, &tmp, &tmp_dbl)
		}
		mul_tbl_add(&tmp, &p_tbl, hi, &tmp_add, &tmp_addend, unsafe_is_vartime)

		ge_double(&tmp, &tmp, &tmp_dbl)
		ge_double(&tmp, &tmp, &tmp_dbl)
		ge_double(&tmp, &tmp, &tmp_dbl)
		ge_double(&tmp, &tmp, &tmp_dbl)
		mul_tbl_add(&tmp, &p_tbl, lo, &tmp_add, &tmp_addend, unsafe_is_vartime)
	}

	ge_set(ge, &tmp)

	if !unsafe_is_vartime {
		ge_clear(&tmp)
		mem.zero_explicit(&tmp_add, size_of(Add_Scratch))
		mem.zero_explicit(&tmp_addend, size_of(Addend_Group_Element))
		mem.zero_explicit(&tmp_dbl, size_of(Double_Scratch))
	}
}

@(private)
Multiply_Table :: [15]Addend_Group_Element // 0 = inf, which is implicit.

@(private)
mul_tbl_set :: proc "contextless" (
	tbl: ^Multiply_Table,
	ge: ^Group_Element,
	tmp_add: ^Add_Scratch,
) {
	tmp: Group_Element = ---
	ge_set(&tmp, ge)

	ge_addend_set(&tbl[0], ge)
	for i := 1; i < 15; i = i + 1 {
		ge_add_addend(&tmp, &tmp, &tbl[0], tmp_add)
		ge_addend_set(&tbl[i], &tmp)
	}

	ge_clear(&tmp)
}

@(private)
mul_tbl_add :: proc "contextless" (
	ge: ^Group_Element,
	tbl: ^Multiply_Table,
	idx: u64,
	tmp_add: ^Add_Scratch,
	tmp_addend: ^Addend_Group_Element,
	unsafe_is_vartime: bool,
) {
	// Variable time lookup, with the addition omitted entirely if idx == 0.
	if unsafe_is_vartime {
		// Skip adding the point at infinity.
		if idx != 0 {
			ge_add_addend(ge, ge, &tbl[idx - 1], tmp_add)
		}
		return
	}

	// Constant time lookup.
	tmp_addend^ = {
		// Point at infinity (0, 1, 1, 0) in precomputed form
		{1, 0, 0, 0, 0}, // y - x
		{1, 0, 0, 0, 0}, // y + x
		{0, 0, 0, 0, 0}, // t * 2d
		{2, 0, 0, 0, 0}, // z * 2
	}
	for i := u64(1); i < 16; i = i + 1 {
		_, ctrl := bits.sub_u64(0, (i ~ idx), 0)
		ge_addend_conditional_assign(tmp_addend, &tbl[i - 1], int(~ctrl) & 1)
	}
	ge_add_addend(ge, ge, tmp_addend, tmp_add)
}
