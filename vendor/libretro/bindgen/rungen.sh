#!/bin/sh

bindgen libretro.sjson
GENOUT=../libretro.odin

# https://github.com/karl-zylinski/odin-c-bindgen/issues/97
rpl "RETRO_" "" $GENOUT

rpl "foreign lib" "foreign _" $GENOUT

# This is fixed in newer versions.
TEMPFILE=$(mktemp /tmp/bindgen.XXXXXX)
sed '2457d' $GENOUT > $TEMPFILE
mv $TEMPFILE $GENOUT
