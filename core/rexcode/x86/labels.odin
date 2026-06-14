package rexcode_x86

// =============================================================================
// x86 LABELS
// =============================================================================
//
// Type aliases to the array-index label model in `isa/labels.odin`, so
// callers can construct values like `x86.Label_Definition(3)` without
// importing `isa`. The label-construction procedures themselves
// (`label`, `label_forward`, `label_set_at`, `label_named`,
// `label_reserve`, `label_set`, `label_map_init/destroy`) are parametric
// over the Instruction type and live in `isa/labels.odin` -- callers
// invoke them directly as `isa.<proc>(...)`.

import "../isa"

Label_Definition :: isa.Label_Definition
Label_Map        :: isa.Label_Map
LABEL_UNDEFINED  :: isa.LABEL_UNDEFINED
