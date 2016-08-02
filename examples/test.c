int main() {
	int x = 15;
	int y = 4;
	x = x & (~y);
	if (x > 0) {
		x = 123;
	} else {
		x = 321;
	}
	return 0;
}
