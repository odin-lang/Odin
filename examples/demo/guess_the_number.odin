package guess_the_number

import "core:os"
import "core:time"
import "core:math"
import "core:math/rand"
import "core:strconv"
import "core:fmt"

main :: proc() {
	rand.set_global_seed(u64(time.duration_nanoseconds(time.Duration(time.now()._nsec))));
	secret_number := rand.int_max(101);
	fmt.println("Welcome to guess the number!");
	fmt.println("Please enter a number between 1 and 101, then press return.");
	loop: for {
		had_input, guess := fmt.readln();
		if had_input {
			fmt.print("You guessed: ", guess);
			switch (math.compare_value(strconv.atoi(guess), secret_number)) {
				case math.Ordering.Less:
					fmt.println("Too small!");
				case math.Ordering.Greater:
					fmt.println("Too big!");
				case math.Ordering.Equal:
					fmt.println("You win!");
					break loop;
			}
			fmt.println("Please enter a number between 1 and 101, then press return.");
		}
	}
}