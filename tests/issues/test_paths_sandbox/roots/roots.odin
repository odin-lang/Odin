package test_paths_roots

A :: #load("../../../../LICENSE", string)
B :: #exists("../../../../no_such_file_anywhere")

#assert(len(A) > 0)
#assert(!B)
