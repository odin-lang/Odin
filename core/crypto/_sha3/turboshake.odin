package _sha3

init_turboshake :: proc "contextless" (ctx: ^Context, d: byte, sec_strength: int) {
	ensure_contextless((d >= 0x01 && d <= 0x7f), "crypto/sha3: invalid TurboSHAKE domain separation byte, allowed: >= 0x01 && <= 0x7f")

	ctx.mdlen = sec_strength / 8
	ctx.dsbyte = d
	
	init(ctx)

	ctx.keccak_round_start = 12
}
