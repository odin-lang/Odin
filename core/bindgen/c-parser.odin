package bindgen

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"

// Global counters
anonymousStructCount := 0;
anonymousUnionCount := 0;
anonymousEnumCount := 0;

knownTypeAliases : map[string]Type;

CustomHandler :: proc(data : ^ParserData);
CustomExpressionHandler :: proc(data : ^ParserData) -> LiteralValue;

ParserOptions :: struct {
    ignoredTokens : []string,

    // Handlers
    customHandlers : map[string]CustomHandler,
    customExpressionHandlers : map[string]CustomExpressionHandler,
}

ParserData :: struct {
    bytes : []u8,
    bytesLength : u32,
    offset : u32,

    // References
    nodes : Nodes,
    options : ^ParserOptions,

    // Knowned values
    knownedLiterals : map[string]LiteralValue,

    // Whether we have eaten a '\n' character that has no backslash just before
    foundFullReturn : bool,
}

is_identifier :: proc(token : string) -> bool {
    return (token[0] >= 'a' && token[0] <= 'z') ||
        (token[0] >= 'A' && token[0] <= 'Z') ||
        (token[0] == '_');
}

parse :: proc(bytes : []u8, options : ParserOptions, loc := #caller_location) -> Nodes {
    options := options;

    data : ParserData;
    data.bytes = bytes;
    data.bytesLength = cast(u32) len(bytes);
    data.options = &options;

    for data.offset = 0; data.offset < data.bytesLength; {
        token := peek_token(&data);
        if data.offset == data.bytesLength do break;

        if token in options.customHandlers {
            options.customHandlers[token](&data);
        }
        else if token == "{" || token == "}" || token == ";" {
            eat_token(&data);
        }
        else if token == "extern" {
            check_and_eat_token(&data, "extern");
        }
        else if token == "\"C\"" {
            check_and_eat_token(&data, "\"C\"");
        }
        else if token == "#" {
            parse_directive(&data);
        }
        else if token == "typedef" {
            parse_typedef(&data);
        }
        else if is_identifier(token) {
            parse_variable_or_function_declaration(&data);
        }
        else {
            print_error(&data, loc, "Unexpected token: ", token, ".");
            return data.nodes;
        }
    }

    return data.nodes;
}

parse_any :: proc(data : ^ParserData) -> string {
    offset := peek_token_end(data);
    identifier := extract_string(data, data.offset, offset);
    data.offset = offset;
    return identifier;
}

parse_identifier :: proc(data : ^ParserData, loc := #caller_location) -> string {
    identifier := parse_any(data);

    if (identifier[0] < 'a' || identifier[0] > 'z') &&
        (identifier[0] < 'A' || identifier[0] > 'Z') &&
        (identifier[0] != '_') {
            print_error(data, loc, "Expected identifier but found ", identifier, ".");
        }

    return identifier;
}

parse_type_dimensions :: proc(data : ^ParserData, type : ^Type) {
    token := peek_token(data);
    for token == "[" {
        eat_token(data);
        token = peek_token(data);
        if token == "]" {
            pointerType : PointerType;
            pointerType.type = new(Type);
            pointerType.type^ = type^; // Copy
            type.base = pointerType;
            delete(type.dimensions);
        } else {
            dimension := evaluate_i64(data);
            append(&type.dimensions, cast(u64) dimension);
        }
        check_and_eat_token(data, "]");
        token = peek_token(data);
    }
}

// This will parse anything that look like a type:
// Builtin: char/int/float/...
// Struct-like: struct A/struct { ... }/enum E
// Function pointer: void (*f)(...)
//
// Definition permitted: If a struct-like definition is found, it will generate
// the according Node and return a corresponding type.
parse_type :: proc(data : ^ParserData, definitionPermitted := false) -> Type {
    type : Type;

    // Eat qualifiers
    token := peek_token(data);
    if token == "const" {
        eat_token(data);
        token = peek_token(data);
    }

    // Parse main type
    if token == "struct" {
        type.base = parse_struct_type(data, definitionPermitted);
    }
    else if token == "union" {
        type.base = parse_union_type(data);
    }
    else if token == "enum" {
        type.base = parse_enum_type(data);
    }
    else {
        // Test builtin type
        type.base = parse_builtin_type(data);
        if type.base.(BuiltinType) == BuiltinType.Unknown {
            // Basic identifier type
            identifierType : IdentifierType;
            identifierType.name = parse_identifier(data);
            type.base = identifierType;
        }
    }

    // Eat qualifiers
    token = peek_token(data);
    if token == "const" {
        eat_token(data);
        token = peek_token(data);
    }

    // Check if pointer
    for token == "*" {
        check_and_eat_token(data, "*");
        token = peek_token(data);

        pointerType : PointerType;
        pointerType.type = new(Type);
        pointerType.type^ = type; // Copy

        type.base = pointerType;

        // Eat qualifiers
        if token == "const" {
            eat_token(data);
            token = peek_token(data);
        }
    }

    // Parse array dimensions if any.
    parse_type_dimensions(data, &type);

    // ----- Function pointer type

    if token == "(" {
        check_and_eat_token(data, "(");
        check_and_eat_token(data, "*");

        functionPointerType : FunctionPointerType;
        functionPointerType.returnType = new(Type);
        functionPointerType.returnType^ = type;
        functionPointerType.name = parse_identifier(data);

        check_and_eat_token(data, ")");
        parse_function_parameters(data, &functionPointerType.parameters);

        type.base = functionPointerType;
    }

    return type;
}

parse_builtin_type :: proc(data : ^ParserData) -> BuiltinType {
    previousBuiltinType := BuiltinType.Unknown;
    intFound := false;
    shortFound := false;
    signedFound := false;
    unsignedFound := false;
    longCount := 0;

    for true {
        token := peek_token(data);

        // Attribute
        attributeFound := true;
        if token == "long" do longCount += 1;
        else if token == "short" do shortFound = true;
        else if token == "unsigned" do unsignedFound = true;
        else if token == "signed" do signedFound = true;
        else do attributeFound = false;
        if attributeFound { eat_token(data); continue; }

        // Known type alias
        if token in knownTypeAliases {
            builtinType, ok := knownTypeAliases[token].base.(BuiltinType);
            if ok {
                eat_token(data);
                previousBuiltinType = builtinType;
            }
            break;
        }

        // Classic type and standard types
        if token == "void" { eat_token(data); return BuiltinType.Void; }
        else if token == "int" {
            eat_token(data);
            intFound = true;
        }
        else if token == "float" { eat_token(data); return BuiltinType.Float; }
        else if token == "double" {
            eat_token(data);
            if longCount == 0 do return BuiltinType.Double;
            else do return BuiltinType.LongDouble;
        }
        else if token == "char" {
            eat_token(data);
            if signedFound do return BuiltinType.SChar;
            else if unsignedFound do return BuiltinType.UChar;
            else do return BuiltinType.Char;
        }
        else if token == "__int8" {
            // @note :MicrosoftDumminess __intX are Microsoft's fixed-size integers
            // https://docs.microsoft.com/fr-fr/cpp/cpp/int8-int16-int32-int64
            // and for unsigned version, they prefixed it with "unsigned"...
            eat_token(data);
            if unsignedFound do return BuiltinType.UInt8;
            else do return BuiltinType.Int8;
        }
        else if token == "__int16" {
            eat_token(data);
            if unsignedFound do return BuiltinType.UInt16;
            else do return BuiltinType.Int16;
        }
        else if token == "__int32" {
            eat_token(data);
            if unsignedFound do return BuiltinType.UInt32;
            else do return BuiltinType.Int32;
        }
        else if token == "__int64" {
            eat_token(data);
            if unsignedFound do return BuiltinType.UInt64;
            else do return BuiltinType.Int64;
        }
        else if token == "int8_t" { eat_token(data); return BuiltinType.Int8; }
        else if token == "int16_t" { eat_token(data); return BuiltinType.Int16; }
        else if token == "int32_t" { eat_token(data); return BuiltinType.Int32; }
        else if token == "int64_t" { eat_token(data); return BuiltinType.Int64; }
        else if token == "uint8_t" { eat_token(data); return BuiltinType.UInt8; }
        else if token == "uint16_t" { eat_token(data); return BuiltinType.UInt16; }
        else if token == "uint32_t" { eat_token(data); return BuiltinType.UInt32; }
        else if token == "uint64_t" { eat_token(data); return BuiltinType.UInt64; }
        else if token == "size_t" { eat_token(data); return BuiltinType.Size; }
        else if token == "ssize_t" { eat_token(data); return BuiltinType.SSize; }
        else if token == "ptrdiff_t" { eat_token(data); return BuiltinType.PtrDiff; }
        else if token == "uintptr_t" { eat_token(data); return BuiltinType.UIntPtr; }
        else if token == "intptr_t" { eat_token(data); return BuiltinType.IntPtr; }

        break;
    }

    // Adapt previous builtin type
    if previousBuiltinType == BuiltinType.ShortInt {
        shortFound = true;
    }
    else if previousBuiltinType == BuiltinType.Int {
        intFound = true;
    }
    else if previousBuiltinType == BuiltinType.LongInt {
        longCount += 1;
    }
    else if previousBuiltinType == BuiltinType.LongLongInt {
        longCount += 2;
    }
    else if previousBuiltinType == BuiltinType.UShortInt {
        unsignedFound = true;
        shortFound = true;
    }
    else if previousBuiltinType == BuiltinType.UInt {
        unsignedFound = true;
    }
    else if previousBuiltinType == BuiltinType.ULongInt {
        unsignedFound = true;
        longCount += 1;
    }
    else if previousBuiltinType == BuiltinType.ULongLongInt {
        unsignedFound = true;
        longCount += 2;
    }
    else if (previousBuiltinType != BuiltinType.Unknown) {
        return previousBuiltinType; // float, void, etc.
    }

    // Implicit and explicit int
    if intFound || shortFound || unsignedFound || signedFound || longCount > 0 {
        if unsignedFound {
            if shortFound do return BuiltinType.UShortInt;
            if longCount == 0 do return BuiltinType.UInt;
            if longCount == 1 do return BuiltinType.ULongInt;
            if longCount == 2 do return BuiltinType.ULongLongInt;
        } else {
            if shortFound do return BuiltinType.ShortInt;
            if longCount == 0 do return BuiltinType.Int;
            if longCount == 1 do return BuiltinType.LongInt;
            if longCount == 2 do return BuiltinType.LongLongInt;
        }
    }

    return BuiltinType.Unknown;
}

parse_struct_type :: proc(data : ^ParserData, definitionPermitted : bool) -> IdentifierType {
    check_and_eat_token(data, "struct");

    type : IdentifierType;
    token := peek_token(data);

    if !definitionPermitted || token != "{" {
        type.name = parse_identifier(data);
        token = peek_token(data);
    } else {
        type.name = tcat("AnonymousStruct", anonymousStructCount);
        type.anonymous = true;
        anonymousStructCount += 1;
    }

    if token == "{" {
        node := parse_struct_definition(data);
        node.name = type.name;
    } else if definitionPermitted {
        // @note Whatever happens, we create a definition of the struct,
        // as it might be used to forward declare it and then use it only with a pointer.
        // This for instance the pattern for xcb_connection_t which definition
        // is never known from user API.
        node : StructDefinitionNode;
        node.forwardDeclared = false;
        node.name = type.name;
        append(&data.nodes.structDefinitions, node);
    }

    return type;
}

parse_union_type :: proc(data : ^ParserData) -> IdentifierType {
    check_and_eat_token(data, "union");

    type : IdentifierType;
    token := peek_token(data);

    if token != "{" {
        type.name = parse_identifier(data);
        token = peek_token(data);
    } else {
        type.name = tcat("AnonymousUnion", anonymousUnionCount);
        type.anonymous = true;
        anonymousUnionCount += 1;
    }

    if token == "{" {
        node := parse_union_definition(data);
        node.name = type.name;
    }

    return type;
}

parse_enum_type :: proc(data : ^ParserData) -> IdentifierType {
    check_and_eat_token(data, "enum");

    type : IdentifierType;
    token := peek_token(data);

    if token != "{" {
        type.name = parse_identifier(data);
        token = peek_token(data);
    } else {
        type.name = tcat("AnonymousEnum", anonymousEnumCount);
        type.anonymous = true;
        anonymousEnumCount += 1;
    }

    if token == "{" {
        node := parse_enum_definition(data);
        node.name = type.name;
    }

    return type;
}

/**
 * We only care about defines of some value
 */
parse_directive :: proc(data : ^ParserData) {
    check_and_eat_token(data, "#");

    token := peek_token(data);
    if token == "define" {
        parse_define(data);
    } // We ignore all other directives
    else {
        eat_line(data);
    }
}

parse_define :: proc(data : ^ParserData) {
    check_and_eat_token(data, "define");
    data.foundFullReturn = false;

    node : DefineNode;
    node.name = parse_identifier(data);

    // Does it look like end? It might be a #define with no expression
    if is_define_end(data) {
        node.value = 1;
        append(&data.nodes.defines, node);
        data.knownedLiterals[node.name] = node.value;
    } // Macros are ignored
    else if is_define_macro(data) {
        print_warning("Ignoring define macro for ", node.name, ".");
    }
    else {
        literalValue, ok := evaluate(data);
        if ok {
            node.value = literalValue;
            append(&data.nodes.defines, node);
            data.knownedLiterals[node.name] = node.value;
        }
        else {
            print_warning("Ignoring define expression for ", node.name, ".");
        }
    }

    // Evaluating the expression, we might have already eaten a full return,
    // if so, do nothing.
    if !data.foundFullReturn {
        eat_define_lines(data);
    }
}

// @fixme Move
change_anonymous_node_name :: proc (data : ^ParserData, oldName : string, newName : string) -> bool {
    for i := 0; i < len(data.nodes.structDefinitions); i += 1 {
        if data.nodes.structDefinitions[i].name == oldName {
            data.nodes.structDefinitions[i].name = newName;
            return true;
        }
    }

    for i := 0; i < len(data.nodes.enumDefinitions); i += 1 {
        if data.nodes.enumDefinitions[i].name == oldName {
            data.nodes.enumDefinitions[i].name = newName;
            return true;
        }
    }

    for i := 0; i < len(data.nodes.unionDefinitions); i += 1 {
        if data.nodes.unionDefinitions[i].name == oldName {
            data.nodes.unionDefinitions[i].name = newName;
            return true;
        }
    }

    return false;
}

/**
 * Type aliasing.
 *  typedef <sourceType> <name>;
 */
parse_typedef :: proc(data : ^ParserData) {
    check_and_eat_token(data, "typedef");

    // @note Struct-like definitions (and such)
    // are generated within type parsing.
    //
    // So that typedef struct { int foo; }* Ap; is valid.

    // Parsing type
    node : TypedefNode;
    node.type = parse_type(data, true);

    if sourceType, ok := node.type.base.(FunctionPointerType); ok {
        node.name = sourceType.name;
    } else {
        node.name = parse_identifier(data);
    }

    // Checking if function type
    token := peek_token(data);
    if token == "(" {
        functionType : FunctionType;
        functionType.returnType = new(Type);
        functionType.returnType^ = node.type;

        parse_function_parameters(data, &functionType.parameters);

        node.type.base = functionType;
    }

    // Checking if array
    parse_type_dimensions(data, &node.type);

    // If the underlying type is anonymous,
    // we just affect it the name.
    addTypedefNode := true;
    if identifierType, ok := node.type.base.(IdentifierType); ok {
        if identifierType.anonymous {
            addTypedefNode = !change_anonymous_node_name(data, identifierType.name, node.name);
        }
    }

    if addTypedefNode {
        knownTypeAliases[node.name] = node.type;
        append(&data.nodes.typedefs, node);
    }

    check_and_eat_token(data, ";");

    // @note Commented tool for debug
    // fmt.println("Typedef: ", node.type, node.name);
}

parse_struct_definition :: proc(data : ^ParserData) -> ^StructDefinitionNode {
    node : StructDefinitionNode;
    node.forwardDeclared = false;
    parse_struct_or_union_members(data, &node.members);

    append(&data.nodes.structDefinitions, node);
    return &data.nodes.structDefinitions[len(data.nodes.structDefinitions) - 1];
}

parse_union_definition :: proc(data : ^ParserData) -> ^UnionDefinitionNode {
    node : UnionDefinitionNode;
    parse_struct_or_union_members(data, &node.members);

    append(&data.nodes.unionDefinitions, node);
    return &data.nodes.unionDefinitions[len(data.nodes.unionDefinitions) - 1];
}

parse_enum_definition :: proc(data : ^ParserData) -> ^EnumDefinitionNode {
    node : EnumDefinitionNode;
    parse_enum_members(data, &node.members);

    append(&data.nodes.enumDefinitions, node);
    return &data.nodes.enumDefinitions[len(data.nodes.enumDefinitions) - 1];
}

/**
 *  {
 *      <name> = <value>,
 *      <name>,
 *  }
 */
parse_enum_members :: proc(data : ^ParserData, members : ^[dynamic]EnumMember) {
    check_and_eat_token(data, "{");

    nextMemberValue : i64 = 0;
    token := peek_token(data);
    for token != "}" {
        member : EnumMember;
        member.name = parse_identifier(data);
        member.hasValue = false;

        token = peek_token(data);
        if token == "=" {
            check_and_eat_token(data, "=");

            member.hasValue = true;
            member.value = evaluate_i64(data);
            nextMemberValue = member.value;
            token = peek_token(data);
        } else {
            member.value = nextMemberValue;
        }

        data.knownedLiterals[member.name] = member.value;
        nextMemberValue += 1;

        // Eat until end, as this might be a complex expression that we couldn't understand
        if token != "," && token != "}" {
            print_warning("Parser cannot understand fully the expression of enum member ", member.name, ".");
            for token != "," && token != "}" {
                eat_token(data);
                token = peek_token(data);
            }
        }
        if token == "," {
            check_and_eat_token(data, ",");
            token = peek_token(data);
        }

        append(members, member);
    }

    check_and_eat_token(data, "}");
}

/**
 *  {
 *      <type> <name>;
 *      <type> <name1>, <name2>;
 *      <type> <name>[<dimension>];
 *  }
 */
parse_struct_or_union_members :: proc(data : ^ParserData, structOrUnionMembers : ^[dynamic]StructOrUnionMember) {
    check_and_eat_token(data, "{");

    // To ensure unique id
    unamedCount := 0;

    token := peek_token(data);
    for token != "}" {
        member : StructOrUnionMember;
        member.type = parse_type(data, true);

        for true {
            // In the case of function pointer types, the name has been parsed
            // during type inspection.
            if type, ok := member.type.base.(FunctionPointerType); ok {
                member.name = type.name;
            }
            else {
                // Unamed (struct or union)
                token = peek_token(data);
                if !is_identifier(token) {
                    member.name = tcat("unamed", unamedCount);
                    unamedCount += 1;
                }
                else {
                    member.name = parse_identifier(data);
                }
            }

            parse_type_dimensions(data, &member.type);

            token = peek_token(data);
            if token == ":" {
                check_and_eat_token(data, ":");
                print_warning("Found bitfield in struct, which is not handled correctly.");
                evaluate_i64(data);
                token = peek_token(data);
            }

            append(structOrUnionMembers, member);

            // Multiple declarations on one line
            if token == "," {
                check_and_eat_token(data, ",");
                continue;
            }

            break;
        }

        check_and_eat_token(data, ";");
        token = peek_token(data);
    }

    check_and_eat_token(data, "}");
}

parse_variable_or_function_declaration :: proc(data : ^ParserData) {
    type := parse_type(data, true);

    // If it's just a type, it might be a struct definition
    token := peek_token(data);
    if token == ";" {
        check_and_eat_token(data, ";");
        return;
    }

    // Eat array declaration if any
    // @fixme The return type of a function declaration will be wrong!
    for data.bytes[data.offset] == '[' {
        for data.bytes[data.offset] != ']' {
            data.offset += 1;
        }
        data.offset += 1;
    }

    name := parse_identifier(data);

    token = peek_token(data);
    if token == "(" {
        functionDeclarationNode := parse_function_declaration(data);
        functionDeclarationNode.returnType = type;
        functionDeclarationNode.name = name;
        return;
    } else if token == "[" {
        // Eat whole array declaration
        for data.bytes[data.offset] == '[' {
            for data.bytes[data.offset] != ']' {
                data.offset += 1;
            }
            data.offset += 1;
        }
    }

    // Global variable declaration (with possible multiple declarations)
    token = peek_token(data);

    for true {
        if token == "," {
            print_warning("Found global variable declaration '", name, "', we won't generated any binding for it.");
            check_and_eat_token(data, ",");

            name = parse_identifier(data);
            token = peek_token(data);
            continue;
        }
        else if token == ";" {
            if name != "" {
                print_warning("Found global variable declaration '", name, "', we won't generated any binding for it.");
            }
            check_and_eat_token(data, ";");
            break;
        }

        // Global variable assignment, considered as constant define.
        node : DefineNode;

        check_and_eat_token(data, "=");
        literalValue, ok := evaluate(data);
        if ok {
            node.name = name;
            node.value = literalValue;
            append(&data.nodes.defines, node);
        }
        else {
            print_warning("Ignoring global variable expression for '", name, "'.");
        }

        name = "";
        token = peek_token(data);
    }
}

parse_function_declaration :: proc(data : ^ParserData) -> ^FunctionDeclarationNode {
    node : FunctionDeclarationNode;

    parse_function_parameters(data, &node.parameters);

    // Function definition? Ignore it.
    token := peek_token(data);
    if token == "{" {
        bracesCount := 1;
        for true {
            data.offset += 1;
            if data.bytes[data.offset] == '{' do bracesCount += 1;
            else if data.bytes[data.offset] == '}' do bracesCount -= 1;
            if bracesCount == 0 do break;
        }
        data.offset += 1;
    } // Function declaration
    else {
        check_and_eat_token(data, ";");
    }

    append(&data.nodes.functionDeclarations, node);
    return &data.nodes.functionDeclarations[len(data.nodes.functionDeclarations) - 1];
}

parse_function_parameters :: proc(data : ^ParserData, parameters : ^[dynamic]FunctionParameter) {
    check_and_eat_token(data, "(");

    token := peek_token(data);
    for token != ")" {
        parameter : FunctionParameter;

        token = peek_token(data);
        if token == "." {
            print_warning("A function accepts variadic arguments, this is currently not handled within generated code.");

            check_and_eat_token(data, ".");
            check_and_eat_token(data, ".");
            check_and_eat_token(data, ".");
            break;
        } else {
            parameter.type = parse_type(data);
        }

        // Check if named parameter
        token = peek_token(data);
        if token != ")" && token != "," {
            parameter.name = parse_identifier(data);
            parse_type_dimensions(data, &parameter.type);
            token = peek_token(data);
        }

        if token == "," {
            eat_token(data);
            token = peek_token(data);
        }

        append(parameters, parameter);
    }

    check_and_eat_token(data, ")");
}
