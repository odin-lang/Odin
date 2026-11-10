On Windows, the compiler will look within this folder for the needed Microsoft Visual Studio binaries and libraries as well as the Windows SDK. This is an alternative to having those things installed system-wide.

The compiler will search this folder for the folders `VC` and `Windows Kits\10`.

This enables the creation of Odin installation programs that dump the required MSVC/Windows SDK stuff into this folder. The layout is compatible with Mārtiņš Možeiko's portable-msvc.py: https://gist.github.com/mmozeiko/7f3162ec2988e81e56d5c4e22cde9977 -- It's possible to put that script in the parent folder (`bin`) and run it. It will write all the needed libraries into this folder.

Note for Odin compiler developers: This folder is searched by the `find_paths_in_bin_msvc` function in `microsoft_craziness.h`.