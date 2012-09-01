namespace Utils {

    errordomain ParsingError {
        NOT_A_NUMBER,
    }

    void println (string text = "") {
        stdout.printf (@"$text\n");
    }

    string raw_input (string prompt) {
        stdout.printf (@"$prompt ");
        var ret = stdin.read_line();

        return ret._strip();
    }

    bool positive_answer (string answr) {
        return (answr.down() == "y") || (answr.down() == "yes");
    }

    int checked_int_parse (string number_arg) throws ParsingError {
        unichar c;
        var number = number_arg.strip();
        int i = 0;

        if (number == "")
            throw new ParsingError.NOT_A_NUMBER ("Empty string");

        number.get_next_char (ref i, out c);
        if (!(c.isdigit() || c == '-'))
            throw new ParsingError.NOT_A_NUMBER ("Cannot parse: %s".printf(
                                                                    number));

        for (; number.get_next_char (ref i, out c);) {
            if (!c.isdigit())
                throw new ParsingError.NOT_A_NUMBER ("Cannot parse: %s".printf(
                                                                    number));
        }

        return int.parse (number);
    }

}
