module URI
include URI::RFC2396_REGEXP
def split(uri);end
def join(*args);end
def regexp(*args);end
def parse(uri);end
def scheme_list();end
def extract(str, schemes = nil, &block);end
def encode_www_form_component(str, enc = nil);end
def decode_www_form_component(str, enc = nil);end
def encode_www_form(enum, enc = nil);end
def decode_www_form(str, enc = nil);end
def get_encoding(label);end
def escape(*args);end
def encode(*args);end
def unescape(*args);end
def decode(*args);end
def self.split(uri);end
def self.join(*args);end
def self.regexp(*args);end
def self.parse(uri);end
def self.scheme_list();end
def self.extract(str, schemes = nil, &block);end
def self.encode_www_form_component(str, enc = nil);end
def self.decode_www_form_component(str, enc = nil);end
def self.encode_www_form(enum, enc = nil);end
def self.decode_www_form(str, enc = nil);end
def self.get_encoding(label);end
end
module URI::RFC2396_REGEXP
end
module URI::RFC2396_REGEXP::PATTERN
end
class URI::RFC2396_Parser < Object
include URI::RFC2396_REGEXP
include Kernel
def split(uri);end
def join(*args);end
def escape(str, unsafe = nil);end
def regexp();end
def pattern();end
def parse(uri);end
def unescape(str, escaped = nil);end
def extract(str, schemes = nil);end
def make_regexp(*args);end
end
class URI::RFC3986_Parser < Object
include Kernel
def split(uri);end
def join(*args);end
def regexp();end
def parse(uri);end
end
module URI::Util
def make_components_hash(klass, array_hash);end
def self.make_components_hash(klass, array_hash);end
end
module URI::Escape
def escape(*args);end
def encode(*args);end
def unescape(*args);end
def decode(*args);end
end
class URI::Error < StandardError
include Kernel
def self.exception(*args);end
end
class URI::InvalidURIError < URI::Error
include Kernel
def self.exception(*args);end
end
class URI::InvalidComponentError < URI::Error
include Kernel
def self.exception(*args);end
end
class URI::BadURIError < URI::Error
include Kernel
def self.exception(*args);end
end
class URI::Generic < Object
include URI
include URI::RFC2396_REGEXP
include Kernel
def self.component();end
def self.default_port();end
def self.use_registry();end
def self.build2(args);end
def self.build(args);end
def self.component();end
def self.default_port();end
def self.use_registry();end
def self.build2(args);end
def self.build(args);end
def find_proxy();end
def parser();end
def coerce(oth);end
def merge!(oth);end
def merge(oth);end
def path=(v);end
def +(oth);end
def -(oth);end
def default_port();end
def normalize();end
def host();end
def host=(v);end
def component();end
def scheme=(v);end
def userinfo=(userinfo);end
def hostname=(v);end
def port=(v);end
def query=(v);end
def opaque=(v);end
def fragment=(v);end
def relative?();end
def password();end
def scheme();end
def user=(user);end
def password=(password);end
def path();end
def userinfo();end
def hostname();end
def port();end
def registry=(v);end
def absolute?();end
def hierarchical?();end
def opaque();end
def registry();end
def query();end
def fragment();end
def absolute();end
def route_from(oth);end
def route_to(oth);end
def normalize!();end
def user();end
end
class URI::FTP < URI::Generic
include OpenURI::OpenRead
include URI
include URI::RFC2396_REGEXP
include Kernel
def self.build(args);end
def self.new2(user, password, host, port, path, typecode = nil, arg_check = nil);end
def self.component();end
def self.default_port();end
def self.use_registry();end
def self.build2(args);end
def self.build(args);end
def self.new2(user, password, host, port, path, typecode = nil, arg_check = nil);end
def path();end
def merge(oth);end
def buffer_open(buf, proxy, options);end
def typecode();end
def typecode=(typecode);end
end
class URI::HTTP < URI::Generic
include OpenURI::OpenRead
include URI
include URI::RFC2396_REGEXP
include Kernel
def self.build(args);end
def self.component();end
def self.default_port();end
def self.use_registry();end
def self.build2(args);end
def self.build(args);end
def buffer_open(buf, proxy, options);end
def request_uri();end
end
class URI::HTTPS < URI::HTTP
include OpenURI::OpenRead
include URI
include URI::RFC2396_REGEXP
include Kernel
def self.build(args);end
def self.component();end
def self.default_port();end
def self.use_registry();end
def self.build2(args);end
end
class URI::LDAP < URI::Generic
include URI
include URI::RFC2396_REGEXP
include Kernel
def self.build(args);end
def self.component();end
def self.default_port();end
def self.use_registry();end
def self.build2(args);end
def self.build(args);end
def extensions();end
def attributes();end
def extensions=(val);end
def scope();end
def hierarchical?();end
def dn();end
def filter();end
def dn=(val);end
def attributes=(val);end
def scope=(val);end
def filter=(val);end
end
class URI::LDAPS < URI::LDAP
include URI
include URI::RFC2396_REGEXP
include Kernel
def self.build(args);end
def self.component();end
def self.default_port();end
def self.use_registry();end
def self.build2(args);end
end
class URI::MailTo < URI::Generic
include URI
include URI::RFC2396_REGEXP
include Kernel
def self.build(args);end
def self.component();end
def self.default_port();end
def self.use_registry();end
def self.build2(args);end
def self.build(args);end
def to();end
def headers();end
def to=(v);end
def headers=(v);end
def to_mailtext();end
def to_rfc822text();end
end
class Date < Object
include Comparable
include Kernel
def self._load(arg0);end
def self.today(*args);end
def self.parse(*args);end
def self.httpdate(*args);end
def self._parse(*args);end
def self.strptime(*args);end
def self._strptime(*args);end
def self.rfc2822(*args);end
def self.rfc822(*args);end
def self.xmlschema(*args);end
def self.iso8601(*args);end
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
def self._iso8601(arg0);end
def self._rfc3339(arg0);end
def self.rfc3339(*args);end
def self._xmlschema(arg0);end
def self._rfc2822(arg0);end
def self._rfc822(arg0);end
def self._httpdate(arg0);end
def self._jisx0301(arg0);end
def self.jisx0301(*args);end
def self._load(arg0);end
def self.today(*args);end
def self.parse(*args);end
def self.httpdate(*args);end
def self._parse(*args);end
def self.strptime(*args);end
def self._strptime(*args);end
def self.rfc2822(*args);end
def self.rfc822(*args);end
def self.xmlschema(*args);end
def self.iso8601(*args);end
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
def self._iso8601(arg0);end
def self._rfc3339(arg0);end
def self.rfc3339(*args);end
def self._xmlschema(arg0);end
def self._rfc2822(arg0);end
def self._rfc822(arg0);end
def self._httpdate(arg0);end
def self._jisx0301(arg0);end
def self.jisx0301(*args);end
def gregorian();end
def prev_day(*args);end
def next_day(*args);end
def prev_month(*args);end
def next_month(*args);end
def prev_year(*args);end
def <<(arg0);end
def >>(arg0);end
def next_year(*args);end
def to_date();end
def to_datetime();end
def to_time();end
def start();end
def marshal_dump();end
def marshal_load(arg0);end
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
def strftime(*args);end
def rfc2822();end
def rfc822();end
def xmlschema();end
def iso8601();end
def httpdate();end
def leap?();end
def jd();end
def rfc3339();end
def jisx0301();end
def ajd();end
def amjd();end
def mjd();end
def ld();end
def day_fraction();end
def cwyear();end
def next();end
def cweek();end
def cwday();end
def julian?();end
def gregorian?();end
def new_start(*args);end
def italy();end
def upto(arg0);end
def julian();end
def england();end
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
def self.httpdate(*args);end
def self.strptime(*args);end
def self._strptime(*args);end
def self.rfc2822(*args);end
def self.rfc822(*args);end
def self.xmlschema(*args);end
def self.iso8601(*args);end
def self.jd(*args);end
def self.ordinal(*args);end
def self.civil(*args);end
def self.commercial(*args);end
def self.rfc3339(*args);end
def self.jisx0301(*args);end
def self._load(arg0);end
def self._parse(*args);end
def self.valid_jd?(*args);end
def self.valid_ordinal?(*args);end
def self.valid_civil?(*args);end
def self.valid_date?(*args);end
def self.valid_commercial?(*args);end
def self.julian_leap?(arg0);end
def self.gregorian_leap?(arg0);end
def self.leap?(arg0);end
def self._iso8601(arg0);end
def self._rfc3339(arg0);end
def self._xmlschema(arg0);end
def self._rfc2822(arg0);end
def self._rfc822(arg0);end
def self._httpdate(arg0);end
def self._jisx0301(arg0);end
def self.now(*args);end
def self.parse(*args);end
def self.httpdate(*args);end
def self.strptime(*args);end
def self._strptime(*args);end
def self.rfc2822(*args);end
def self.rfc822(*args);end
def self.xmlschema(*args);end
def self.iso8601(*args);end
def self.jd(*args);end
def self.ordinal(*args);end
def self.civil(*args);end
def self.commercial(*args);end
def self.rfc3339(*args);end
def self.jisx0301(*args);end
def min();end
def offset();end
def zone();end
def sec();end
def hour();end
def strftime(*args);end
def second();end
def sec_fraction();end
def xmlschema(*args);end
def iso8601(*args);end
def rfc3339(*args);end
def jisx0301(*args);end
def minute();end
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
module OpenURI
def check_options(options);end
def scan_open_optional_arguments(*args);end
def open_uri(name, *rest);end
def open_loop(uri, options);end
def redirectable?(uri1, uri2);end
def open_http(buf, target, proxy, options);end
def self.check_options(options);end
def self.scan_open_optional_arguments(*args);end
def self.open_uri(name, *rest);end
def self.open_loop(uri, options);end
def self.redirectable?(uri1, uri2);end
def self.open_http(buf, target, proxy, options);end
end
class OpenURI::HTTPError < StandardError
include Kernel
def self.exception(*args);end
def io();end
end
class OpenURI::HTTPRedirect < OpenURI::HTTPError
include Kernel
def self.exception(*args);end
def uri();end
end
class OpenURI::Buffer < Object
include Kernel
def <<(str);end
def size();end
def io();end
end
module OpenURI::Meta
def init(obj, src = nil);end
def self.init(obj, src = nil);end
def status();end
def base_uri();end
def base_uri=(arg0);end
def status=(arg0);end
def meta_add_field2(name, values);end
def metas();end
def meta();end
def meta_setup_encoding();end
def charset();end
def meta_add_field(name, value);end
def last_modified();end
def content_type_parse();end
def content_type();end
def content_encoding();end
end
module OpenURI::OpenRead
def read(*args);end
def open(*args);end
end
