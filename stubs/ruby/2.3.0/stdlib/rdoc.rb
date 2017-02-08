module RDoc
def load_yaml();end
def self.load_yaml();end
end
class RDoc::Error < RuntimeError
include Kernel
def self.exception(*args);end
end
class RDoc::RDoc < Object
include Kernel
def self.current();end
def self.add_generator(klass);end
def self.current=(rdoc);end
def self.current();end
def self.add_generator(klass);end
def self.current=(rdoc);end
def store();end
def options();end
def error(msg);end
def exclude();end
def generator();end
def last_modified();end
def stats();end
def gather_files(files);end
def normalized_file_list(relative_files, force_doc = nil, exclude_pattern = nil);end
def remove_unparseable(files);end
def handle_pipe();end
def document(options);end
def install_siginfo_handler();end
def load_options();end
def setup_output_dir(dir, force);end
def output_flag_file(op_dir);end
def store=(store);end
def update_output_dir(op_dir, time, last = nil);end
def parse_dot_doc_file(in_dir, filename);end
def list_files_in_directory(dir);end
def parse_file(filename);end
def parse_files(files);end
def generate();end
def remove_siginfo_handler();end
def exclude=(arg0);end
def generator=(arg0);end
def options=(arg0);end
end
class RDoc::TestCase < Minitest::Unit::TestCase
include Minitest::Guard
include Minitest::Test::LifecycleHooks
include Minitest::Assertions
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.inherited(klass);end
def self.runnable_methods();end
def self.test_order();end
def self.io_lock();end
def self.io_lock=(arg0);end
def self.i_suck_and_my_tests_are_order_dependent!();end
def self.make_my_diffs_pretty!();end
def self.parallelize_me!();end
def self.jruby?(*args);end
def self.maglev?(*args);end
def self.mri?(*args);end
def self.rubinius?(*args);end
def self.windows?(*args);end
def self.run(reporter, options = nil);end
def self.reset();end
def self.methods_matching(re);end
def self.runnables();end
def self.with_info_handler(reporter, &block);end
def self.run_one_method(klass, method_name, reporter);end
def self.on_signal(name, action);end
def list(*args);end
def block(*args);end
def item(*args);end
def setup();end
def head(level, text);end
def comment(text, top_level = nil);end
def rule(weight);end
def doc(*args);end
def assert_file(path);end
def assert_directory(path);end
def refute_file(path);end
def blank_line();end
def hard_break();end
def mu_pp(obj);end
def para(*args);end
def raw(*args);end
def temp_dir();end
def verb(*args);end
def verbose_capture_io();end
end
module Minitest::Test::LifecycleHooks
def setup();end
def before_setup();end
def after_setup();end
def before_teardown();end
def teardown();end
def after_teardown();end
end
class RDoc::CrossReference < Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def seen();end
def resolve(name, text);end
def seen=(arg0);end
end
class RDoc::ERBIO < ERB
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.version();end
def set_eoutvar(compiler, io_variable);end
end
class ERB::Compiler < Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def compile(s);end
def trim_mode();end
def percent();end
def make_scanner(src);end
def pre_cmd();end
def post_cmd();end
def content_dump(s);end
def add_put_cmd(out, content);end
def add_insert_cmd(out, content);end
def prepare_trim_mode(mode);end
def put_cmd();end
def insert_cmd();end
def put_cmd=(arg0);end
def insert_cmd=(arg0);end
def pre_cmd=(arg0);end
def post_cmd=(arg0);end
end
class ERB::Compiler::PercentLine < Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def empty?();end
def value();end
end
class ERB::Compiler::Scanner < Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.regist_scanner(klass, trim_mode, percent);end
def self.default_scanner=(klass);end
def self.make_scanner(src, trim_mode, percent);end
def self.regist_scanner(klass, trim_mode, percent);end
def self.default_scanner=(klass);end
def self.make_scanner(src, trim_mode, percent);end
def scan();end
def stag();end
def stag=(arg0);end
end
class ERB::Compiler::TrimScanner < ERB::Compiler::Scanner
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.regist_scanner(klass, trim_mode, percent);end
def self.default_scanner=(klass);end
def self.make_scanner(src, trim_mode, percent);end
def scan(&block);end
def stag();end
def trim_line1(line);end
def trim_line2(line);end
def explicit_trim_line(line);end
def scan_line(line);end
def percent_line(line, &block);end
def is_erb_stag?(s);end
def stag=(arg0);end
end
class ERB::Compiler::SimpleScanner < ERB::Compiler::Scanner
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.regist_scanner(klass, trim_mode, percent);end
def self.default_scanner=(klass);end
def self.make_scanner(src, trim_mode, percent);end
def scan();end
end
class ERB::Compiler::SimpleScanner2 < ERB::Compiler::Scanner
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.regist_scanner(klass, trim_mode, percent);end
def self.default_scanner=(klass);end
def self.make_scanner(src, trim_mode, percent);end
def scan();end
end
class ERB::Compiler::ExplicitScanner < ERB::Compiler::Scanner
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.regist_scanner(klass, trim_mode, percent);end
def self.default_scanner=(klass);end
def self.make_scanner(src, trim_mode, percent);end
def scan();end
end
class ERB::Compiler::Buffer < Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def push(cmd);end
def cr();end
def close();end
def script();end
end
module ERB::Util
def h(s);end
def html_escape(s);end
def url_encode(s);end
def u(s);end
def self.h(s);end
def self.html_escape(s);end
def self.url_encode(s);end
def self.u(s);end
end
module ERB::DefMethod
def def_erb_method(methodname, erb_or_fname);end
def self.def_erb_method(methodname, erb_or_fname);end
end
class RDoc::ERBPartial < ERB
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.version();end
def set_eoutvar(compiler, eoutvar = nil);end
end
module RDoc::Encoding
def set_encoding(string);end
def read_file(filename, encoding, force_transcode = nil);end
def self.set_encoding(string);end
def self.read_file(filename, encoding, force_transcode = nil);end
end
module RDoc::Generator
end
module RDoc::Generator::Markup
def description();end
def aref_to(target_path);end
def as_href(from_path);end
def formatter();end
def cvs_url(url, full_path);end
end
class RDoc::Generator::Darkfish < Object
include ERB::Util
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def store();end
def files();end
def base_dir();end
def dry_run();end
def dry_run=(arg0);end
def generate();end
def asset_rel_path();end
def classes();end
def file_output();end
def json_index();end
def modsort();end
def template_dir();end
def outputdir();end
def debug_msg(*args);end
def class_dir();end
def file_dir();end
def gen_sub_directories();end
def write_style_sheet();end
def install_rdoc_static_file(source, destination, options);end
def setup();end
def generate_index();end
def generate_class_files();end
def generate_file_files();end
def generate_table_of_contents();end
def copy_static();end
def get_sorted_module_list(classes);end
def render_template(template_file, out_file = nil);end
def generate_class(klass, template_file = nil);end
def get_svninfo(klass);end
def generate_page(file);end
def generate_servlet_not_found(message);end
def generate_servlet_root(installed);end
def time_delta_string(seconds);end
def assemble_template(body_file);end
def render(file_name);end
def template_for(file, page = nil, klass = nil);end
def template_result(template, context, template_file);end
def asset_rel_path=(arg0);end
def file_output=(arg0);end
end
class RDoc::Generator::JsonIndex < Object
include RDoc::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def index();end
def reset(files, classes);end
def generate();end
def debug_msg(*args);end
def class_dir();end
def file_dir();end
def generate_gzipped();end
def build_index();end
def index_classes();end
def index_methods();end
def index_pages();end
def search_string(string);end
end
class RDoc::Generator::RI < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def generate();end
end
class RDoc::Generator::POT < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def generate();end
def class_dir();end
end
class RDoc::Generator::POT::MessageExtractor < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def extract();end
end
class RDoc::Generator::POT::PO < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def add(entry);end
end
class RDoc::Generator::POT::POEntry < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def merge(other_entry);end
def flags();end
def extracted_comment();end
def references();end
def msgid();end
def msgstr();end
def translator_comment();end
end
class RDoc::Options < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def parse(argv);end
def template();end
def files=(arg0);end
def exclude();end
def generator();end
def encode_with(coder);end
def generator_name();end
def generator_options();end
def hyperlink_all();end
def line_numbers();end
def locale_dir();end
def option_parser();end
def output_decoration();end
def rdoc_include();end
def show_hash();end
def tab_width();end
def init_ivars();end
def finish();end
def init_with(map);end
def markup();end
def yaml_initialize(tag, map);end
def dry_run();end
def force_output();end
def update_output_dir();end
def op_dir();end
def sanitize_path(path);end
def check_files();end
def check_generator();end
def finish_page_dir();end
def template_dir_for(template);end
def generator_descriptions();end
def formatter();end
def root();end
def page_dir();end
def setup_generator(*args);end
def files();end
def charset();end
def write_options();end
def verbosity();end
def quiet=(bool);end
def to_yaml(*args);end
def coverage_report();end
def force_update();end
def charset=(arg0);end
def force_output=(arg0);end
def force_update=(arg0);end
def encoding=(arg0);end
def dry_run=(arg0);end
def main_page=(arg0);end
def main_page();end
def title();end
def title=(arg0);end
def formatter=(arg0);end
def encoding();end
def pipe();end
def line_numbers=(arg0);end
def locale=(arg0);end
def exclude=(arg0);end
def generator=(arg0);end
def coverage_report=(arg0);end
def template_dir();end
def locale_dir=(arg0);end
def generator_options=(arg0);end
def hyperlink_all=(arg0);end
def op_dir=(arg0);end
def option_parser=(arg0);end
def output_decoration=(arg0);end
def markup=(arg0);end
def pipe=(arg0);end
def rdoc_include=(arg0);end
def root=(arg0);end
def show_hash=(arg0);end
def page_dir=(arg0);end
def tab_width=(arg0);end
def template=(arg0);end
def template_dir=(arg0);end
def template_stylesheets=(arg0);end
def static_path=(arg0);end
def verbosity=(arg0);end
def webcvs=(arg0);end
def template_stylesheets();end
def update_output_dir=(arg0);end
def quiet();end
def webcvs();end
def static_path();end
def visibility=(visibility);end
def default_title=(string);end
def visibility();end
def locale();end
end
class RDoc::Parser < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.can_parse(file_name);end
def self.binary?(file);end
def self.for(top_level, file_name, content, options, stats);end
def self.parsers();end
def self.alias_extension(old_ext, new_ext);end
def self.can_parse_by_name(file_name);end
def self.process_directive(code_object, directive, value);end
def self.zip?(file);end
def self.check_modeline(file_name);end
def self.use_markup(content);end
def self.remove_modeline(content);end
def self.parse_files_matching(regexp);end
def self.can_parse(file_name);end
def self.binary?(file);end
def self.for(top_level, file_name, content, options, stats);end
def self.parsers();end
def self.alias_extension(old_ext, new_ext);end
def self.can_parse_by_name(file_name);end
def self.process_directive(code_object, directive, value);end
def self.zip?(file);end
def self.check_modeline(file_name);end
def self.use_markup(content);end
def self.remove_modeline(content);end
def self.parse_files_matching(regexp);end
def file_name();end
end
module RDoc::Parser::RubyTools
include RDoc::RubyToken
def reset();end
def get_tkread();end
def skip_tkspace(*args);end
def get_tk();end
def unget_tk(tk);end
def peek_tk();end
def add_token_listener(obj);end
def remove_token_listener(obj);end
def token_listener(obj);end
def get_tk_until(*args);end
def peek_read();end
end
class RDoc::RubyToken::Token < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def text();end
def seek();end
def line_no();end
def text=(arg0);end
def set_text(text);end
def char_no();end
end
class RDoc::RubyToken::TkNode < RDoc::RubyToken::Token
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def text();end
def node();end
def set_text(text);end
end
class RDoc::RubyToken::TkId < RDoc::RubyToken::Token
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def text();end
def set_text(text);end
end
class RDoc::RubyToken::TkKW < RDoc::RubyToken::TkId
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkVal < RDoc::RubyToken::Token
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def value();end
def text();end
def value=(arg0);end
def set_text(text);end
end
class RDoc::RubyToken::TkOp < RDoc::RubyToken::Token
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def text();end
def name=(arg0);end
def set_text(text);end
end
class RDoc::RubyToken::TkOPASGN < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def text();end
def op();end
end
class RDoc::RubyToken::TkUnknownChar < RDoc::RubyToken::Token
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def text();end
def set_text(text);end
end
class RDoc::RubyToken::TkError < RDoc::RubyToken::Token
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkCLASS < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkMODULE < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkDEF < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkUNDEF < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkBEGIN < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkRESCUE < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkENSURE < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkEND < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkIF < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkUNLESS < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkTHEN < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkELSIF < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkELSE < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkCASE < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkWHEN < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkWHILE < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkUNTIL < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkFOR < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkBREAK < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkNEXT < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkREDO < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkRETRY < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkIN < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkDO < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkRETURN < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkYIELD < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkSUPER < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkSELF < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkNIL < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkTRUE < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkFALSE < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkAND < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkOR < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkNOT < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkIF_MOD < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkUNLESS_MOD < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkWHILE_MOD < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkUNTIL_MOD < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkALIAS < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkDEFINED < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TklBEGIN < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TklEND < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::Tk__LINE__ < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::Tk__FILE__ < RDoc::RubyToken::TkKW
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkIDENTIFIER < RDoc::RubyToken::TkId
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkFID < RDoc::RubyToken::TkId
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkGVAR < RDoc::RubyToken::TkId
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkCVAR < RDoc::RubyToken::TkId
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkIVAR < RDoc::RubyToken::TkId
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkCONSTANT < RDoc::RubyToken::TkId
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkINTEGER < RDoc::RubyToken::TkVal
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkFLOAT < RDoc::RubyToken::TkVal
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkSTRING < RDoc::RubyToken::TkVal
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkHEREDOC < RDoc::RubyToken::TkVal
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkXSTRING < RDoc::RubyToken::TkVal
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkREGEXP < RDoc::RubyToken::TkVal
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkSYMBOL < RDoc::RubyToken::TkVal
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def to_sym();end
end
class RDoc::RubyToken::TkCHAR < RDoc::RubyToken::TkVal
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkDSTRING < RDoc::RubyToken::TkNode
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkDXSTRING < RDoc::RubyToken::TkNode
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkDREGEXP < RDoc::RubyToken::TkNode
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkNTH_REF < RDoc::RubyToken::TkNode
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkBACK_REF < RDoc::RubyToken::TkNode
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkUPLUS < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkUMINUS < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkPOW < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkCMP < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkEQ < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkEQQ < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkNEQ < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkGEQ < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkLEQ < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkANDOP < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkOROP < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkMATCH < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkNMATCH < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkDOT2 < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkDOT3 < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkAREF < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkASET < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkLSHFT < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkRSHFT < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkCOLON2 < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkCOLON3 < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkASSOC < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkQUESTION < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkCOLON < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkfLPAREN < RDoc::RubyToken::Token
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkfLBRACK < RDoc::RubyToken::Token
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkfLBRACE < RDoc::RubyToken::Token
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkSYMBEG < RDoc::RubyToken::Token
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkAMPER < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkGT < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkLT < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkPLUS < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkSTAR < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkMINUS < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkMULT < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkDIV < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkMOD < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkBITOR < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkBITXOR < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkBITAND < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkBITNOT < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkNOTOP < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkBACKQUOTE < RDoc::RubyToken::TkOp
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkASSIGN < RDoc::RubyToken::Token
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkDOT < RDoc::RubyToken::Token
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkLPAREN < RDoc::RubyToken::Token
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkLBRACK < RDoc::RubyToken::Token
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkLBRACE < RDoc::RubyToken::Token
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkRPAREN < RDoc::RubyToken::Token
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkRBRACK < RDoc::RubyToken::Token
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkRBRACE < RDoc::RubyToken::Token
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkCOMMA < RDoc::RubyToken::Token
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkSEMICOLON < RDoc::RubyToken::Token
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkCOMMENT < RDoc::RubyToken::TkVal
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkSPACE < RDoc::RubyToken::Token
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkNL < RDoc::RubyToken::Token
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkEND_OF_SCRIPT < RDoc::RubyToken::Token
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkBACKSLASH < RDoc::RubyToken::TkUnknownChar
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkAT < RDoc::RubyToken::TkUnknownChar
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkDOLLAR < RDoc::RubyToken::TkUnknownChar
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::RubyToken::TkRD_COMMENT < RDoc::RubyToken::TkCOMMENT
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
module RDoc::Parser::Text
end
class RDoc::Parser::Simple < RDoc::Parser
include RDoc::Parser::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.can_parse(file_name);end
def self.binary?(file);end
def self.for(top_level, file_name, content, options, stats);end
def self.parsers();end
def self.alias_extension(old_ext, new_ext);end
def self.can_parse_by_name(file_name);end
def self.process_directive(code_object, directive, value);end
def self.zip?(file);end
def self.check_modeline(file_name);end
def self.use_markup(content);end
def self.remove_modeline(content);end
def self.parse_files_matching(regexp);end
def scan();end
def content();end
def remove_coding_comment(text);end
def remove_private_comment(comment);end
end
class RDoc::Parser::C < RDoc::Parser
include RDoc::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.can_parse(file_name);end
def self.binary?(file);end
def self.for(top_level, file_name, content, options, stats);end
def self.parsers();end
def self.alias_extension(old_ext, new_ext);end
def self.can_parse_by_name(file_name);end
def self.process_directive(code_object, directive, value);end
def self.zip?(file);end
def self.check_modeline(file_name);end
def self.use_markup(content);end
def self.remove_modeline(content);end
def self.parse_files_matching(regexp);end
def scan();end
def content();end
def top_level();end
def classes();end
def enclosure_dependencies();end
def known_classes();end
def missing_dependencies();end
def singleton_classes();end
def handle_tab_width(body);end
def handle_ifdefs_in(body);end
def load_variable_map(map_name);end
def deduplicate_call_seq();end
def find_class(raw_name, name);end
def deduplicate_method_name(class_obj, method_name);end
def do_aliases();end
def find_alias_comment(class_name, new_name, old_name);end
def do_attrs();end
def handle_attr(var_name, attr_name, read, write);end
def do_boot_defclass();end
def handle_class_module(var_name, type, class_name, parent, in_module);end
def do_classes();end
def do_define_class();end
def do_define_class_under();end
def do_singleton_class();end
def do_struct_define_without_accessor();end
def do_constants();end
def handle_constants(type, var_name, const_name, definition);end
def do_define_module();end
def do_define_module_under();end
def do_includes();end
def do_methods();end
def handle_method(type, var_name, meth_name, function, param_count, source_file = nil);end
def do_missing();end
def do_modules();end
def handle_singleton(sclass_var, class_var);end
def find_attr_comment(var_name, attr_name, read = nil, write = nil);end
def find_body(class_name, meth_name, meth_obj, file_content, quiet = nil);end
def find_override_comment(class_name, meth_obj);end
def find_modifiers(comment, meth_obj);end
def find_class_comment(class_name, class_mod);end
def look_for_directives_in(context, comment);end
def find_const_comment(type, const_name, class_name = nil);end
def rb_scan_args(method_body);end
def remove_commented_out_lines();end
def content=(arg0);end
end
class RDoc::Parser::ChangeLog < RDoc::Parser
include RDoc::Parser::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.can_parse(file_name);end
def self.binary?(file);end
def self.for(top_level, file_name, content, options, stats);end
def self.parsers();end
def self.alias_extension(old_ext, new_ext);end
def self.can_parse_by_name(file_name);end
def self.process_directive(code_object, directive, value);end
def self.zip?(file);end
def self.check_modeline(file_name);end
def self.use_markup(content);end
def self.remove_modeline(content);end
def self.parse_files_matching(regexp);end
def scan();end
def continue_entry_body(entry_body, continuation);end
def create_document(groups);end
def create_entries(entries);end
def create_items(items);end
def group_entries(entries);end
def parse_entries();end
end
class RDoc::Parser::Markdown < RDoc::Parser
include RDoc::Parser::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.can_parse(file_name);end
def self.binary?(file);end
def self.for(top_level, file_name, content, options, stats);end
def self.parsers();end
def self.alias_extension(old_ext, new_ext);end
def self.can_parse_by_name(file_name);end
def self.process_directive(code_object, directive, value);end
def self.zip?(file);end
def self.check_modeline(file_name);end
def self.use_markup(content);end
def self.remove_modeline(content);end
def self.parse_files_matching(regexp);end
def scan();end
end
class RDoc::Parser::RD < RDoc::Parser
include RDoc::Parser::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.can_parse(file_name);end
def self.binary?(file);end
def self.for(top_level, file_name, content, options, stats);end
def self.parsers();end
def self.alias_extension(old_ext, new_ext);end
def self.can_parse_by_name(file_name);end
def self.process_directive(code_object, directive, value);end
def self.zip?(file);end
def self.check_modeline(file_name);end
def self.use_markup(content);end
def self.remove_modeline(content);end
def self.parse_files_matching(regexp);end
def scan();end
end
class RDoc::Parser::Ruby < RDoc::Parser
include RDoc::Parser::RubyTools
include RDoc::TokenStream
include RDoc::RubyToken
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.can_parse(file_name);end
def self.binary?(file);end
def self.for(top_level, file_name, content, options, stats);end
def self.parsers();end
def self.alias_extension(old_ext, new_ext);end
def self.can_parse_by_name(file_name);end
def self.process_directive(code_object, directive, value);end
def self.zip?(file);end
def self.check_modeline(file_name);end
def self.use_markup(content);end
def self.remove_modeline(content);end
def self.parse_files_matching(regexp);end
def create_attr(container, single, name, rw, comment);end
def create_module_alias(container, constant, rhs_name);end
def make_message(message);end
def get_bool();end
def parse_yield(context, single, tk, method);end
def skip_optional_do_after_expression();end
def get_class_or_module(container, ignore_constants = nil);end
def skip_for_variable();end
def get_class_specification();end
def parse_symbol_arg_paren(no);end
def parse_symbol_arg_space(no, tk);end
def get_constant();end
def parse_symbol_in_arg();end
def parse_call_parameters(tk);end
def parse_top_level_statements(container);end
def get_constant_with_optional_parens();end
def update_visibility(container, vis_type, vis, singleton);end
def read_directive(allowed);end
def get_end_token(tk);end
def get_method_container(container, name_t);end
def parse_method_dummy(container);end
def scan();end
def get_symbol_or_name();end
def parse_class(container, single, tk, comment);end
def parse_module(container, single, tk, comment);end
def stop_at_EXPR_END();end
def suppress_parents(container, ancestor);end
def remove_private_comments(comment);end
def parse_attr(context, single, tk, comment);end
def parse_symbol_arg(*args);end
def read_documentation_modifiers(context, allowed);end
def parse_attr_accessor(context, single, tk, comment);end
def parse_alias(context, single, tk, comment);end
def look_for_directives_in(context, comment);end
def parse_class_regular(container, declaration_context, single, name_t, given_name, comment);end
def parse_statements(container, single = nil, current_method = nil, comment = nil);end
def parse_class_singleton(container, name, comment);end
def parse_constant(container, tk, comment, ignore_constants = nil);end
def new_comment(comment);end
def parse_constant_body(container, constant);end
def parse_comment(container, tk, comment);end
def parse_comment_tomdoc(container, tk, comment);end
def parse_comment_ghost(container, text, name, column, line_no, comment);end
def parse_comment_attr(container, type, name, comment);end
def parse_extend_or_include(klass, container, comment);end
def skip_tkspace_comment(*args);end
def parse_identifier(container, single, tk, comment);end
def parse_visibility(container, single, tk);end
def parse_meta_attr(context, single, tk, comment);end
def parse_meta_method(container, single, tk, comment);end
def record_location(container);end
def parse_meta_method_name(comment, tk);end
def parse_meta_method_params(container, single, meth, tk, comment);end
def parse_method(container, single, tk, comment);end
def parse_method_name(container);end
def parse_method_params_and_body(container, single, meth, added_container);end
def parse_method_parameters(method);end
def skip_method(container);end
def parse_method_name_singleton(container, name_t);end
def parse_method_name_regular(container, name_t);end
def get_tkread_clean(pattern, replacement);end
def error(msg);end
def get_visibility_information(tk, single);end
def parse_method_or_yield_parameters(*args);end
def collect_first_comment();end
def parse_require(context, comment);end
def parse_rescue();end
def consume_trailing_spaces();end
end
class RDoc::Servlet < WEBrick::HTTPServlet::AbstractServlet
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.get_instance(server, *options);end
def self.get_instance(server, *options);end
def options();end
def error(exception, req, res);end
def root(req, res);end
def asset_dirs();end
def asset(generator_name, req, res);end
def if_modified_since(req, res, path = nil);end
def do_GET(req, res);end
def root_search(req, res);end
def show_documentation(req, res);end
def generator_for(store);end
def not_found(generator, req, res, message = nil);end
def documentation_page(store, generator, path, req, res);end
def documentation_search(store, generator, req, res);end
def documentation_source(path);end
def store_for(source_name);end
def installed_docs();end
def ri_paths(&block);end
end
module RDoc::RI
end
class RDoc::RI::Error < RDoc::Error
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.exception(*args);end
end
class RDoc::RI::Driver < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.dump(data_path);end
def self.run(*args);end
def self.process_args(argv);end
def self.default_options();end
def self.dump(data_path);end
def self.run(*args);end
def self.process_args(argv);end
def self.default_options();end
def run();end
def complete(name);end
def classes();end
def page();end
def formatter(io);end
def add_method(out, name);end
def add_class(out, name, classes);end
def parse_name(name);end
def stores();end
def show_all();end
def use_stdout();end
def interactive();end
def add_also_in(out, also_in);end
def add_from(out, store);end
def add_extends(out, extends);end
def add_extension_modules(out, type, extensions);end
def add_extension_modules_single(out, store, include);end
def add_extension_modules_multiple(out, store, modules);end
def add_includes(out, includes);end
def lookup_method(name);end
def method_document(name, filtered);end
def add_method_documentation(out, klass);end
def add_method_list(out, methods, name);end
def ancestors_of(klass);end
def class_cache();end
def class_document(name, found, klasses, includes, extends);end
def render_class(out, store, klass, also_in);end
def class_document_comment(out, comment);end
def class_document_constants(out, klass);end
def classes_and_includes_and_extends_for(name);end
def complete_klass(name, klass, selector, method, completions);end
def complete_method(name, klass, selector, completions);end
def list_methods_matching(name);end
def display_class(name);end
def display_method(name);end
def display_name(name);end
def display_page(name);end
def display_names(names);end
def expand_name(name);end
def display_page_list(store, pages = nil, search = nil);end
def expand_class(klass);end
def find_store(name);end
def filter_methods(found, name);end
def name_regexp(name);end
def find_methods(name);end
def method_type(selector);end
def find_pager_jruby(pager);end
def paging?();end
def in_path?(file);end
def list_known_classes(*args);end
def load_method(store, cache, klass, type, name);end
def load_methods_matching(name);end
def render_method(out, store, method, name);end
def setup_pager();end
def render_method_arguments(out, arglists);end
def render_method_superclass(out, method);end
def render_method_comment(out, method);end
def start_server();end
def show_all=(arg0);end
def stores=(arg0);end
def use_stdout=(arg0);end
end
class RDoc::RI::Driver::Error < RDoc::RI::Error
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.exception(*args);end
end
class RDoc::RI::Driver::NotFoundError < RDoc::RI::Driver::Error
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.exception(*args);end
def message();end
end
module RDoc::RI::Paths
def each(*args);end
def path(*args);end
def gem_dir(name, version);end
def site_dir();end
def home_dir();end
def system_dir();end
def gemdirs(*args);end
def raw_path(system, site, home, gems, *extra_dirs);end
def self.each(*args);end
def self.path(*args);end
def self.gem_dir(name, version);end
def self.site_dir();end
def self.home_dir();end
def self.system_dir();end
def self.gemdirs(*args);end
def self.raw_path(system, site, home, gems, *extra_dirs);end
end
class RDoc::Store < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def all_classes_and_modules();end
def all_files();end
def find_file_named(name);end
def classes_hash();end
def dry_run();end
def friendly_path();end
def c_enclosure_classes();end
def c_enclosure_names();end
def rdoc=(arg0);end
def type=(arg0);end
def page(name);end
def find_class_named(name);end
def make_variable_map(variables);end
def all_classes();end
def all_modules();end
def class_file(klass_name);end
def class_path(klass_name);end
def clean_cache_collection(collection);end
def fix_basic_object_inheritance();end
def remove_nodoc(all_hash);end
def add_file(absolute_name, relative_name = nil);end
def find_unique(all_hash);end
def files_hash();end
def load_class_data(klass_name);end
def find_class_named_from(name, from);end
def path=(arg0);end
def unique_classes_and_modules();end
def find_text_page(file_name);end
def save();end
def method_file(klass_name, method_name);end
def save_class(klass);end
def load_page(page_name);end
def load_all();end
def save_cache();end
def save_method(klass, method);end
def save_page(page);end
def encoding=(arg0);end
def dry_run=(arg0);end
def main=(page);end
def unique_classes();end
def cache_path();end
def find_c_enclosure(variable);end
def add_c_enclosure(variable, namespace);end
def load_cache();end
def title=(title);end
def encoding();end
def type();end
def source();end
def complete(min_visibility);end
def title();end
def cache();end
def unique_modules();end
def module_names();end
def class_methods();end
def add_c_variables(c_parser);end
def load_method(klass_name, method_name);end
def find_class_or_module(name);end
def load_class(klass_name);end
def modules_hash();end
def path();end
def main();end
def find_module_named(name);end
def attributes();end
def rdoc();end
def c_class_variables();end
def page_file(page_name);end
def c_singleton_class_variables();end
end
class RDoc::Store::Error < RDoc::Error
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.exception(*args);end
end
class RDoc::Store::MissingFileError < RDoc::Store::Error
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.exception(*args);end
def message();end
def store();end
def file();end
end
class RDoc::Stats < Object
include RDoc::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def report();end
def summary();end
def add_file(file);end
def begin_adding();end
def done_adding();end
def coverage_level();end
def coverage_level=(level);end
def fully_documented?();end
def add_alias(as);end
def add_attribute(attribute);end
def add_constant(constant);end
def add_method(method);end
def add_class(klass);end
def add_module(mod);end
def files_so_far();end
def num_files();end
def calculate();end
def doc_stats(collection);end
def great_job();end
def percent_doc();end
def report_class_module(cm);end
def report_constants(cm);end
def report_attributes(cm);end
def report_methods(cm);end
def undoc_params(method);end
end
class RDoc::Stats::Quiet < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def begin_adding(*args);end
def done_adding(*args);end
def print_alias(*args);end
def print_attribute(*args);end
def print_class(*args);end
def print_constant(*args);end
def print_file(*args);end
def print_method(*args);end
def print_module(*args);end
end
class RDoc::Stats::Normal < RDoc::Stats::Quiet
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def begin_adding();end
def done_adding();end
def print_file(files_so_far, filename);end
end
class RDoc::Stats::Verbose < RDoc::Stats::Normal
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def nodoc(co);end
def print_alias(as);end
def print_attribute(attribute);end
def print_class(klass);end
def print_constant(constant);end
def print_file(files_so_far, file);end
def print_method(method);end
def print_module(mod);end
end
class RDoc::Task < Rake::TaskLib
include Rake::DSL
include Rake::FileUtilsExt
include FileUtils
include FileUtils::StreamUtils_
include Rake::Cloneable
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def options();end
def main();end
def name=(arg0);end
def generator();end
def markup();end
def main=(arg0);end
def title();end
def title=(arg0);end
def generator=(arg0);end
def options=(arg0);end
def template();end
def define();end
def markup=(arg0);end
def template=(arg0);end
def rdoc_dir();end
def rdoc_files();end
def external();end
def defaults();end
def check_names(names);end
def clobber_task_description();end
def inline_source();end
def inline_source=(value);end
def rdoc_task_description();end
def rerdoc_task_description();end
def option_list();end
def before_running_rdoc(&block);end
def rdoc_dir=(arg0);end
def rdoc_files=(arg0);end
def external=(arg0);end
end
module FileUtils::StreamUtils_
end
class FileUtils::Entry_ < Object
include FileUtils::StreamUtils_
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def entries();end
def path();end
def directory?();end
def exist?();end
def file?();end
def pipe?();end
def symlink?();end
def socket?();end
def blockdev?();end
def chardev?();end
def stat();end
def lstat();end
def chmod(mode);end
def chown(uid, gid);end
def prefix();end
def remove();end
def traverse();end
def remove_file();end
def copy_file(dest);end
def copy(dest);end
def wrap_traverse(pre, post);end
def rel();end
def copy_metadata(path);end
def preorder_traverse();end
def postorder_traverse();end
def dereference?();end
def lstat!();end
def door?();end
def stat!();end
def remove_dir1();end
def platform_support();end
end
module FileUtils::LowMethods
end
module FileUtils::Verbose
include FileUtils
include FileUtils::StreamUtils_
def copy_stream(src, dest);end
def identical?(a, b);end
def chmod(*args);end
def chown(*args);end
def link(*args);end
def symlink(*args);end
def chdir(*args);end
def getwd();end
def pwd();end
def mkdir(*args);end
def rmdir(*args);end
def mkdir_p(*args);end
def install(*args);end
def remove(*args);end
def touch(*args);end
def cd(*args);end
def uptodate?(new, old_list);end
def mkpath(*args);end
def makedirs(*args);end
def ln(*args);end
def remove_file(path, force = nil);end
def ln_s(*args);end
def ln_sf(*args);end
def cp(*args);end
def copy_file(src, dest, preserve = nil, dereference = nil);end
def copy(*args);end
def cp_r(*args);end
def copy_entry(src, dest, preserve = nil, dereference_root = nil, remove_destination = nil);end
def mv(*args);end
def remove_entry_secure(path, force = nil);end
def remove_entry(path, force = nil);end
def move(*args);end
def rm(*args);end
def rm_f(*args);end
def safe_unlink(*args);end
def rm_r(*args);end
def rm_rf(*args);end
def rmtree(*args);end
def remove_dir(path, force = nil);end
def compare_file(a, b);end
def compare_stream(a, b);end
def cmp(a, b);end
def chmod_R(*args);end
def chown_R(*args);end
def sh(*args);end
def split_all(path);end
def safe_ln(*args);end
def ruby(*args);end
def self.copy_stream(src, dest);end
def self.identical?(a, b);end
def self.chmod(*args);end
def self.chown(*args);end
def self.link(*args);end
def self.symlink(*args);end
def self.chdir(*args);end
def self.getwd();end
def self.pwd();end
def self.mkdir(*args);end
def self.rmdir(*args);end
def self.mkdir_p(*args);end
def self.install(*args);end
def self.remove(*args);end
def self.touch(*args);end
def self.cd(*args);end
def self.uptodate?(new, old_list);end
def self.mkpath(*args);end
def self.makedirs(*args);end
def self.ln(*args);end
def self.remove_file(path, force = nil);end
def self.ln_s(*args);end
def self.ln_sf(*args);end
def self.cp(*args);end
def self.copy_file(src, dest, preserve = nil, dereference = nil);end
def self.copy(*args);end
def self.cp_r(*args);end
def self.copy_entry(src, dest, preserve = nil, dereference_root = nil, remove_destination = nil);end
def self.mv(*args);end
def self.remove_entry_secure(path, force = nil);end
def self.remove_entry(path, force = nil);end
def self.move(*args);end
def self.rm(*args);end
def self.rm_f(*args);end
def self.safe_unlink(*args);end
def self.rm_r(*args);end
def self.rm_rf(*args);end
def self.rmtree(*args);end
def self.remove_dir(path, force = nil);end
def self.compare_file(a, b);end
def self.compare_stream(a, b);end
def self.cmp(a, b);end
def self.chmod_R(*args);end
def self.chown_R(*args);end
end
module FileUtils::NoWrite
include FileUtils::LowMethods
include FileUtils
include FileUtils::StreamUtils_
def copy_stream(*args);end
def identical?(*args);end
def chmod(*args);end
def chown(*args);end
def link(*args);end
def symlink(*args);end
def chdir(*args);end
def getwd(*args);end
def pwd(*args);end
def mkdir(*args);end
def rmdir(*args);end
def mkdir_p(*args);end
def install(*args);end
def remove(*args);end
def touch(*args);end
def cd(*args);end
def uptodate?(*args);end
def mkpath(*args);end
def makedirs(*args);end
def ln(*args);end
def remove_file(*args);end
def ln_s(*args);end
def ln_sf(*args);end
def cp(*args);end
def copy_file(*args);end
def copy(*args);end
def cp_r(*args);end
def copy_entry(*args);end
def mv(*args);end
def remove_entry_secure(*args);end
def remove_entry(*args);end
def move(*args);end
def rm(*args);end
def rm_f(*args);end
def safe_unlink(*args);end
def rm_r(*args);end
def rm_rf(*args);end
def rmtree(*args);end
def remove_dir(*args);end
def compare_file(*args);end
def compare_stream(*args);end
def cmp(*args);end
def chmod_R(*args);end
def chown_R(*args);end
def sh(*args);end
def split_all(path);end
def safe_ln(*args);end
def ruby(*args);end
def self.copy_stream(*args);end
def self.identical?(*args);end
def self.chmod(*args);end
def self.chown(*args);end
def self.link(*args);end
def self.symlink(*args);end
def self.chdir(*args);end
def self.getwd(*args);end
def self.pwd(*args);end
def self.mkdir(*args);end
def self.rmdir(*args);end
def self.mkdir_p(*args);end
def self.install(*args);end
def self.remove(*args);end
def self.touch(*args);end
def self.cd(*args);end
def self.uptodate?(*args);end
def self.mkpath(*args);end
def self.makedirs(*args);end
def self.ln(*args);end
def self.remove_file(*args);end
def self.ln_s(*args);end
def self.ln_sf(*args);end
def self.cp(*args);end
def self.copy_file(*args);end
def self.copy(*args);end
def self.cp_r(*args);end
def self.copy_entry(*args);end
def self.mv(*args);end
def self.remove_entry_secure(*args);end
def self.remove_entry(*args);end
def self.move(*args);end
def self.rm(*args);end
def self.rm_f(*args);end
def self.safe_unlink(*args);end
def self.rm_r(*args);end
def self.rm_rf(*args);end
def self.rmtree(*args);end
def self.remove_dir(*args);end
def self.compare_file(*args);end
def self.compare_stream(*args);end
def self.cmp(*args);end
def self.chmod_R(*args);end
def self.chown_R(*args);end
end
module FileUtils::DryRun
include FileUtils::LowMethods
include FileUtils
include FileUtils::StreamUtils_
def copy_stream(*args);end
def identical?(*args);end
def chmod(*args);end
def chown(*args);end
def link(*args);end
def symlink(*args);end
def chdir(*args);end
def getwd(*args);end
def pwd(*args);end
def mkdir(*args);end
def rmdir(*args);end
def mkdir_p(*args);end
def install(*args);end
def remove(*args);end
def touch(*args);end
def cd(*args);end
def uptodate?(*args);end
def mkpath(*args);end
def makedirs(*args);end
def ln(*args);end
def remove_file(*args);end
def ln_s(*args);end
def ln_sf(*args);end
def cp(*args);end
def copy_file(*args);end
def copy(*args);end
def cp_r(*args);end
def copy_entry(*args);end
def mv(*args);end
def remove_entry_secure(*args);end
def remove_entry(*args);end
def move(*args);end
def rm(*args);end
def rm_f(*args);end
def safe_unlink(*args);end
def rm_r(*args);end
def rm_rf(*args);end
def rmtree(*args);end
def remove_dir(*args);end
def compare_file(*args);end
def compare_stream(*args);end
def cmp(*args);end
def chmod_R(*args);end
def chown_R(*args);end
def sh(*args);end
def split_all(path);end
def safe_ln(*args);end
def ruby(*args);end
def self.copy_stream(*args);end
def self.identical?(*args);end
def self.chmod(*args);end
def self.chown(*args);end
def self.link(*args);end
def self.symlink(*args);end
def self.chdir(*args);end
def self.getwd(*args);end
def self.pwd(*args);end
def self.mkdir(*args);end
def self.rmdir(*args);end
def self.mkdir_p(*args);end
def self.install(*args);end
def self.remove(*args);end
def self.touch(*args);end
def self.cd(*args);end
def self.uptodate?(*args);end
def self.mkpath(*args);end
def self.makedirs(*args);end
def self.ln(*args);end
def self.remove_file(*args);end
def self.ln_s(*args);end
def self.ln_sf(*args);end
def self.cp(*args);end
def self.copy_file(*args);end
def self.copy(*args);end
def self.cp_r(*args);end
def self.copy_entry(*args);end
def self.mv(*args);end
def self.remove_entry_secure(*args);end
def self.remove_entry(*args);end
def self.move(*args);end
def self.rm(*args);end
def self.rm_f(*args);end
def self.safe_unlink(*args);end
def self.rm_r(*args);end
def self.rm_rf(*args);end
def self.rmtree(*args);end
def self.remove_dir(*args);end
def self.compare_file(*args);end
def self.compare_stream(*args);end
def self.cmp(*args);end
def self.chmod_R(*args);end
def self.chown_R(*args);end
end
module RDoc::Text
def encode_fallback(character, encoding, fallback);end
def self.encode_fallback(character, encoding, fallback);end
def parse(text, format = nil);end
def markup(text);end
def to_html(text);end
def normalize_comment(text);end
def expand_tabs(text);end
def flush_left(text);end
def strip_stars(text);end
def strip_hashes(text);end
def strip_newlines(text);end
def snippet(text, limit = nil);end
def wrap(txt, line_len = nil);end
end
class RDoc::Markdown < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.parse(markdown);end
def self.extension(name);end
def self.rule_info(name, rendered);end
def self.parse(markdown);end
def self.extension(name);end
def self.rule_info(name, rendered);end
def _HtmlBlockDd();end
def _HtmlBlockOpenDt();end
def _HtmlBlockCloseDt();end
def _HtmlBlockDt();end
def _HtmlBlockOpenFrameset();end
def parse(markdown);end
def _HtmlBlockCloseFrameset();end
def _HtmlBlockFrameset();end
def _HtmlBlockOpenLi();end
def _HtmlBlockLi();end
def _HtmlBlockOpenTbody();end
def _HtmlBlockCloseLi();end
def _HtmlBlockTbody();end
def _HtmlBlockOpenTd();end
def result();end
def _HtmlBlockCloseTd();end
def _HtmlBlockOpenUl();end
def _HtmlBlockCloseTbody();end
def _HtmlBlockTd();end
def _HtmlBlockOpenTfoot();end
def _HtmlBlockCloseTfoot();end
def _HtmlBlockTfoot();end
def _HtmlBlockOpenTh();end
def _HtmlBlockCloseTh();end
def _HtmlBlockCloseUl();end
def _HtmlBlockOpenThead();end
def _HtmlBlockCloseThead();end
def _HtmlBlockTh();end
def _HtmlBlockOpenTr();end
def _HtmlBlockCloseTr();end
def _HtmlBlockThead();end
def _HtmlBlockOpenScript();end
def _HtmlBlockCloseScript();end
def _HtmlBlockTr();end
def _HtmlBlockInTags();end
def html?();end
def _HtmlBlockScript();end
def _HtmlUnclosed();end
def _HtmlUnclosedType();end
def _HtmlBlockSelfClosing();end
def _StyleOpen();end
def _HtmlBlockType();end
def css?();end
def extension(name, enable);end
def _InStyleTags();end
def _Str();end
def _StyleClose();end
def _Space();end
def _Strong();end
def _UlOrStarLine();end
def _Emph();end
def _Image();end
def _Link();end
def _HtmlComment();end
def _Code();end
def _RawHtml();end
def _Entity();end
def _EscapedChar();end
def _Symbol();end
def _NormalChar();end
def _StrChunk();end
def _Alphanumeric();end
def _HexEntity();end
def _DecEntity();end
def _CharEntity();end
def _LineBreak();end
def _TerminalEndline();end
def _NormalEndline();end
def _Eof();end
def _SpecialChar();end
def _UlLine();end
def _StarLine();end
def _EmphStar();end
def _EmphUl();end
def _OneStarOpen();end
def _OneStarClose();end
def _OneUlOpen();end
def _OneUlClose();end
def _StrongStar();end
def _StrongUl();end
def _TwoStarOpen();end
def _TwoStarClose();end
def _TwoUlOpen();end
def _TwoUlClose();end
def _ExplicitLink();end
def _ReferenceLink();end
def _AutoLink();end
def _ReferenceLinkDouble();end
def _ReferenceLinkSingle();end
def _Label();end
def _Source();end
def _Title();end
def _SourceContents();end
def _Nonspacechar();end
def _TitleSingle();end
def _TitleDouble();end
def _AutoLinkUrl();end
def _AutoLinkEmail();end
def _RefSrc();end
def _RefTitle();end
def _RefTitleSingle();end
def _RefTitleDouble();end
def _RefTitleParens();end
def _EmptyTitle();end
def _References();end
def _SkipBlock();end
def _Ticks1();end
def _Ticks2();end
def _Ticks3();end
def _Ticks4();end
def _Ticks5();end
def _NoteReference();end
def _InlineNote();end
def get_byte();end
def _HtmlTag();end
def _Quoted();end
def _AlphanumericAscii();end
def _ExtendedSpecialChar();end
def _Digit();end
def _NonAlphanumeric();end
def _RawNoteReference();end
def _RawNoteBlock();end
def _Notes();end
def github?();end
def definition_lists?();end
def _DefinitionListItem();end
def _DefinitionListLabel();end
def setup_parser(str, debug = nil);end
def set_string(string, pos);end
def _DefinitionListDefinition();end
def setup_foreign_grammar();end
def failing_rule_offset();end
def current_column(*args);end
def current_line(*args);end
def get_text(start);end
def show_pos();end
def failure_info();end
def failure_caret();end
def failure_character();end
def failure_oneline();end
def raise_error();end
def show_error(*args);end
def set_failed_rule(name);end
def failed_rule();end
def match_string(str);end
def apply(rule);end
def _root();end
def external_invoke(other, rule, *args);end
def result=(arg0);end
def apply_with_args(rule, *args);end
def grow_lr(rule, args, start_pos, m);end
def extension?(name);end
def string();end
def emphasis(text);end
def inner_parse(text);end
def peg_parse(*args);end
def link_to(content, label = nil, text = nil);end
def list_item_from(unparsed);end
def note(label);end
def break_on_newline=(enable);end
def css=(enable);end
def note_for(ref);end
def github=(enable);end
def paragraph(parts);end
def notes=(enable);end
def break_on_newline?();end
def definition_lists=(enable);end
def notes?();end
def html=(enable);end
def reference(label, link);end
def strong(text);end
def _Doc();end
def _BOM();end
def _Block();end
def _BlankLine();end
def _BlockQuote();end
def _Verbatim();end
def _CodeFence();end
def _Note();end
def _Reference();end
def _HorizontalRule();end
def _Heading();end
def _OrderedList();end
def _BulletList();end
def _DefinitionList();end
def _HtmlBlock();end
def _StyleBlock();end
def _Para();end
def _Plain();end
def _NonindentSpace();end
def _Inlines();end
def _AtxInline();end
def _Newline();end
def _Sp();end
def _Inline();end
def _AtxStart();end
def _AtxHeading();end
def _SetextHeading();end
def _SetextHeading1();end
def _SetextHeading2();end
def lines();end
def _SetextBottom1();end
def _SetextBottom2();end
def _StartList();end
def _Endline();end
def _RawLine();end
def _BlockQuoteRaw();end
def _Line();end
def scan(reg);end
def _NonblankIndentedLine();end
def _IndentedLine();end
def _VerbatimChunk();end
def _Bullet();end
def _Spacechar();end
def _ListTight();end
def _ListLoose();end
def _ListItemTight();end
def _Enumerator();end
def _ListItem();end
def _ListBlock();end
def _ListContinuationBlock();end
def _ListBlockLine();end
def _Indent();end
def _OptionallyIndentedLine();end
def _HtmlOpenAnchor();end
def _Spnl();end
def _HtmlAttribute();end
def _HtmlCloseAnchor();end
def _HtmlAnchor();end
def _HtmlBlockOpenAddress();end
def _HtmlBlockCloseAddress();end
def _HtmlBlockAddress();end
def _HtmlBlockOpenBlockquote();end
def _HtmlBlockCloseBlockquote();end
def _HtmlBlockBlockquote();end
def _HtmlBlockOpenCenter();end
def _HtmlBlockCloseCenter();end
def _HtmlBlockCenter();end
def _HtmlBlockOpenDir();end
def _HtmlBlockCloseDir();end
def _HtmlBlockDir();end
def _HtmlBlockOpenDiv();end
def _HtmlBlockCloseDiv();end
def _HtmlBlockDiv();end
def _HtmlBlockOpenDl();end
def _HtmlBlockCloseDl();end
def _HtmlBlockDl();end
def _HtmlBlockOpenFieldset();end
def _HtmlBlockCloseFieldset();end
def _HtmlBlockFieldset();end
def _HtmlBlockOpenForm();end
def _HtmlBlockCloseForm();end
def _HtmlBlockForm();end
def _HtmlBlockOpenH1();end
def _HtmlBlockCloseH1();end
def _HtmlBlockH1();end
def _HtmlBlockOpenH2();end
def _HtmlBlockCloseH2();end
def _HtmlBlockH2();end
def _HtmlBlockOpenH3();end
def _HtmlBlockCloseH3();end
def _HtmlBlockH3();end
def _HtmlBlockOpenH4();end
def _HtmlBlockCloseH4();end
def _HtmlBlockH4();end
def _HtmlBlockOpenH5();end
def pos();end
def pos=(arg0);end
def _HtmlBlockH5();end
def _HtmlBlockCloseH5();end
def _HtmlBlockCloseH6();end
def _HtmlBlockOpenH6();end
def _HtmlBlockOpenMenu();end
def _HtmlBlockH6();end
def _HtmlBlockMenu();end
def _HtmlBlockCloseMenu();end
def _HtmlBlockCloseNoframes();end
def _HtmlBlockOpenNoframes();end
def _HtmlBlockOpenNoscript();end
def _HtmlBlockNoframes();end
def _HtmlBlockNoscript();end
def _HtmlBlockCloseNoscript();end
def _HtmlBlockCloseOl();end
def _HtmlBlockOpenOl();end
def _HtmlBlockOpenP();end
def _HtmlBlockOl();end
def _HtmlBlockP();end
def _HtmlBlockCloseP();end
def _HtmlBlockClosePre();end
def _HtmlBlockOpenPre();end
def _HtmlBlockOpenTable();end
def _HtmlBlockPre();end
def _HtmlBlockTable();end
def _HtmlBlockCloseTable();end
def _HtmlBlockUl();end
def _HtmlBlockOpenDd();end
def _HtmlBlockCloseDd();end
end
class RDoc::Markdown::ParseError < RuntimeError
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.exception(*args);end
end
class RDoc::Markdown::MemoEntry < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def result();end
def pos();end
def ans();end
def set();end
def left_rec();end
def move!(ans, pos, result);end
def left_rec=(arg0);end
end
class RDoc::Markdown::RuleInfo < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def rendered();end
end
class RDoc::Markdown::Literals < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.rule_info(name, rendered);end
def self.rule_info(name, rendered);end
def lines();end
def scan(reg);end
def result();end
def string();end
def pos();end
def pos=(arg0);end
def parse(*args);end
def get_byte();end
def setup_parser(str, debug = nil);end
def set_string(string, pos);end
def setup_foreign_grammar();end
def failing_rule_offset();end
def current_column(*args);end
def current_line(*args);end
def get_text(start);end
def show_pos();end
def failure_info();end
def failure_caret();end
def failure_character();end
def failure_oneline();end
def raise_error();end
def show_error(*args);end
def set_failed_rule(name);end
def failed_rule();end
def match_string(str);end
def apply(rule);end
def external_invoke(other, rule, *args);end
def result=(arg0);end
def apply_with_args(rule, *args);end
def grow_lr(rule, args, start_pos, m);end
def _BOM();end
def _Newline();end
def _Spacechar();end
def _Alphanumeric();end
def _AlphanumericAscii();end
def _NonAlphanumeric();end
end
class RDoc::Markdown::Literals::ParseError < RuntimeError
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.exception(*args);end
end
class RDoc::Markdown::Literals::MemoEntry < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def result();end
def pos();end
def ans();end
def set();end
def left_rec();end
def move!(ans, pos, result);end
def left_rec=(arg0);end
end
class RDoc::Markdown::Literals::RuleInfo < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def rendered();end
end
class RDoc::Markup < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.parse(str);end
def self.parse(str);end
def convert(input, formatter);end
def attribute_manager();end
def add_word_pair(start, stop, name);end
def add_html(tag, name);end
def add_special(pattern, name);end
end
class RDoc::Markup::Parser < Object
include RDoc::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.parse(str);end
def self.tokenize(str);end
def self.parse(str);end
def self.tokenize(str);end
def skip(token_type, error = nil);end
def parse(parent, indent = nil);end
def tokens();end
def debug();end
def tokenize(input);end
def build_heading(level);end
def build_verbatim(margin);end
def build_paragraph(margin);end
def get();end
def peek_token();end
def unget();end
def parse_text(parent, indent);end
def setup_scanner(input);end
def token_pos(byte_offset);end
def char_pos(byte_offset);end
def build_list(margin);end
def debug=(arg0);end
end
class RDoc::Markup::Parser::Error < RuntimeError
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.exception(*args);end
end
class RDoc::Markup::Parser::ParseError < RDoc::Markup::Parser::Error
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.exception(*args);end
end
class RDoc::Markup::PreProcess < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.reset();end
def self.post_process(&block);end
def self.post_processors();end
def self.register(directive, &block);end
def self.registered();end
def self.reset();end
def self.post_process(&block);end
def self.post_processors();end
def self.register(directive, &block);end
def self.registered();end
def options();end
def options=(arg0);end
def handle(text, code_object = nil, &block);end
def handle_directive(prefix, directive, param, code_object = nil, encoding = nil);end
def include_file(name, indent, encoding);end
def find_include_file(name);end
end
class RDoc::Markup::AttrChanger < Struct
include Enumerable
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.[](*args);end
def self.members();end
def self.[](*args);end
def self.members();end
def turn_on();end
def turn_off();end
def turn_on=(_);end
def turn_off=(_);end
end
class Process::Tms < Struct
include Enumerable
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
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
class Etc::Passwd < Struct
include Enumerable
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.[](*args);end
def self.each();end
def self.members();end
def self.to_a(*args);end
def self.to_h(*args);end
def self.find(*args);end
def self.entries(*args);end
def self.sort();end
def self.sort_by();end
def self.grep(arg0);end
def self.grep_v(arg0);end
def self.count(*args);end
def self.detect(*args);end
def self.find_index(*args);end
def self.find_all();end
def self.reject();end
def self.collect();end
def self.map();end
def self.flat_map();end
def self.collect_concat();end
def self.inject(*args);end
def self.reduce(*args);end
def self.partition();end
def self.group_by();end
def self.first(*args);end
def self.all?();end
def self.any?();end
def self.one?();end
def self.none?();end
def self.min(*args);end
def self.max(*args);end
def self.minmax();end
def self.min_by(*args);end
def self.max_by(*args);end
def self.minmax_by();end
def self.member?(arg0);end
def self.each_with_index(*args);end
def self.reverse_each(*args);end
def self.each_entry(*args);end
def self.each_slice(arg0);end
def self.each_cons(arg0);end
def self.each_with_object(arg0);end
def self.zip(*args);end
def self.take(arg0);end
def self.take_while();end
def self.drop(arg0);end
def self.drop_while();end
def self.cycle(*args);end
def self.chunk();end
def self.slice_before(*args);end
def self.slice_after(*args);end
def self.slice_when();end
def self.chunk_while();end
def self.lazy();end
def self.to_set(*args);end
def self.[](*args);end
def self.each();end
def self.members();end
def uid();end
def gid();end
def name=(_);end
def uid=(_);end
def gid=(_);end
def dir();end
def passwd();end
def gecos();end
def shell();end
def passwd=(_);end
def gecos=(_);end
def dir=(_);end
def shell=(_);end
end
class Etc::Group < Struct
include Enumerable
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.[](*args);end
def self.each();end
def self.members();end
def self.to_a(*args);end
def self.to_h(*args);end
def self.find(*args);end
def self.entries(*args);end
def self.sort();end
def self.sort_by();end
def self.grep(arg0);end
def self.grep_v(arg0);end
def self.count(*args);end
def self.detect(*args);end
def self.find_index(*args);end
def self.find_all();end
def self.reject();end
def self.collect();end
def self.map();end
def self.flat_map();end
def self.collect_concat();end
def self.inject(*args);end
def self.reduce(*args);end
def self.partition();end
def self.group_by();end
def self.first(*args);end
def self.all?();end
def self.any?();end
def self.one?();end
def self.none?();end
def self.min(*args);end
def self.max(*args);end
def self.minmax();end
def self.min_by(*args);end
def self.max_by(*args);end
def self.minmax_by();end
def self.member?(arg0);end
def self.each_with_index(*args);end
def self.reverse_each(*args);end
def self.each_entry(*args);end
def self.each_slice(arg0);end
def self.each_cons(arg0);end
def self.each_with_object(arg0);end
def self.zip(*args);end
def self.take(arg0);end
def self.take_while();end
def self.drop(arg0);end
def self.drop_while();end
def self.cycle(*args);end
def self.chunk();end
def self.slice_before(*args);end
def self.slice_after(*args);end
def self.slice_when();end
def self.chunk_while();end
def self.lazy();end
def self.to_set(*args);end
def self.[](*args);end
def self.each();end
def self.members();end
def gid();end
def name=(_);end
def gid=(_);end
def passwd();end
def passwd=(_);end
def mem();end
def mem=(_);end
end
class RDoc::Markup::AttrSpan < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def [](n);end
def set_attrs(start, length, bits);end
end
class RDoc::Markup::Attributes < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def bitmap_for(name);end
def special();end
def each_name_of(bitmap);end
def as_string(bitmap);end
end
class RDoc::Markup::AttributeManager < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def attributes();end
def attribute(turn_on, turn_off);end
def add_word_pair(start, stop, name);end
def add_html(tag, name);end
def add_special(pattern, name);end
def flow(str);end
def special();end
def matching_word_pairs();end
def word_pair_map();end
def html_tags();end
def protectable();end
def change_attribute(current, new);end
def changed_attribute_by_name(current_set, new_set);end
def copy_string(start_pos, end_pos);end
def convert_attrs(str, attrs);end
def convert_html(str, attrs);end
def convert_specials(str, attrs);end
def mask_protected_sequences();end
def unmask_protected_sequences();end
def split_into_flow();end
def display_attributes();end
end
class RDoc::Markup::Special < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def text();end
def type();end
def text=(arg0);end
end
class RDoc::Markup::BlankLine < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def accept(visitor);end
end
class RDoc::Markup::BlockQuote < RDoc::Markup::Raw
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def accept(visitor);end
end
class RDoc::Markup::Document < Object
include Enumerable
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def <<(part);end
def empty?();end
def each(&block);end
def concat(parts);end
def push(*args);end
def merge(other);end
def file();end
def parts();end
def accept(visitor);end
def file=(location);end
def omit_headings_below();end
def omit_headings_below=(arg0);end
def merged?();end
def table_of_contents();end
end
class RDoc::Markup::HardBreak < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def accept(visitor);end
end
class RDoc::Markup::Heading < Struct
include Enumerable
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.[](*args);end
def self.members();end
def self.to_html();end
def self.to_label();end
def self.[](*args);end
def self.members();end
def self.to_html();end
def self.to_label();end
def text();end
def label(*args);end
def accept(visitor);end
def text=(_);end
def level();end
def aref();end
def plain_html();end
def level=(_);end
end
class RDoc::Markup::Include < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def file();end
def include_path();end
end
class RDoc::Markup::IndentedParagraph < RDoc::Markup::Raw
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def text(*args);end
def accept(visitor);end
def indent();end
end
class RDoc::Markup::List < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def <<(item);end
def empty?();end
def last();end
def push(*args);end
def type();end
def accept(visitor);end
def type=(arg0);end
def items();end
end
class RDoc::Markup::ListItem < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def <<(part);end
def empty?();end
def length();end
def push(*args);end
def label();end
def parts();end
def accept(visitor);end
def label=(arg0);end
end
class RDoc::Markup::Paragraph < RDoc::Markup::Raw
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def text(*args);end
def accept(visitor);end
end
class RDoc::Markup::Raw < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def <<(text);end
def push(*args);end
def merge(other);end
def text();end
def parts();end
def accept(visitor);end
end
class RDoc::Markup::Rule < #<Class:0x007f88f2dbffb0>
include Enumerable
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.[](*args);end
def self.members();end
def accept(visitor);end
end
class RDoc::Markup::Verbatim < RDoc::Markup::Raw
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def text();end
def normalize();end
def accept(visitor);end
def format=(arg0);end
def ruby?();end
end
class RDoc::Markup::Formatter < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.gen_relative_url(path, target);end
def self.gen_relative_url(path, target);end
def convert(content);end
def ignore(*args);end
def accept_document(document);end
def add_special_RDOCLINK();end
def add_special_TIDYLINK();end
def add_tag(name, start, stop);end
def annotate(tag);end
def convert_flow(flow);end
def convert_string(string);end
def off_tags(res, item);end
def on_tags(res, item);end
def convert_special(special);end
def in_tt?();end
def tt?(tag);end
def parse_url(url);end
end
class RDoc::Markup::Formatter::InlineTag < Struct
include Enumerable
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.[](*args);end
def self.members();end
def self.[](*args);end
def self.members();end
def off();end
def bit();end
def on();end
def bit=(_);end
def on=(_);end
def off=(_);end
end
class RDoc::Markup::FormatterTestCase < RDoc::TestCase
include Minitest::Guard
include Minitest::Test::LifecycleHooks
include Minitest::Assertions
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.add_visitor_tests();end
def self.inherited(klass);end
def self.runnable_methods();end
def self.test_order();end
def self.io_lock();end
def self.io_lock=(arg0);end
def self.i_suck_and_my_tests_are_order_dependent!();end
def self.make_my_diffs_pretty!();end
def self.parallelize_me!();end
def self.jruby?(*args);end
def self.maglev?(*args);end
def self.mri?(*args);end
def self.rubinius?(*args);end
def self.windows?(*args);end
def self.run(reporter, options = nil);end
def self.reset();end
def self.methods_matching(re);end
def self.runnables();end
def self.with_info_handler(reporter, &block);end
def self.run_one_method(klass, method_name, reporter);end
def self.on_signal(name, action);end
def self.add_visitor_tests();end
def setup();end
end
class RDoc::Markup::TextFormatterTestCase < RDoc::Markup::FormatterTestCase
include Minitest::Guard
include Minitest::Test::LifecycleHooks
include Minitest::Assertions
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.add_text_tests();end
def self.add_visitor_tests();end
def self.inherited(klass);end
def self.runnable_methods();end
def self.test_order();end
def self.io_lock();end
def self.io_lock=(arg0);end
def self.i_suck_and_my_tests_are_order_dependent!();end
def self.make_my_diffs_pretty!();end
def self.parallelize_me!();end
def self.jruby?(*args);end
def self.maglev?(*args);end
def self.mri?(*args);end
def self.rubinius?(*args);end
def self.windows?(*args);end
def self.run(reporter, options = nil);end
def self.reset();end
def self.methods_matching(re);end
def self.runnables();end
def self.with_info_handler(reporter, &block);end
def self.run_one_method(klass, method_name, reporter);end
def self.on_signal(name, action);end
def self.add_text_tests();end
end
class RDoc::Markup::ToAnsi < RDoc::Markup::ToRdoc
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.gen_relative_url(path, target);end
def start_accepting();end
def accept_list_item_end(list_item);end
def accept_list_item_start(list_item);end
def init_tags();end
end
class RDoc::Markup::ToBs < RDoc::Markup::ToRdoc
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.gen_relative_url(path, target);end
def accept_heading(heading);end
def annotate(tag);end
def convert_string(string);end
def convert_special(special);end
def init_tags();end
end
class RDoc::Markup::ToHtml < RDoc::Markup::Formatter
include RDoc::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.gen_relative_url(path, target);end
def list();end
def from_path();end
def code_object();end
def code_object=(arg0);end
def res();end
def to_html(item);end
def start_accepting();end
def end_accepting();end
def accept_paragraph(paragraph);end
def accept_block_quote(block_quote);end
def accept_heading(heading);end
def accept_list_end(list);end
def accept_list_item_end(list_item);end
def accept_list_item_start(list_item);end
def accept_list_start(list);end
def accept_raw(raw);end
def accept_rule(rule);end
def accept_verbatim(verbatim);end
def convert_string(text);end
def accept_blank_line(blank_line);end
def init_tags();end
def handle_special_HARD_BREAK(special);end
def in_list_entry();end
def handle_RDOCLINK(url);end
def gen_url(url, text);end
def handle_special_HYPERLINK(special);end
def handle_special_RDOCLINK(special);end
def handle_special_TIDYLINK(special);end
def parseable?(text);end
def html_list_name(list_type, open_tag);end
def list_item_start(list_item, list_type);end
def list_end_for(list_type);end
def from_path=(arg0);end
end
class RDoc::Markup::ToHtmlCrossref < RDoc::Markup::ToHtml
include RDoc::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.gen_relative_url(path, target);end
def link(name, text);end
def context();end
def show_hash();end
def show_hash=(arg0);end
def handle_special_CROSSREF(special);end
def gen_url(url, text);end
def handle_special_HYPERLINK(special);end
def handle_special_RDOCLINK(special);end
def cross_reference(name, text = nil);end
def context=(arg0);end
end
class RDoc::Markup::ToHtmlSnippet < RDoc::Markup::ToHtml
include RDoc::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.gen_relative_url(path, target);end
def truncate(text);end
def convert(content);end
def mask();end
def start_accepting();end
def accept_paragraph(paragraph);end
def accept_heading(heading);end
def accept_list_item_end(list_item);end
def accept_list_item_start(list_item);end
def accept_list_start(list);end
def accept_raw(*args);end
def accept_rule(*args);end
def accept_verbatim(verbatim);end
def convert_flow(flow);end
def off_tags(res, item);end
def on_tags(res, item);end
def handle_special_CROSSREF(special);end
def handle_special_HARD_BREAK(special);end
def gen_url(url, text);end
def html_list_name(list_type, open_tag);end
def list_item_start(list_item, list_type);end
def character_limit();end
def characters();end
def paragraph_limit();end
def paragraphs();end
def add_paragraph();end
end
class RDoc::Markup::ToLabel < RDoc::Markup::Formatter
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.gen_relative_url(path, target);end
def convert(text);end
def res();end
def start_accepting(*args);end
def end_accepting(*args);end
def accept_paragraph(*args);end
def accept_block_quote(*args);end
def accept_heading(*args);end
def accept_list_end(*args);end
def accept_list_item_end(*args);end
def accept_list_item_start(*args);end
def accept_list_start(*args);end
def accept_raw(*args);end
def accept_rule(*args);end
def accept_verbatim(*args);end
def accept_blank_line(*args);end
def handle_special_CROSSREF(special);end
def handle_special_HARD_BREAK(*args);end
def handle_special_TIDYLINK(special);end
end
class RDoc::Markup::ToMarkdown < RDoc::Markup::ToRdoc
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.gen_relative_url(path, target);end
def accept_list_end(list);end
def accept_list_item_end(list_item);end
def accept_list_item_start(list_item);end
def accept_list_start(list);end
def accept_rule(rule);end
def accept_verbatim(verbatim);end
def init_tags();end
def handle_special_HARD_BREAK(special);end
def gen_url(url, text);end
def handle_special_RDOCLINK(special);end
def handle_special_TIDYLINK(special);end
def handle_rdoc_link(url);end
end
class RDoc::Markup::ToRdoc < RDoc::Markup::Formatter
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.gen_relative_url(path, target);end
def prefix();end
def width();end
def attributes(text);end
def res();end
def indent();end
def wrap(text);end
def start_accepting();end
def end_accepting();end
def accept_paragraph(paragraph);end
def accept_block_quote(block_quote);end
def accept_heading(heading);end
def accept_list_end(list);end
def accept_list_item_end(list_item);end
def accept_list_item_start(list_item);end
def accept_list_start(list);end
def accept_raw(raw);end
def accept_rule(rule);end
def accept_verbatim(verbatim);end
def list_type();end
def indent=(arg0);end
def accept_blank_line(blank_line);end
def accept_indented_paragraph(paragraph);end
def init_tags();end
def list_index();end
def list_width();end
def use_prefix();end
def handle_special_SUPPRESSED_CROSSREF(special);end
def handle_special_HARD_BREAK(special);end
def width=(arg0);end
end
class RDoc::Markup::ToTableOfContents < RDoc::Markup::Formatter
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.to_toc();end
def self.gen_relative_url(path, target);end
def self.to_toc();end
def res();end
def suppressed?(heading);end
def start_accepting();end
def end_accepting();end
def accept_paragraph(*args);end
def accept_block_quote(*args);end
def accept_heading(heading);end
def accept_list_end(*args);end
def accept_list_item_end(*args);end
def accept_list_item_start(*args);end
def accept_list_start(*args);end
def accept_raw(*args);end
def accept_rule(*args);end
def accept_verbatim(*args);end
def accept_document(document);end
def omit_headings_below();end
def omit_headings_below=(arg0);end
def accept_blank_line(*args);end
def accept_list_end_bullet(*args);end
end
class RDoc::Markup::ToTest < RDoc::Markup::Formatter
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.gen_relative_url(path, target);end
def start_accepting();end
def end_accepting();end
def accept_paragraph(paragraph);end
def accept_heading(heading);end
def accept_list_end(list);end
def accept_list_item_end(list_item);end
def accept_list_item_start(list_item);end
def accept_list_start(list);end
def accept_raw(raw);end
def accept_rule(rule);end
def accept_verbatim(verbatim);end
def accept_blank_line(blank_line);end
end
class RDoc::Markup::ToTtOnly < RDoc::Markup::Formatter
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.gen_relative_url(path, target);end
def res();end
def start_accepting();end
def end_accepting();end
def accept_paragraph(paragraph);end
def accept_block_quote(block_quote);end
def accept_heading(markup_item);end
def accept_list_end(list);end
def accept_list_item_end(markup_item);end
def accept_list_item_start(list_item);end
def accept_list_start(list);end
def accept_raw(markup_item);end
def accept_rule(markup_item);end
def accept_verbatim(markup_item);end
def list_type();end
def accept_blank_line(markup_item);end
def tt_sections(text);end
def do_nothing(markup_item);end
end
class RDoc::Markup::ToJoinedParagraph < RDoc::Markup::Formatter
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.gen_relative_url(path, target);end
def start_accepting();end
def end_accepting();end
def accept_paragraph(paragraph);end
def accept_block_quote(*args);end
def accept_heading(*args);end
def accept_list_end(*args);end
def accept_list_item_end(*args);end
def accept_list_item_start(*args);end
def accept_list_start(*args);end
def accept_raw(*args);end
def accept_rule(*args);end
def accept_verbatim(*args);end
end
class RDoc::RD < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.parse(rd);end
def self.parse(rd);end
end
class RDoc::RD::BlockParser < Racc::Parser
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.racc_runtime_type();end
def _reduce_14(val, _values, result);end
def _reduce_15(val, _values, result);end
def _reduce_16(val, _values, result);end
def _reduce_17(val, _values, result);end
def _reduce_18(val, _values, result);end
def parse(src);end
def _reduce_19(val, _values, result);end
def _reduce_21(val, _values, result);end
def _reduce_22(val, _values, result);end
def _reduce_27(val, _values, result);end
def _reduce_28(val, _values, result);end
def _reduce_29(val, _values, result);end
def _reduce_20(val, _values, result);end
def _reduce_30(val, _values, result);end
def labels();end
def _reduce_32(val, _values, result);end
def _reduce_31(val, _values, result);end
def _reduce_34(val, _values, result);end
def _reduce_33(val, _values, result);end
def _reduce_36(val, _values, result);end
def _reduce_35(val, _values, result);end
def _reduce_38(val, _values, result);end
def _reduce_37(val, _values, result);end
def _reduce_40(val, _values, result);end
def _reduce_39(val, _values, result);end
def _reduce_42(val, _values, result);end
def _reduce_41(val, _values, result);end
def _reduce_44(val, _values, result);end
def _reduce_43(val, _values, result);end
def _reduce_46(val, _values, result);end
def _reduce_45(val, _values, result);end
def _reduce_48(val, _values, result);end
def _reduce_47(val, _values, result);end
def _reduce_50(val, _values, result);end
def _reduce_49(val, _values, result);end
def content(values);end
def _reduce_51(val, _values, result);end
def _reduce_52(val, _values, result);end
def _reduce_54(val, _values, result);end
def _reduce_55(val, _values, result);end
def include_path=(arg0);end
def _reduce_62(val, _values, result);end
def _reduce_63(val, _values, result);end
def _reduce_57(val, _values, result);end
def _reduce_65(val, _values, result);end
def _reduce_66(val, _values, result);end
def _reduce_64(val, _values, result);end
def include_path();end
def _reduce_69(val, _values, result);end
def _reduce_67(val, _values, result);end
def _reduce_68(val, _values, result);end
def _reduce_71(val, _values, result);end
def _reduce_72(val, _values, result);end
def footnotes();end
def next_token();end
def on_error(et, ev, _values);end
def paragraph(value);end
def line_index();end
def add_footnote(content);end
def add_label(label);end
def _reduce_1(val, _values, result);end
def _reduce_2(val, _values, result);end
def _reduce_3(val, _values, result);end
def _reduce_4(val, _values, result);end
def _reduce_5(val, _values, result);end
def _reduce_6(val, _values, result);end
def _reduce_none(val, _values, result);end
def _reduce_8(val, _values, result);end
def _reduce_9(val, _values, result);end
def _reduce_10(val, _values, result);end
def _reduce_11(val, _values, result);end
def _reduce_12(val, _values, result);end
def _reduce_13(val, _values, result);end
end
class RDoc::RD::InlineParser < Racc::Parser
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.racc_runtime_type();end
def parse(inline);end
def inline(rdoc, reference = nil);end
def next_token();end
def on_error(et, ev, values);end
def _reduce_2(val, _values, result);end
def _reduce_3(val, _values, result);end
def _reduce_none(val, _values, result);end
def _reduce_13(val, _values, result);end
def _reduce_14(val, _values, result);end
def _reduce_15(val, _values, result);end
def _reduce_16(val, _values, result);end
def _reduce_17(val, _values, result);end
def _reduce_18(val, _values, result);end
def _reduce_19(val, _values, result);end
def _reduce_20(val, _values, result);end
def _reduce_21(val, _values, result);end
def _reduce_22(val, _values, result);end
def _reduce_27(val, _values, result);end
def _reduce_29(val, _values, result);end
def _reduce_30(val, _values, result);end
def _reduce_31(val, _values, result);end
def _reduce_32(val, _values, result);end
def _reduce_33(val, _values, result);end
def _reduce_34(val, _values, result);end
def _reduce_36(val, _values, result);end
def _reduce_37(val, _values, result);end
def _reduce_38(val, _values, result);end
def _reduce_39(val, _values, result);end
def _reduce_40(val, _values, result);end
def _reduce_41(val, _values, result);end
def _reduce_43(val, _values, result);end
def _reduce_44(val, _values, result);end
def _reduce_45(val, _values, result);end
def _reduce_46(val, _values, result);end
def _reduce_57(val, _values, result);end
def _reduce_62(val, _values, result);end
def _reduce_64(val, _values, result);end
def prev_words_on_error(ev);end
def next_words_on_error();end
def _reduce_23(val, _values, result);end
def _reduce_24(val, _values, result);end
def _reduce_25(val, _values, result);end
def _reduce_26(val, _values, result);end
def _reduce_58(val, _values, result);end
def _reduce_59(val, _values, result);end
def _reduce_60(val, _values, result);end
def _reduce_78(val, _values, result);end
def _reduce_101(val, _values, result);end
def _reduce_102(val, _values, result);end
def _reduce_109(val, _values, result);end
def _reduce_111(val, _values, result);end
def _reduce_113(val, _values, result);end
def _reduce_114(val, _values, result);end
def _reduce_115(val, _values, result);end
def _reduce_136(val, _values, result);end
end
class RDoc::RD::Inline < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def rdoc();end
def reference();end
def append(more);end
end
class RDoc::TomDoc < RDoc::Markup::Parser
include RDoc::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.parse(text);end
def self.add_post_processor();end
def self.signature(comment);end
def self.tokenize(str);end
def self.parse(text);end
def self.add_post_processor();end
def self.signature(comment);end
def tokens();end
def tokenize(text);end
def build_heading(level);end
def build_verbatim(margin);end
def build_paragraph(margin);end
def parse_text(parent, indent);end
end
class RDoc::RubyLex < Object
include IRB
include RDoc::RubyToken
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.included(mod);end
def self.debug_level();end
def self.tokenize(ruby, options);end
def self.debug?();end
def self.debug_level=(arg0);end
def self.bind(cl);end
def self.def_exception(n, m, s = nil);end
def self.Raise(*args);end
def self.Fail(*args);end
def self.def_e2message(c, m);end
def self.included(mod);end
def self.debug_level();end
def self.tokenize(ruby, options);end
def self.debug?();end
def self.debug_level=(arg0);end
def getc();end
def ungetc(*args);end
def seek();end
def eof?();end
def peek(*args);end
def token();end
def indent();end
def line_no();end
def continue();end
def exception_on_syntax_error();end
def exception_on_syntax_error=(arg0);end
def lex_state();end
def char_no();end
def lex_state=(arg0);end
def continue=(arg0);end
def get_readed();end
def reader();end
def lex_init();end
def set_input(io, p = nil, &block);end
def skip_space();end
def readed_auto_clean_up();end
def getc_of_rests();end
def peek_equal?(str);end
def peek_match?(regexp);end
def prompt();end
def set_prompt(*args);end
def initialize_input();end
def each_top_level_statement();end
def lex();end
def identify_comment();end
def identify_here_document();end
def identify_string(ltype, quoted = nil, type = nil);end
def identify_number(*args);end
def lex_int2();end
def identify_quotation();end
def identify_gvar();end
def identify_identifier();end
def skip_inner_expression();end
def read_escape();end
def Raise(*args);end
def Fail(*args);end
def skip_space=(arg0);end
def readed_auto_clean_up=(arg0);end
end
class RDoc::RubyLex::Error < RDoc::Error
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.exception(*args);end
end
class RDoc::RubyLex::AlreadyDefinedToken < StandardError
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.exception(*args);end
end
class RDoc::RubyLex::TkReading2TokenNoKey < StandardError
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.exception(*args);end
end
class RDoc::RubyLex::TkSymbol2TokenNoKey < StandardError
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.exception(*args);end
end
class RDoc::RubyLex::TkReading2TokenDuplicateError < StandardError
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.exception(*args);end
end
class RDoc::RubyLex::SyntaxError < StandardError
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.exception(*args);end
end
class RDoc::RubyLex::TerminateLineInput < StandardError
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.exception(*args);end
end
class IRB::OutputMethod < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.included(mod);end
def self.bind(cl);end
def self.def_exception(n, m, s = nil);end
def self.Raise(*args);end
def self.Fail(*args);end
def self.def_e2message(c, m);end
def self.included(mod);end
def Raise(*args);end
def Fail(*args);end
def printn(*args);end
def ppx(prefix, *objs);end
def parse_printf_format(format, opts);end
end
class IRB::OutputMethod::NotImplementedError < StandardError
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.exception(*args);end
end
class IRB::StdioOutputMethod < IRB::OutputMethod
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.included(mod);end
def self.bind(cl);end
def self.def_exception(n, m, s = nil);end
def self.Raise(*args);end
def self.Fail(*args);end
def self.def_e2message(c, m);end
end
module IRB::Notifier
def included(mod);end
def def_notifier(*args);end
def bind(cl);end
def def_exception(n, m, s = nil);end
def Raise(*args);end
def Fail(*args);end
def def_e2message(c, m);end
def self.included(mod);end
def self.def_notifier(*args);end
def Raise(*args);end
def Fail(*args);end
end
class IRB::Notifier::ErrUndefinedNotifier < StandardError
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.exception(*args);end
end
class IRB::Notifier::ErrUnrecognizedLevel < StandardError
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.exception(*args);end
end
class IRB::Notifier::AbstractNotifier < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def prefix();end
def exec_if();end
def notify?();end
def printn(*args);end
def ppx(prefix, *objs);end
end
class IRB::Notifier::CompositeNotifier < IRB::Notifier::AbstractNotifier
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def level();end
def level=(value);end
def def_notifier(level, prefix = nil);end
def notifiers();end
def level_notifier();end
def level_notifier=(value);end
end
class IRB::Notifier::LeveledNotifier < IRB::Notifier::AbstractNotifier
include Comparable
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def level();end
def notify?();end
end
class IRB::Notifier::NoMsgNotifier < IRB::Notifier::LeveledNotifier
include Comparable
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def notify?();end
end
class IRB::SLex < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.included(mod);end
def self.bind(cl);end
def self.def_exception(n, m, s = nil);end
def self.Raise(*args);end
def self.Fail(*args);end
def self.def_e2message(c, m);end
def self.included(mod);end
def match(token);end
def create(token, preproc = nil, postproc = nil);end
def search(token);end
def def_rules(*args);end
def def_rule(token, preproc = nil, postproc = nil, &block);end
def Raise(*args);end
def Fail(*args);end
def preproc(token, proc);end
def postproc(token);end
end
class IRB::SLex::ErrNodeNothing < StandardError
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.exception(*args);end
end
class IRB::SLex::ErrNodeAlreadyExists < StandardError
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.exception(*args);end
end
class IRB::SLex::Node < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def match(chrs, op = nil);end
def search(chrs, opt = nil);end
def preproc();end
def postproc();end
def preproc=(arg0);end
def postproc=(arg0);end
def create_subnode(chrs, preproc = nil, postproc = nil);end
def match_io(io, op = nil);end
end
module RDoc::RubyToken
def def_token(token_n, super_token = nil, reading = nil, *opts);end
def self.def_token(token_n, super_token = nil, reading = nil, *opts);end
def Token(token, value = nil);end
def set_token_position(line, char);end
end
module RDoc::TokenStream
def to_html(token_stream);end
def self.to_html(token_stream);end
def start_collecting_tokens();end
def add_token(*args);end
def add_tokens(*args);end
def token_stream();end
def collect_tokens();end
def pop_token();end
def tokens_to_s();end
end
class RDoc::Comment < Object
include RDoc::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def empty?();end
def force_encoding(encoding);end
def text();end
def file();end
def normalize();end
def normalized?();end
def parse();end
def location=(arg0);end
def format=(format);end
def text=(text);end
def tomdoc?();end
def location();end
def remove_private();end
def extract_call_seq(method);end
def document=(arg0);end
end
module RDoc::I18n
end
class RDoc::I18n::Locale < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.[](locale_name);end
def self.[]=(locale_name, locale);end
def self.[](locale_name);end
def self.[]=(locale_name, locale);end
def translate(message);end
end
class RDoc::I18n::Text < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def translate(locale);end
def extract_messages();end
end
class RDoc::CodeObject < Object
include RDoc::Generator::Markup
include RDoc::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def store();end
def options();end
def offset();end
def file();end
def metadata();end
def file_name();end
def line();end
def store=(store);end
def done_documenting();end
def done_documenting=(value);end
def parent();end
def display?();end
def comment();end
def document_children();end
def document_self();end
def force_documentation();end
def received_nodoc();end
def section();end
def viewer();end
def initialize_visibility();end
def comment=(comment);end
def documented?();end
def document_children=(document_children);end
def document_self=(document_self);end
def each_parent();end
def force_documentation=(value);end
def full_name=(full_name);end
def ignore();end
def stop_doc();end
def ignored?();end
def parent_file_name();end
def parent_name();end
def record_location(top_level);end
def start_doc();end
def suppress();end
def suppressed?();end
def line=(arg0);end
def offset=(arg0);end
def parent=(arg0);end
def section=(arg0);end
def viewer=(arg0);end
end
class RDoc::Context < RDoc::CodeObject
include Comparable
include RDoc::Generator::Markup
include RDoc::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def unmatched_alias_lists=(arg0);end
def classes_hash();end
def modules();end
def method_list();end
def remove_invisible(min_visibility);end
def each_ancestor();end
def find_local_symbol(symbol);end
def methods_by_type(*args);end
def initialize_methods_etc();end
def add_attribute(attribute);end
def add_constant(constant);end
def add_include(include);end
def add_method(method);end
def add_extend(ext);end
def aliases();end
def sections_hash();end
def http_url(prefix);end
def name_for_path();end
def classes_and_modules();end
def requires();end
def find_method(name, singleton);end
def find_attribute(name, singleton);end
def add_to(array, thing);end
def resolve_aliases(added);end
def add_class(class_type, given_name, superclass = nil);end
def child_name(name);end
def add_module(class_type, name);end
def find_module_named(name);end
def upgrade_to_class(mod, class_type, enclosing);end
def add_class_or_module(mod, self_hash, all_hash);end
def temporary_section();end
def temporary_section=(arg0);end
def add_module_alias(from, name, file);end
def full_name();end
def add_require(require);end
def any_content(*args);end
def attributes();end
def class_attributes();end
def class_method_list();end
def defined_in?(file);end
def each_attribute();end
def each_classmodule(&block);end
def each_constant();end
def each_include();end
def each_extend();end
def each_method();end
def each_section();end
def add(klass, name, comment);end
def find_class_method_named(name);end
def find_constant_named(name);end
def find_enclosing_module_named(name);end
def find_external_alias(name, singleton);end
def find_external_alias_named(name);end
def find_file_named(name);end
def find_instance_method_named(name);end
def find_symbol(symbol);end
def find_symbol_module(symbol);end
def instance_attributes();end
def instance_method_list();end
def sort_sections();end
def methods_matching(methods, singleton = nil, &block);end
def ongoing_visibility=(visibility);end
def remove_from_documentation?();end
def remove_invisible_in(array, min_visibility);end
def section_contents();end
def set_current_section(title, comment);end
def set_visibility_for(methods, visibility, singleton = nil);end
def top_level();end
def params();end
def params=(arg0);end
def block_params();end
def block_params=(arg0);end
def visibility();end
def classes();end
def fully_documented?();end
def modules_hash();end
def find_method_named(name);end
def find_attribute_named(name);end
def add_alias(an_alias);end
def record_location(top_level);end
def add_section(title, comment = nil);end
def visibility=(arg0);end
def external_aliases();end
def includes();end
def extends();end
def methods_hash();end
def constants_hash();end
def current_section();end
def current_section=(arg0);end
def in_files();end
def sections();end
def unmatched_alias_lists();end
end
class RDoc::Context::Section < Object
include RDoc::Generator::Markup
include RDoc::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def marshal_dump();end
def marshal_load(array);end
def parse();end
def title();end
def parent();end
def comment();end
def aref();end
def add_comment(comment);end
def in_files();end
def comments();end
def remove_comment(comment);end
def extract_comment(comment);end
def plain_html();end
def sequence();end
end
class RDoc::TopLevel < RDoc::Context
include Comparable
include RDoc::Generator::Markup
include RDoc::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def path();end
def marshal_dump();end
def marshal_load(array);end
def full_name();end
def parser();end
def last_modified();end
def classes_or_modules();end
def display?();end
def text?();end
def page_name();end
def base_name();end
def cvs_url();end
def absolute_name();end
def find_class_or_module(name);end
def add_alias(an_alias);end
def search_record();end
def diagram();end
def find_local_symbol(symbol);end
def relative_name();end
def add_constant(constant);end
def add_include(include);end
def add_method(method);end
def http_url(prefix);end
def find_module_named(name);end
def diagram=(arg0);end
def file_stat();end
def object_class();end
def add_to_classes_or_modules(mod);end
def file_stat=(arg0);end
def relative_name=(arg0);end
def absolute_name=(arg0);end
def parser=(arg0);end
end
class RDoc::AnonClass < RDoc::ClassModule
include Comparable
include RDoc::Generator::Markup
include RDoc::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.from_module(class_type, mod);end
end
class RDoc::ClassModule < RDoc::Context
include Comparable
include RDoc::Generator::Markup
include RDoc::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.from_module(class_type, mod);end
def self.from_module(class_type, mod);end
def path();end
def merge(class_module);end
def marshal_dump();end
def marshal_load(array);end
def name=(new_name);end
def full_name();end
def description();end
def type();end
def parse(comment_location);end
def store=(store);end
def complete(min_visibility);end
def comment=(comment);end
def documented?();end
def is_alias_for();end
def aref();end
def aref_prefix();end
def search_record();end
def is_alias_for=(arg0);end
def constant_aliases();end
def comment_location();end
def diagram();end
def add_comment(comment, location);end
def add_things(my_things, other_things);end
def direct_ancestors();end
def clear_comment();end
def update_aliases();end
def remove_nodoc_children();end
def update_includes();end
def document_self_or_methods();end
def each_ancestor();end
def find_ancestor_local_symbol(symbol);end
def find_class_named(name);end
def merge_collections(mine, other, other_files, &block);end
def merge_sections(cm);end
def remove_things(my_things, other_files);end
def module?();end
def name_for_path();end
def non_aliases();end
def superclass=(superclass);end
def update_extends();end
def constant_aliases=(arg0);end
def comment_location=(arg0);end
def diagram=(arg0);end
end
class RDoc::NormalClass < RDoc::ClassModule
include Comparable
include RDoc::Generator::Markup
include RDoc::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.from_module(class_type, mod);end
def aref_prefix();end
def direct_ancestors();end
def definition();end
end
class RDoc::NormalModule < RDoc::ClassModule
include Comparable
include RDoc::Generator::Markup
include RDoc::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.from_module(class_type, mod);end
def aref_prefix();end
def module?();end
def definition();end
end
class RDoc::SingleClass < RDoc::ClassModule
include Comparable
include RDoc::Generator::Markup
include RDoc::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.from_module(class_type, mod);end
def aref_prefix();end
def definition();end
end
class RDoc::Alias < RDoc::CodeObject
include RDoc::Generator::Markup
include RDoc::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def text();end
def singleton();end
def aref();end
def html_name();end
def pretty_name();end
def name_prefix();end
def singleton=(arg0);end
def new_name();end
def old_name();end
def pretty_old_name();end
def full_old_name();end
def pretty_new_name();end
end
class RDoc::AnyMethod < RDoc::MethodAttr
include RDoc::TokenStream
include Comparable
include RDoc::Generator::Markup
include RDoc::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.add_line_numbers();end
def self.add_line_numbers=(arg0);end
def marshal_dump();end
def marshal_load(array);end
def store=(store);end
def params();end
def params=(arg0);end
def dont_rename_initialize();end
def dont_rename_initialize=(arg0);end
def is_alias_for();end
def call_seq();end
def arglists();end
def param_seq();end
def add_alias(an_alias, context = nil);end
def aref_prefix();end
def call_seq=(call_seq);end
def c_function();end
def c_function=(arg0);end
def calls_super();end
def calls_super=(arg0);end
def superclass_method();end
def param_list();end
end
class RDoc::MethodAttr < RDoc::CodeObject
include Comparable
include RDoc::Generator::Markup
include RDoc::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.add_line_numbers();end
def self.add_line_numbers=(arg0);end
def self.add_line_numbers();end
def self.add_line_numbers=(arg0);end
def aliases();end
def path();end
def text();end
def name=(arg0);end
def full_name();end
def type();end
def store=(store);end
def visibility();end
def add_line_numbers(src);end
def markup_code();end
def initialize_visibility();end
def documented?();end
def parent_name();end
def params();end
def params=(arg0);end
def block_params();end
def block_params=(value);end
def singleton();end
def is_alias_for();end
def call_seq();end
def arglists();end
def param_seq();end
def see();end
def find_see();end
def find_method_or_attribute(name);end
def add_alias(an_alias, context);end
def aref();end
def aref_prefix();end
def html_name();end
def pretty_name();end
def name_prefix();end
def output_name(context);end
def search_record();end
def visibility=(arg0);end
def singleton=(arg0);end
def is_alias_for=(arg0);end
def call_seq=(arg0);end
end
class RDoc::GhostMethod < RDoc::AnyMethod
include RDoc::TokenStream
include Comparable
include RDoc::Generator::Markup
include RDoc::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.add_line_numbers();end
def self.add_line_numbers=(arg0);end
end
class RDoc::MetaMethod < RDoc::AnyMethod
include RDoc::TokenStream
include Comparable
include RDoc::Generator::Markup
include RDoc::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.add_line_numbers();end
def self.add_line_numbers=(arg0);end
end
class RDoc::Attr < RDoc::MethodAttr
include Comparable
include RDoc::Generator::Markup
include RDoc::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def self.add_line_numbers();end
def self.add_line_numbers=(arg0);end
def marshal_dump();end
def marshal_load(array);end
def add_alias(an_alias, context);end
def aref_prefix();end
def rw();end
def rw=(arg0);end
def definition();end
def calls_super();end
def token_stream();end
end
class RDoc::Constant < RDoc::CodeObject
include RDoc::Generator::Markup
include RDoc::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def path();end
def value();end
def marshal_dump();end
def marshal_load(array);end
def name=(arg0);end
def full_name();end
def value=(arg0);end
def store=(store);end
def visibility();end
def documented?();end
def is_alias_for();end
def visibility=(arg0);end
def is_alias_for=(arg0);end
end
class RDoc::Mixin < RDoc::CodeObject
include RDoc::Generator::Markup
include RDoc::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def name=(arg0);end
def full_name();end
def store=(store);end
def module();end
end
class RDoc::Include < RDoc::Mixin
include RDoc::Generator::Markup
include RDoc::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::Extend < RDoc::Mixin
include RDoc::Generator::Markup
include RDoc::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
end
class RDoc::Require < RDoc::CodeObject
include RDoc::Generator::Markup
include RDoc::Text
include JSON::Ext::Generator::GeneratorMethods::Object
include PP::ObjectMixin
include Minitest::Expectations
include Kernel
def name=(arg0);end
def top_level();end
end
