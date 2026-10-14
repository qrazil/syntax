# Java skeleton for Bison                           -*- java -*-

# Copyright (C) 2007-2015, 2018-2021 Free Software Foundation, Inc.

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

m4_include(b4_skeletonsdir/[java.m4])

b4_header_if([b4_complain([%header/%defines does not make sense in Java])])

m4_define([b4_symbol_no_destructor_assert],
[b4_symbol_if([$1], [has_destructor],
              [b4_complain_at(m4_unquote(b4_symbol([$1], [destructor_loc])),
                              [%destructor does not make sense in Java])])])
b4_symbol_foreach([b4_symbol_no_destructor_assert])

## --------------- ##
## api.push-pull.  ##
## --------------- ##

b4_percent_define_default([[api.push-pull]], [[pull]])
b4_percent_define_check_values([[[[api.push-pull]],
                                 [[pull]], [[push]], [[both]]]])

# Define m4 conditional macros that encode the value
# of the api.push-pull flag.
b4_define_flag_if([pull]) m4_define([b4_pull_flag], [[1]])
b4_define_flag_if([push]) m4_define([b4_push_flag], [[1]])
m4_case(b4_percent_define_get([[api.push-pull]]),
        [pull], [m4_define([b4_push_flag], [[0]])],
        [push], [m4_define([b4_pull_flag], [[0]])])

# Define a macro to be true when api.push-pull has the value "both".
m4_define([b4_both_if],[b4_push_if([b4_pull_if([$1],[$2])],[$2])])

# Handle BISON_USE_PUSH_FOR_PULL for the test suite.  So that push parsing
# tests function as written, do not let BISON_USE_PUSH_FOR_PULL modify the
# behavior of Bison at all when push parsing is already requested.
b4_define_flag_if([use_push_for_pull])
b4_use_push_for_pull_if([
  b4_push_if([m4_define([b4_use_push_for_pull_flag], [[0]])],
             [m4_define([b4_push_flag], [[1]])])])

# Define a macro to encapsulate the parse state variables.  This
# allows them to be defined either in parse() when doing pull parsing,
# or as class instance variable when doing push parsing.
m4_define([b4_define_state],
[[
    /* Lookahead token kind.  */
    int yychar = YYEMPTY_;
    /* Lookahead symbol kind.  */
    SymbolKind yytoken = null;

    /* State.  */
    int yyn = 0;
    int yylen = 0;
    int yystate = 0;
    YYStack yystack = new YYStack ();
    int label = YYNEWSTATE;

]b4_locations_if([[
    /* The location where the error started.  */
    ]b4_location_type[ yyerrloc = null;

    /* Location. */
    ]b4_location_type[ yylloc = new ]b4_location_type[ (null, null);]])[

    /* Semantic value of the lookahead.  */
    ]b4_yystype[ yylval = null;
]])

# parse.lac
b4_percent_define_default([[parse.lac]], [[none]])
b4_percent_define_check_values([[[[parse.lac]], [[full]], [[none]]]])
b4_define_flag_if([lac])
m4_define([b4_lac_flag],
          [m4_if(b4_percent_define_get([[parse.lac]]),
                 [none], [[0]], [[1]])])


## ------------- ##
## Parser File.  ##
## ------------- ##

b4_output_begin([b4_parser_file_name])[
]b4_copyright([Skeleton implementation for Bison LALR(1) parsers in Java],
              [2007-2015, 2018-2021])[
]b4_disclaimer[
]b4_percent_define_ifdef([api.package], [package b4_percent_define_get([api.package]);[
]])[
]b4_user_pre_prologue[
]b4_user_post_prologue[
import java.text.MessageFormat;
import java.util.ArrayList;
]b4_percent_code_get([[imports]])[
/**
 * A Bison parser, automatically generated from <tt>]m4_bpatsubst(b4_file_name, [^"\(.*\)"$], [\1])[</tt>.
 *
 * @@author LALR (1) parser skeleton written by Paolo Bonzini.
 */
]b4_parser_class_declaration[
{
]b4_identification[
][
]b4_parse_error_bmatch(
           [detailed\|verbose], [[
  /**
   * True if verbose error messages are enabled.
   */
