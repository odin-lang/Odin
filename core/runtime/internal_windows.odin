package runtime

@(link_name="__umodti3")
umodti3 :: proc "c" (a, b: i128) -> i128 {
	s_a := a >> (128 - 1);
	s_b := b >> (128 - 1);
	an := (a ~ s_a) - s_a;
	bn := (b ~ s_b) - s_b;

	r: u128 = ---;
	_ = udivmod128(transmute(u128)an, transmute(u128)bn, &r);
	return (transmute(i128)r ~ s_a) - s_a;
}


@(link_name="__udivmodti4")
udivmodti4 :: proc "c" (a, b: u128, rem: ^u128) -> u128 {
	return udivmod128(a, b, rem);
}

@(link_name="__udivti3")
udivti3 :: proc "c" (a, b: u128) -> u128 {
	return udivmodti4(a, b, nil);
}
