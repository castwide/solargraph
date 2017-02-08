module Forwardable
def debug();end
def debug=(arg0);end
def self.debug();end
def self.debug=(arg0);end
def instance_delegate(hash);end
def def_instance_delegators(accessor, *methods);end
def def_instance_delegator(accessor, method, ali = nil);end
def delegate(hash);end
def def_delegators(accessor, *methods);end
def def_delegator(accessor, method, ali = nil);end
end
module SingleForwardable
def single_delegate(hash);end
def def_single_delegators(accessor, *methods);end
def def_single_delegator(accessor, method, ali = nil);end
def delegate(hash);end
def def_delegators(accessor, *methods);end
def def_delegator(accessor, method, ali = nil);end
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
class CSV < Object
include Enumerable
include Kernel
def self.instance(*args);end
def self.filter(*args);end
def self.foreach(path, options = nil, &block);end
def self.generate(*args);end
def self.generate_line(row, options = nil);end
def self.parse(*args);end
def self.parse_line(line, options = nil);end
def self.read(path, *options);end
def self.table(path, options = nil);end
def self.instance_delegate(hash);end
def self.def_instance_delegators(accessor, *methods);end
def self.def_instance_delegator(accessor, method, ali = nil);end
def self.delegate(hash);end
def self.def_delegators(accessor, *methods);end
def self.def_delegator(accessor, method, ali = nil);end
def self.instance(*args);end
def self.filter(*args);end
def self.foreach(path, options = nil, &block);end
def self.generate(*args);end
def self.generate_line(row, options = nil);end
def self.parse(*args);end
def self.parse_line(line, options = nil);end
def self.read(path, *options);end
def self.table(path, options = nil);end
def col_sep();end
def row_sep();end
def quote_char();end
def field_size_limit();end
def skip_lines();end
def converters();end
def unconverted_fields?();end
def headers();end
def return_headers?();end
def write_headers?();end
def header_converters();end
def skip_blanks?();end
def force_quotes?();end
def encoding();end
def lineno();end
def binmode(*args);end
def binmode?(*args);end
def close(*args);end
def close_read(*args);end
def close_write(*args);end
def closed?(*args);end
def eof(*args);end
def eof?(*args);end
def external_encoding(*args);end
def fcntl(*args);end
def fileno(*args);end
def flock(*args);end
def flush(*args);end
def fsync(*args);end
def internal_encoding(*args);end
def ioctl(*args);end
def isatty(*args);end
def path(*args);end
def pid(*args);end
def pos(*args);end
def pos=(*args);end
def reopen(*args);end
def seek(*args);end
def stat(*args);end
def string(*args);end
def sync(*args);end
def sync=(*args);end
def tell(*args);end
def to_i(*args);end
def to_io(*args);end
def truncate(*args);end
def tty?(*args);end
def rewind();end
def <<(row);end
def add_row(row);end
def convert(*args);end
def header_convert(*args);end
def each();end
def read();end
def header_row?();end
def shift();end
end
class CSV::Row < Object
include Enumerable
include Kernel
def self.instance_delegate(hash);end
def self.def_instance_delegators(accessor, *methods);end
def self.def_instance_delegator(accessor, method, ali = nil);end
def self.delegate(hash);end
def self.def_delegators(accessor, *methods);end
def self.def_delegator(accessor, method, ali = nil);end
def empty?(*args);end
def length(*args);end
def size(*args);end
def header_row?();end
def field_row?();end
def headers();end
def field(header_or_index, minimum_index = nil);end
def [](header_or_index, minimum_index = nil);end
def fetch(header, *varargs);end
def has_key?(header);end
def key?(header);end
def member?(header);end
def []=(*args);end
def <<(arg);end
def push(*args);end
def delete(header_or_index, minimum_index = nil);end
def delete_if(&block);end
def fields(*args);end
def values_at(*args);end
def index(header, minimum_index = nil);end
def header?(name);end
def field?(data);end
def each(&block);end
def to_hash();end
def to_csv(*args);end
end
class CSV::Table < Object
include Enumerable
include Kernel
def self.instance_delegate(hash);end
def self.def_instance_delegators(accessor, *methods);end
def self.def_instance_delegator(accessor, method, ali = nil);end
def self.delegate(hash);end
def self.def_delegators(accessor, *methods);end
def self.def_delegator(accessor, method, ali = nil);end
def mode();end
def empty?(*args);end
def length(*args);end
def size(*args);end
def by_col();end
def by_col!();end
def by_col_or_row();end
def by_col_or_row!();end
def by_row();end
def by_row!();end
def headers();end
def [](index_or_header);end
def []=(index_or_header, value);end
def values_at(*args);end
def <<(row_or_array);end
def push(*args);end
def delete(index_or_header);end
def delete_if(&block);end
def each(&block);end
def to_a();end
def to_csv(*args);end
end
class CSV::MalformedCSVError < RuntimeError
include Kernel
def self.exception(*args);end
end
class CSV::FieldInfo < Struct
include Enumerable
include Kernel
def self.[](*args);end
def self.members();end
def self.[](*args);end
def self.members();end
def index();end
def index=(arg0);end
def line();end
def line=(arg0);end
def header();end
def header=(arg0);end
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
