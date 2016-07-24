# Todo

## Tokenizer
* Unicode character category check - Letters, Digits
* Extra operators
	- << and <<=
	- >> and >>=

## Parser
* Extra checking here rather than in the checker
* Mulitple files (done)
	- Namespaces

## Checker
* Cyclic Type Checking
	- type A: struct { b: B; }; type B: struct { a: A; };
	- ^ Should be illegal as it's a cyclic definition
* Big numbers library
	- integer
	- rational
	- real
* Multiple files (done)
	- Namespaces

## Codegen
* Emit LLVM-IR using custom library
* Debug info

## Command Line Tool
* Begin!!!
* Choose/determine architecture




## Language

* should `if/for` statements init statement be of the same scope as the block scope or not? (currently not)
