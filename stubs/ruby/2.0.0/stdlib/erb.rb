class CGI < Object
include Kernel
def self.escape(string);end
def self.unescape(string, encoding = nil);end
def self.escapeHTML(string);end
def self.unescapeHTML(string);end
def self.escape_html(str);end
def self.unescape_html(str);end
def self.escapeElement(string, *elements);end
def self.unescapeElement(string, *elements);end
def self.escape_element(str);end
def self.unescape_element(str);end
def self.rfc1123_date(time);end
def self.pretty(string, shift = nil);end
def self.escape(string);end
def self.unescape(string, encoding = nil);end
def self.escapeHTML(string);end
def self.unescapeHTML(string);end
def self.escape_html(str);end
def self.unescape_html(str);end
def self.escapeElement(string, *elements);end
def self.unescapeElement(string, *elements);end
def self.escape_element(str);end
def self.unescape_element(str);end
def self.rfc1123_date(time);end
def self.pretty(string, shift = nil);end
end
class ERB < Object
include Kernel
def self.version();end
def self.version();end
def make_compiler(trim_mode);end
def src();end
def filename();end
def filename=(arg0);end
def set_eoutvar(compiler, eoutvar = nil);end
def run(*args);end
def result(*args);end
def def_method(mod, methodname, fname = nil);end
def def_module(*args);end
def def_class(*args);end
end
class ERB::Compiler < Object
include Kernel
def content_dump(s);end
def add_put_cmd(out, content);end
def add_insert_cmd(out, content);end
def compile(s);end
def prepare_trim_mode(mode);end
def make_scanner(src);end
def percent();end
def trim_mode();end
def put_cmd();end
def put_cmd=(arg0);end
def insert_cmd();end
def insert_cmd=(arg0);end
def pre_cmd();end
def pre_cmd=(arg0);end
def post_cmd();end
def post_cmd=(arg0);end
end
class ERB::Compiler::PercentLine < Object
include Kernel
def value();end
def empty?();end
end
class ERB::Compiler::Scanner < Object
include Kernel
def self.regist_scanner(klass, trim_mode, percent);end
def self.default_scanner=(klass);end
def self.make_scanner(src, trim_mode, percent);end
def self.regist_scanner(klass, trim_mode, percent);end
def self.default_scanner=(klass);end
def self.make_scanner(src, trim_mode, percent);end
def stag();end
def stag=(arg0);end
def scan();end
end
class ERB::Compiler::TrimScanner < ERB::Compiler::Scanner
include Kernel
def self.regist_scanner(klass, trim_mode, percent);end
def self.default_scanner=(klass);end
def self.make_scanner(src, trim_mode, percent);end
def stag();end
def stag=(arg0);end
def scan(&block);end
def percent_line(line, &block);end
def scan_line(line);end
def trim_line1(line);end
def trim_line2(line);end
def explicit_trim_line(line);end
def is_erb_stag?(s);end
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
def script();end
def push(cmd);end
def cr();end
def close();end
end
module ERB::Util
def h(s);end
def html_escape(s);end
def u(s);end
def url_encode(s);end
def self.h(s);end
def self.html_escape(s);end
def self.u(s);end
def self.url_encode(s);end
end
module ERB::DefMethod
def def_erb_method(methodname, erb_or_fname);end
def self.def_erb_method(methodname, erb_or_fname);end
end
class StringScanner < Object
include Kernel
def self.must_C_version();end
def self.must_C_version();end
def reset();end
def terminate();end
def clear();end
def string();end
def string=(arg0);end
def concat(arg0);end
def <<(arg0);end
def pos();end
def pos=(arg0);end
def charpos();end
def pointer();end
def pointer=(arg0);end
def scan(arg0);end
def skip(arg0);end
def match?(arg0);end
def check(arg0);end
def scan_full(arg0, arg1, arg2);end
def scan_until(arg0);end
def skip_until(arg0);end
def exist?(arg0);end
def check_until(arg0);end
def search_full(arg0, arg1, arg2);end
def getch();end
def get_byte();end
def getbyte();end
def peek(arg0);end
def peep(arg0);end
def unscan();end
def beginning_of_line?();end
def bol?();end
def eos?();end
def empty?();end
def rest?();end
def matched?();end
def matched();end
def matched_size();end
def [](arg0);end
def pre_match();end
def post_match();end
def rest();end
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
