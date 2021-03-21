

package test;

big::struct{
  x:[1000]u8,
  y:[1000]u8,
  z:[1000]u8,
}

@(link_name="process")
process::proc "c" (b: big) -> (re:big) {
  re = b;
  return;
}

main::proc() {
  a:big;
  process(a);
}