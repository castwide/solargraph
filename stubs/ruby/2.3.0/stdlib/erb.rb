class CGI < Object
include Kernel
def self.escapeHTML(arg0);end
def self.escape(string);end
def self.h(arg0);end
def self.unescape(string, encoding = nil);end
def self.unescapeHTML(string);end
def self.escape_html(arg0);end
def self.unescape_html(string);end
def self.escapeElement(string, *elements);end
def self.unescapeElement(string, *elements);end
def self.escape_element(string, *elements);end
def self.unescape_element(string, *elements);end
def self.rfc1123_date(time);end
def self.pretty(string, shift = nil);end
end
module CGI::Util
include CGI::Escape
def escape(string);end
def h(arg0);end
def escapeHTML(arg0);end
def unescape(string, encoding = nil);end
def unescapeHTML(string);end
def escape_html(arg0);end
def unescape_html(string);end
def escapeElement(string, *elements);end
def unescapeElement(string, *elements);end
def escape_element(string, *elements);end
def unescape_element(string, *elements);end
def rfc1123_date(time);end
def pretty(string, shift = nil);end
end
module CGI::Escape
def escapeHTML(arg0);end
end
class ERB < Object
include Kernel
def self.version();end
def self.version();end
def encoding();end
def result(*args);end
def lineno();end
def lineno=(arg0);end
def filename();end
def run(*args);end
def src();end
def make_compiler(trim_mode);end
def set_eoutvar(compiler, eoutvar = nil);end
def location=(arg0);end
def def_method(mod, methodname, fname = nil);end
def def_module(*args);end
def def_class(*args);end
def filename=(arg0);end
end
class ERB::Compiler < Object
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
include Kernel
def empty?();end
def value();end
end
class ERB::Compiler::Scanner < Object
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
include Kernel
def self.regist_scanner(klass, trim_mode, percent);end
def self.default_scanner=(klass);end
def self.make_scanner(src, trim_mode, percent);end
def scan();end
end
class ERB::Compiler::SimpleScanner2 < ERB::Compiler::Scanner
include Kernel
def self.regist_scanner(klass, trim_mode, percent);end
def self.default_scanner=(klass);end
def self.make_scanner(src, trim_mode, percent);end
def scan();end
end
class ERB::Compiler::ExplicitScanner < ERB::Compiler::Scanner
include Kernel
def self.regist_scanner(klass, trim_mode, percent);end
def self.default_scanner=(klass);end
def self.make_scanner(src, trim_mode, percent);end
def scan();end
end
class ERB::Compiler::Buffer < Object
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
class StringScanner < Object
include Kernel
def self.must_C_version();end
def self.must_C_version();end
def <<(arg0);end
def [](arg0);end
def empty?();end
def clear();end
def getbyte();end
def concat(arg0);end
def scan(arg0);end
def pre_match();end
def post_match();end
def string();end
def pos();end
def pos=(arg0);end
def skip(arg0);end
def exist?(arg0);end
def peek(arg0);end
def terminate();end
def reset();end
def match?(arg0);end
def string=(arg0);end
def rest();end
def eos?();end
def charpos();end
def pointer();end
def pointer=(arg0);end
def check(arg0);end
def scan_full(arg0, arg1, arg2);end
def scan_until(arg0);end
def skip_until(arg0);end
def check_until(arg0);end
def search_full(arg0, arg1, arg2);end
def getch();end
def get_byte();end
def peep(arg0);end
def unscan();end
def beginning_of_line?();end
def bol?();end
def rest?();end
def matched?();end
def matched();end
def matched_size();end
def rest_size();end
def restsize();end
end
class StringScanner::Error < StandardError
include Kernel
def self.exception(*args);end
end
class StringScanner::Error < StandardError
include Kernel
def self.exception(*args);end
end
