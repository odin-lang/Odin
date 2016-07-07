main :: proc(args: []string) -> i32 {
	if args.count < 2 {
		io.println("Please specify a .odin file");
		return 1;
	}

	for arg_index := 1; arg_index < args.count; arg_index++ {
		arg := args[arg_index];
		filename := arg;
		ext := filepath.path_extension(filename);
		if (ext != "odin") {
			io.println("File is not a .odin file");
			return 1;
		}
		output_name := filepath.change_extension(filename, "c");

		parser: Parser;
		err: Error;
		parser, err = make_parser(filename);
		if err {
			handle_error();
		}
		defer destroy_parser(*parser);

		root_node := parse_statement_list(*parser, null);

		code_generator: CodeGenerator;
		code_generator, err = make_code_generator(*parser, root);
		if err {
			handle_error();
		}
		defer destroy_code_generator(*code_generator);

		output: File;
		output, err = file_create(output_nameu);
		if err {
			handle_error();
		}
		defer file_close(*output);

		convert_to_c_code(*code_generator, root, *output);
	}

	return 0;
};
