module Exception2MessageMapper
def extend_object(cl);end
def message(klass, exp);end
def Raise(*args);end
def Fail(*args);end
def def_e2message(k, c, m);end
def def_exception(k, n, m, s = nil);end
def e2mm_message(klass, exp);end
def self.extend_object(cl);end
def self.message(klass, exp);end
def self.Raise(*args);end
def self.Fail(*args);end
def self.def_e2message(k, c, m);end
def self.def_exception(k, n, m, s = nil);end
def self.e2mm_message(klass, exp);end
def fail(*args);end
def bind(cl);end
def Raise(*args);end
def Fail(*args);end
def def_e2message(c, m);end
def def_exception(n, m, s = nil);end
end
class Exception2MessageMapper::ErrNotRegisteredException < StandardError
include Kernel
def self.exception(*args);end
end
module IRB
def start(*args);end
def version();end
def conf();end
def CurrentContext();end
def setup(ap_path);end
def irb_at_exit();end
def irb_exit(irb, ret);end
def irb_abort(irb, exception = nil);end
def init_config(ap_path);end
def init_error();end
def parse_opts();end
def run_config();end
def load_modules();end
def rc_file(*args);end
def rc_file_generators();end
def Inspector(inspect, init = nil);end
def delete_caller();end
def self.start(*args);end
def self.version();end
def self.conf();end
def self.CurrentContext();end
def self.setup(ap_path);end
def self.irb_at_exit();end
def self.irb_exit(irb, ret);end
def self.irb_abort(irb, exception = nil);end
def self.init_config(ap_path);end
def self.init_error();end
def self.parse_opts();end
def self.run_config();end
def self.load_modules();end
def self.rc_file(*args);end
def self.rc_file_generators();end
def self.Inspector(inspect, init = nil);end
def self.delete_caller();end
end
class IRB::DefaultEncodings < Struct
include Enumerable
include Kernel
def self.[](*args);end
def self.members();end
def self.[](*args);end
def self.members();end
def external();end
def internal();end
def external=(_);end
def internal=(_);end
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
class IRB::WorkSpace < Object
include Kernel
def main();end
def evaluate(context, statements, file = nil, line = nil);end
def filter_backtrace(bt);end
end
class IRB::Inspector < Object
include Kernel
def self.keys_with_inspector(inspector);end
def self.def_inspector(key, arg = nil, &block);end
def self.keys_with_inspector(inspector);end
def self.def_inspector(key, arg = nil, &block);end
def init();end
def inspect_value(v);end
end
class IRB::Context < Object
include Kernel
def irb_name();end
def irb_name=(arg0);end
def use_readline?();end
def workspace=(arg0);end
def save_history=(*args);end
def debug_level=(value);end
def workspace_home();end
def ignore_sigint?();end
def ignore_sigint();end
def ignore_eof();end
def echo();end
def rc?();end
def return_format();end
def inspect_last_value();end
def set_last_value(value);end
def last_value();end
def __to_s__();end
def use_readline();end
def inspect?();end
def file_input?();end
def use_readline=(opt);end
def debug?();end
def load_modules();end
def __inspect__();end
def io();end
def irb();end
def io=(arg0);end
def debug_level();end
def irb=(arg0);end
def ap_name=(arg0);end
def rc=(arg0);end
def load_modules=(arg0);end
def thread();end
def workspace();end
def prompt_i=(arg0);end
def prompt_s=(arg0);end
def prompt_c=(arg0);end
def prompt_n=(arg0);end
def auto_indent_mode=(arg0);end
def prompt_mode();end
def ignore_sigint=(arg0);end
def ignore_eof=(arg0);end
def return_format=(arg0);end
def verbose=(arg0);end
def back_trace_limit=(arg0);end
def echo=(arg0);end
def rc();end
def prompt_s();end
def main();end
def prompt_n();end
def prompt_i();end
def prompting?();end
def prompt_c();end
def auto_indent_mode();end
def verbose?();end
def ignore_eof?();end
def ap_name();end
def inspect_mode();end
def inspect_mode=(opt);end
def evaluate(line, line_no);end
def math_mode=(*args);end
def echo?();end
def use_tracer=(*args);end
def use_loader=(*args);end
def eval_history=(*args);end
def verbose();end
def back_trace_limit();end
def prompt_mode=(mode);end
def irb_path();end
def irb_path=(arg0);end
end
module IRB::ExtendCommandBundle
def extend_object(obj);end
def install_extend_commands();end
def def_extend_command(cmd_name, cmd_class, load_file = nil, *aliases);end
def irb_original_method_name(method_name);end
def self.extend_object(obj);end
def self.install_extend_commands();end
def self.def_extend_command(cmd_name, cmd_class, load_file = nil, *aliases);end
def self.irb_original_method_name(method_name);end
def irb(*args);end
def irb_exit(*args);end
def irb_context();end
def irb_current_working_workspace(*args);end
def irb_change_workspace(*args);end
def irb_workspaces(*args);end
def irb_push_workspace(*args);end
def irb_pop_workspace(*args);end
def irb_load(*args);end
def irb_require(*args);end
def irb_source(*args);end
def irb_jobs(*args);end
def irb_fg(*args);end
def irb_kill(*args);end
def irb_help(*args);end
def install_alias_method(to, from, override = nil);end
end
module IRB::ContextExtender
def install_extend_commands();end
def def_extend_command(cmd_name, load_file, *aliases);end
def self.install_extend_commands();end
def self.def_extend_command(cmd_name, load_file, *aliases);end
end
module IRB::MethodExtender
def def_pre_proc(base_method, extend_method);end
def new_alias_name(name, prefix = nil, postfix = nil);end
def def_post_proc(base_method, extend_method);end
end
class IRB::OutputMethod < Object
include Kernel
def self.included(mod);end
def self.bind(cl);end
def self.Raise(*args);end
def self.Fail(*args);end
def self.def_e2message(c, m);end
def self.def_exception(n, m, s = nil);end
def self.included(mod);end
def pp(*args);end
def Raise(*args);end
def Fail(*args);end
def printn(*args);end
def ppx(prefix, *objs);end
def parse_printf_format(format, opts);end
end
class IRB::OutputMethod::NotImplementedError < StandardError
include Kernel
def self.exception(*args);end
end
class IRB::StdioOutputMethod < IRB::OutputMethod
include Kernel
def self.included(mod);end
def self.bind(cl);end
def self.Raise(*args);end
def self.Fail(*args);end
def self.def_e2message(c, m);end
def self.def_exception(n, m, s = nil);end
end
module IRB::Notifier
def included(mod);end
def def_notifier(*args);end
def bind(cl);end
def Raise(*args);end
def Fail(*args);end
def def_e2message(c, m);end
def def_exception(n, m, s = nil);end
def self.included(mod);end
def self.def_notifier(*args);end
def Raise(*args);end
def Fail(*args);end
end
class IRB::Notifier::ErrUndefinedNotifier < StandardError
include Kernel
def self.exception(*args);end
end
class IRB::Notifier::ErrUnrecognizedLevel < StandardError
include Kernel
def self.exception(*args);end
end
class IRB::Notifier::AbstractNotifier < Object
include Kernel
def prefix();end
def pp(*args);end
def exec_if();end
def notify?();end
def printn(*args);end
def ppx(prefix, *objs);end
end
class IRB::Notifier::CompositeNotifier < IRB::Notifier::AbstractNotifier
include Kernel
def def_notifier(level, prefix = nil);end
def level();end
def level=(value);end
def notifiers();end
def level_notifier();end
def level_notifier=(value);end
end
class IRB::Notifier::LeveledNotifier < IRB::Notifier::AbstractNotifier
include Comparable
include Kernel
def level();end
def notify?();end
end
class IRB::Notifier::NoMsgNotifier < IRB::Notifier::LeveledNotifier
include Comparable
include Kernel
def notify?();end
end
class IRB::SLex < Object
include Kernel
def self.included(mod);end
def self.bind(cl);end
def self.Raise(*args);end
def self.Fail(*args);end
def self.def_e2message(c, m);end
def self.def_exception(n, m, s = nil);end
def self.included(mod);end
def match(token);end
def create(token, preproc = nil, postproc = nil);end
def Raise(*args);end
def Fail(*args);end
def def_rules(*args);end
def def_rule(token, preproc = nil, postproc = nil, &block);end
def preproc(token, proc);end
def postproc(token);end
def search(token);end
end
class IRB::SLex::ErrNodeNothing < StandardError
include Kernel
def self.exception(*args);end
end
class IRB::SLex::ErrNodeAlreadyExists < StandardError
include Kernel
def self.exception(*args);end
end
class IRB::SLex::Node < Object
include Kernel
def match(chrs, op = nil);end
def preproc();end
def postproc();end
def search(chrs, opt = nil);end
def preproc=(arg0);end
def postproc=(arg0);end
def create_subnode(chrs, preproc = nil, postproc = nil);end
def match_io(io, op = nil);end
end
class IRB::InputMethod < Object
include Kernel
def file_name();end
def prompt();end
def prompt=(arg0);end
def readable_after_eof?();end
end
class IRB::StdioInputMethod < IRB::InputMethod
include Kernel
def encoding();end
def eof?();end
def readable_after_eof?();end
def line(line_no);end
end
class IRB::FileInputMethod < IRB::InputMethod
include Kernel
def encoding();end
def eof?();end
def file_name();end
end
class IRB::ReadlineInputMethod < IRB::InputMethod
include Readline
include Kernel
def encoding();end
def eof?();end
def readable_after_eof?();end
def line(line_no);end
end
class IRB::Locale < Object
include Kernel
def find(file, paths = nil);end
def encoding();end
def territory();end
def modifier();end
def lang();end
end
class IRB::Abort < Exception
include Kernel
def self.exception(*args);end
end
class IRB::Irb < Object
include Kernel
def context();end
def signal_handle();end
def eval_input();end
def scanner();end
def prompt(prompt, ltype, indent, line_no);end
def signal_status(status);end
def output_value();end
def suspend_name(*args);end
def suspend_workspace(workspace);end
def suspend_input_method(input_method);end
def suspend_context(context);end
def scanner=(arg0);end
end
module RubyToken
def def_token(token_n, super_token = nil, reading = nil, *opts);end
def self.def_token(token_n, super_token = nil, reading = nil, *opts);end
def Token(token, value = nil);end
end
class RubyToken::Token < Object
include Kernel
def seek();end
def line_no();end
def char_no();end
end
class RubyToken::TkNode < RubyToken::Token
include Kernel
def node();end
end
class RubyToken::TkId < RubyToken::Token
include Kernel
end
class RubyToken::TkVal < RubyToken::Token
include Kernel
def value();end
end
class RubyToken::TkOp < RubyToken::Token
include Kernel
def name=(arg0);end
end
class RubyToken::TkOPASGN < RubyToken::TkOp
include Kernel
def op();end
end
class RubyToken::TkUnknownChar < RubyToken::Token
include Kernel
end
class RubyToken::TkError < RubyToken::Token
include Kernel
end
class RubyToken::TkCLASS < RubyToken::TkId
include Kernel
end
class RubyToken::TkMODULE < RubyToken::TkId
include Kernel
end
class RubyToken::TkDEF < RubyToken::TkId
include Kernel
end
class RubyToken::TkUNDEF < RubyToken::TkId
include Kernel
end
class RubyToken::TkBEGIN < RubyToken::TkId
include Kernel
end
class RubyToken::TkRESCUE < RubyToken::TkId
include Kernel
end
class RubyToken::TkENSURE < RubyToken::TkId
include Kernel
end
class RubyToken::TkEND < RubyToken::TkId
include Kernel
end
class RubyToken::TkIF < RubyToken::TkId
include Kernel
end
class RubyToken::TkUNLESS < RubyToken::TkId
include Kernel
end
class RubyToken::TkTHEN < RubyToken::TkId
include Kernel
end
class RubyToken::TkELSIF < RubyToken::TkId
include Kernel
end
class RubyToken::TkELSE < RubyToken::TkId
include Kernel
end
class RubyToken::TkCASE < RubyToken::TkId
include Kernel
end
class RubyToken::TkWHEN < RubyToken::TkId
include Kernel
end
class RubyToken::TkWHILE < RubyToken::TkId
include Kernel
end
class RubyToken::TkUNTIL < RubyToken::TkId
include Kernel
end
class RubyToken::TkFOR < RubyToken::TkId
include Kernel
end
class RubyToken::TkBREAK < RubyToken::TkId
include Kernel
end
class RubyToken::TkNEXT < RubyToken::TkId
include Kernel
end
class RubyToken::TkREDO < RubyToken::TkId
include Kernel
end
class RubyToken::TkRETRY < RubyToken::TkId
include Kernel
end
class RubyToken::TkIN < RubyToken::TkId
include Kernel
end
class RubyToken::TkDO < RubyToken::TkId
include Kernel
end
class RubyToken::TkRETURN < RubyToken::TkId
include Kernel
end
class RubyToken::TkYIELD < RubyToken::TkId
include Kernel
end
class RubyToken::TkSUPER < RubyToken::TkId
include Kernel
end
class RubyToken::TkSELF < RubyToken::TkId
include Kernel
end
class RubyToken::TkNIL < RubyToken::TkId
include Kernel
end
class RubyToken::TkTRUE < RubyToken::TkId
include Kernel
end
class RubyToken::TkFALSE < RubyToken::TkId
include Kernel
end
class RubyToken::TkAND < RubyToken::TkId
include Kernel
end
class RubyToken::TkOR < RubyToken::TkId
include Kernel
end
class RubyToken::TkNOT < RubyToken::TkId
include Kernel
end
class RubyToken::TkIF_MOD < RubyToken::TkId
include Kernel
end
class RubyToken::TkUNLESS_MOD < RubyToken::TkId
include Kernel
end
class RubyToken::TkWHILE_MOD < RubyToken::TkId
include Kernel
end
class RubyToken::TkUNTIL_MOD < RubyToken::TkId
include Kernel
end
class RubyToken::TkALIAS < RubyToken::TkId
include Kernel
end
class RubyToken::TkDEFINED < RubyToken::TkId
include Kernel
end
class RubyToken::TklBEGIN < RubyToken::TkId
include Kernel
end
class RubyToken::TklEND < RubyToken::TkId
include Kernel
end
class RubyToken::Tk__LINE__ < RubyToken::TkId
include Kernel
end
class RubyToken::Tk__FILE__ < RubyToken::TkId
include Kernel
end
class RubyToken::TkIDENTIFIER < RubyToken::TkId
include Kernel
end
class RubyToken::TkFID < RubyToken::TkId
include Kernel
end
class RubyToken::TkGVAR < RubyToken::TkId
include Kernel
end
class RubyToken::TkCVAR < RubyToken::TkId
include Kernel
end
class RubyToken::TkIVAR < RubyToken::TkId
include Kernel
end
class RubyToken::TkCONSTANT < RubyToken::TkId
include Kernel
end
class RubyToken::TkINTEGER < RubyToken::TkVal
include Kernel
end
class RubyToken::TkFLOAT < RubyToken::TkVal
include Kernel
end
class RubyToken::TkSTRING < RubyToken::TkVal
include Kernel
end
class RubyToken::TkXSTRING < RubyToken::TkVal
include Kernel
end
class RubyToken::TkREGEXP < RubyToken::TkVal
include Kernel
end
class RubyToken::TkSYMBOL < RubyToken::TkVal
include Kernel
end
class RubyToken::TkDSTRING < RubyToken::TkNode
include Kernel
end
class RubyToken::TkDXSTRING < RubyToken::TkNode
include Kernel
end
class RubyToken::TkDREGEXP < RubyToken::TkNode
include Kernel
end
class RubyToken::TkNTH_REF < RubyToken::TkNode
include Kernel
end
class RubyToken::TkBACK_REF < RubyToken::TkNode
include Kernel
end
class RubyToken::TkUPLUS < RubyToken::TkOp
include Kernel
end
class RubyToken::TkUMINUS < RubyToken::TkOp
include Kernel
end
class RubyToken::TkPOW < RubyToken::TkOp
include Kernel
end
class RubyToken::TkCMP < RubyToken::TkOp
include Kernel
end
class RubyToken::TkEQ < RubyToken::TkOp
include Kernel
end
class RubyToken::TkEQQ < RubyToken::TkOp
include Kernel
end
class RubyToken::TkNEQ < RubyToken::TkOp
include Kernel
end
class RubyToken::TkGEQ < RubyToken::TkOp
include Kernel
end
class RubyToken::TkLEQ < RubyToken::TkOp
include Kernel
end
class RubyToken::TkANDOP < RubyToken::TkOp
include Kernel
end
class RubyToken::TkOROP < RubyToken::TkOp
include Kernel
end
class RubyToken::TkMATCH < RubyToken::TkOp
include Kernel
end
class RubyToken::TkNMATCH < RubyToken::TkOp
include Kernel
end
class RubyToken::TkDOT2 < RubyToken::TkOp
include Kernel
end
class RubyToken::TkDOT3 < RubyToken::TkOp
include Kernel
end
class RubyToken::TkAREF < RubyToken::TkOp
include Kernel
end
class RubyToken::TkASET < RubyToken::TkOp
include Kernel
end
class RubyToken::TkLSHFT < RubyToken::TkOp
include Kernel
end
class RubyToken::TkRSHFT < RubyToken::TkOp
include Kernel
end
class RubyToken::TkCOLON2 < RubyToken::TkOp
include Kernel
end
class RubyToken::TkCOLON3 < RubyToken::TkOp
include Kernel
end
class RubyToken::TkASSOC < RubyToken::TkOp
include Kernel
end
class RubyToken::TkQUESTION < RubyToken::TkOp
include Kernel
end
class RubyToken::TkCOLON < RubyToken::TkOp
include Kernel
end
class RubyToken::TkfLPAREN < RubyToken::Token
include Kernel
end
class RubyToken::TkfLBRACK < RubyToken::Token
include Kernel
end
class RubyToken::TkfLBRACE < RubyToken::Token
include Kernel
end
class RubyToken::TkSTAR < RubyToken::Token
include Kernel
end
class RubyToken::TkAMPER < RubyToken::Token
include Kernel
end
class RubyToken::TkSYMBEG < RubyToken::Token
include Kernel
end
class RubyToken::TkGT < RubyToken::TkOp
include Kernel
end
class RubyToken::TkLT < RubyToken::TkOp
include Kernel
end
class RubyToken::TkPLUS < RubyToken::TkOp
include Kernel
end
class RubyToken::TkMINUS < RubyToken::TkOp
include Kernel
end
class RubyToken::TkMULT < RubyToken::TkOp
include Kernel
end
class RubyToken::TkDIV < RubyToken::TkOp
include Kernel
end
class RubyToken::TkMOD < RubyToken::TkOp
include Kernel
end
class RubyToken::TkBITOR < RubyToken::TkOp
include Kernel
end
class RubyToken::TkBITXOR < RubyToken::TkOp
include Kernel
end
class RubyToken::TkBITAND < RubyToken::TkOp
include Kernel
end
class RubyToken::TkBITNOT < RubyToken::TkOp
include Kernel
end
class RubyToken::TkNOTOP < RubyToken::TkOp
include Kernel
end
class RubyToken::TkBACKQUOTE < RubyToken::TkOp
include Kernel
end
class RubyToken::TkASSIGN < RubyToken::Token
include Kernel
end
class RubyToken::TkDOT < RubyToken::Token
include Kernel
end
class RubyToken::TkLPAREN < RubyToken::Token
include Kernel
end
class RubyToken::TkLBRACK < RubyToken::Token
include Kernel
end
class RubyToken::TkLBRACE < RubyToken::Token
include Kernel
end
class RubyToken::TkRPAREN < RubyToken::Token
include Kernel
end
class RubyToken::TkRBRACK < RubyToken::Token
include Kernel
end
class RubyToken::TkRBRACE < RubyToken::Token
include Kernel
end
class RubyToken::TkCOMMA < RubyToken::Token
include Kernel
end
class RubyToken::TkSEMICOLON < RubyToken::Token
include Kernel
end
class RubyToken::TkCOMMENT < RubyToken::Token
include Kernel
end
class RubyToken::TkRD_COMMENT < RubyToken::Token
include Kernel
end
class RubyToken::TkSPACE < RubyToken::Token
include Kernel
end
class RubyToken::TkNL < RubyToken::Token
include Kernel
end
class RubyToken::TkEND_OF_SCRIPT < RubyToken::Token
include Kernel
end
class RubyToken::TkBACKSLASH < RubyToken::TkUnknownChar
include Kernel
end
class RubyToken::TkAT < RubyToken::TkUnknownChar
include Kernel
end
class RubyToken::TkDOLLAR < RubyToken::TkUnknownChar
include Kernel
end
class RubyLex < Object
include RubyToken
include Kernel
def self.included(mod);end
def self.debug_level();end
def self.debug_level=(arg0);end
def self.debug?();end
def self.bind(cl);end
def self.Raise(*args);end
def self.Fail(*args);end
def self.def_e2message(c, m);end
def self.def_exception(n, m, s = nil);end
def self.included(mod);end
def self.debug_level();end
def self.debug_level=(arg0);end
def self.debug?();end
def getc();end
def ungetc(*args);end
def seek();end
def eof?();end
def peek(*args);end
def exception_on_syntax_error();end
def exception_on_syntax_error=(arg0);end
def set_prompt(*args);end
def indent();end
def line_no();end
def prompt();end
def set_input(io, p = nil, &block);end
def each_top_level_statement();end
def Raise(*args);end
def Fail(*args);end
def lex_init();end
def skip_space();end
def readed_auto_clean_up();end
def char_no();end
def get_readed();end
def getc_of_rests();end
def peek_equal?(str);end
def peek_match?(regexp);end
def initialize_input();end
def lex();end
def token();end
def identify_comment();end
def identify_here_document();end
def identify_string(ltype, quoted = nil);end
def read_escape();end
def identify_number();end
def lex_int2();end
def identify_quotation();end
def identify_gvar();end
def identify_identifier();end
def identify_string_dvar();end
def skip_space=(arg0);end
def readed_auto_clean_up=(arg0);end
end
class RubyLex::AlreadyDefinedToken < StandardError
include Kernel
def self.exception(*args);end
end
class RubyLex::TkReading2TokenNoKey < StandardError
include Kernel
def self.exception(*args);end
end
class RubyLex::TkSymbol2TokenNoKey < StandardError
include Kernel
def self.exception(*args);end
end
class RubyLex::TkReading2TokenDuplicateError < StandardError
include Kernel
def self.exception(*args);end
end
class RubyLex::SyntaxError < StandardError
include Kernel
def self.exception(*args);end
end
class RubyLex::TerminateLineInput < StandardError
include Kernel
def self.exception(*args);end
end
class RubyToken::Token < Object
include Kernel
def seek();end
def line_no();end
def char_no();end
end
class RubyToken::TkNode < RubyToken::Token
include Kernel
def node();end
end
class RubyToken::TkId < RubyToken::Token
include Kernel
end
class RubyToken::TkVal < RubyToken::Token
include Kernel
def value();end
end
class RubyToken::TkOp < RubyToken::Token
include Kernel
def name=(arg0);end
end
class RubyToken::TkOPASGN < RubyToken::TkOp
include Kernel
def op();end
end
class RubyToken::TkUnknownChar < RubyToken::Token
include Kernel
end
class RubyToken::TkError < RubyToken::Token
include Kernel
end
class RubyToken::TkCLASS < RubyToken::TkId
include Kernel
end
class RubyToken::TkMODULE < RubyToken::TkId
include Kernel
end
class RubyToken::TkDEF < RubyToken::TkId
include Kernel
end
class RubyToken::TkUNDEF < RubyToken::TkId
include Kernel
end
class RubyToken::TkBEGIN < RubyToken::TkId
include Kernel
end
class RubyToken::TkRESCUE < RubyToken::TkId
include Kernel
end
class RubyToken::TkENSURE < RubyToken::TkId
include Kernel
end
class RubyToken::TkEND < RubyToken::TkId
include Kernel
end
class RubyToken::TkIF < RubyToken::TkId
include Kernel
end
class RubyToken::TkUNLESS < RubyToken::TkId
include Kernel
end
class RubyToken::TkTHEN < RubyToken::TkId
include Kernel
end
class RubyToken::TkELSIF < RubyToken::TkId
include Kernel
end
class RubyToken::TkELSE < RubyToken::TkId
include Kernel
end
class RubyToken::TkCASE < RubyToken::TkId
include Kernel
end
class RubyToken::TkWHEN < RubyToken::TkId
include Kernel
end
class RubyToken::TkWHILE < RubyToken::TkId
include Kernel
end
class RubyToken::TkUNTIL < RubyToken::TkId
include Kernel
end
class RubyToken::TkFOR < RubyToken::TkId
include Kernel
end
class RubyToken::TkBREAK < RubyToken::TkId
include Kernel
end
class RubyToken::TkNEXT < RubyToken::TkId
include Kernel
end
class RubyToken::TkREDO < RubyToken::TkId
include Kernel
end
class RubyToken::TkRETRY < RubyToken::TkId
include Kernel
end
class RubyToken::TkIN < RubyToken::TkId
include Kernel
end
class RubyToken::TkDO < RubyToken::TkId
include Kernel
end
class RubyToken::TkRETURN < RubyToken::TkId
include Kernel
end
class RubyToken::TkYIELD < RubyToken::TkId
include Kernel
end
class RubyToken::TkSUPER < RubyToken::TkId
include Kernel
end
class RubyToken::TkSELF < RubyToken::TkId
include Kernel
end
class RubyToken::TkNIL < RubyToken::TkId
include Kernel
end
class RubyToken::TkTRUE < RubyToken::TkId
include Kernel
end
class RubyToken::TkFALSE < RubyToken::TkId
include Kernel
end
class RubyToken::TkAND < RubyToken::TkId
include Kernel
end
class RubyToken::TkOR < RubyToken::TkId
include Kernel
end
class RubyToken::TkNOT < RubyToken::TkId
include Kernel
end
class RubyToken::TkIF_MOD < RubyToken::TkId
include Kernel
end
class RubyToken::TkUNLESS_MOD < RubyToken::TkId
include Kernel
end
class RubyToken::TkWHILE_MOD < RubyToken::TkId
include Kernel
end
class RubyToken::TkUNTIL_MOD < RubyToken::TkId
include Kernel
end
class RubyToken::TkALIAS < RubyToken::TkId
include Kernel
end
class RubyToken::TkDEFINED < RubyToken::TkId
include Kernel
end
class RubyToken::TklBEGIN < RubyToken::TkId
include Kernel
end
class RubyToken::TklEND < RubyToken::TkId
include Kernel
end
class RubyToken::Tk__LINE__ < RubyToken::TkId
include Kernel
end
class RubyToken::Tk__FILE__ < RubyToken::TkId
include Kernel
end
class RubyToken::TkIDENTIFIER < RubyToken::TkId
include Kernel
end
class RubyToken::TkFID < RubyToken::TkId
include Kernel
end
class RubyToken::TkGVAR < RubyToken::TkId
include Kernel
end
class RubyToken::TkCVAR < RubyToken::TkId
include Kernel
end
class RubyToken::TkIVAR < RubyToken::TkId
include Kernel
end
class RubyToken::TkCONSTANT < RubyToken::TkId
include Kernel
end
class RubyToken::TkINTEGER < RubyToken::TkVal
include Kernel
end
class RubyToken::TkFLOAT < RubyToken::TkVal
include Kernel
end
class RubyToken::TkSTRING < RubyToken::TkVal
include Kernel
end
class RubyToken::TkXSTRING < RubyToken::TkVal
include Kernel
end
class RubyToken::TkREGEXP < RubyToken::TkVal
include Kernel
end
class RubyToken::TkSYMBOL < RubyToken::TkVal
include Kernel
end
class RubyToken::TkDSTRING < RubyToken::TkNode
include Kernel
end
class RubyToken::TkDXSTRING < RubyToken::TkNode
include Kernel
end
class RubyToken::TkDREGEXP < RubyToken::TkNode
include Kernel
end
class RubyToken::TkNTH_REF < RubyToken::TkNode
include Kernel
end
class RubyToken::TkBACK_REF < RubyToken::TkNode
include Kernel
end
class RubyToken::TkUPLUS < RubyToken::TkOp
include Kernel
end
class RubyToken::TkUMINUS < RubyToken::TkOp
include Kernel
end
class RubyToken::TkPOW < RubyToken::TkOp
include Kernel
end
class RubyToken::TkCMP < RubyToken::TkOp
include Kernel
end
class RubyToken::TkEQ < RubyToken::TkOp
include Kernel
end
class RubyToken::TkEQQ < RubyToken::TkOp
include Kernel
end
class RubyToken::TkNEQ < RubyToken::TkOp
include Kernel
end
class RubyToken::TkGEQ < RubyToken::TkOp
include Kernel
end
class RubyToken::TkLEQ < RubyToken::TkOp
include Kernel
end
class RubyToken::TkANDOP < RubyToken::TkOp
include Kernel
end
class RubyToken::TkOROP < RubyToken::TkOp
include Kernel
end
class RubyToken::TkMATCH < RubyToken::TkOp
include Kernel
end
class RubyToken::TkNMATCH < RubyToken::TkOp
include Kernel
end
class RubyToken::TkDOT2 < RubyToken::TkOp
include Kernel
end
class RubyToken::TkDOT3 < RubyToken::TkOp
include Kernel
end
class RubyToken::TkAREF < RubyToken::TkOp
include Kernel
end
class RubyToken::TkASET < RubyToken::TkOp
include Kernel
end
class RubyToken::TkLSHFT < RubyToken::TkOp
include Kernel
end
class RubyToken::TkRSHFT < RubyToken::TkOp
include Kernel
end
class RubyToken::TkCOLON2 < RubyToken::TkOp
include Kernel
end
class RubyToken::TkCOLON3 < RubyToken::TkOp
include Kernel
end
class RubyToken::TkASSOC < RubyToken::TkOp
include Kernel
end
class RubyToken::TkQUESTION < RubyToken::TkOp
include Kernel
end
class RubyToken::TkCOLON < RubyToken::TkOp
include Kernel
end
class RubyToken::TkfLPAREN < RubyToken::Token
include Kernel
end
class RubyToken::TkfLBRACK < RubyToken::Token
include Kernel
end
class RubyToken::TkfLBRACE < RubyToken::Token
include Kernel
end
class RubyToken::TkSTAR < RubyToken::Token
include Kernel
end
class RubyToken::TkAMPER < RubyToken::Token
include Kernel
end
class RubyToken::TkSYMBEG < RubyToken::Token
include Kernel
end
class RubyToken::TkGT < RubyToken::TkOp
include Kernel
end
class RubyToken::TkLT < RubyToken::TkOp
include Kernel
end
class RubyToken::TkPLUS < RubyToken::TkOp
include Kernel
end
class RubyToken::TkMINUS < RubyToken::TkOp
include Kernel
end
class RubyToken::TkMULT < RubyToken::TkOp
include Kernel
end
class RubyToken::TkDIV < RubyToken::TkOp
include Kernel
end
class RubyToken::TkMOD < RubyToken::TkOp
include Kernel
end
class RubyToken::TkBITOR < RubyToken::TkOp
include Kernel
end
class RubyToken::TkBITXOR < RubyToken::TkOp
include Kernel
end
class RubyToken::TkBITAND < RubyToken::TkOp
include Kernel
end
class RubyToken::TkBITNOT < RubyToken::TkOp
include Kernel
end
class RubyToken::TkNOTOP < RubyToken::TkOp
include Kernel
end
class RubyToken::TkBACKQUOTE < RubyToken::TkOp
include Kernel
end
class RubyToken::TkASSIGN < RubyToken::Token
include Kernel
end
class RubyToken::TkDOT < RubyToken::Token
include Kernel
end
class RubyToken::TkLPAREN < RubyToken::Token
include Kernel
end
class RubyToken::TkLBRACK < RubyToken::Token
include Kernel
end
class RubyToken::TkLBRACE < RubyToken::Token
include Kernel
end
class RubyToken::TkRPAREN < RubyToken::Token
include Kernel
end
class RubyToken::TkRBRACK < RubyToken::Token
include Kernel
end
class RubyToken::TkRBRACE < RubyToken::Token
include Kernel
end
class RubyToken::TkCOMMA < RubyToken::Token
include Kernel
end
class RubyToken::TkSEMICOLON < RubyToken::Token
include Kernel
end
class RubyToken::TkCOMMENT < RubyToken::Token
include Kernel
end
class RubyToken::TkRD_COMMENT < RubyToken::Token
include Kernel
end
class RubyToken::TkSPACE < RubyToken::Token
include Kernel
end
class RubyToken::TkNL < RubyToken::Token
include Kernel
end
class RubyToken::TkEND_OF_SCRIPT < RubyToken::Token
include Kernel
end
class RubyToken::TkBACKSLASH < RubyToken::TkUnknownChar
include Kernel
end
class RubyToken::TkAT < RubyToken::TkUnknownChar
include Kernel
end
class RubyToken::TkDOLLAR < RubyToken::TkUnknownChar
include Kernel
end
module Readline
def input=(arg0);end
def output=(arg0);end
def completion_proc();end
def completion_case_fold();end
def pre_input_hook();end
def special_prefixes();end
def completion_proc=(arg0);end
def completion_case_fold=(arg0);end
def line_buffer();end
def point();end
def point=(arg0);end
def set_screen_size(arg0, arg1);end
def get_screen_size();end
def vi_editing_mode();end
def vi_editing_mode?();end
def emacs_editing_mode();end
def emacs_editing_mode?();end
def completion_append_character=(arg0);end
def completion_append_character();end
def basic_word_break_characters=(arg0);end
def basic_word_break_characters();end
def completer_word_break_characters=(arg0);end
def completer_word_break_characters();end
def basic_quote_characters=(arg0);end
def basic_quote_characters();end
def completer_quote_characters=(arg0);end
def completer_quote_characters();end
def filename_quote_characters=(arg0);end
def filename_quote_characters();end
def refresh_line();end
def pre_input_hook=(arg0);end
def insert_text(arg0);end
def delete_text(*args);end
def redisplay();end
def special_prefixes=(arg0);end
def self.input=(arg0);end
def self.output=(arg0);end
def self.completion_proc();end
def self.completion_case_fold();end
def self.pre_input_hook();end
def self.special_prefixes();end
def self.completion_proc=(arg0);end
def self.completion_case_fold=(arg0);end
def self.line_buffer();end
def self.point();end
def self.point=(arg0);end
def self.set_screen_size(arg0, arg1);end
def self.get_screen_size();end
def self.vi_editing_mode();end
def self.vi_editing_mode?();end
def self.emacs_editing_mode();end
def self.emacs_editing_mode?();end
def self.completion_append_character=(arg0);end
def self.completion_append_character();end
def self.basic_word_break_characters=(arg0);end
def self.basic_word_break_characters();end
def self.completer_word_break_characters=(arg0);end
def self.completer_word_break_characters();end
def self.basic_quote_characters=(arg0);end
def self.basic_quote_characters();end
def self.completer_quote_characters=(arg0);end
def self.completer_quote_characters();end
def self.filename_quote_characters=(arg0);end
def self.filename_quote_characters();end
def self.refresh_line();end
def self.pre_input_hook=(arg0);end
def self.insert_text(arg0);end
def self.delete_text(*args);end
def self.redisplay();end
def self.special_prefixes=(arg0);end
end
