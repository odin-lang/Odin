/**
 * Odin binding generator from C header data.
 */

package bindgen

import "core:os"
import "core:fmt"
import "core:runtime"

GeneratorOptions :: struct {
    mode : string, // "odin" or "jai"

    // Variable
    variableCase : Case,

    // Defines
    definePrefixes : []string,
    defineTransparentPrefixes : []string,
    definePostfixes : []string,
    defineTransparentPostfixes : []string,
    defineCase : Case,

    // Pseudo-types
    pseudoTypePrefixes : []string,
    pseudoTypeTransparentPrefixes : []string,
    pseudoTypePostfixes : []string,
    pseudoTypeTransparentPostfixes : []string,
    pseudoTypeCase : Case,

    // Enums
    enumConsideredFlagsPostfixes : []string,

    // Functions
    functionPrefixes : []string,
    functionTransparentPrefixes : []string,
    functionPostfixes : []string,
    functionTransparentPostfixes : []string,
    functionCase : Case,

    // Enum values
    enumValuePrefixes : []string,
    enumValueTransparentPrefixes : []string,
    enumValuePostfixes : []string,
    enumValueTransparentPostfixes : []string,
    enumValueCase : Case,
    enumValueNameRemove : bool,
    enumValueNameRemovePostfixes : []string,

    parserOptions : ParserOptions,
}

GeneratorData :: struct {
    handle : os.Handle,
    nodes : Nodes,

    // References
    foreignLibrary : string,
    options : ^GeneratorOptions,
}

generate :: proc(
    packageName : string,
    foreignLibrary : string,
    outputFile : string,
    headerFiles : []string,
    options : GeneratorOptions,
) {
    options := options;
    data : GeneratorData;
    data.options = &options;
    data.foreignLibrary = foreignLibrary;

    if options.mode == "" {
        options.mode = "odin";
    }

    // Outputing odin file
    errno : os.Errno;

    // chmod 664 when creating file
    mode: int = 0;
    when os.OS == "linux" || os.OS == "darwin" {
        mode = os.S_IRUSR | os.S_IWUSR | os.S_IRGRP | os.S_IWGRP | os.S_IROTH;
    }

    data.handle, errno = os.open(outputFile, os.O_WRONLY | os.O_CREATE | os.O_TRUNC, mode);
    if errno != 0 {
        fmt.eprint("[bindgen] Unable to write to output file ", outputFile, " (", errno ,")\n");
        return;
    }
    defer os.close(data.handle);

    if options.mode == "jai" {
        fcat(data.handle, foreignLibrary, " :: #foreign_library \"", foreignLibrary, "\";\n");
        fcat(data.handle, "\n");
    } else {
        fcat(data.handle, "package ", packageName, "\n");
        fcat(data.handle, "\n");
        fcat(data.handle, "foreign import \"", foreignLibrary, "\"\n");
        fcat(data.handle, "\n");
        fcat(data.handle, "import _c \"core:c\"\n");
        fcat(data.handle, "\n");
    }

    // Parsing header files
    anonymousStructCount = 0;
    anonymousUnionCount = 0;
    anonymousEnumCount = 0;

    for headerFile in headerFiles {
        bytes, ok := os.read_entire_file(headerFile);
        if !ok {
            fmt.eprint("[bindgen] Unable to read file ", headerFile, "\n");
            return;
        }

        // We fuse the SOAs
        headerNodes := parse(bytes, options.parserOptions);
        merge_generic_nodes(&data.nodes.defines, &headerNodes.defines);
        merge_generic_nodes(&data.nodes.enumDefinitions, &headerNodes.enumDefinitions);
        merge_generic_nodes(&data.nodes.unionDefinitions, &headerNodes.unionDefinitions);
        merge_forward_declared_nodes(&data.nodes.structDefinitions, &headerNodes.structDefinitions);
        merge_generic_nodes(&data.nodes.functionDeclarations, &headerNodes.functionDeclarations);
        merge_generic_nodes(&data.nodes.typedefs, &headerNodes.typedefs);
    }

    // Exporting
    export_defines(&data);
    export_typedefs(&data);
    export_enums(&data);
    export_structs(&data);
    export_unions(&data);

    // Foreign block for functions
    if options.mode != "jai" {
        foreignLibrarySimple := simplify_library_name(foreignLibrary);
        fcat(data.handle, "@(default_calling_convention=\"c\")\n");
        fcat(data.handle, "foreign ", foreignLibrarySimple, " {\n");
        fcat(data.handle, "\n");
    }

    export_functions(&data);

    if options.mode != "jai" {
        fcat(data.handle, "}\n");
    }
}

// system:foo.lib -> foo
simplify_library_name :: proc(libraryName : string) -> string {
    startOffset := 0;
    endOffset := len(libraryName);

    for c, i in libraryName {
        if startOffset == 0 && c == ':' {
            startOffset = i + 1;
        }
        else if c == '.' {
            endOffset = i;
            break;
        }
    }

    return libraryName[startOffset:endOffset];
}

merge_generic_nodes :: proc(nodes : ^$T, headerNodes : ^T) {
    for headerNode in headerNodes {
        // Check that there are no duplicated nodes (due to forward declaration or such)
        duplicatedIndex := -1;
        for i := 0; i < len(nodes); i += 1 {
            node := nodes[i];
            if node.name == headerNode.name {
                duplicatedIndex = i;
                break;
            }
        }

        if duplicatedIndex < 0 {
            append(nodes, headerNode);
        }
    }
}

merge_forward_declared_nodes :: proc(nodes : ^$T, headerNodes : ^T) {
    for headerNode in headerNodes {
        // Check that there are no duplicated nodes (due to forward declaration or such)
        duplicatedIndex := -1;
        for i := 0; i < len(nodes); i += 1 {
            node := nodes[i];
            if node.name == headerNode.name {
                duplicatedIndex = i;
                break;
            }
        }

        if duplicatedIndex < 0 {
            append(nodes, headerNode);
        }
        else if !headerNode.forwardDeclared && len(headerNode.members) > 0 {
            nodes[duplicatedIndex] = headerNode;
        }
    }
}
