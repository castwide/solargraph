module Psych
def dump(o, io = nil, options = nil);end
def quick_emit(thing, opts = nil, &block);end
def parse(yaml, filename = nil);end
def parser();end
def libyaml_version();end
def safe_load(yaml, whitelist_classes = nil, whitelist_symbols = nil, aliases = nil, filename = nil);end
def parse_stream(yaml, filename = nil, &block);end
def parse_file(filename);end
def dump_stream(*args);end
def to_json(object);end
def load_stream(yaml, filename = nil);end
def load_file(filename);end
def add_domain_type(domain, type_tag, &block);end
def add_builtin_type(type_tag, &block);end
def remove_type(type_tag);end
def add_tag(tag, klass);end
def load_tags();end
def dump_tags();end
def domain_types();end
def load_documents(yaml, &block);end
def detect_implicit(thing);end
def add_ruby_type(type_tag, &block);end
def add_private_type(type_tag, &block);end
def tagurize(thing);end
def read_type_class(type, reference);end
def object_maker(klass, hash);end
def load_tags=(arg0);end
def dump_tags=(arg0);end
def domain_types=(arg0);end
def self.dump(o, io = nil, options = nil);end
def self.quick_emit(thing, opts = nil, &block);end
def self.parse(yaml, filename = nil);end
def self.parser();end
def self.libyaml_version();end
def self.safe_load(yaml, whitelist_classes = nil, whitelist_symbols = nil, aliases = nil, filename = nil);end
def self.parse_stream(yaml, filename = nil, &block);end
def self.parse_file(filename);end
def self.dump_stream(*args);end
def self.to_json(object);end
def self.load_stream(yaml, filename = nil);end
def self.load_file(filename);end
def self.add_domain_type(domain, type_tag, &block);end
def self.add_builtin_type(type_tag, &block);end
def self.remove_type(type_tag);end
def self.add_tag(tag, klass);end
def self.load_tags();end
def self.dump_tags();end
def self.domain_types();end
def self.load_documents(yaml, &block);end
def self.detect_implicit(thing);end
def self.add_ruby_type(type_tag, &block);end
def self.add_private_type(type_tag, &block);end
def self.tagurize(thing);end
def self.read_type_class(type, reference);end
def self.object_maker(klass, hash);end
def self.load_tags=(arg0);end
def self.dump_tags=(arg0);end
def self.domain_types=(arg0);end
end
class Psych::Parser < Object
include Kernel
def parse(*args);end
def handler();end
def mark();end
def handler=(arg0);end
def external_encoding=(arg0);end
end
class Psych::Parser::Mark < #<Class:0x007fc7d5a31bd8>
include Enumerable
include Kernel
def self.[](*args);end
def self.members();end
end
class Process::Tms < Struct
include Enumerable
include Kernel
def self.[](*args);end
def self.members();end
def self.[](*args);end
def self.members();end
def utime();end
def utime=(_);end
def stime();end
def stime=(_);end
def cutime();end
def cutime=(_);end
def cstime();end
def cstime=(_);end
end
class Psych::Exception < RuntimeError
include Kernel
def self.exception(*args);end
end
class Psych::BadAlias < Psych::Exception
include Kernel
def self.exception(*args);end
end
class Psych::DisallowedClass < Psych::Exception
include Kernel
def self.exception(*args);end
end
class Psych::SyntaxError < Psych::Exception
include Kernel
def self.exception(*args);end
def offset();end
def file();end
def line();end
def column();end
def problem();end
def context();end
end
class Psych::Handler < Object
include Kernel
def empty();end
def start_stream(encoding);end
def end_stream();end
def start_document(version, tag_directives, implicit);end
def end_document(implicit);end
def alias(anchor);end
def scalar(value, anchor, tag, plain, quoted, style);end
def start_sequence(anchor, tag, implicit, style);end
def end_sequence();end
def start_mapping(anchor, tag, implicit, style);end
def end_mapping();end
def streaming?();end
end
class Psych::Handler::DumperOptions < Object
include Kernel
def canonical();end
def canonical=(arg0);end
def indentation();end
def indentation=(arg0);end
def line_width();end
def line_width=(arg0);end
end
class Psych::Emitter < Psych::Handler
include Kernel
def start_stream(arg0);end
def end_stream();end
def start_document(arg0, arg1, arg2);end
def end_document(arg0);end
def alias(arg0);end
def scalar(arg0, arg1, arg2, arg3, arg4, arg5);end
def start_sequence(arg0, arg1, arg2, arg3);end
def end_sequence();end
def start_mapping(arg0, arg1, arg2, arg3);end
def end_mapping();end
def canonical();end
def canonical=(arg0);end
def indentation();end
def indentation=(arg0);end
def line_width();end
def line_width=(arg0);end
end
class Psych::ClassLoader < Object
include Kernel
def exception();end
def regexp();end
def date();end
def symbol();end
def range();end
def object();end
def symbolize(sym);end
def big_decimal();end
def complex();end
def date_time();end
def psych_omap();end
def psych_set();end
def rational();end
def struct();end
end
class Psych::ClassLoader::Restricted < Psych::ClassLoader
include Kernel
def symbolize(sym);end
end
module Psych::Visitors
end
class Psych::Visitors::Visitor < Object
include Kernel
def accept(target);end
end
class Psych::Visitors::ToRuby < Psych::Visitors::Visitor
include Kernel
def self.create();end
def self.create();end
def accept(target);end
def class_loader();end
def visit_Psych_Nodes_Scalar(o);end
def visit_Psych_Nodes_Sequence(o);end
def visit_Psych_Nodes_Mapping(o);end
def visit_Psych_Nodes_Document(o);end
def visit_Psych_Nodes_Stream(o);end
def visit_Psych_Nodes_Alias(o);end
end
class Psych::Visitors::YAMLTree < Psych::Visitors::Visitor
include Kernel
def self.create(*args);end
def self.create(*args);end
def <<(object);end
def push(object);end
def finished();end
def finish();end
def start(*args);end
def tree();end
def accept(target);end
def started();end
def finished?();end
def started?();end
def visit_Psych_Omap(o);end
def visit_Hash(o);end
def visit_Encoding(o);end
def visit_Object(o);end
def visit_Struct(o);end
def visit_Exception(o);end
def visit_NameError(o);end
def visit_Regexp(o);end
def visit_DateTime(o);end
def visit_Time(o);end
def visit_Rational(o);end
def visit_Complex(o);end
def visit_Integer(o);end
def visit_TrueClass(o);end
def visit_FalseClass(o);end
def visit_Date(o);end
def visit_Float(o);end
def visit_BigDecimal(o);end
def visit_String(o);end
def visit_Module(o);end
def visit_Class(o);end
def visit_Range(o);end
def visit_Psych_Set(o);end
def visit_Array(o);end
def visit_NilClass(o);end
def visit_Symbol(o);end
def visit_BasicObject(o);end
end
class Psych::Visitors::YAMLTree::Registrar < Object
include Kernel
def key?(target);end
def register(target, node);end
def id_for(target);end
def node_for(target);end
end
class Psych::Visitors::NoAliasRuby < Psych::Visitors::ToRuby
include Kernel
def self.create();end
def visit_Psych_Nodes_Alias(o);end
end
class Psych::Visitors::Emitter < Psych::Visitors::Visitor
include Kernel
def visit_Psych_Nodes_Scalar(o);end
def visit_Psych_Nodes_Sequence(o);end
def visit_Psych_Nodes_Mapping(o);end
def visit_Psych_Nodes_Document(o);end
def visit_Psych_Nodes_Stream(o);end
def visit_Psych_Nodes_Alias(o);end
end
class Psych::Visitors::JSONTree < Psych::Visitors::YAMLTree
include Psych::JSON::RubyEvents
include Kernel
def self.create(*args);end
def self.create(*args);end
def accept(target);end
end
class Psych::Visitors::DepthFirst < Psych::Visitors::Visitor
include Kernel
end
class Psych::Omap < Hash
include Enumerable
include Kernel
def self.[](*args);end
def self.try_convert(arg0);end
end
class Psych::Set < Hash
include Enumerable
include Kernel
def self.[](*args);end
def self.try_convert(arg0);end
end
class Psych::ScalarScanner < Object
include Kernel
def class_loader();end
def tokenize(string);end
def parse_time(string);end
def parse_int(string);end
end
module Psych::Nodes
end
class Psych::Nodes::Node < Object
include Enumerable
include Kernel
def each(&block);end
def tag();end
def to_ruby();end
def yaml(*args);end
def children();end
def transform();end
end
class Psych::Nodes::Stream < Psych::Nodes::Node
include Enumerable
include Kernel
def encoding();end
def encoding=(arg0);end
end
class Psych::Nodes::Document < Psych::Nodes::Node
include Enumerable
include Kernel
def version();end
def version=(arg0);end
def root();end
def tag_directives();end
def implicit();end
def implicit_end();end
def tag_directives=(arg0);end
def implicit=(arg0);end
def implicit_end=(arg0);end
end
class Psych::Nodes::Sequence < Psych::Nodes::Node
include Enumerable
include Kernel
def tag();end
def implicit();end
def implicit=(arg0);end
def anchor();end
def style();end
def anchor=(arg0);end
def tag=(arg0);end
def style=(arg0);end
end
class Psych::Nodes::Scalar < Psych::Nodes::Node
include Enumerable
include Kernel
def tag();end
def value();end
def quoted();end
def value=(arg0);end
def anchor();end
def style();end
def anchor=(arg0);end
def tag=(arg0);end
def style=(arg0);end
def plain();end
def plain=(arg0);end
def quoted=(arg0);end
end
class Psych::Nodes::Mapping < Psych::Nodes::Node
include Enumerable
include Kernel
def tag();end
def implicit();end
def implicit=(arg0);end
def anchor();end
def style();end
def anchor=(arg0);end
def tag=(arg0);end
def style=(arg0);end
end
class Psych::Nodes::Alias < Psych::Nodes::Node
include Enumerable
include Kernel
def anchor();end
def anchor=(arg0);end
end
module Psych::Streaming
def start(*args);end
end
module Psych::Streaming::ClassMethods
def new(io);end
end
class Psych::TreeBuilder < Psych::Handler
include Kernel
def root();end
def start_stream(encoding);end
def end_stream();end
def start_document(version, tag_directives, implicit);end
def end_document(*args);end
def alias(anchor);end
def scalar(value, anchor, tag, plain, quoted, style);end
def start_sequence(anchor, tag, implicit, style);end
def end_sequence();end
def start_mapping(anchor, tag, implicit, style);end
def end_mapping();end
end
module Psych::JSON
end
module Psych::JSON::RubyEvents
def visit_DateTime(o);end
def visit_Time(o);end
def visit_String(o);end
def visit_Symbol(o);end
end
module Psych::JSON::YAMLEvents
def start_document(version, tag_directives, implicit);end
def end_document(*args);end
def scalar(value, anchor, tag, plain, quoted, style);end
def start_sequence(anchor, tag, implicit, style);end
def start_mapping(anchor, tag, implicit, style);end
end
class Psych::JSON::TreeBuilder < Psych::TreeBuilder
include Psych::JSON::YAMLEvents
include Kernel
end
class Psych::JSON::Stream < Psych::Visitors::JSONTree
include Psych::Streaming
include Psych::JSON::RubyEvents
include Kernel
def self.create(*args);end
end
class Psych::JSON::Stream::Emitter < Psych::Stream::Emitter
include Psych::JSON::YAMLEvents
include Kernel
end
class Psych::Coder < Object
include Kernel
def [](k);end
def []=(k, v);end
def map(*args);end
def tag();end
def add(k, v);end
def type();end
def object();end
def scalar(*args);end
def implicit();end
def implicit=(arg0);end
def style();end
def tag=(arg0);end
def style=(arg0);end
def scalar=(value);end
def seq();end
def seq=(list);end
def map=(map);end
def represent_scalar(tag, value);end
def represent_seq(tag, list);end
def represent_map(tag, map);end
def represent_object(tag, obj);end
def object=(arg0);end
end
module Psych::DeprecatedMethods
def taguri();end
def to_yaml_style();end
def taguri=(arg0);end
def to_yaml_style=(arg0);end
end
class Psych::Stream < Psych::Visitors::YAMLTree
include Psych::Streaming
include Kernel
def self.create(*args);end
end
class Psych::Stream::Emitter < Psych::Emitter
include Kernel
def end_document(*args);end
def streaming?();end
end
module Psych::Handlers
end
class Psych::Handlers::DocumentStream < Psych::TreeBuilder
include Kernel
def start_document(version, tag_directives, implicit);end
def end_document(*args);end
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
def eos?();end
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
class Date < Object
include Comparable
include Kernel
def self._load(arg0);end
def self.today(*args);end
def self.parse(*args);end
def self.strptime(*args);end
def self.valid_jd?(*args);end
def self.valid_ordinal?(*args);end
def self.valid_civil?(*args);end
def self.valid_date?(*args);end
def self.valid_commercial?(*args);end
def self.julian_leap?(arg0);end
def self.gregorian_leap?(arg0);end
def self.leap?(arg0);end
def self.jd(*args);end
def self.ordinal(*args);end
def self.civil(*args);end
def self.commercial(*args);end
def self._strptime(*args);end
def self._parse(*args);end
def self._iso8601(arg0);end
def self.iso8601(*args);end
def self._rfc3339(arg0);end
def self.rfc3339(*args);end
def self._xmlschema(arg0);end
def self.xmlschema(*args);end
def self._rfc2822(arg0);end
def self._rfc822(arg0);end
def self.rfc2822(*args);end
def self.rfc822(*args);end
def self._httpdate(arg0);end
def self.httpdate(*args);end
def self._jisx0301(arg0);end
def self.jisx0301(*args);end
def self._load(arg0);end
def self.today(*args);end
def self.parse(*args);end
def self.strptime(*args);end
def self.valid_jd?(*args);end
def self.valid_ordinal?(*args);end
def self.valid_civil?(*args);end
def self.valid_date?(*args);end
def self.valid_commercial?(*args);end
def self.julian_leap?(arg0);end
def self.gregorian_leap?(arg0);end
def self.leap?(arg0);end
def self.jd(*args);end
def self.ordinal(*args);end
def self.civil(*args);end
def self.commercial(*args);end
def self._strptime(*args);end
def self._parse(*args);end
def self._iso8601(arg0);end
def self.iso8601(*args);end
def self._rfc3339(arg0);end
def self.rfc3339(*args);end
def self._xmlschema(arg0);end
def self.xmlschema(*args);end
def self._rfc2822(arg0);end
def self._rfc822(arg0);end
def self.rfc2822(*args);end
def self.rfc822(*args);end
def self._httpdate(arg0);end
def self.httpdate(*args);end
def self._jisx0301(arg0);end
def self.jisx0301(*args);end
def <<(arg0);end
def >>(arg0);end
def start();end
def marshal_dump();end
def marshal_load(arg0);end
def to_datetime();end
def asctime();end
def mday();end
def day();end
def mon();end
def month();end
def year();end
def wday();end
def yday();end
def +(arg0);end
def -(arg0);end
def ctime();end
def sunday?();end
def monday?();end
def tuesday?();end
def wednesday?();end
def thursday?();end
def step(*args);end
def saturday?();end
def friday?();end
def succ();end
def downto(arg0);end
def iso8601();end
def leap?();end
def jd();end
def strftime(*args);end
def xmlschema();end
def rfc3339();end
def rfc822();end
def rfc2822();end
def httpdate();end
def jisx0301();end
def ajd();end
def amjd();end
def mjd();end
def ld();end
def day_fraction();end
def cweek();end
def cwyear();end
def cwday();end
def gregorian?();end
def julian?();end
def italy();end
def new_start(*args);end
def julian();end
def england();end
def prev_day(*args);end
def next_day(*args);end
def gregorian();end
def next_month(*args);end
def prev_month(*args);end
def next_year(*args);end
def prev_year(*args);end
def to_date();end
def next();end
def to_time();end
def upto(arg0);end
end
class Date::Infinity < Numeric
include Comparable
include Kernel
def +@();end
def -@();end
def to_f();end
def coerce(other);end
def abs();end
def zero?();end
def nan?();end
def infinite?();end
def finite?();end
end
class DateTime < Date
include Comparable
include Kernel
def self.now(*args);end
def self.parse(*args);end
def self.strptime(*args);end
def self.jd(*args);end
def self.ordinal(*args);end
def self.civil(*args);end
def self.commercial(*args);end
def self._strptime(*args);end
def self.iso8601(*args);end
def self.rfc3339(*args);end
def self.xmlschema(*args);end
def self.rfc2822(*args);end
def self.rfc822(*args);end
def self.httpdate(*args);end
def self.jisx0301(*args);end
def self._load(arg0);end
def self.valid_jd?(*args);end
def self.valid_ordinal?(*args);end
def self.valid_civil?(*args);end
def self.valid_date?(*args);end
def self.valid_commercial?(*args);end
def self.julian_leap?(arg0);end
def self.gregorian_leap?(arg0);end
def self.leap?(arg0);end
def self._parse(*args);end
def self._iso8601(arg0);end
def self._rfc3339(arg0);end
def self._xmlschema(arg0);end
def self._rfc2822(arg0);end
def self._rfc822(arg0);end
def self._httpdate(arg0);end
def self._jisx0301(arg0);end
def self.now(*args);end
def self.parse(*args);end
def self.strptime(*args);end
def self.jd(*args);end
def self.ordinal(*args);end
def self.civil(*args);end
def self.commercial(*args);end
def self._strptime(*args);end
def self.iso8601(*args);end
def self.rfc3339(*args);end
def self.xmlschema(*args);end
def self.rfc2822(*args);end
def self.rfc822(*args);end
def self.httpdate(*args);end
def self.jisx0301(*args);end
def min();end
def offset();end
def zone();end
def sec();end
def hour();end
def strftime(*args);end
def second();end
def to_datetime();end
def to_time();end
def iso8601(*args);end
def rfc3339(*args);end
def xmlschema(*args);end
def jisx0301(*args);end
def minute();end
def sec_fraction();end
def second_fraction();end
def new_offset(*args);end
def to_date();end
end
class Date::Infinity < Numeric
include Comparable
include Kernel
def +@();end
def -@();end
def to_f();end
def coerce(other);end
def abs();end
def zero?();end
def nan?();end
def infinite?();end
def finite?();end
end
