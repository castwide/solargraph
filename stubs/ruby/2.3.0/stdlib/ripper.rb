class Ripper < Object
include Kernel
def self.slice(src, pattern, n = nil);end
def self.parse(src, filename = nil, lineno = nil);end
def self.dedent_string(arg0, arg1);end
def self.tokenize(src, filename = nil, lineno = nil);end
def self.lex(src, filename = nil, lineno = nil);end
def self.token_match(src, pattern);end
def self.sexp(src, filename = nil, lineno = nil);end
def self.sexp_raw(src, filename = nil, lineno = nil);end
def self.slice(src, pattern, n = nil);end
def self.parse(src, filename = nil, lineno = nil);end
def self.dedent_string(arg0, arg1);end
def self.tokenize(src, filename = nil, lineno = nil);end
def self.lex(src, filename = nil, lineno = nil);end
def self.token_match(src, pattern);end
def self.sexp(src, filename = nil, lineno = nil);end
def self.sexp_raw(src, filename = nil, lineno = nil);end
def end_seen?();end
def filename();end
def yydebug();end
def yydebug=(arg0);end
def error?();end
def parse();end
def encoding();end
def lineno();end
def column();end
end
class Ripper::Lexer < Ripper
include Kernel
def self.slice(src, pattern, n = nil);end
def self.parse(src, filename = nil, lineno = nil);end
def self.dedent_string(arg0, arg1);end
def self.tokenize(src, filename = nil, lineno = nil);end
def self.lex(src, filename = nil, lineno = nil);end
def self.token_match(src, pattern);end
def self.sexp(src, filename = nil, lineno = nil);end
def self.sexp_raw(src, filename = nil, lineno = nil);end
def parse();end
def tokenize();end
def lex();end
end
class Ripper::Lexer::Elem < Struct
include Enumerable
include Kernel
def self.[](*args);end
def self.members();end
def self.[](*args);end
def self.members();end
def pos();end
def pos=(_);end
def event();end
def tok();end
def event=(_);end
def tok=(_);end
end
class Process::Tms < Struct
include Enumerable
include Kernel
def self.[](*args);end
def self.members();end
def self.[](*args);end
def self.members();end
def utime();end
def stime();end
def cutime();end
def cstime();end
def utime=(_);end
def stime=(_);end
def cutime=(_);end
def cstime=(_);end
end
class Ripper::TokenPattern < Object
include Kernel
def self.compile(*args);end
def self.compile(*args);end
def match(str);end
def match_list(tokens);end
end
class Ripper::TokenPattern::Error < StandardError
include Kernel
def self.exception(*args);end
end
class Ripper::TokenPattern::CompileError < Ripper::TokenPattern::Error
include Kernel
def self.exception(*args);end
end
class Ripper::TokenPattern::MatchError < Ripper::TokenPattern::Error
include Kernel
def self.exception(*args);end
end
class Ripper::TokenPattern::MatchData < Object
include Kernel
def string(*args);end
end
class Ripper::Filter < Object
include Kernel
def lineno();end
def filename();end
def parse(*args);end
def column();end
end
class Ripper::SexpBuilder < Ripper
include Kernel
def self.slice(src, pattern, n = nil);end
def self.parse(src, filename = nil, lineno = nil);end
def self.dedent_string(arg0, arg1);end
def self.tokenize(src, filename = nil, lineno = nil);end
def self.lex(src, filename = nil, lineno = nil);end
def self.token_match(src, pattern);end
def self.sexp(src, filename = nil, lineno = nil);end
def self.sexp_raw(src, filename = nil, lineno = nil);end
def on_BEGIN(*args);end
def on_END(*args);end
def on_alias(*args);end
def on_alias_error(*args);end
def on_aref(*args);end
def on_aref_field(*args);end
def on_arg_ambiguous(*args);end
def on_arg_paren(*args);end
def on_args_add(*args);end
def on_args_add_block(*args);end
def on_args_add_star(*args);end
def on_args_new(*args);end
def on_array(*args);end
def on_assign(*args);end
def on_assign_error(*args);end
def on_assoc_new(*args);end
def on_assoc_splat(*args);end
def on_assoclist_from_args(*args);end
def on_bare_assoc_hash(*args);end
def on_begin(*args);end
def on_binary(*args);end
def on_block_var(*args);end
def on_block_var_add_block(*args);end
def on_block_var_add_star(*args);end
def on_blockarg(*args);end
def on_bodystmt(*args);end
def on_brace_block(*args);end
def on_break(*args);end
def on_call(*args);end
def on_case(*args);end
def on_class(*args);end
def on_class_name_error(*args);end
def on_command(*args);end
def on_command_call(*args);end
def on_const_path_field(*args);end
def on_const_path_ref(*args);end
def on_const_ref(*args);end
def on_def(*args);end
def on_defined(*args);end
def on_defs(*args);end
def on_do_block(*args);end
def on_dot2(*args);end
def on_dot3(*args);end
def on_dyna_symbol(*args);end
def on_else(*args);end
def on_elsif(*args);end
def on_ensure(*args);end
def on_excessed_comma(*args);end
def on_fcall(*args);end
def on_field(*args);end
def on_for(*args);end
def on_hash(*args);end
def on_if(*args);end
def on_if_mod(*args);end
def on_ifop(*args);end
def on_lambda(*args);end
def on_magic_comment(*args);end
def on_massign(*args);end
def on_method_add_arg(*args);end
def on_method_add_block(*args);end
def on_mlhs_add(*args);end
def on_mlhs_add_star(*args);end
def on_mlhs_new(*args);end
def on_mlhs_paren(*args);end
def on_module(*args);end
def on_mrhs_add(*args);end
def on_mrhs_add_star(*args);end
def on_mrhs_new(*args);end
def on_mrhs_new_from_args(*args);end
def on_next(*args);end
def on_opassign(*args);end
def on_operator_ambiguous(*args);end
def on_param_error(*args);end
def on_params(*args);end
def on_paren(*args);end
def on_parse_error(*args);end
def on_program(*args);end
def on_qsymbols_add(*args);end
def on_qsymbols_new(*args);end
def on_qwords_add(*args);end
def on_qwords_new(*args);end
def on_redo(*args);end
def on_regexp_add(*args);end
def on_regexp_literal(*args);end
def on_regexp_new(*args);end
def on_rescue(*args);end
def on_rescue_mod(*args);end
def on_rest_param(*args);end
def on_retry(*args);end
def on_return(*args);end
def on_return0(*args);end
def on_sclass(*args);end
def on_stmts_add(*args);end
def on_stmts_new(*args);end
def on_string_add(*args);end
def on_string_concat(*args);end
def on_string_content(*args);end
def on_string_dvar(*args);end
def on_string_embexpr(*args);end
def on_string_literal(*args);end
def on_super(*args);end
def on_symbol(*args);end
def on_symbol_literal(*args);end
def on_symbols_add(*args);end
def on_symbols_new(*args);end
def on_top_const_field(*args);end
def on_top_const_ref(*args);end
def on_unary(*args);end
def on_undef(*args);end
def on_unless(*args);end
def on_unless_mod(*args);end
def on_until(*args);end
def on_until_mod(*args);end
def on_var_alias(*args);end
def on_var_field(*args);end
def on_var_ref(*args);end
def on_vcall(*args);end
def on_void_stmt(*args);end
def on_when(*args);end
def on_while(*args);end
def on_while_mod(*args);end
def on_word_add(*args);end
def on_word_new(*args);end
def on_words_add(*args);end
def on_words_new(*args);end
def on_xstring_add(*args);end
def on_xstring_literal(*args);end
def on_xstring_new(*args);end
def on_yield(*args);end
def on_yield0(*args);end
def on_zsuper(*args);end
def on_backref(tok);end
def on_backtick(tok);end
def on_comma(tok);end
def on_const(tok);end
def on_cvar(tok);end
def on_embexpr_beg(tok);end
def on_embexpr_end(tok);end
def on_embvar(tok);end
def on_float(tok);end
def on_gvar(tok);end
def on_ident(tok);end
def on_imaginary(tok);end
def on_int(tok);end
def on_ivar(tok);end
def on_kw(tok);end
def on_lbrace(tok);end
def on_lbracket(tok);end
def on_lparen(tok);end
def on_nl(tok);end
def on_op(tok);end
def on_period(tok);end
def on_rbrace(tok);end
def on_rbracket(tok);end
def on_rparen(tok);end
def on_semicolon(tok);end
def on_symbeg(tok);end
def on_tstring_beg(tok);end
def on_tstring_content(tok);end
def on_tstring_end(tok);end
def on_words_beg(tok);end
def on_qwords_beg(tok);end
def on_qsymbols_beg(tok);end
def on_symbols_beg(tok);end
def on_words_sep(tok);end
def on_rational(tok);end
def on_regexp_beg(tok);end
def on_regexp_end(tok);end
def on_label(tok);end
def on_label_end(tok);end
def on_tlambda(tok);end
def on_tlambeg(tok);end
def on_ignored_nl(tok);end
def on_comment(tok);end
def on_embdoc_beg(tok);end
def on_embdoc(tok);end
def on_embdoc_end(tok);end
def on_sp(tok);end
def on_heredoc_beg(tok);end
def on_heredoc_end(tok);end
def on___end__(tok);end
def on_CHAR(tok);end
end
class Ripper::SexpBuilderPP < Ripper::SexpBuilder
include Kernel
def self.slice(src, pattern, n = nil);end
def self.parse(src, filename = nil, lineno = nil);end
def self.dedent_string(arg0, arg1);end
def self.tokenize(src, filename = nil, lineno = nil);end
def self.lex(src, filename = nil, lineno = nil);end
def self.token_match(src, pattern);end
def self.sexp(src, filename = nil, lineno = nil);end
def self.sexp_raw(src, filename = nil, lineno = nil);end
end
