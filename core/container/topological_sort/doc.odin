/*
// A generic `O(V+E)` topological sorter implementation.
// This is the fastest known method for topological sorting.

Example:
	import "core:container/topological_sort"
	import "core:fmt"

	Step :: enum {Compile, Link, Run, Test}

	main :: proc() {
		sorter: topological_sort.Sorter(Step)
		topological_sort.init(&sorter)

		topological_sort.add_dependency(&sorter, Step.Link, Step.Compile)  // Link depends on Compile
		topological_sort.add_dependency(&sorter, Step.Test,  Step.Compile) // Test depends on Compile
		topological_sort.add_dependency(&sorter, Step.Run,   Step.Link)    // Run depends on Link

		sorted, cycled, _ := topological_sort.sort(&sorter)
		defer delete(sorted)
		defer delete(cycled)

		fmt.println("Sorted:")
		for t in sorted {
			fmt.println("  ", t)
		}
	}

Output:
	Sorted:
	  Compile
	  Test
	  Link
	  Run
*/
package container_topological_sort
