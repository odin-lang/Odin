# Todo

## Tokenizer
* Unicode character category check - Letters, Digits
* Extra operators
	- << and <<=
	- >> and >>=

## Parser
* Extra checking here rather than in the checker
* Mulitple files

## Checker
* Cyclic Type Checking
	- type A: struct { b: B; }; type B: struct { a: A; };
	- ^ Should be illegal as it's a cyclic definition
* Big numbers library
	- integer
	- rational
	- real
* Multiple files

## Codegen
* Begin!!!
* Emit LLVM-IR using custom library
* Debug info

## Command Line Tool
* Begin!!!
* Choose/determine architecture

