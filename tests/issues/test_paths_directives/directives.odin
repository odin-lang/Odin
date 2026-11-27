package test_paths_directives

S16 : string16 : "directives.odin"

A :: #load(S16, string)
B :: #exists(S16)
C :: #load(#file, string)
D :: #load("a\x00b")
E :: #load_directory("no_such_collection:x")

#assert(len(A) > 0)
#assert(B)
#assert(len(C) == len(A))
