module Forwardable
def debug();end
def debug=(arg0);end
def self.debug();end
def self.debug=(arg0);end
def def_delegators(accessor, *methods);end
def instance_delegate(hash);end
def def_instance_delegator(accessor, method, ali = nil);end
def def_instance_delegators(accessor, *methods);end
def delegate(hash);end
def def_delegator(accessor, method, ali = nil);end
end
module SingleForwardable
def def_delegators(accessor, *methods);end
def delegate(hash);end
def def_delegator(accessor, method, ali = nil);end
def single_delegate(hash);end
def def_single_delegator(accessor, method, ali = nil);end
def def_single_delegators(accessor, *methods);end
end
class Date < Object
include Comparable
include Kernel
def self._load(arg0);end
def self.today(*args);end
def self.parse(*args);end
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
def self.strptime(*args);end
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
def self.strptime(*args);end
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
def leap?();end
def jd();end
def iso8601();end
def start();end
def rfc3339();end
def xmlschema();end
def marshal_dump();end
def marshal_load(arg0);end
def rfc2822();end
def rfc822();end
def httpdate();end
def jisx0301();end
def ajd();end
def mday();end
def day();end
def mon();end
def month();end
def year();end
def wday();end
def yday();end
def amjd();end
def mjd();end
def +(arg0);end
def -(arg0);end
def cweek();end
def cwday();end
def sunday?();end
def monday?();end
def tuesday?();end
def wednesday?();end
def thursday?();end
def step(*args);end
def saturday?();end
def day_fraction();end
def friday?();end
def succ();end
def downto(arg0);end
def ld();end
def julian?();end
def cwyear();end
def new_start(*args);end
def england();end
def julian();end
def gregorian?();end
def prev_day(*args);end
def italy();end
def prev_month(*args);end
def next_year(*args);end
def gregorian();end
def to_datetime();end
def next_month(*args);end
def prev_year(*args);end
def to_time();end
def to_date();end
def next_day(*args);end
def asctime();end
def ctime();end
def strftime(*args);end
def next();end
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
def self.jd(*args);end
def self.ordinal(*args);end
def self.civil(*args);end
def self.commercial(*args);end
def self._strptime(*args);end
def self.strptime(*args);end
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
def self.jd(*args);end
def self.ordinal(*args);end
def self.civil(*args);end
def self.commercial(*args);end
def self._strptime(*args);end
def self.strptime(*args);end
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
def iso8601(*args);end
def rfc3339(*args);end
def xmlschema(*args);end
def jisx0301(*args);end
def minute();end
def sec_fraction();end
def second_fraction();end
def new_offset(*args);end
def to_time();end
def to_date();end
def to_datetime();end
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
class CSV < Object
include Enumerable
include Kernel
def self.read(path, *options);end
def self.foreach(path, options = nil, &block);end
def self.parse(*args);end
def self.table(path, options = nil);end
def self.instance(*args);end
def self.filter(*args);end
def self.generate(*args);end
def self.generate_line(row, options = nil);end
def self.parse_line(line, options = nil);end
def self.def_delegators(accessor, *methods);end
def self.instance_delegate(hash);end
def self.def_instance_delegator(accessor, method, ali = nil);end
def self.def_instance_delegators(accessor, *methods);end
def self.delegate(hash);end
def self.def_delegator(accessor, method, ali = nil);end
def self.read(path, *options);end
def self.foreach(path, options = nil, &block);end
def self.parse(*args);end
def self.table(path, options = nil);end
def self.instance(*args);end
def self.filter(*args);end
def self.generate(*args);end
def self.generate_line(row, options = nil);end
def self.parse_line(line, options = nil);end
def <<(row);end
def read();end
def unconverted_fields?();end
def binmode(*args);end
def return_headers?();end
def write_headers?();end
def skip_blanks?();end
def force_quotes?();end
def flush(*args);end
def stat(*args);end
def add_row(row);end
def header_convert(*args);end
def truncate(*args);end
def headers();end
def each();end
def encoding();end
def header_row?();end
def flock(*args);end
def reopen(*args);end
def to_io(*args);end
def fileno(*args);end
def to_i(*args);end
def fsync(*args);end
def sync(*args);end
def sync=(*args);end
def lineno();end
def string(*args);end
def tell(*args);end
def seek(*args);end
def path(*args);end
def rewind();end
def pos(*args);end
def pos=(*args);end
def eof(*args);end
def eof?(*args);end
def close(*args);end
def closed?(*args);end
def close_read(*args);end
def close_write(*args);end
def isatty(*args);end
def tty?(*args);end
def binmode?(*args);end
def shift();end
def ioctl(*args);end
def fcntl(*args);end
def pid(*args);end
def external_encoding(*args);end
def internal_encoding(*args);end
def col_sep();end
def row_sep();end
def convert(*args);end
def quote_char();end
def field_size_limit();end
def converters();end
def header_converters();end
def skip_lines();end
end
class CSV::Row < Object
include Enumerable
include Kernel
def self.def_delegators(accessor, *methods);end
def self.instance_delegate(hash);end
def self.def_instance_delegator(accessor, method, ali = nil);end
def self.def_instance_delegators(accessor, *methods);end
def self.delegate(hash);end
def self.def_delegator(accessor, method, ali = nil);end
def <<(arg);end
def [](header_or_index, minimum_index = nil);end
def []=(*args);end
def empty?(*args);end
def length(*args);end
def size(*args);end
def each(&block);end
def to_hash();end
def member?(header);end
def index(header, minimum_index = nil);end
def delete(header_or_index, minimum_index = nil);end
def fetch(header, *varargs);end
def push(*args);end
def values_at(*args);end
def delete_if(&block);end
def has_key?(header);end
def key?(header);end
def field(header_or_index, minimum_index = nil);end
def headers();end
def fields(*args);end
def header_row?();end
def field_row?();end
def header?(name);end
def field?(data);end
def to_csv(*args);end
end
class CSV::Table < Object
include Enumerable
include Kernel
def self.def_delegators(accessor, *methods);end
def self.instance_delegate(hash);end
def self.def_instance_delegator(accessor, method, ali = nil);end
def self.def_instance_delegators(accessor, *methods);end
def self.delegate(hash);end
def self.def_delegator(accessor, method, ali = nil);end
def <<(row_or_array);end
def [](index_or_header);end
def []=(index_or_header, value);end
def empty?(*args);end
def length(*args);end
def size(*args);end
def each(&block);end
def to_a();end
def delete(index_or_header);end
def push(*args);end
def values_at(*args);end
def delete_if(&block);end
def mode();end
def headers();end
def to_csv(*args);end
def by_col();end
def by_col!();end
def by_col_or_row();end
def by_col_or_row!();end
def by_row();end
def by_row!();end
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
def header();end
def line();end
def index=(_);end
def line=(_);end
def header=(_);end
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
