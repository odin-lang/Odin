import re
import urllib.request as req
from tokenize import tokenize
from io import BytesIO
import string
import os.path
import math

file_and_urls = [
    ("vk_platform.h",    'https://raw.githubusercontent.com/KhronosGroup/Vulkan-Headers/main/include/vulkan/vk_platform.h',    True),
    ("vulkan_core.h",    'https://raw.githubusercontent.com/KhronosGroup/Vulkan-Headers/main/include/vulkan/vulkan_core.h',    False),
    ("vk_layer.h",       'https://raw.githubusercontent.com/KhronosGroup/Vulkan-Headers/main/include/vulkan/vk_layer.h',       True),
    ("vk_icd.h",         'https://raw.githubusercontent.com/KhronosGroup/Vulkan-Headers/main/include/vulkan/vk_icd.h',         True),
    ("vulkan_win32.h",   'https://raw.githubusercontent.com/KhronosGroup/Vulkan-Headers/main/include/vulkan/vulkan_win32.h',   False),
    ("vulkan_metal.h",   'https://raw.githubusercontent.com/KhronosGroup/Vulkan-Headers/main/include/vulkan/vulkan_metal.h',   False),
    ("vulkan_macos.h",   'https://raw.githubusercontent.com/KhronosGroup/Vulkan-Headers/main/include/vulkan/vulkan_macos.h',   False),
    ("vulkan_ios.h",     'https://raw.githubusercontent.com/KhronosGroup/Vulkan-Headers/main/include/vulkan/vulkan_ios.h',     False),
    ("vulkan_wayland.h", 'https://raw.githubusercontent.com/KhronosGroup/Vulkan-Headers/main/include/vulkan/vulkan_wayland.h', False),
    ("vulkan_xlib.h",    'https://raw.githubusercontent.com/KhronosGroup/Vulkan-Headers/main/include/vulkan/vulkan_xlib.h',    False),
    ("vulkan_xcb.h",     'https://raw.githubusercontent.com/KhronosGroup/Vulkan-Headers/main/include/vulkan/vulkan_xcb.h',     False),
    ("vulkan_beta.h",    'https://raw.githubusercontent.com/KhronosGroup/Vulkan-Headers/main/include/vulkan/vulkan_beta.h',    False),
    # Vulkan Video
    ("vulkan_video_codec_av1std.h",         'https://raw.githubusercontent.com/KhronosGroup/Vulkan-Headers/main/include/vk_video/vulkan_video_codec_av1std.h', False),
    ("vulkan_video_codec_av1std_decode.h",  'https://raw.githubusercontent.com/KhronosGroup/Vulkan-Headers/main/include/vk_video/vulkan_video_codec_av1std_decode.h', False),
    ("vulkan_video_codec_av1std_encode.h",  'https://raw.githubusercontent.com/KhronosGroup/Vulkan-Headers/main/include/vk_video/vulkan_video_codec_av1std_encode.h', False),
    ("vulkan_video_codec_h264std.h",        'https://raw.githubusercontent.com/KhronosGroup/Vulkan-Headers/main/include/vk_video/vulkan_video_codec_h264std.h', False),
    ("vulkan_video_codec_h264std_decode.h", 'https://raw.githubusercontent.com/KhronosGroup/Vulkan-Headers/main/include/vk_video/vulkan_video_codec_h264std_decode.h', False),
    ("vulkan_video_codec_h264std_encode.h", 'https://raw.githubusercontent.com/KhronosGroup/Vulkan-Headers/main/include/vk_video/vulkan_video_codec_h264std_encode.h', False),
    ("vulkan_video_codec_h265std.h",        'https://raw.githubusercontent.com/KhronosGroup/Vulkan-Headers/main/include/vk_video/vulkan_video_codec_h265std.h', False),
    ("vulkan_video_codec_h265std_decode.h", 'https://raw.githubusercontent.com/KhronosGroup/Vulkan-Headers/main/include/vk_video/vulkan_video_codec_h265std_decode.h', False),
    ("vulkan_video_codec_h265std_encode.h", 'https://raw.githubusercontent.com/KhronosGroup/Vulkan-Headers/main/include/vk_video/vulkan_video_codec_h265std_encode.h', False),
]

for file, url, _ in file_and_urls:
    if not os.path.isfile(file):
        with open(file, 'w', encoding='utf-8') as f:
            f.write(req.urlopen(url).read().decode('utf-8'))

src = ""
for file, _, skip in file_and_urls:
    if skip: continue
    with open(file, 'r', encoding='utf-8') as f:
        src += f.read()


def no_vk(t):
    t = t.replace('PFN_vk_icd', 'Procicd')
    t = t.replace('PFN_vk', 'Proc')
    t = t.replace('PFN_', 'Proc')
    t = t.replace('PFN_', 'Proc')

    t = re.sub('(?:Vk|VK_)?(\\w+)', '\\1', t)

    # Vulkan Video
    t = re.sub('(?:Std|STD_|VK_STD)?(\\w+)', '\\1', t)
    return t

OPAQUE_STRUCTS = """
wl_surface       :: struct {} // Opaque struct defined by Wayland
wl_display       :: struct {} // Opaque struct defined by Wayland
xcb_connection_t :: struct {} // Opaque struct defined by xcb
IOSurfaceRef     :: struct {} // Opaque struct defined by Apple’s CoreGraphics framework
"""

def convert_type(t, prev_name, curr_name):
    table = {
        "Bool32":      'b32',
        "float":       'f32',
        "double":      'f64',
        "uint32_t":    'u32',
        "uint64_t":    'u64',
        "size_t":      'int',
        'int16_t':     'i16',
        'int32_t':     'i32',
        'int64_t':     'i64',
        'int':         'c.int',
        'uint8_t':     'u8',
        'int8_t':     'i8',
        "uint16_t":    'u16',
        "char":        "byte",
        "void":        "void",
        "void*":       "rawptr",
        "void *":      "rawptr",
        "char*":       'cstring',
        "const uint32_t* const*": "^[^]u32",
        "const void*": 'rawptr',
        "const char*": 'cstring',
        "const char* const*": '[^]cstring',
        "const ObjectTableEntryNVX* const*": "^^ObjectTableEntryNVX",
        "const void* const *": "[^]rawptr",
        "const AccelerationStructureGeometryKHR* const*": "^[^]AccelerationStructureGeometryKHR",
        "const AccelerationStructureBuildRangeInfoKHR* const*": "^[^]AccelerationStructureBuildRangeInfoKHR",
        "const MicromapUsageEXT* const*": "^[^]MicromapUsageEXT",
        "struct BaseOutStructure": "BaseOutStructure",
        "struct BaseInStructure":  "BaseInStructure",
        "struct wl_display": "wl_display",
        "struct wl_surface": "wl_surface",
        "Display": "XlibDisplay",
        "Window": "XlibWindow",
        "VisualID": "XlibVisualID",
        'v': '',
    }

    if t in table.keys():
        return table[t]

    if t == "":
        return t

    if t.startswith("const"):
        t = convert_type(t[6:], prev_name, curr_name)

    elif t.endswith("*"):
        pointer = "^"
        ttype = t[:len(t)-1]
        elem = convert_type(ttype, prev_name, curr_name)

        if curr_name.endswith("s") or curr_name.endswith("Table"):
            if prev_name.endswith("Count") or prev_name.endswith("Counts"):
                pointer = "[^]"
            elif curr_name.startswith("pp"):
                if elem.startswith("[^]"):
                    pass
                else:
                    pointer = "[^]"
            elif curr_name.startswith("p"):
                pointer = "[^]"

        if curr_name and elem.endswith("Flags"):
            pointer = "[^]"

        return "{}{}".format(pointer, elem)
    elif t[0].isupper():
        return t

    return t

def parse_array(n, t):
    name, length = n.split('[', 1)
    length = no_vk(length[:-1])
    type_ = "[{}]{}".format(length, do_type(t))
    return name, type_

def remove_prefix(text, prefix):
    if text.startswith(prefix):
        return text[len(prefix):]
    return text
def remove_suffix(text, suffix):
    if text.endswith(suffix):
        return text[:-len(suffix)]
    return text


def to_snake_case(name):
    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    return re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1).lower()

ext_suffixes = ["KHR", "EXT", "AMD", "NV", "NVX", "GOOGLE", "KHX"]
ext_suffixes_title = [ext.title() for ext in ext_suffixes]


def fix_arg(arg):
    name = arg

    # Remove useless pointer identifier in field name
    for p in ('s_', 'p_', 'pp_', 'pfn_'):
        if name.startswith(p):
            name = name[len(p)::]
    name = name.replace("__", "_")

    return name


def fix_ext_suffix(name):
    for ext in ext_suffixes_title:
        if name.endswith(ext):
            start = name[:-len(ext)]
            end = name[-len(ext):].upper()
            return start+end
    return name

def to_int(x):
    if x.startswith('0x'):
        return int(x, 16)
    return int(x)

def is_int(x):
    try:
        int(x)
        return True
    except ValueError:
        return False

def fix_enum_arg(name, is_flag_bit=False):
    # name = name.title()
    name = fix_ext_suffix(name)
    if len(name) > 0 and name[0].isdigit() and not name.startswith("0x") and not is_int(name):
        if name[1] == "D":
            name = name[1] + name[0] + (name[2:] if len(name) > 2 else "")
        else:
            name = "_"+name
    if is_flag_bit:
        name = name.replace("_BIT", "")
    return name

def do_type(t, prev_name="", name=""):
    return convert_type(no_vk(t), prev_name, name).replace("FlagBits", "Flags")

def parse_handles_def(f):
    f.write("// Handles types\n")
    handles = [h for h in re.findall(r"VK_DEFINE_HANDLE\(Vk(\w+)\)", src, re.S)]

    max_len = max(len(h) for h in handles)
    for h in handles:
        f.write("{} :: distinct Handle\n".format(h.ljust(max_len)))

    handles_non_dispatchable = [h for h in re.findall(r"VK_DEFINE_NON_DISPATCHABLE_HANDLE\(Vk(\w+)\)", src, re.S)]
    max_len = max(len(h) for h in handles_non_dispatchable)
    for h in handles_non_dispatchable:
        f.write("{} :: distinct NonDispatchableHandle\n".format(h.ljust(max_len)))


flags_defs = set()

def parse_flags_def(f):
    names = [n for n in re.findall(r"typedef VkFlags Vk(\w+?);", src)]

    global flags_defs
    flags_defs = set(names)


class FlagError(ValueError):
    pass
class IgnoreFlagError(ValueError):
    pass

def fix_enum_name(name, prefix, suffix, is_flag_bit):
    name = remove_prefix(name, prefix)
    if suffix:
        name = remove_suffix(name, suffix)
    if name.startswith("0x"):
        if is_flag_bit:
            i = int(name, 16)
            if i == 0:
                raise IgnoreFlagError(i)
            v = int(math.log2(i))
            if 2**v != i:
                raise FlagError(i)
            return str(v)
        return name
    elif is_flag_bit:
        ignore = False
        try:
            if int(name) == 0:
                ignore = True
        except:
            pass
        if ignore:
            raise IgnoreFlagError()

    return fix_enum_arg(name, is_flag_bit)


def fix_enum_value(value, prefix, suffix, is_flag_bit):
    v = no_vk(value)
    g = tokenize(BytesIO(v.encode('utf-8')).readline)
    tokens = [val for _, val, _, _, _ in g]
    assert len(tokens) > 2
    token = ''.join([t for t in tokens[1:-1] if t])
    token = fix_enum_name(token, prefix, suffix, is_flag_bit)
    return token

def parse_constants(f):
    f.write("// General Constants\n")
    all_data = re.findall(r"#define VK_(\w+)\s*(.*?)U?\n", src, re.S)
    allowed_names = (
        "HEADER_VERSION",
        "MAX_DRIVER_NAME_SIZE",
        "MAX_DRIVER_INFO_SIZE",
    )
    allowed_data = [nv for nv in all_data if nv[0] in allowed_names]
    max_len = max(len(name) for name, value in allowed_data)
    for name, value in allowed_data:
        f.write("{}{} :: {}\n".format(name, "".rjust(max_len-len(name)), value))

    f.write("\n// Vulkan Video Constants\n")
    vulkan_video_data = re.findall(r"#define STD_(\w+)\s*(.*?)U?\n", src, re.S)
    max_len = max(len(name) for name, value in vulkan_video_data)
    for name, value in vulkan_video_data:
        f.write("{}{} :: {}\n".format(name, "".rjust(max_len-len(name)), value))

    f.write("\n// Vulkan Video Codec Constants\n")
    vulkan_video_codec_allowed_suffixes = (
        "_EXTENSION_NAME",
    )
    vulkan_video_codec_data = re.findall(r"#define VK_STD_(\w+)\s*(.*?)U?\n", src, re.S)
    vulkan_video_codec_allowed_data = [nv for nv in vulkan_video_codec_data if nv[0].endswith(vulkan_video_codec_allowed_suffixes)]
    max_len = max(len(name) for name, value in vulkan_video_codec_allowed_data)
    for name, value in vulkan_video_codec_allowed_data:
        f.write("{}{} :: {}\n".format(name, "".rjust(max_len-len(name)), value))

    f.write("\n// Vendor Constants\n")
    fixes = '|'.join(ext_suffixes)
    inner = r"((?:(?:" + fixes + r")\w+)|(?:\w+" + fixes + r"))"
    pattern = r"#define\s+VK_" + inner + r"\s*(.*?)\n"
    data = re.findall(pattern, src, re.S)

    number_suffix_re = re.compile(r"(\d+)[UuLlFf]")

    max_len = max(len(name) for name, value in data)
    for name, value in data:
        value = remove_prefix(value, 'VK_')
        v = number_suffix_re.findall(value)
        if v:
            value = v[0]
        f.write("{}{} :: {}\n".format(name, "".rjust(max_len-len(name)), value))
    f.write("\n")


def parse_enums(f):
    f.write("import \"core:c\"\n\n")
    f.write("// Enums\n")

    data = re.findall(r"typedef enum (\w+) {(.+?)} \w+;", src, re.S)
    data = [(no_vk(n), f) for n, f in data]

    data.sort(key=lambda x: x[0])

    generated_flags = set()

    for name, fields in data:
        enum_name = name

        is_flag_bit = False
        if "FlagBits" in enum_name:
            is_flag_bit = True
            flags_name = enum_name.replace("FlagBits", "Flags")
            enum_name = enum_name.replace("FlagBits", "Flag")
            generated_flags.add(flags_name)
            f.write("{} :: distinct bit_set[{}; Flags]\n".format(flags_name, enum_name))

        if is_flag_bit:
            f.write("{} :: enum Flags {{\n".format(name.replace("FlagBits", "Flag")))
        else:
            f.write("{} :: enum c.int {{\n".format(name))

        prefix = to_snake_case(name).upper()
        suffix = None
        for ext in ext_suffixes:
            prefix_new = remove_suffix(prefix, "_"+ext)
            assert suffix is None
            if prefix_new != prefix:
                suffix = "_"+ext
                prefix = prefix_new
                break


        prefix = prefix.replace("_FLAG_BITS", "")
        prefix += "_"

        ff = []

        names_and_values = re.findall(r"VK_(\w+?) = (.*?)(?:,|})", fields, re.S)

        groups = []
        flags = {}

        for name, value in names_and_values:
            n = fix_enum_name(name, prefix, suffix, is_flag_bit)
            try:
                v = fix_enum_value(value, prefix, suffix, is_flag_bit)
            except FlagError as e:
                v = int(str(e))
                groups.append((n, v))
                continue
            except IgnoreFlagError as e:
                groups.append((n, 0))
                continue

            if n == v:
                continue
            try:
                flags[int(v)] = n
            except ValueError as e:
                pass

            if v == "NONE":
                continue

            ff.append((n, v))

        max_flag_value = max([int(v) for n, v in ff if is_int(v)] + [0])
        max_group_value = max([int(v) for n, v in groups if is_int(v)] + [0])
        if max_flag_value < max_group_value:
            if (1<<max_flag_value)+1 < max_group_value:
                ff.append(('_MAX', 31))
                flags[31] = '_MAX'
                pass

        max_len = max([len(n) for n, v in ff] + [0])

        flag_names = set([n for n, v in ff])

        for n, v in ff:
            if is_flag_bit and not is_int(v) and v not in flag_names:
                print("Ignoring", n, "=", v)
                continue
            f.write("\t{} = {},".format(n.ljust(max_len), v))
            if n == "_MAX":
                f.write(" // Needed for the *_ALL bit set")
            f.write("\n")



        f.write("}\n\n")

        for n, v in groups:
            used_flags = []
            for i in range(0, 32):
                if 1<<i & v != 0:
                    if i in flags:
                        used_flags.append('.'+flags[i])
                    else:
                        used_flags.append('{}({})'.format(enum_name, i))
            # Make sure the 's' is after Flags and not the extension name.
            ext_suffix = ''
            for suffix in ext_suffixes:
                if not enum_name.endswith(suffix):
                    continue

                ext_suffix = suffix
                enum_name = remove_suffix(enum_name, ext_suffix)
                break
            s = "{enum_name}s{ext_suffix}_{n} :: {enum_name}s{ext_suffix}{{".format(enum_name=enum_name, ext_suffix=ext_suffix, n=n)
            s += ', '.join(used_flags)
            s += "}\n"
            f.write(s)

        if len(groups) > 0:
            f.write("\n\n")


    unused_flags = [flag for flag in flags_defs if flag not in generated_flags]
    unused_flags.sort()

    max_len = max(len(flag) for flag in unused_flags)
    for flag in unused_flags:
        flag_name = flag.replace("Flags", "Flag")
        f.write("{} :: distinct bit_set[{}; Flags]\n".format(flag.ljust(max_len), flag_name))
        f.write("{} :: enum u32 {{}}\n".format(flag_name.ljust(max_len)))

def parse_fake_enums(f):
    data = re.findall(r"static const Vk(\w+FlagBits2) VK_(\w+?) = (\w+);", src, re.S)

    data.sort(key=lambda x: x[0])

    fake_enums = {}

    for type_name, name, value in data:
        if type_name in fake_enums:
            fake_enums[type_name].append((name,value))
        else:
            fake_enums[type_name] = [(name, value)]

    for name in fake_enums.keys():
        flags_name = name.replace("FlagBits", "Flags")
        enum_name = name.replace("FlagBits", "Flag")
        f.write("{} :: distinct bit_set[{}; Flags64]\n".format(flags_name, enum_name))
        f.write("{} :: enum Flags64 {{\n".format(name.replace("FlagBits", "Flag")))

        prefix = to_snake_case(name).upper()
        suffix = None
        for ext in ext_suffixes:
            prefix_new = remove_suffix(prefix, "_"+ext)
            assert suffix is None
            if prefix_new != prefix:
                suffix = "_"+ext
                prefix = prefix_new
                break


        prefix = prefix.replace("_FLAG_BITS2", "_2")
        prefix += "_"

        ff = []

        groups = []
        flags = {}

        names_and_values = fake_enums[name]

        for name, value in names_and_values:
            value = value.replace("ULL", "")
            n = fix_enum_name(name, prefix, suffix, True)
            try:
                v = fix_enum_value(value, prefix, suffix, True)
            except FlagError as e:
                v = int(str(e))
                groups.append((n, v))
                continue
            except IgnoreFlagError as e:
                groups.append((n, 0))
                continue

            if n == v:
                continue
            try:
                flags[int(v)] = n
            except ValueError as e:
                pass

            if v == "NONE":
                continue

            ff.append((n, v))

        max_flag_value = max([int(v) for n, v in ff if is_int(v)] + [0])
        max_group_value = max([int(v) for n, v in groups if is_int(v)] + [0])
        if max_flag_value < max_group_value:
            if (1<<max_flag_value)+1 < max_group_value:
                ff.append(('_MAX', 31))
                flags[31] = '_MAX'
                pass

        max_len = max([len(n) for n, v in ff] + [0])

        flag_names = set([n for n, v in ff])

        for n, v in ff:
            if not is_int(v) and v not in flag_names:
                print("Ignoring", n, "=", v)
                continue
            f.write("\t{} = {},".format(n.ljust(max_len), v))
            if n == "_MAX":
                f.write(" // Needed for the *_ALL bit set")
            f.write("\n")

        f.write("}\n\n")

class BitfieldError(ValueError):
    pass

def bitfield_type_to_size(type_):
    if type_ == 'u8':
        return 8
    if type_ == 'u16':
        return 16
    if type_ == 'u32':
        return 32
    if type_ == 'u64':
        return 64
    if 'Flags' in type_:
        return 32
    else:
        raise BitfieldError(f"Invalid type for bitfield: {type_}")

def bitfield_size_to_type(size):
    if size == 8:
        return 'u8'
    if size == 16:
        return 'u16'
    if size == 32:
        return 'u32'
    if size == 64:
        return 'u64'
    else:
        raise BitfieldError(f"Invalid size for bitfield: {size}")


class Bitfield:
    class Field:
        def __init__(self, name, type_, bitsize):
            self.name = name
            self.type = type_
            self.bitsize = bitsize
            
    def __init__(self, type_):
        self.bitsize = bitfield_type_to_size(type_)
        self.type = bitfield_size_to_type(self.bitsize)
        self.fields_bitsize = 0
        self.fields = []

    def add_field(self, name, type_, bitsize):
        self.fields.append(Bitfield.Field(name, type_, bitsize))
        self.fields_bitsize += bitsize
        
    def write(self, f, name=None, indent=0, justify=True):
        max_name = 1 if not justify else max([len(f.name) for f in self.fields], default=0)
        max_type = 1 if not justify else max([len(f.type) for f in self.fields], default=0)
        is_bit_set = all([f.bitsize == 1 or f.name == "reserved" for f in self.fields])
        if is_bit_set and name is None:
            raise BitfieldError(f"bit_set can not be anonymous")
            
        if is_bit_set:
            if not name.endswith("Flags"):
                raise BitfieldError(f"bit_set name should end with 'Flags': {name}")
            enum_name = re.sub('Flags$', 'Flag', name)
            f.write("{}{} :: distinct bit_set[{}; {}]\n".format('\t' * indent, name, enum_name, self.type))
            f.write("{}{} :: enum {} {{\n".format('\t' * indent, enum_name, self.type))
            for field in self.fields:
                if field.name != "reserved":
                    f.write("{}{},\n".format('\t' * (indent + 1), field.name))
            f.write(('\t' * indent) + "}\n")
                
        else:
            f.write("{}{} bit_field {} {{\n".format('\t' * indent, name + ' ::' if name else 'using _:', self.type))
            for field in self.fields:
                type_ = field.type.replace("Flags", "Flag")
                f.write("{}{} {} | {},\n".format(
                    '\t' * (indent + 1),
                    (field.name + ":").ljust(max_name + 1),
                    type_.ljust(max_type),
                    field.bitsize))
            f.write(('\t' * indent) + "}" + ("," if name is None else "") + "\n")

def parse_structs(f):
    data = re.findall(r"typedef (struct|union) Vk(\w+?) {(.+?)} \w+?;", src, re.S)
    data += re.findall(r"typedef (struct|union) Std(\w+?) {(.+?)} \w+?;", src, re.S)

    for _type, struct_name, fields in data:
        fields = re.findall(r"\s+(.+?)[\s:]+([_a-zA-Z0-9[\]]+);", fields)

        prev_name = ""
        ffields = []
        bitfield = None
        for type_, fname in fields:
            # If the field name only has a number in it, then it is a C bit field.
            # We will collect all the bit fields and then create either a bit_field or a bit_set.
            if is_int(fname):
                bf_field = type_.split(' ')
                # Get rid of empty spaces
                bf_field = list(filter(bool, bf_field))
                # [type, fieldname]
                assert len(bf_field) == 2, "Failed to parse the bit field!"
                field_type = do_type(bf_field[0])
                bitsize = int(fname)

                # Close the set because the field size is greater than the bitfield type
                if bitfield and (bitfield.fields_bitsize + bitsize) > bitfield_type_to_size(field_type):
                    ffields.append(tuple([None, bitfield]))
                    bitfield = None

                # Raise an error if the field type size is greater than the bitfield type size
                if bitfield is not None and bitfield_type_to_size(bitfield.type) < bitfield_type_to_size(field_type):
                    raise BitfieldError(f"field will not fit in the bitfield: {bitfield.type} < {field_type}")

                # Create a new bitfield if we don't have one
                if not bitfield:
                    bitfield = Bitfield(field_type)

                # Add the field to the bitfield
                bitfield.add_field(bf_field[1], field_type, bitsize)
                continue

            # Close the bitfield because this is not a field
            elif bitfield:
                ffields.append(tuple([None, bitfield]))
                bitfield = None

            if '[' in fname:
                fname, type_ = parse_array(fname, type_)
            n = fix_arg(fname)
            if "Flag_Bits" in type_:
                # comment = " // only single bit set"
                raise BitfieldError("only single bit set")
            t = do_type(type_, prev_name, fname)
            if n == "matrix":
                n = "mat"

            ffields.append(tuple([n, t]))
            prev_name = fname

        # Close the bitfield because we have no more fields
        if bitfield:
            ffields.append(tuple([None, bitfield]))

        # Write the struct as a bitfield if it only has bit fields
        if len(ffields) == 1 and ffields[0][0] is None:
            ffields[0][1].write(f, struct_name, 0, True)
            f.write("\n")

        # Write as a normal struct (or union) if it has other fields
        # and inject anonymous bitfields into the struct if there are any
        else:
            has_anon_bitfield = any(name is None for name, _ in ffields)
            max_len = max([0 if n is None else len(n) for n, _ in ffields], default=0)
            f.write("{} :: struct ".format(struct_name))
            if _type == "union":
                f.write("#raw_union ")
            f.write("{\n")
            for name, type_ in ffields:
                if name is None:
                    # Inject an anonymous bitfield into the struct
                    type_.write(f, None, indent=1, justify=True)
                else:
                    f.write("\t{} {},\n".format((name + ":").ljust(max_len + 1), type_))
            f.write("}\n\n")

    f.write("// Opaque structs\n")
    f.write(OPAQUE_STRUCTS)

    f.write("// Aliases\n")
    data = re.findall(r"typedef Vk(\w+?) Vk(\w+?);", src, re.S)
    aliases = []
    for _type, name in data:
        if _type == "Flags":
            continue
        name = name.replace("FlagBits", "Flag")
        _type = _type.replace("FlagBits", "Flag")

        if name.endswith("Flag2") or name.endswith("Flags2"):
            continue

        aliases.append((name, _type))

    max_len = max([len(n) for n, _ in aliases] + [0])
    for n, t in aliases:
        k = max_len
        f.write("{} :: {}\n".format(n.ljust(k), t))



procedure_map = {}

def parse_procedures(f):
    data = re.findall(r"typedef (\w+\*?) \(\w+ \*(\w+)\)\((.+?)\);", src, re.S)

    group_ff = {"Loader":[], "Misc":[], "Instance":[], "Device":[]}

    for rt, name, fields in data:
        proc_name = no_vk(name)
        pf = []
        prev_name = ""
        for type_, fname, array_len in re.findall(r"(?:\s*|)(.+?)\s*(\w+)(?:\[(\d+)\])?(?:,|$)", fields):
            curr_name = fix_arg(fname)
            ty = do_type(type_, prev_name, curr_name)
            if array_len != "":
                ty = f"^[{array_len}]{ty}"
            pf.append((ty, curr_name))
            prev_name = curr_name

        data_fields = ', '.join(["{}: {}".format(n, t) for t, n in pf if t != ""])

        ts = "proc \"c\" ({})".format(data_fields)
        rt_str = do_type(rt)
        if rt_str != "void":
            ts += " -> {}".format(rt_str)

        procedure_map[proc_name] = ts

        fields_types_name = [do_type(t) for t in re.findall(r"(?:\s*|)(.+?)\s*\w+(?:,|$)", fields)]
        table_name = fields_types_name[0]
        nn = (proc_name, ts)
        if table_name in ('Device', 'Queue', 'CommandBuffer') and proc_name != 'GetDeviceProcAddr':
            group_ff["Device"].append(nn)
        elif table_name in ('Instance', 'PhysicalDevice') or proc_name == 'GetDeviceProcAddr':
            group_ff["Instance"].append(nn)
        elif table_name in ('rawptr', '', 'DebugReportFlagsEXT') or proc_name == 'GetInstanceProcAddr':
            group_ff["Misc"].append(nn)
        else:
            group_ff["Loader"].append(nn)


    f.write("import \"core:c\"\n\n")
    for group_name, ff in group_ff.items():
        ff.sort()
        f.write("// {} Procedure Types\n".format(group_name))
        max_len = max(len(n) for n, t in ff)
        for n, t in ff:
            f.write("{} :: #type {}\n".format(n.ljust(max_len), t.replace('"c"', '"system"')))
        f.write("\n")

def group_functions(f):
    data = re.findall(r"typedef (\w+\*?) \(\w+ \*(\w+)\)\((.+?)\);", src, re.S)
    group_map = {"Loader":[], "Instance":[], "Device":[]}

    for rt, vkname, fields in data:
        fields_types_name = [do_type(t) for t in re.findall(r"(?:\s*|)(.+?)\s*\w+(?:,|$)", fields)]
        table_name = fields_types_name[0]
        name = no_vk(vkname)

        nn = (fix_arg(name), fix_ext_suffix(name))

        if table_name in ('Device', 'Queue', 'CommandBuffer') and name != 'GetDeviceProcAddr':
            group_map["Device"].append(nn)
        elif table_name in ('Instance', 'PhysicalDevice') and name != 'ProcGetInstanceProcAddr' or name == 'GetDeviceProcAddr':
            group_map["Instance"].append(nn)
        elif table_name in ('rawptr', '', 'DebugReportFlagsEXT') or name == 'GetInstanceProcAddr':
            # Skip the allocation function and the dll entry point
            pass
        else:
            group_map["Loader"].append(nn)
    for _, group in group_map.items():
        group.sort()

    for group_name, group_lines in group_map.items():
        f.write("// {} Procedures\n".format(group_name))
        max_len = max(len(name) for name, _ in group_lines)
        for name, vk_name in group_lines:
            type_str = procedure_map[vk_name]
            f.write('{}: {}\n'.format(remove_prefix(name, "Proc"), name.rjust(max_len)))
        f.write("\n")

    f.write("load_proc_addresses_custom :: proc(set_proc_address: SetProcAddressType) {\n")
    for group_name, group_lines in group_map.items():
        f.write("\t// {} Procedures\n".format(group_name))
        max_len = max(len(name) for name, _ in group_lines)
        for name, vk_name in group_lines:
            k = max_len - len(name)
            f.write('\tset_proc_address(&{}, {}"vk{}")\n'.format(
                remove_prefix(name, 'Proc'),
                "".ljust(k),
                remove_prefix(vk_name, 'Proc'),
            ))
        f.write("\n")
    f.write("}\n\n")

    f.write("// Device Procedure VTable\n")
    f.write("Device_VTable :: struct {\n")
    max_len = max(len(name) for name, _ in group_map["Device"])
    for name, vk_name in group_map["Device"]:
        f.write('\t{}: {},\n'.format(remove_prefix(name, "Proc"), name.rjust(max_len)))
    f.write("}\n\n")

    f.write("load_proc_addresses_device_vtable :: proc(device: Device, vtable: ^Device_VTable) {\n")
    for name, vk_name in group_map["Device"]:
        k = max_len - len(name)
        f.write('\tvtable.{}{} = auto_cast GetDeviceProcAddr(device, "vk{}")\n'.format(
            remove_prefix(name, 'Proc'),
            "".ljust(k),
            remove_prefix(vk_name, 'Proc'),
        ))
    f.write("}\n\n")

    f.write("load_proc_addresses_device :: proc(device: Device) {\n")
    max_len = max(len(name) for name, _ in group_map["Device"])
    for name, vk_name in group_map["Device"]:
        k = max_len - len(name)
        f.write('\t{}{} = auto_cast GetDeviceProcAddr(device, "vk{}")\n'.format(
            remove_prefix(name, 'Proc'),
            "".ljust(k),
            remove_prefix(vk_name, 'Proc'),
        ))
    f.write("}\n\n")

    f.write("load_proc_addresses_instance :: proc(instance: Instance) {\n")
    max_len = max(len(name) for name, _ in group_map["Instance"])
    for name, vk_name in group_map["Instance"]:
        k = max_len - len(name)
        f.write('\t{}{} = auto_cast GetInstanceProcAddr(instance, "vk{}")\n'.format(
            remove_prefix(name, 'Proc'),
            "".ljust(k),
            remove_prefix(vk_name, 'Proc'),
        ))
    f.write("\n\t// Device Procedures (may call into dispatch)\n")
    max_len = max(len(name) for name, _ in group_map["Device"])
    for name, vk_name in group_map["Device"]:
        k = max_len - len(name)
        f.write('\t{}{} = auto_cast GetInstanceProcAddr(instance, "vk{}")\n'.format(
            remove_prefix(name, 'Proc'),
            "".ljust(k),
            remove_prefix(vk_name, 'Proc'),
        ))
    f.write("}\n\n")

    f.write("load_proc_addresses_global :: proc(vk_get_instance_proc_addr: rawptr) {\n")
    f.write("\tGetInstanceProcAddr = auto_cast vk_get_instance_proc_addr\n\n")
    max_len = max(len(name) for name, _ in group_map["Loader"])
    for name, vk_name in group_map["Loader"]:
        k = max_len - len(name)
        f.write('\t{}{} = auto_cast GetInstanceProcAddr(nil, "vk{}")\n'.format(
            remove_prefix(name, 'Proc'),
            "".ljust(k),
            remove_prefix(vk_name, 'Proc'),
        ))
    f.write("}\n\n")

    f.write("""
load_proc_addresses :: proc{
\tload_proc_addresses_global,
\tload_proc_addresses_instance,
\tload_proc_addresses_device,
\tload_proc_addresses_device_vtable,
\tload_proc_addresses_custom,
}\n
"""[1::])



BASE = """
//
// Vulkan wrapper generated from "https://raw.githubusercontent.com/KhronosGroup/Vulkan-Headers/master/include/vulkan/vulkan_core.h"
//
package vulkan
"""[1::]


with open("../core.odin", 'w', encoding='utf-8') as f:
    f.write(BASE)
    f.write("""
// Core API
API_VERSION_1_0 :: (1<<22) | (0<<12) | (0)
API_VERSION_1_1 :: (1<<22) | (1<<12) | (0)
API_VERSION_1_2 :: (1<<22) | (2<<12) | (0)
API_VERSION_1_3 :: (1<<22) | (3<<12) | (0)
API_VERSION_1_4 :: (1<<22) | (4<<12) | (0)

MAKE_VERSION :: proc(major, minor, patch: u32) -> u32 {
\treturn (major<<22) | (minor<<12) | (patch)
}

// Base types
Flags         :: distinct u32
Flags64       :: distinct u64
DeviceSize    :: distinct u64
DeviceAddress :: distinct u64
SampleMask    :: distinct u32

Handle                :: distinct rawptr
NonDispatchableHandle :: distinct u64

SetProcAddressType :: #type proc(p: rawptr, name: cstring)


RemoteAddressNV :: distinct rawptr // Declared inline before MemoryGetRemoteAddressInfoNV

// Base constants
LOD_CLAMP_NONE                        :: 1000.0
REMAINING_MIP_LEVELS                  :: ~u32(0)
REMAINING_ARRAY_LAYERS                :: ~u32(0)
WHOLE_SIZE                            :: ~u64(0)
ATTACHMENT_UNUSED                     :: ~u32(0)
TRUE                                  :: 1
FALSE                                 :: 0
QUEUE_FAMILY_IGNORED                  :: ~u32(0)
SUBPASS_EXTERNAL                      :: ~u32(0)
MAX_PHYSICAL_DEVICE_NAME_SIZE         :: 256
MAX_SHADER_MODULE_IDENTIFIER_SIZE_EXT :: 32
UUID_SIZE                             :: 16
MAX_MEMORY_TYPES                      :: 32
MAX_MEMORY_HEAPS                      :: 16
MAX_EXTENSION_NAME_SIZE               :: 256
MAX_DESCRIPTION_SIZE                  :: 256
MAX_DEVICE_GROUP_SIZE                 :: 32
LUID_SIZE_KHX                         :: 8
LUID_SIZE                             :: 8
MAX_QUEUE_FAMILY_EXTERNAL             :: ~u32(1)
MAX_GLOBAL_PRIORITY_SIZE              :: 16
MAX_GLOBAL_PRIORITY_SIZE_EXT          :: MAX_GLOBAL_PRIORITY_SIZE
QUEUE_FAMILY_EXTERNAL                 :: MAX_QUEUE_FAMILY_EXTERNAL

// Vulkan Video API Constants
VULKAN_VIDEO_CODEC_AV1_DECODE_API_VERSION_1_0_0  :: (1<<22) | (0<<12) | (0)
VULKAN_VIDEO_CODEC_AV1_ENCODE_API_VERSION_1_0_0  :: (1<<22) | (0<<12) | (0)
VULKAN_VIDEO_CODEC_H264_ENCODE_API_VERSION_1_0_0 :: (1<<22) | (0<<12) | (0)
VULKAN_VIDEO_CODEC_H264_DECODE_API_VERSION_1_0_0 :: (1<<22) | (0<<12) | (0)
VULKAN_VIDEO_CODEC_H265_DECODE_API_VERSION_1_0_0 :: (1<<22) | (0<<12) | (0)
VULKAN_VIDEO_CODEC_H265_ENCODE_API_VERSION_1_0_0 :: (1<<22) | (0<<12) | (0)

VULKAN_VIDEO_CODEC_AV1_DECODE_SPEC_VERSION  :: VULKAN_VIDEO_CODEC_AV1_DECODE_API_VERSION_1_0_0
VULKAN_VIDEO_CODEC_AV1_ENCODE_SPEC_VERSION  :: VULKAN_VIDEO_CODEC_AV1_ENCODE_API_VERSION_1_0_0
VULKAN_VIDEO_CODEC_H264_ENCODE_SPEC_VERSION :: VULKAN_VIDEO_CODEC_H264_ENCODE_API_VERSION_1_0_0
VULKAN_VIDEO_CODEC_H264_DECODE_SPEC_VERSION :: VULKAN_VIDEO_CODEC_H264_DECODE_API_VERSION_1_0_0
VULKAN_VIDEO_CODEC_H265_DECODE_SPEC_VERSION :: VULKAN_VIDEO_CODEC_H265_DECODE_API_VERSION_1_0_0
VULKAN_VIDEO_CODEC_H265_ENCODE_SPEC_VERSION :: VULKAN_VIDEO_CODEC_H265_ENCODE_API_VERSION_1_0_0

MAKE_VIDEO_STD_VERSION :: MAKE_VERSION

"""[1::])
    parse_constants(f)
    parse_handles_def(f)
    f.write("\n\n")
    parse_flags_def(f)
with open("../enums.odin", 'w', encoding='utf-8') as f:
    f.write(BASE)
    f.write("\n")
    parse_enums(f)
    parse_fake_enums(f)
    f.write("\n\n")
with open("../structs.odin", 'w', encoding='utf-8') as f:
    f.write(BASE)
    f.write("""
import "core:c"

import win32 "core:sys/windows"
_ :: win32

import "vendor:x11/xlib"
_ :: xlib

when ODIN_OS == .Windows {
\tHINSTANCE           :: win32.HINSTANCE
\tHWND                :: win32.HWND
\tHMONITOR            :: win32.HMONITOR
\tHANDLE              :: win32.HANDLE
\tLPCWSTR             :: win32.LPCWSTR
\tSECURITY_ATTRIBUTES :: win32.SECURITY_ATTRIBUTES
\tDWORD               :: win32.DWORD
\tLONG                :: win32.LONG
\tLUID                :: win32.LUID
} else {
\tHINSTANCE           :: distinct rawptr
\tHWND                :: distinct rawptr
\tHMONITOR            :: distinct rawptr
\tHANDLE              :: distinct rawptr
\tLPCWSTR             :: ^u16
\tSECURITY_ATTRIBUTES :: struct {}
\tDWORD               :: u32
\tLONG                :: c.long
\tLUID :: struct {
\t\tLowPart:  DWORD,
\t\tHighPart: LONG,
\t}
}

when xlib.IS_SUPPORTED {
\tXlibDisplay  :: xlib.Display
\tXlibWindow   :: xlib.Window
\tXlibVisualID :: xlib.VisualID
} else {
\tXlibDisplay  :: struct {} // Opaque struct defined by Xlib
\tXlibWindow   :: c.ulong
\tXlibVisualID :: c.ulong
}

xcb_visualid_t :: u32
xcb_window_t   :: u32
CAMetalLayer   :: struct {}

MTLBuffer_id       :: rawptr
MTLTexture_id      :: rawptr
MTLSharedEvent_id  :: rawptr
MTLDevice_id       :: rawptr
MTLCommandQueue_id :: rawptr

/********************************/
""")
    f.write("\n")
    parse_structs(f)
    f.write("\n\n")
with open("../procedures.odin", 'w', encoding='utf-8') as f:
    f.write(BASE)
    f.write("\n")
    parse_procedures(f)
    f.write("\n")
    group_functions(f)
