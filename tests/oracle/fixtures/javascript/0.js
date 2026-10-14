const PREC = {
  UNARY: 1,
  CAST : 2,
  ELEMENT_ACCESS : 3,
  EMPTY : 3
}

module.exports = grammar({
  name: 'powershell',

  externals: $ => [
    $._statement_terminator
  ],

  extras: $ => [
    $.comment,
    /\s/,
    /`\n/,
    /[\uFEFF\u2060\u200B\u00A0]/
  ],

  conflicts: $ => [
    [$.array_type_name, $.generic_type_name],
    [$._command_argument, $.redirected_file_name],
    [$._literal, $.member_name],
    [$.class_property_definition, $.attribute],
    [$.class_method_definition, $.attribute],
    [$.class_method_definition, $.class_property_definition],
    [$.expandable_string_literal],
    [$.path_command_name, $._value]
  ],
  
  rules: {

    program: $ => seq(
      optional($.param_block),
      $.statement_list
    ),

    // Comments
    comment: $ => token(
      choice(
        /#[^\n]*/,
        seq(
          "<#",
          repeat(
            choice(
              /[^#`]+/,
              /#+[^>#]/,
              /`.{1}|`\n/
            )
          ),
          /#+>/
        )
      )
    ),

    // Literal

    _literal: $ => choice(
      $.integer_literal,
      $.string_literal,
      $.real_literal
    ),

    // Integer Literals

    integer_literal: $ => choice(
      $.decimal_integer_literal,
      $.hexadecimal_integer_literal
    ),

    decimal_integer_literal: $ => token(seq(
      /[0-9]+/, optional(choice("l", "d")), optional(choice("kb", "mb", "gb", "tb", "pb"))
    )),

    hexadecimal_integer_literal: $ => token(seq(
      "0x", /[0-9a-fA-F]+/, optional("l"), optional(choice("kb", "mb", "gb", "tb", "pb"))
    )),

    // Real Literals

    real_literal: $ => token(choice(
      seq(/[0-9]+\.[0-9]+/, optional(token(seq("e", optional(choice("+", "-")), /[0-9]+/))), optional(choice("kb", "mb", "gb", "tb", "pb"))),
      seq(/\.[0-9]+/, optional(token(seq("e", optional(choice("+", "-")), /[0-9]+/))), optional(choice("kb", "mb", "gb", "tb", "pb"))),
      seq(/[0-9]+/, token(seq("e", optional(choice("+", "-")), /[0-9]+/)), optional(choice("kb", "mb", "gb", "tb", "pb")))
    )),

    // String literal

    string_literal: $ => choice(
      $.expandable_string_literal,
      $.verbatim_string_characters,
      $.expandable_here_string_literal,
      $.verbatim_here_string_characters
    ),

    expandable_string_literal: $ => seq(
      /\"(\s*\#*)*/,  // this is a trick to avoid tree-sitter allowing comment between tokens, as string should be tokenize but powershell allow subexpression inside it...
      repeat(
        choice(
          token.immediate(/[^\$\"`]+/),
          $.variable,
          $.sub_expression,
          token.immediate(/\$(`.{1}|`\n|[\s\\])/),
          token.immediate(/`.{1}|`\n/),
          token.immediate("\"\""),
          token.immediate("$"),
        )
      ),
      repeat(token.immediate("$")),
      token.immediate(/(\s*\#*)*\"/)
    ),

    expandable_here_string_literal: $ => seq(
      /@\" *\n/,
      repeat(
        choice(
          token.immediate(/[^\$\n`]+/),
          $.variable,
