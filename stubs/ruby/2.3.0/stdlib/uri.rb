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
def hostname();end
def parser();end
def coerce(oth);end
def merge!(oth);end
def merge(oth);end
def path=(v);end
def +(oth);end
def -(oth);end
def normalize();end
def default_port();end
def host();end
def component();end
def host=(v);end
def scheme();end
def scheme=(v);end
def userinfo=(userinfo);end
def hostname=(v);end
def port=(v);end
def query=(v);end
def opaque=(v);end
def fragment=(v);end
def user();end
def password();end
def user=(user);end
def path();end
def password=(password);end
def registry=(v);end
def hierarchical?();end
def absolute?();end
def absolute();end
def opaque();end
def userinfo();end
def port();end
def registry();end
def query();end
def fragment();end
def relative?();end
def route_from(oth);end
def route_to(oth);end
def normalize!();end
end
class URI::FTP < URI::Generic
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
def typecode();end
def typecode=(typecode);end
end
class URI::HTTP < URI::Generic
include URI
include URI::RFC2396_REGEXP
include Kernel
def self.build(args);end
def self.component();end
def self.default_port();end
def self.use_registry();end
def self.build2(args);end
def self.build(args);end
def request_uri();end
end
class URI::HTTPS < URI::HTTP
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
