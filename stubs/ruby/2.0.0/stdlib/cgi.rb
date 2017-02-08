class CGI < Object
include Kernel
def self.parse(query);end
def self.accept_charset();end
def self.accept_charset=(accept_charset);end
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
def self.parse(query);end
def self.accept_charset();end
def self.accept_charset=(accept_charset);end
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
def http_header(*args);end
def header(*args);end
def nph?();end
def out(*args);end
def accept_charset();end
end
module CGI::QueryExtension
def content_length();end
def server_port();end
def auth_type();end
def content_type();end
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
def accept();end
def accept_charset();end
def accept_encoding();end
def accept_language();end
def cache_control();end
def from();end
def host();end
def negotiate();end
def pragma();end
def referer();end
def user_agent();end
def raw_cookie();end
def raw_cookie2();end
def cookies();end
def cookies=(arg0);end
def params();end
def files();end
def params=(hash);end
def create_body(is_large);end
def unescape_filename?();end
def multipart?();end
def [](key);end
def keys(*args);end
def has_key?(*args);end
def key?(*args);end
def include?(*args);end
end
class CGI::InvalidEncoding < Exception
include Kernel
def self.exception(*args);end
end
class CGI::Cookie < Array
include Enumerable
include Kernel
def self.parse(raw_cookie);end
def self.[](*args);end
def self.try_convert(arg0);end
def self.parse(raw_cookie);end
def name=(arg0);end
def path();end
def path=(arg0);end
def domain();end
def domain=(arg0);end
def expires();end
def expires=(arg0);end
def secure();end
def value();end
def value=(val);end
def secure=(val);end
end
module CGI::HtmlExtension
def a(*args);end
def base(*args);end
def blockquote(*args);end
def caption(*args);end
def checkbox(*args);end
def checkbox_group(*args);end
def file_field(*args);end
def form(*args);end
def hidden(*args);end
def html(*args);end
def image_button(*args);end
def img(*args);end
def multipart_form(*args);end
def password_field(*args);end
def popup_menu(*args);end
def radio_button(*args);end
def radio_group(*args);end
def reset(*args);end
def scrolling_list(*args);end
def submit(*args);end
def text_field(*args);end
def textarea(*args);end
end
