package bindgen

import "core:fmt"

// Prevent keywords clashes and other tricky cases
clean_identifier :: proc(name : string) -> string {
    name := name;

    if name == "" {
        return name;
    }

    // Starting with _? Try removing that.
    for true {
        if name[0] == '_' {
            name = name[1:];
        }
        else {
            break;
        }
    }

    // Number
    if name[0] >= '0' && name[0] <= '9' {
        return tcat("_", name);
    } // Keywords clash
    else if name == "map" || name == "proc" || name == "opaque" || name == "in" {
        return tcat("_", name);
    } // Jai keywords clash
    else if name == "context" ||
            name == "float32" || name == "float64" ||
            name == "s8" || name == "s16" || name == "s32" || name == "s64" ||
            name == "u8" || name == "u16" || name == "u32" || name == "u64" {
        return tcat("_", name);
    }

    return name;
}

clean_variable_name :: proc(name : string, options : ^GeneratorOptions) -> string {
    name := name;
    name = change_case(name, options.variableCase);
    return clean_identifier(name);
}

clean_pseudo_type_name :: proc(structName : string, options : ^GeneratorOptions) -> string {
    structName := structName;
    structName = remove_postfixes(structName, options.pseudoTypePostfixes, options.pseudoTypeTransparentPostfixes);
    structName = remove_prefixes(structName, options.pseudoTypePrefixes, options.pseudoTypeTransparentPrefixes);
    structName = change_case(structName, options.pseudoTypeCase);
    return structName;
}

// Clean up the enum name so that it can be used to remove the prefix from enum values.
clean_enum_name_for_prefix_removal :: proc(enumName : string, options : ^GeneratorOptions) -> (string, [dynamic]string) {
    enumName := enumName;

    if !options.enumValueNameRemove {
        return enumName, nil;
    }

    // Remove postfix and use same case convention as the enum values
    removedPostfixes : [dynamic]string;
    enumName, removedPostfixes = remove_postfixes_with_removed(enumName, options.enumValueNameRemovePostfixes);
    enumName = change_case(enumName, options.enumValueCase);
    return enumName, removedPostfixes;
}

clean_enum_value_name :: proc(valueName : string, enumName : string, postfixes : []string, options : ^GeneratorOptions) -> string {
    valueName := valueName;

    valueName = remove_prefixes(valueName, options.enumValuePrefixes, options.enumValueTransparentPrefixes);
    valueName = remove_postfixes(valueName, postfixes, options.enumValueTransparentPostfixes);

    if options.enumValueNameRemove {
        valueName = remove_prefixes(valueName, []string{enumName});
    }

    valueName = change_case(valueName, options.enumValueCase);

    return clean_identifier(valueName);
}

clean_function_name :: proc(functionName : string, options : ^GeneratorOptions) -> string {
    functionName := functionName;
    functionName = remove_prefixes(functionName, options.functionPrefixes, options.functionTransparentPrefixes);
    functionName = remove_postfixes(functionName, options.definePostfixes, options.defineTransparentPostfixes);
    functionName = change_case(functionName, options.functionCase);
    return functionName;
}

clean_define_name :: proc(defineName : string, options : ^GeneratorOptions) -> string {
    defineName := defineName;
    defineName = remove_prefixes(defineName, options.definePrefixes, options.defineTransparentPrefixes);
    defineName = remove_postfixes(defineName, options.definePostfixes, options.defineTransparentPostfixes);
    defineName = change_case(defineName, options.defineCase);
    return defineName;
}

// Convert to Odin's types
clean_type :: proc(data : ^GeneratorData, type : Type, baseTab : string = "", explicitSharpType := true) -> string {
    output := "";

    for dimension in type.dimensions {
        output = tcat(output, "[", dimension, "]");
    }
    output = tcat(output, clean_base_type(data, type.base, baseTab, explicitSharpType));

    return output;
}

clean_base_type :: proc(data : ^GeneratorData, baseType : BaseType, baseTab : string = "", explicitSharpType := true) -> string {
    options := data.options;

    if _type, ok := baseType.(BuiltinType); ok {
        if _type == BuiltinType.Void do return options.mode == "jai" ? "void" : "";
        else if _type == BuiltinType.Int do return options.mode == "jai" ? "s64" : "_c.int";
        else if _type == BuiltinType.UInt do return options.mode == "jai" ? "u64" :"_c.uint";
        else if _type == BuiltinType.LongInt do return options.mode == "jai" ? "s64" :"_c.long";
        else if _type == BuiltinType.ULongInt do return options.mode == "jai" ? "u64" :"_c.ulong";
        else if _type == BuiltinType.LongLongInt do return options.mode == "jai" ? "s64" :"_c.longlong";
        else if _type == BuiltinType.ULongLongInt do return options.mode == "jai" ? "u64" :"_c.ulonglong";
        else if _type == BuiltinType.ShortInt do return options.mode == "jai" ? "s16" :"_c.short";
        else if _type == BuiltinType.UShortInt do return options.mode == "jai" ? "u16" :"_c.ushort";
        else if _type == BuiltinType.Char do return options.mode == "jai" ? "u8" :"_c.char";
        else if _type == BuiltinType.SChar do return options.mode == "jai" ? "s8" :"_c.schar";
        else if _type == BuiltinType.UChar do return options.mode == "jai" ? "u8" :"_c.uchar";
        else if _type == BuiltinType.Float do return options.mode == "jai" ? "float32" :"_c.float";
        else if _type == BuiltinType.Double do return options.mode == "jai" ? "float64" :"_c.double";
        else if _type == BuiltinType.LongDouble {
            print_warning("Found long double which is currently not supported. Fallback to double in generated code.");
            return options.mode == "jai" ? "double" :"_c.double";
        }
        else if _type == BuiltinType.Int8 do return options.mode == "jai" ? "s8" :"i8";
        else if _type == BuiltinType.Int16 do return options.mode == "jai" ? "s16" :"i16";
        else if _type == BuiltinType.Int32 do return options.mode == "jai" ? "s32" :"i32";
        else if _type == BuiltinType.Int64 do return options.mode == "jai" ? "s64" :"i64";
        else if _type == BuiltinType.UInt8 do return options.mode == "jai" ? "u8" :"u8";
        else if _type == BuiltinType.UInt16 do return options.mode == "jai" ? "u16" :"u16";
        else if _type == BuiltinType.UInt32 do return options.mode == "jai" ? "u32" :"u32";
        else if _type == BuiltinType.UInt64 do return options.mode == "jai" ? "u64" :"u64";
        else if _type == BuiltinType.Size do return options.mode == "jai" ? "u64" :"_c.size_t";
        else if _type == BuiltinType.SSize do return options.mode == "jai" ? "u64" :"_c.ssize_t";
        else if _type == BuiltinType.PtrDiff do return options.mode == "jai" ? "s64" :"_c.ptrdiff_t";
        else if _type == BuiltinType.UIntPtr do return options.mode == "jai" ? "u64" :"_c.uintptr_t";
        else if _type == BuiltinType.IntPtr do return options.mode == "jai" ? "s64" :"_c.intptr_t";
    }
    else if _type, ok := baseType.(PointerType); ok {
        if options.mode == "jai" {
            // Hide pointers to types that were not declared.
            if !is_known_base_type(data, _type.type.base) {
                print_warning("*", _type.type.base.(IdentifierType).name, " replaced by *void as the pointed type is unknown.");
                return "*void";
            }
        } else {
            if __type, ok := _type.type.base.(BuiltinType); ok {
                if __type == BuiltinType.Void do return "rawptr";
                else if __type == BuiltinType.Char do return "cstring";
            }
        }
        name := clean_type(data, _type.type^, baseTab);
        return tcat(options.mode == "jai" ? "*" :"^", name);
    }
    else if _type, ok := baseType.(IdentifierType); ok {
        return clean_pseudo_type_name(_type.name, options);
    }
    else if _type, ok := baseType.(FunctionType); ok {
        output : string;
        if explicitSharpType {
            output = "#type ";
        }
        output = tcat(output, options.mode == "jai" ? "(" :"proc(");
        parameters := clean_function_parameters(data, _type.parameters, baseTab);
        output = tcat(output, parameters, ")");

        returnType := clean_type(data, _type.returnType^);
        if len(returnType) > 0 && returnType != "void" {
            output = tcat(output, " -> ", returnType);
        }
        return output;
    }
    else if _type, ok := baseType.(FunctionPointerType); ok {
        output : string;
        if explicitSharpType {
            output = "#type ";
        }
        output = tcat(output, options.mode == "jai" ? "(" :"proc(");
        parameters := clean_function_parameters(data, _type.parameters, baseTab);
        output = tcat(output, parameters, ")");

        returnType := clean_type(data, _type.returnType^);
        if len(returnType) > 0 && returnType != "void" {
            output = tcat(output, " -> ", returnType);
        }

        if options.mode == "jai" {
            output = tcat(output, " #foreign");
        }
        return output;
    }

    return "<niy>";
}

clean_function_parameters :: proc(data : ^GeneratorData, parameters : [dynamic]FunctionParameter, baseTab : string) -> string {
    output := "";
    options := data.options;

    // Special case: function(void) does not really have a parameter
    if len(parameters) == 1 {
        if _type, ok := parameters[0].type.base.(BuiltinType); ok {
            if _type == BuiltinType.Void {
                return "";
            }
        }
    }

    tab := "";
    if options.mode == "jai" { // @note :OdinCodingStyle Odin forces a coding style, now. Ugh.
        if (len(parameters) > 1) {
            output = tcat(output, "\n");
            tab = tcat(baseTab, "    ");
        }
    }

    unamedParametersCount := 0;
    for parameter, i in parameters {
        type := clean_type(data, parameter.type);

        name : string;
        if len(parameter.name) != 0 {
            name = clean_variable_name(parameter.name, options);
        } else {
            name = tcat("unamed", unamedParametersCount);
            unamedParametersCount += 1;
        }

        output = tcat(output, tab, name, " : ", type);

        if i != len(parameters) - 1 {
            if options.mode == "jai" { // @note :OdinCodingStyle
                output = tcat(output, ",\n");
            } else {
                output = tcat(output, ", ");
            }
        }
    }

    if (len(parameters) > 1) {
        if options.mode == "jai" { // @note :OdinCodingStyle
            output = tcat(output, "\n", baseTab);
        }
    }

    return output;
}

is_known_base_type :: proc(data : ^GeneratorData, baseType : BaseType) -> bool {
    if _type, ok := baseType.(IdentifierType); ok {
        for it in data.nodes.typedefs {
            if _type.name == it.name {
                return true;
            }
        }
        for it in data.nodes.structDefinitions {
            if _type.name == it.name {
                return true;
            }
        }
        for it in data.nodes.enumDefinitions {
            if _type.name == it.name {
                return true;
            }
        }
        for it in data.nodes.unionDefinitions {
            if _type.name == it.name {
                return true;
            }
        }
        return false;
    }

    return true;
}
