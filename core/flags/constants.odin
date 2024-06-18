package flags

import "core:time"

// Set to true to compile with support for core named types disabled, as a
// fallback in the event your platform does not support one of the types, or
// you have no need for them and want a smaller binary.
NO_CORE_NAMED_TYPES :: #config(ODIN_CORE_FLAGS_NO_CORE_NAMED_TYPES, false)

// Override support for parsing `time` types.
IMPORTING_TIME      :: #config(ODIN_CORE_FLAGS_USE_TIME, time.IS_SUPPORTED)

// Override support for parsing `net` types.
// TODO: Update this when the BSDs are supported.
IMPORTING_NET       :: #config(ODIN_CORE_FLAGS_USE_NET, ODIN_OS == .Windows || ODIN_OS == .Linux || ODIN_OS == .Darwin)

TAG_ARGS          :: "args"
SUBTAG_NAME       :: "name"
SUBTAG_POS        :: "pos"
SUBTAG_REQUIRED   :: "required"
SUBTAG_HIDDEN     :: "hidden"
SUBTAG_VARIADIC   :: "variadic"
SUBTAG_FILE       :: "file"
SUBTAG_PERMS      :: "perms"
SUBTAG_INDISTINCT :: "indistinct"

TAG_USAGE         :: "usage"

UNDOCUMENTED_FLAG :: "<This flag has not been documented yet.>"

INTERNAL_VARIADIC_FLAG   :: "varg"

RESERVED_HELP_FLAG       :: "help"
RESERVED_HELP_FLAG_SHORT :: "h"

// If there are more than this number of flags in total, only the required and
// positional flags will be shown in the one-line usage summary.
ONE_LINE_FLAG_CUTOFF_COUNT :: 16
