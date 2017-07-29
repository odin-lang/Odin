import (
	"fmt.odin";
	"strconv.odin";
	"thread.odin";
	win32 "sys/windows.odin";
)

prefix_table := [...]string{
	"White",
	"Red",
	"Orange",
	"Yellow",
	"Green",
	"Blue",
	"Octarine",
	"Black",
};

worker_proc :: proc(t: ^thread.Thread) -> int {
	for iteration in 1...5 {
		fmt.printf("Th/read %d is on iteration %d\n", t.user_index, iteration);
		fmt.printf("`%s`: iteration %d\n", prefix_table[t.user_index], iteration);
		win32.sleep(1);
	}
	return 0;
}


main :: proc() {
	threads := make([]^thread.Thread, 0, len(prefix_table));

	for i in 0..len(prefix_table) {
		if t := thread.create(worker_proc); t != nil {
			t.init_context = context;
			t.use_init_context = true;
			t.user_index = len(threads);
			append(&threads, t);
			thread.start(t);
		}
	}

	for len(threads) > 0 {
		for i := 0; i < len(threads); i += 1 {
			if t := threads[i]; thread.is_done(t) {
				fmt.printf("Thread %d is done\n", t.user_index);
				thread.destroy(t);

				threads[i] = threads[len(threads)-1];
				pop(&threads);
				i -= 1;
			}
		}
	}
}

