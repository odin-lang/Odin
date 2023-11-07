package build


Odin_Command_Type :: enum {
    Invalid,
    Build,
    Check,
}

odin :: proc(command_type: Odin_Command_Type) -> bool {
    
    return true
}