#+private
package flags

import "core:io"
import "core:os"
import "core:reflect"
import "core:strings"
import "core:terminal"
import "core:terminal/ansi"

Color_Styles :: struct {
	reset:       string,
	heading:     string,
	identifier:  string,
	placeholder: string,
	secondary:   string,
	error:       string,
}

should_colorize :: proc(mode: Color_Mode, stream: io.Stream) -> bool {
	switch mode {
	case .Never:
		return false
	case .Always:
		return true
	case .Auto:
		if os.get_env("NO_COLOR", context.temp_allocator) != "" {
			return false
		}

		stdout := os.to_stream(os.stdout)
		if stream.procedure == stdout.procedure && stream.data == stdout.data {
			return terminal.is_terminal(os.stdout)
		}

		stderr := os.to_stream(os.stderr)
		if stream.procedure == stderr.procedure && stream.data == stderr.data {
			return terminal.is_terminal(os.stderr)
		}
	}

	return false
}

make_color_styles :: proc(use_color: bool, palette: Color_Palette) -> (styles: Color_Styles) {
	if !use_color {
		return
	}

	styles.reset = ansi.sgr(ansi.RESET)
	if len(palette.reset) > 0 {
		styles.reset = ansi.sgr(palette.reset)
	}
	styles.heading = ansi.sgr(palette.heading) if len(palette.heading) > 0 else ""
	styles.identifier = ansi.sgr(palette.identifier) if len(palette.identifier) > 0 else ""
	styles.placeholder = ansi.sgr(palette.placeholder) if len(palette.placeholder) > 0 else ""
	styles.secondary = ansi.sgr(palette.secondary) if len(palette.secondary) > 0 else ""
	styles.error = ansi.sgr(palette.error) if len(palette.error) > 0 else ""
	return
}

write_styled :: proc(builder: ^strings.Builder, text, prefix, reset: string) {
	if len(prefix) > 0 {
		strings.write_string(builder, prefix)
		strings.write_string(builder, text)
		strings.write_string(builder, reset)
	} else {
		strings.write_string(builder, text)
	}
}

write_type_description :: proc(
	builder: ^strings.Builder,
	description: string,
	palette: Color_Styles,
) {
	if len(palette.placeholder) == 0 {
		strings.write_string(builder, description)
		return
	}

	metadata_index := -1
	in_placeholder: bool
	scan_metadata: for r, i in description {
		switch r {
		case '<':
			in_placeholder = true
		case '>':
			in_placeholder = false
		case ',':
			if !in_placeholder {
				metadata_index = i
				break scan_metadata
			}
		}
	}
	type_text := description
	if metadata_index >= 0 {
		type_text = description[:metadata_index]
	}

	for len(type_text) > 0 {
		start := strings.index_byte(type_text, '<')
		if start < 0 {
			strings.write_string(builder, type_text)
			break
		}

		strings.write_string(builder, type_text[:start])
		end := strings.index_byte(type_text[start:], '>')
		if end < 0 {
			strings.write_string(builder, type_text[start:])
			break
		}
		end += start + 1
		write_styled(builder, type_text[start:end], palette.placeholder, palette.reset)
		type_text = type_text[end:]
	}

	if metadata_index >= 0 {
		write_styled(builder, description[metadata_index:], palette.secondary, palette.reset)
	}
}

resolve_color_mode :: proc(
	data_type: typeid,
	args: []string,
	style: Parsing_Style,
	fallback: Color_Mode,
) -> Color_Mode {
	color_mode := fallback

	for field in reflect.struct_fields_zipped(data_type) {
		args_tag, has_args_tag := reflect.struct_tag_lookup(field.tag, TAG_ARGS)
		if !has_args_tag {
			continue
		}
		if _, is_color := get_subtag(args_tag, SUBTAG_COLOR); !is_color {
			continue
		}

		name := get_field_name(field)

		for i := 0; i < len(args); i += 1 {
			arg := args[i]
			if !strings.has_prefix(arg, "-") {
				continue
			}

			arg = arg[1:]
			if style == .Unix && strings.has_prefix(arg, "-") {
				arg = arg[1:]
			} else if style == .Odin && strings.has_prefix(arg, "-") {
				continue
			}

			flag_name := arg
			value: string
			has_value: bool
			assignment_index := strings.index_byte(arg, '=')
			if style == .Odin {
				colon_index := strings.index_byte(arg, ':')
				if assignment_index < 0 || colon_index >= 0 && colon_index < assignment_index {
					assignment_index = colon_index
				}
			}
			if assignment_index >= 0 {
				flag_name = arg[:assignment_index]
				value = arg[assignment_index + 1:]
				has_value = true
			}
			if flag_name != name {
				continue
			}

			if !has_value && style == .Unix && i + 1 < len(args) {
				i += 1
				value = args[i]
				has_value = true
			}

			if !has_value {
				continue
			}

			switch value {
			case "never", "Never":
				color_mode = .Never
			case "auto", "Auto":
				color_mode = .Auto
			case "always", "Always":
				color_mode = .Always
			}
		}
	}

	return color_mode
}
