package bindgen

import "core:fmt"
import "core:os"
import "core:io"
import "core:strings"
import "core:unicode/utf8"

Case :: enum {
    Unknown,
    Camel,
    Constant,
    Kebab,
    Pascal,
    Snake,
}

WordCase :: enum {
    Unknown,
    Up,
    Low,
    FirstUp,
    // When first upping, numbers are followed always by a capital
    FirstUpNumberReset,
}

// Change a character to a capital.
to_uppercase :: proc(c : rune) -> rune {
    c := c;
    if c >= 'a' && c <= 'z' {
        c = c - 'a' + 'A';
    }
    return c;
}

// Change a character to lowercase.
to_lowercase :: proc(c : rune) -> rune {
    c := c;
    if c >= 'A' && c <= 'Z' {
        c = c - 'A' + 'a';
    }
    return c;
}

// @note Stolen tprint and fprint from fmt package, because it was confusing due to args: ..any and sep default parameter.
tcat :: proc(args: ..any) -> string {
    return fmt.tprint(args=args, sep="");
}

fcat :: proc(fd: os.Handle, args: ..any) -> int {
    return fmt.fprint(fd=fd, args=args, sep="");
}

// Change the case convention of a word.
change_word_case :: proc(str : string, targetCase : WordCase) -> string {
    newStr : string;
    if targetCase == WordCase.Up {
        for c in str {
            newStr = tcat(newStr, to_uppercase(c));
        }
    }
    else if targetCase == WordCase.Low {
        for c in str {
            newStr = tcat(newStr, to_lowercase(c));
        }
    }
    else if targetCase == WordCase.FirstUp {
        for c, i in str {
            if i == 0 {
                newStr = tcat(newStr, to_uppercase(c));
            } else {
                newStr = tcat(newStr, to_lowercase(c));
            }
        }
    }
    else if targetCase == WordCase.FirstUpNumberReset {
        for c, i in str {
            if i == 0 || (str[i - 1] >= '0' && str[i - 1] <= '9') {
                newStr = tcat(newStr, to_uppercase(c));
            } else {
                newStr = tcat(newStr, to_lowercase(c));
            }
        }
    }
    return newStr;
}

// Change the case convention of a string by detecting original convention,
// then splitting it into words.
change_case :: proc(str : string, targetCase : Case) -> string {
    if targetCase == Case.Unknown {
        return str;
    }

    // Split
    parts := autosplit_string(str);

    // Join
    newStr : string;
    if targetCase == Case.Pascal {
        for part, i in parts {
            newStr = tcat(newStr, change_word_case(part, WordCase.FirstUpNumberReset));
        }
    }
    else if targetCase == Case.Snake {
        for part, i in parts {
            newStr = tcat(newStr, change_word_case(part, WordCase.Low), (i != len(parts) - 1) ? "_" : "");
        }
    }
    else if targetCase == Case.Kebab {
        for part, i in parts {
            newStr = tcat(newStr, change_word_case(part, WordCase.Low), (i != len(parts) - 1) ? "-" : "");
        }
    }
    else if targetCase == Case.Camel {
        for part, i in parts {
            if i == 0 {
                newStr = tcat(newStr, change_word_case(part, WordCase.Low));
            } else {
                newStr = tcat(newStr, change_word_case(part, WordCase.FirstUpNumberReset));
            }
        }
    }
    else if targetCase == Case.Constant {
        for part, i in parts {
            newStr = tcat(newStr, change_word_case(part, WordCase.Up), (i != len(parts) - 1) ? "_" : "");
        }
    }

    return newStr;
}

// Identify the case of the provided string.
// Full lowercase with no separator is identified as camelCase.
find_case :: proc(str : string) -> Case {
    refuted : bool;

    // CONSTANT_CASE
    refuted = false;
    for c in str {
        if (c != '_') && (c < 'A' || c > 'Z') && (c < '0' || c > '9') {
            refuted = true;
            break;
        }
    }
    if !refuted do return Case.Constant;

    for c in str {
        // snake_case
        if c == '_' {
            return Case.Snake;
        } // kebab-case
        else if c == '-' {
            return Case.Kebab;
        }
    }

    // PascalCase
    if str[0] >= 'A' && str[0] <= 'Z' {
        return Case.Pascal;
    }

    // camelCase
    return Case.Camel;
}

// Splits the string according to detected case.
//  HeyBuddy -> {"Hey", "Buddy"}
//  hey-buddy -> {"hey", "buddy"}
//  _hey_buddy -> {"", "hey", "buddy"}
// and such...
autosplit_string :: proc(str : string) -> [dynamic]string {
    lowCount := 0;
    upCount := 0;
    for c in str {
        // If any '_', split according to that (CONSTANT_CASE or snake_case)
        if c == '_' {
            return split_from_separator(str, '_');
        } // If any '-', split according to that (kebab-case)
        else if c == '-' {
            return split_from_separator(str, '-');
        }
        else if c >= 'a' && c <= 'z' {
            lowCount += 1;
        }
        else if c >= 'A' && c <= 'Z' {
            upCount += 1;
        }
    }

    // If it seems to be only one word
    if lowCount == 0 || upCount == 0 {
        parts : [dynamic]string;
        append(&parts, str);
        return parts;
    }

    // Split at each uppercase letter (PascalCase or camelCase)
    return split_from_capital(str);
}

split_from_separator :: proc(str : string, sep : rune) -> [dynamic]string {
    parts : [dynamic]string;

    lastI := 0;

    // Empty strings for starting separators in string
    for c in str {
        if c == sep {
            append(&parts, "");
            lastI += 1;
        } else {
            break;
        }
    }

    // Ignore non letter prefix
    if lastI == 0 {
        for c in str {
            if (c < 'a' || c > 'z') && (c < 'A' || c > 'Z') {
                lastI += 1;
            }
            else {
                break;
            }
        }
    }

    for c, i in str {
        if i > lastI + 1 && c == sep {
            append(&parts, str[lastI:i]);
            lastI = i + 1;
        }
    }

    append(&parts, str[lastI:]);

    return parts;
}

split_from_capital :: proc(str : string) -> [dynamic]string {
    parts : [dynamic]string;

    // Ignore non letter prefix
    lastI := 0;
    for c in str {
        if (c < 'a' || c > 'z') && (c < 'A' || c > 'Z') {
            lastI += 1;
        }
        else {
            break;
        }
    }

    // We want to handle:
    //      myBrainIsCRAZY  -> my Brain Is Crazy
    //      myCRAZYBrain    -> my CRAZY Brain
    //      SOLO            -> SOLO

    // Do split
    for i := 1; i < len(str); i += 1 {
        if str[i] >= 'A' && str[i] <= 'Z' {
            // Do not split too much if it seems to be a capitalized word
            if (lastI == i - 1) && (str[lastI] >= 'A' && str[lastI] <= 'Z') {
                for ; i + 1 < len(str); i += 1 {
                    if str[i + 1] < 'A' || str[i + 1] > 'Z' {
                        break;
                    }
                }
                if (i + 1 == len(str)) && (str[i] >= 'A' && str[i] <= 'Z') {
                    i += 1;
                }
            }

            append(&parts, str[lastI:i]);
            lastI = i;
        }
    }

    if lastI != len(str) {
        append(&parts, str[lastI:]);
    }

    return parts;
}

// Check if str if prefixed with any of the provided strings,
// even combinaisons of those, and remove them.
remove_prefixes :: proc(str : string, prefixes : []string, transparentPrefixes : []string = nil) -> string {
    str := str;
    transparentStr := "";

    found := true;
    for found {
        found = false;

        // Remove effective prefixes
        for prefix in prefixes {
            if len(str) >= len(prefix) &&
            str[:len(prefix)] == prefix {
                str = str[len(prefix):];
                if len(str) != 0 && (str[0] == '_' || str[0] == '-') {
                    str = str[1:];
                }
                found = true;
                break;
            }
        }

        if found do continue;

        // Remove transparent ones, only one by one,
        // as we want effective ones to be fully removed.
        for prefix in transparentPrefixes {
            if len(str) >= len(prefix) &&
            str[:len(prefix)] == prefix {
                str = str[len(prefix):];
                transparentStr = tcat(transparentStr, prefix);
                if len(str) != 0 && (str[0] == '_' || str[0] == '-') {
                    str = str[1:];
                    transparentStr = tcat(transparentStr, '_');
                }
                found = true;
                break;
            }
        }
    }

    return tcat(transparentStr, str);
}

// Check if str if postfixes with any of the provided strings,
// even combinaisons of those, and remove them.
remove_postfixes_with_removed :: proc(
    str : string,
    postfixes : []string,
    transparentPostfixes : []string = nil) -> (string, [dynamic]string) {
    str := str;
    removedPostfixes : [dynamic]string;
    transparentStr := "";

    found := true;
    for found {
        found = false;

        // Remove effective postfixes
        for postfix in postfixes {
            if ends_with(str, postfix) {
                str = str[:len(str) - len(postfix)];
                if len(str) != 0 && (str[len(str)-1] == '_' || str[len(str)-1] == '-') {
                    str = str[:len(str)-1];
                }
                append(&removedPostfixes, postfix);
                found = true;
                break;
            }
        }

        if found do continue;

        // Remove transparent ones, only one by one,
        // as we want effective ones to be fully removed.
        for postfix in transparentPostfixes {
            if ends_with(str, postfix) {
                str = str[:len(str) - len(postfix)];
                transparentStr = tcat(postfix, transparentStr);
                if len(str) != 0 && (str[len(str)-1] == '_' || str[len(str)-1] == '-') {
                    str = str[:len(str)-1];
                    transparentStr = tcat('_', transparentStr);
                }
                found = true;
                break;
            }
        }
    }

    return tcat(str, transparentStr), removedPostfixes;
}

remove_postfixes :: proc(
    str : string,
    postfixes : []string,
    transparentPostfixes : []string = nil) -> string {
    str := str;
    removedPostfixes : [dynamic]string;
    str, removedPostfixes = remove_postfixes_with_removed(str, postfixes, transparentPostfixes);
    return str;
}

ends_with :: proc(str : string, postfix : string) -> bool {
    return len(str) >= len(postfix) && str[len(str) - len(postfix):] == postfix;
}
