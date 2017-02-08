class CGI < Object
include Kernel
def self.parse(query);end
def self.accept_charset();end
def self.accept_charset=(accept_charset);end
def self.escapeHTML(arg0);end
def self.escape(string);end
def self.h(arg0);end
def self.rfc1123_date(time);end
def self.unescape(string, encoding = nil);end
def self.unescapeHTML(string);end
def self.escape_html(arg0);end
def self.unescape_html(string);end
def self.escapeElement(string, *elements);end
def self.unescapeElement(string, *elements);end
def self.escape_element(string, *elements);end
def self.unescape_element(string, *elements);end
def self.pretty(string, shift = nil);end
def self.parse(query);end
def self.accept_charset();end
def self.accept_charset=(accept_charset);end
def out(*args);end
def http_header(*args);end
def header(*args);end
def nph?();end
def accept_charset();end
end
module CGI::QueryExtension
def [](key);end
def include?(*args);end
def keys(*args);end
def has_key?(*args);end
def key?(*args);end
def files();end
def host();end
def from();end
def accept();end
def content_type();end
def params();end
def raw_cookie();end
def raw_cookie2();end
def cookies();end
def params=(hash);end
def content_length();end
def create_body(is_large);end
def unescape_filename?();end
def user_agent();end
def multipart?();end
def accept_charset();end
def server_port();end
def auth_type();end
def gateway_interface();end
def path_info();end
def path_translated();end
def query_string();end
def remote_addr();end
def remote_host();end
def remote_ident();end
def remote_user();end
def request_method();end
def script_name();end
def server_name();end
def server_protocol();end
def server_software();end
def accept_encoding();end
def accept_language();end
def cache_control();end
def negotiate();end
def pragma();end
def referer();end
def cookies=(arg0);end
end
class CGI::InvalidEncoding < Exception
include Kernel
def self.exception(*args);end
end
module CGI::Util
include CGI::Escape
def escape(string);end
def h(arg0);end
def rfc1123_date(time);end
def unescape(string, encoding = nil);end
def escapeHTML(arg0);end
def unescapeHTML(string);end
def escape_html(arg0);end
def unescape_html(string);end
def escapeElement(string, *elements);end
def unescapeElement(string, *elements);end
def escape_element(string, *elements);end
def unescape_element(string, *elements);end
def pretty(string, shift = nil);end
end
module CGI::Escape
def escapeHTML(arg0);end
end
class CGI::Cookie < Array
include Enumerable
include Kernel
def self.parse(raw_cookie);end
def self.[](*args);end
def self.try_convert(arg0);end
def self.parse(raw_cookie);end
def path();end
def value();end
def name=(arg0);end
def value=(val);end
def path=(arg0);end
def expires();end
def domain();end
def secure();end
def httponly();end
def secure=(val);end
def httponly=(val);end
def domain=(arg0);end
def expires=(arg0);end
end
module CGI::HtmlExtension
def form(*args);end
def reset(*args);end
def a(*args);end
def base(*args);end
def blockquote(*args);end
def caption(*args);end
def checkbox(*args);end
def checkbox_group(*args);end
def file_field(*args);end
def hidden(*args);end
def html(*args);end
def image_button(*args);end
def img(*args);end
def multipart_form(*args);end
def password_field(*args);end
def popup_menu(*args);end
def radio_button(*args);end
def radio_group(*args);end
def scrolling_list(*args);end
def submit(*args);end
def text_field(*args);end
def textarea(*args);end
end
