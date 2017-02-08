module Psych
def libyaml_version();end
def quick_emit(thing, opts = nil, &block);end
def load_documents(yaml, &block);end
def detect_implicit(thing);end
def add_ruby_type(type_tag, &block);end
def add_private_type(type_tag, &block);end
def tagurize(thing);end
def read_type_class(type, reference);end
def object_maker(klass, hash);end
def parse(yaml, filename = nil);end
def parse_file(filename);end
def parser();end
def parse_stream(yaml, filename = nil, &block);end
def dump(o, io = nil, options = nil);end
def dump_stream(*args);end
def to_json(o);end
def load_stream(yaml, filename = nil);end
def load_file(filename);end
def add_domain_type(domain, type_tag, &block);end
def add_builtin_type(type_tag, &block);end
def remove_type(type_tag);end
def add_tag(tag, klass);end
def load_tags();end
def load_tags=(arg0);end
def dump_tags();end
def dump_tags=(arg0);end
def domain_types();end
def domain_types=(arg0);end
def self.libyaml_version();end
def self.quick_emit(thing, opts = nil, &block);end
def self.load_documents(yaml, &block);end
def self.detect_implicit(thing);end
def self.add_ruby_type(type_tag, &block);end
def self.add_private_type(type_tag, &block);end
def self.tagurize(thing);end
def self.read_type_class(type, reference);end
def self.object_maker(klass, hash);end
def self.parse(yaml, filename = nil);end
def self.parse_file(filename);end
def self.parser();end
def self.parse_stream(yaml, filename = nil, &block);end
def self.dump(o, io = nil, options = nil);end
def self.dump_stream(*args);end
def self.to_json(o);end
def self.load_stream(yaml, filename = nil);end
def self.load_file(filename);end
def self.add_domain_type(domain, type_tag, &block);end
def self.add_builtin_type(type_tag, &block);end
def self.remove_type(type_tag);end
def self.add_tag(tag, klass);end
def self.load_tags();end
def self.load_tags=(arg0);end
def self.dump_tags();end
def self.dump_tags=(arg0);end
def self.domain_types();end
def self.domain_types=(arg0);end
end
class Psych::Parser < Object
include Kernel
def parse(*args);end
def mark();end
def handler();end
def handler=(arg0);end
def external_encoding=(arg0);end
end
class Psych::Parser::Mark < #<Class:0x00000000d124a0>
include Enumerable
include Kernel
def self.[](*args);end
def self.members();end
end
class Struct::Tms < Struct
include Enumerable
include Kernel
def self.[](*args);end
def self.members();end
def self.[](*args);end
def self.members();end
def utime();end
def utime=(arg0);end
def stime();end
def stime=(arg0);end
def cutime();end
def cutime=(arg0);end
def cstime();end
def cstime=(arg0);end
end
class Psych::Error < RuntimeError
include Kernel
def self.exception(*args);end
end
class Psych::SyntaxError < Psych::Error
include Kernel
def self.exception(*args);end
def file();end
def line();end
def column();end
def offset();end
def problem();end
def context();end
end
class Psych::Handler < Object
include Kernel
def start_stream(encoding);end
def start_document(version, tag_directives, implicit);end
def end_document(implicit);end
def alias(anchor);end
def scalar(value, anchor, tag, plain, quoted, style);end
def start_sequence(anchor, tag, implicit, style);end
def end_sequence();end
def start_mapping(anchor, tag, implicit, style);end
def end_mapping();end
def empty();end
def end_stream();end
def streaming?();end
end
class Psych::Handler::DumperOptions < Object
include Kernel
def line_width();end
def line_width=(arg0);end
def indentation();end
def indentation=(arg0);end
def canonical();end
def canonical=(arg0);end
end
class Psych::Emitter < Psych::Handler
include Kernel
def start_stream(arg0);end
def end_stream();end
def start_document(arg0, arg1, arg2);end
def end_document(arg0);end
def scalar(arg0, arg1, arg2, arg3, arg4, arg5);end
def start_sequence(arg0, arg1, arg2, arg3);end
def end_sequence();end
def start_mapping(arg0, arg1, arg2, arg3);end
def end_mapping();end
def alias(arg0);end
def canonical();end
def canonical=(arg0);end
def indentation();end
def indentation=(arg0);end
def line_width();end
def line_width=(arg0);end
end
module Psych::Visitors
end
class Psych::Visitors::Visitor < Object
include Kernel
def accept(target);end
end
class Psych::Visitors::ToRuby < Psych::Visitors::Visitor
include Kernel
def accept(target);end
def visit_Psych_Nodes_Scalar(o);end
def visit_Psych_Nodes_Sequence(o);end
def visit_Psych_Nodes_Mapping(o);end
def visit_Psych_Nodes_Document(o);end
def visit_Psych_Nodes_Stream(o);end
def visit_Psych_Nodes_Alias(o);end
end
class Psych::Visitors::YAMLTree < Psych::Visitors::Visitor
include Kernel
def started();end
def finished();end
def finished?();end
def started?();end
def start(*args);end
def finish();end
def tree();end
def push(object);end
def <<(object);end
def accept(target);end
def visit_Psych_Omap(o);end
def visit_Object(o);end
def visit_Struct(o);end
def visit_Exception(o);end
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
def visit_Hash(o);end
def visit_Psych_Set(o);end
def visit_Array(o);end
def visit_NilClass(o);end
def visit_Symbol(o);end
end
class Psych::Visitors::YAMLTree::Registrar < Object
include Kernel
def register(target, node);end
def key?(target);end
def id_for(target);end
def node_for(target);end
end
class Psych::Visitors::Emitter < Psych::Visitors::Visitor
include Kernel
def visit_Psych_Nodes_Stream(o);end
def visit_Psych_Nodes_Document(o);end
def visit_Psych_Nodes_Scalar(o);end
def visit_Psych_Nodes_Sequence(o);end
def visit_Psych_Nodes_Mapping(o);end
def visit_Psych_Nodes_Alias(o);end
end
class Psych::Visitors::JSONTree < Psych::Visitors::YAMLTree
include Psych::JSON::RubyEvents
include Kernel
def accept(target);end
end
class Psych::Visitors::DepthFirst < Psych::Visitors::Visitor
include Kernel
end
module Psych::Nodes
end
class Psych::Nodes::Node < Object
include Enumerable
include Kernel
def children();end
def tag();end
def each(&block);end
def to_ruby();end
def transform();end
def yaml(*args);end
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
def tag_directives();end
def tag_directives=(arg0);end
def implicit();end
def implicit=(arg0);end
def implicit_end();end
def implicit_end=(arg0);end
def root();end
end
class Psych::Nodes::Sequence < Psych::Nodes::Node
include Enumerable
include Kernel
def anchor();end
def anchor=(arg0);end
def tag();end
def tag=(arg0);end
def implicit();end
def implicit=(arg0);end
def style();end
def style=(arg0);end
end
class Psych::Nodes::Scalar < Psych::Nodes::Node
include Enumerable
include Kernel
def value();end
def value=(arg0);end
def anchor();end
def anchor=(arg0);end
def tag();end
def tag=(arg0);end
def plain();end
def plain=(arg0);end
def quoted();end
def quoted=(arg0);end
def style();end
def style=(arg0);end
end
class Psych::Nodes::Mapping < Psych::Nodes::Node
include Enumerable
include Kernel
def anchor();end
def anchor=(arg0);end
def tag();end
def tag=(arg0);end
def implicit();end
def implicit=(arg0);end
def style();end
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
class Psych::ScalarScanner < Object
include Kernel
def tokenize(string);end
def parse_int(string);end
def parse_time(string);end
end
module Psych::JSON
end
module Psych::JSON::RubyEvents
def visit_Time(o);end
def visit_DateTime(o);end
def visit_String(o);end
def visit_Symbol(o);end
end
module Psych::JSON::YAMLEvents
def start_document(version, tag_directives, implicit);end
def end_document(*args);end
def start_mapping(anchor, tag, implicit, style);end
def start_sequence(anchor, tag, implicit, style);end
def scalar(value, anchor, tag, plain, quoted, style);end
end
class Psych::JSON::TreeBuilder < Psych::TreeBuilder
include Psych::JSON::YAMLEvents
include Kernel
end
class Psych::JSON::Stream < Psych::Visitors::JSONTree
include Psych::Streaming
include Psych::JSON::RubyEvents
include Kernel
end
class Psych::JSON::Stream::Emitter < Psych::Stream::Emitter
include Psych::JSON::YAMLEvents
include Kernel
end
class Psych::TreeBuilder < Psych::Handler
include Kernel
def root();end
def start_sequence(anchor, tag, implicit, style);end
def end_sequence();end
def start_mapping(anchor, tag, implicit, style);end
def end_mapping();end
def start_document(version, tag_directives, implicit);end
def end_document(*args);end
def start_stream(encoding);end
def end_stream();end
def scalar(value, anchor, tag, plain, quoted, style);end
def alias(anchor);end
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
class Psych::Coder < Object
include Kernel
def tag();end
def tag=(arg0);end
def style();end
def style=(arg0);end
def implicit();end
def implicit=(arg0);end
def object();end
def object=(arg0);end
def type();end
def seq();end
def scalar(*args);end
def map(*args);end
def represent_scalar(tag, value);end
def represent_seq(tag, list);end
def represent_map(tag, map);end
def represent_object(tag, obj);end
def scalar=(value);end
def map=(map);end
def []=(k, v);end
def add(k, v);end
def [](k);end
def seq=(list);end
end
module Psych::DeprecatedMethods
def taguri();end
def taguri=(arg0);end
def to_yaml_style();end
def to_yaml_style=(arg0);end
end
class Psych::Stream < Psych::Visitors::YAMLTree
include Psych::Streaming
include Kernel
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
class Psych::Exception < RuntimeError
include Kernel
def self.exception(*args);end
end
class Psych::BadAlias < Psych::Exception
include Kernel
def self.exception(*args);end
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
class Date < Object
include Comparable
include Kernel
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
def self.today(*args);end
def self._strptime(*args);end
def self.strptime(*args);end
def self._parse(*args);end
def self.parse(*args);end
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
def self.today(*args);end
def self._strptime(*args);end
def self.strptime(*args);end
def self._parse(*args);end
def self.parse(*args);end
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
def ajd();end
def amjd();end
def jd();end
def mjd();end
def ld();end
def year();end
def yday();end
def mon();end
def month();end
def mday();end
def day();end
def day_fraction();end
def cwyear();end
def cweek();end
def cwday();end
def wday();end
def sunday?();end
def monday?();end
def tuesday?();end
def wednesday?();end
def thursday?();end
def friday?();end
def saturday?();end
def julian?();end
def gregorian?();end
def leap?();end
def start();end
def new_start(*args);end
def italy();end
def england();end
def julian();end
def gregorian();end
def +(arg0);end
def -(arg0);end
def next_day(*args);end
def prev_day(*args);end
def next();end
def succ();end
def >>(arg0);end
def <<(arg0);end
def next_month(*args);end
def prev_month(*args);end
def next_year(*args);end
def prev_year(*args);end
def step(*args);end
def upto(arg0);end
def downto(arg0);end
def strftime(*args);end
def asctime();end
def ctime();end
def iso8601();end
def xmlschema();end
def rfc3339();end
def rfc2822();end
def rfc822();end
def httpdate();end
def jisx0301();end
def marshal_dump();end
def marshal_load(arg0);end
def to_time();end
def to_date();end
def to_datetime();end
end
class Date::Infinity < Numeric
include Comparable
include Kernel
def zero?();end
def finite?();end
def infinite?();end
def nan?();end
def abs();end
def -@();end
def +@();end
def coerce(other);end
def to_f();end
end
class DateTime < Date
include Comparable
include Kernel
def self.jd(*args);end
def self.ordinal(*args);end
def self.civil(*args);end
def self.commercial(*args);end
def self.now(*args);end
def self._strptime(*args);end
def self.strptime(*args);end
def self.parse(*args);end
def self.iso8601(*args);end
def self.rfc3339(*args);end
def self.xmlschema(*args);end
def self.rfc2822(*args);end
def self.rfc822(*args);end
def self.httpdate(*args);end
def self.jisx0301(*args);end
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
def self._load(arg0);end
def self.jd(*args);end
def self.ordinal(*args);end
def self.civil(*args);end
def self.commercial(*args);end
def self.now(*args);end
def self._strptime(*args);end
def self.strptime(*args);end
def self.parse(*args);end
def self.iso8601(*args);end
def self.rfc3339(*args);end
def self.xmlschema(*args);end
def self.rfc2822(*args);end
def self.rfc822(*args);end
def self.httpdate(*args);end
def self.jisx0301(*args);end
def hour();end
def min();end
def minute();end
def sec();end
def second();end
def sec_fraction();end
def second_fraction();end
def offset();end
def zone();end
def new_offset(*args);end
def strftime(*args);end
def iso8601(*args);end
def xmlschema(*args);end
def rfc3339(*args);end
def jisx0301(*args);end
def to_time();end
def to_date();end
def to_datetime();end
end
class Date::Infinity < Numeric
include Comparable
include Kernel
def zero?();end
def finite?();end
def infinite?();end
def nan?();end
def abs();end
def -@();end
def +@();end
def coerce(other);end
def to_f();end
end
