package test_paths_load

S16 : string16 : "../../../../LICENSE"

A :: #load("../../../../LICENSE")
B :: #load_directory("../../../..")
C :: #exists("../../../../LICENSE")
D :: #exists("../../../../no_such_file_anywhere")
E :: #load(S16)
F :: #load("a\x00b")
G :: #load("core:../LICENSE")
H :: #load(ODIN_ROOT + "LICENSE")
I :: #load(#file)
J :: #load("foo:sub/bar.txt")
K :: #exists("foo:sub/missing.txt")
L :: #load("foo:../../../../LICENSE")
M :: #load(ODIN_ROOT + "core/fmt/doc.odin")
