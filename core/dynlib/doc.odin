/*
Package `core:dynlib` implements loading of shared libraries/DLLs and their symbols.

The behaviour of dynamically loaded libraries is specific to the target platform of the program.
For in depth detail on the underlying behaviour please refer to your target platform's documentation.

See `example` directory for an example library exporting 3 symbols and a host program loading them automatically
by defining a symbol table struct.
*/
package dynlib
