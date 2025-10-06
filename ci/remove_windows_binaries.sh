#!/usr/bin/env sh

find "$1" -type f \(\
	-iname "*.exe"    \
	-o -iname "*.dll" \
	-o -iname "*.lib" \
	-o -iname "*.pdb" \
    \) -delete
