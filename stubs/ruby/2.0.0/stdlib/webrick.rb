module WEBrick
end
class WEBrick::HTTPVersion < Object
include Comparable
include Kernel
def self.convert(version);end
def self.convert(version);end
def major();end
def major=(arg0);end
def minor();end
def minor=(arg0);end
end
module WEBrick::HTTPUtils
def normalize_path(path);end
def load_mime_types(file);end
def mime_type(filename, mime_tab);end
def parse_header(raw);end
def split_header_value(str);end
def parse_range_header(ranges_specifier);end
def parse_qvalues(value);end
def dequote(str);end
def quote(str);end
def parse_query(str);end
def parse_form_data(io, boundary);end
def _make_regex(str);end
def _make_regex!(str);end
def _escape(str, regex);end
def _unescape(str, regex);end
def escape(str);end
def unescape(str);end
def escape_form(str);end
def unescape_form(str);end
def escape_path(str);end
def escape8bit(str);end
def self.normalize_path(path);end
def self.load_mime_types(file);end
def self.mime_type(filename, mime_tab);end
def self.parse_header(raw);end
def self.split_header_value(str);end
def self.parse_range_header(ranges_specifier);end
def self.parse_qvalues(value);end
def self.dequote(str);end
def self.quote(str);end
def self.parse_query(str);end
def self.parse_form_data(io, boundary);end
def self._make_regex(str);end
def self._make_regex!(str);end
def self._escape(str, regex);end
def self._unescape(str, regex);end
def self.escape(str);end
def self.unescape(str);end
def self.escape_form(str);end
def self.unescape_form(str);end
def self.escape_path(str);end
def self.escape8bit(str);end
end
class WEBrick::HTTPUtils::FormData < String
include Comparable
include Kernel
def self.try_convert(arg0);end
def name=(arg0);end
def filename();end
def filename=(arg0);end
def next_data=(arg0);end
def [](*args);end
def <<(str);end
def append_data(data);end
def each_data();end
def list();end
def to_ary();end
end
module WEBrick::Utils
def set_non_blocking(io);end
def set_close_on_exec(io);end
def su(user);end
def getservername();end
def create_listeners(address, port, logger = nil);end
def random_string(len);end
def timeout(seconds, exception = nil);end
def self.set_non_blocking(io);end
def self.set_close_on_exec(io);end
def self.su(user);end
def self.getservername();end
def self.create_listeners(address, port, logger = nil);end
def self.random_string(len);end
def self.timeout(seconds, exception = nil);end
end
class WEBrick::Utils::TimeoutHandler < Object
include Singleton
include Kernel
def self.instance();end
def self.register(seconds, exception);end
def self.cancel(id);end
def self._load(str);end
def self.instance();end
def self.register(seconds, exception);end
def self.cancel(id);end
def interrupt(thread, id, exception);end
def register(thread, time, exception);end
def cancel(thread, id);end
end
module Singleton::SingletonClassMethods
def clone();end
def _load(str);end
end
class WEBrick::BasicLog < Object
include Kernel
def level();end
def level=(arg0);end
def close();end
def log(level, data);end
def <<(obj);end
def fatal(msg);end
def error(msg);end
def info(msg);end
def debug(msg);end
def fatal?();end
def error?();end
def warn?();end
def info?();end
def debug?();end
end
class WEBrick::Log < WEBrick::BasicLog
include Kernel
def time_format();end
def time_format=(arg0);end
def log(level, data);end
end
module WEBrick::Config
end
class WEBrick::ServerError < StandardError
include Kernel
def self.exception(*args);end
end
class WEBrick::SimpleServer < Object
include Kernel
def self.start();end
def self.start();end
end
class WEBrick::Daemon < Object
include Kernel
def self.start();end
def self.start();end
end
class WEBrick::GenericServer < Object
include Kernel
def status();end
def config();end
def logger();end
def tokens();end
def listeners();end
def [](key);end
def listen(address, port);end
def start(&block);end
def stop();end
def shutdown();end
def run(sock);end
end
module WEBrick::AccessLog
def setup_params(config, req, res);end
def escape(data);end
def self.setup_params(config, req, res);end
def self.escape(data);end
end
class WEBrick::AccessLog::AccessLogError < StandardError
include Kernel
def self.exception(*args);end
end
module WEBrick::HTMLUtils
def escape(string);end
def self.escape(string);end
end
class WEBrick::Cookie < Object
include Kernel
def self.parse(str);end
def self.parse_set_cookie(str);end
def self.parse_set_cookies(str);end
def self.parse(str);end
def self.parse_set_cookie(str);end
def self.parse_set_cookies(str);end
def value();end
def value=(arg0);end
def version();end
def version=(arg0);end
def domain();end
def domain=(arg0);end
def path();end
def path=(arg0);end
def secure();end
def secure=(arg0);end
def comment();end
def comment=(arg0);end
def max_age();end
def max_age=(arg0);end
def expires=(t);end
def expires();end
end
module WEBrick::HTTPStatus
def [](code);end
def reason_phrase(code);end
def info?(code);end
def success?(code);end
def redirect?(code);end
def error?(code);end
def client_error?(code);end
def server_error?(code);end
def self.[](code);end
def self.reason_phrase(code);end
def self.info?(code);end
def self.success?(code);end
def self.redirect?(code);end
def self.error?(code);end
def self.client_error?(code);end
def self.server_error?(code);end
end
class WEBrick::HTTPStatus::Status < StandardError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
def self.code();end
def self.reason_phrase();end
def code();end
def reason_phrase();end
def to_i();end
end
class WEBrick::HTTPStatus::Info < WEBrick::HTTPStatus::Status
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::Success < WEBrick::HTTPStatus::Status
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::Redirect < WEBrick::HTTPStatus::Status
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::Error < WEBrick::HTTPStatus::Status
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::ClientError < WEBrick::HTTPStatus::Error
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::ServerError < WEBrick::HTTPStatus::Error
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::EOFError < StandardError
include Kernel
def self.exception(*args);end
end
class WEBrick::HTTPStatus::Continue < WEBrick::HTTPStatus::Info
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::SwitchingProtocols < WEBrick::HTTPStatus::Info
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::OK < WEBrick::HTTPStatus::Success
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::Created < WEBrick::HTTPStatus::Success
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::Accepted < WEBrick::HTTPStatus::Success
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::NonAuthoritativeInformation < WEBrick::HTTPStatus::Success
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::NoContent < WEBrick::HTTPStatus::Success
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::ResetContent < WEBrick::HTTPStatus::Success
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::PartialContent < WEBrick::HTTPStatus::Success
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::MultiStatus < WEBrick::HTTPStatus::Success
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::MultipleChoices < WEBrick::HTTPStatus::Redirect
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::MovedPermanently < WEBrick::HTTPStatus::Redirect
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::Found < WEBrick::HTTPStatus::Redirect
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::SeeOther < WEBrick::HTTPStatus::Redirect
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::NotModified < WEBrick::HTTPStatus::Redirect
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::UseProxy < WEBrick::HTTPStatus::Redirect
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::TemporaryRedirect < WEBrick::HTTPStatus::Redirect
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::BadRequest < WEBrick::HTTPStatus::ClientError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::Unauthorized < WEBrick::HTTPStatus::ClientError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::PaymentRequired < WEBrick::HTTPStatus::ClientError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::Forbidden < WEBrick::HTTPStatus::ClientError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::NotFound < WEBrick::HTTPStatus::ClientError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::MethodNotAllowed < WEBrick::HTTPStatus::ClientError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::NotAcceptable < WEBrick::HTTPStatus::ClientError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::ProxyAuthenticationRequired < WEBrick::HTTPStatus::ClientError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::RequestTimeout < WEBrick::HTTPStatus::ClientError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::Conflict < WEBrick::HTTPStatus::ClientError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::Gone < WEBrick::HTTPStatus::ClientError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::LengthRequired < WEBrick::HTTPStatus::ClientError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::PreconditionFailed < WEBrick::HTTPStatus::ClientError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::RequestEntityTooLarge < WEBrick::HTTPStatus::ClientError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::RequestURITooLarge < WEBrick::HTTPStatus::ClientError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::UnsupportedMediaType < WEBrick::HTTPStatus::ClientError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::RequestRangeNotSatisfiable < WEBrick::HTTPStatus::ClientError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::ExpectationFailed < WEBrick::HTTPStatus::ClientError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::UnprocessableEntity < WEBrick::HTTPStatus::ClientError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::Locked < WEBrick::HTTPStatus::ClientError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::FailedDependency < WEBrick::HTTPStatus::ClientError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::UpgradeRequired < WEBrick::HTTPStatus::ClientError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::PreconditionRequired < WEBrick::HTTPStatus::ClientError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::TooManyRequests < WEBrick::HTTPStatus::ClientError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::RequestHeaderFieldsTooLarge < WEBrick::HTTPStatus::ClientError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::InternalServerError < WEBrick::HTTPStatus::ServerError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::NotImplemented < WEBrick::HTTPStatus::ServerError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::BadGateway < WEBrick::HTTPStatus::ServerError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::ServiceUnavailable < WEBrick::HTTPStatus::ServerError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::GatewayTimeout < WEBrick::HTTPStatus::ServerError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::HTTPVersionNotSupported < WEBrick::HTTPStatus::ServerError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::InsufficientStorage < WEBrick::HTTPStatus::ServerError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPStatus::NetworkAuthenticationRequired < WEBrick::HTTPStatus::ServerError
include Kernel
def self.code();end
def self.reason_phrase();end
def self.exception(*args);end
end
class WEBrick::HTTPRequest < Object
include Kernel
def request_line();end
def request_method();end
def unparsed_uri();end
def http_version();end
def request_uri();end
def path();end
def script_name();end
def script_name=(arg0);end
def path_info();end
def path_info=(arg0);end
def query_string();end
def query_string=(arg0);end
def raw_header();end
def header();end
def cookies();end
def accept();end
def accept_charset();end
def accept_encoding();end
def accept_language();end
def user();end
def user=(arg0);end
def addr();end
def peeraddr();end
def attributes();end
def keep_alive();end
def request_time();end
def parse(*args);end
def continue();end
def body(&block);end
def query();end
def content_length();end
def content_type();end
def [](header_name);end
def each();end
def host();end
def port();end
def server_name();end
def remote_ip();end
def ssl?();end
def keep_alive?();end
def fixup();end
def meta_vars();end
end
class WEBrick::HTTPResponse < Object
include Kernel
def http_version();end
def status();end
def header();end
def cookies();end
def reason_phrase();end
def reason_phrase=(arg0);end
def body();end
def body=(arg0);end
def request_method();end
def request_method=(arg0);end
def request_uri();end
def request_uri=(arg0);end
def request_http_version();end
def request_http_version=(arg0);end
def filename();end
def filename=(arg0);end
def keep_alive();end
def keep_alive=(arg0);end
def config();end
def sent_size();end
def status_line();end
def status=(status);end
def [](field);end
def []=(field, value);end
def content_length();end
def content_length=(len);end
def content_type();end
def content_type=(type);end
def each();end
def chunked?();end
def chunked=(val);end
def keep_alive?();end
def send_response(socket);end
def setup_header();end
def send_header(socket);end
def send_body(socket);end
def set_redirect(status, url);end
def set_error(ex, backtrace = nil);end
end
module WEBrick::HTTPServlet
end
class WEBrick::HTTPServlet::HTTPServletError < StandardError
include Kernel
def self.exception(*args);end
end
class WEBrick::HTTPServlet::AbstractServlet < Object
include Kernel
def self.get_instance(server, *options);end
def self.get_instance(server, *options);end
def service(req, res);end
def do_GET(req, res);end
def do_HEAD(req, res);end
def do_OPTIONS(req, res);end
end
class WEBrick::HTTPServlet::DefaultFileHandler < WEBrick::HTTPServlet::AbstractServlet
include Kernel
def self.get_instance(server, *options);end
def do_GET(req, res);end
def not_modified?(req, res, mtime, etag);end
def make_partial_content(req, res, filename, filesize);end
def prepare_range(range, filesize);end
end
class WEBrick::HTTPServlet::FileHandler < WEBrick::HTTPServlet::AbstractServlet
include Kernel
def self.add_handler(suffix, handler);end
def self.remove_handler(suffix);end
def self.get_instance(server, *options);end
def self.add_handler(suffix, handler);end
def self.remove_handler(suffix);end
def service(req, res);end
def do_GET(req, res);end
def do_POST(req, res);end
def do_OPTIONS(req, res);end
end
class WEBrick::HTTPServlet::CGIHandler < WEBrick::HTTPServlet::AbstractServlet
include Kernel
def self.get_instance(server, *options);end
def do_GET(req, res);end
def do_POST(req, res);end
end
class WEBrick::HTTPServlet::ERBHandler < WEBrick::HTTPServlet::AbstractServlet
include Kernel
def self.get_instance(server, *options);end
def do_GET(req, res);end
def do_POST(req, res);end
end
class WEBrick::HTTPServlet::ProcHandler < WEBrick::HTTPServlet::AbstractServlet
include Kernel
def self.get_instance(server, *options);end
def get_instance(server, *options);end
def do_GET(request, response);end
def do_POST(request, response);end
end
class WEBrick::HTTPServerError < WEBrick::ServerError
include Kernel
def self.exception(*args);end
end
class WEBrick::HTTPServer < WEBrick::GenericServer
include Kernel
def run(sock);end
def service(req, res);end
def do_OPTIONS(req, res);end
def mount(dir, servlet, *options);end
def mount_proc(dir, proc = nil, &block);end
def unmount(dir);end
def umount(dir);end
def search_servlet(path);end
def virtual_host(server);end
def lookup_server(req);end
def access_log(config, req, res);end
end
class WEBrick::HTTPServer::MountTable < Object
include Kernel
def [](dir);end
def []=(dir, val);end
def delete(dir);end
def scan(path);end
end
module WEBrick::HTTPAuth
def _basic_auth(req, res, realm, req_field, res_field, err_type, block);end
def basic_auth(req, res, realm, &block);end
def proxy_basic_auth(req, res, realm, &block);end
def self._basic_auth(req, res, realm, req_field, res_field, err_type, block);end
def self.basic_auth(req, res, realm, &block);end
def self.proxy_basic_auth(req, res, realm, &block);end
end
module WEBrick::HTTPAuth::Authenticator
def realm();end
def userdb();end
def logger();end
end
module WEBrick::HTTPAuth::ProxyAuthenticator
end
class WEBrick::HTTPAuth::BasicAuth < Object
include WEBrick::HTTPAuth::Authenticator
include Kernel
def self.make_passwd(realm, user, pass);end
def self.make_passwd(realm, user, pass);end
def realm();end
def userdb();end
def logger();end
def authenticate(req, res);end
def challenge(req, res);end
end
class WEBrick::HTTPAuth::ProxyBasicAuth < WEBrick::HTTPAuth::BasicAuth
include WEBrick::HTTPAuth::ProxyAuthenticator
include WEBrick::HTTPAuth::Authenticator
include Kernel
def self.make_passwd(realm, user, pass);end
end
class WEBrick::HTTPAuth::DigestAuth < Object
include WEBrick::HTTPAuth::Authenticator
include Kernel
def self.make_passwd(realm, user, pass);end
def self.make_passwd(realm, user, pass);end
def algorithm();end
def qop();end
def authenticate(req, res);end
def challenge(req, res, stale = nil);end
end
class WEBrick::HTTPAuth::DigestAuth::OpaqueInfo < Struct
include Enumerable
include Kernel
def self.[](*args);end
def self.members();end
def self.[](*args);end
def self.members();end
def time();end
def time=(arg0);end
def nonce();end
def nonce=(arg0);end
def nc();end
def nc=(arg0);end
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
class Struct::Passwd < Struct
include Enumerable
include Kernel
def self.[](*args);end
def self.members();end
def self.each();end
def self.to_a(*args);end
def self.entries(*args);end
def self.sort();end
def self.sort_by();end
def self.grep(arg0);end
def self.count(*args);end
def self.find(*args);end
def self.detect(*args);end
def self.find_index(*args);end
def self.find_all();end
def self.reject();end
def self.collect();end
def self.map();end
def self.flat_map();end
def self.collect_concat();end
def self.inject(*args);end
def self.reduce(*args);end
def self.partition();end
def self.group_by();end
def self.first(*args);end
def self.all?();end
def self.any?();end
def self.one?();end
def self.none?();end
def self.min();end
def self.max();end
def self.minmax();end
def self.min_by();end
def self.max_by();end
def self.minmax_by();end
def self.member?(arg0);end
def self.each_with_index(*args);end
def self.reverse_each(*args);end
def self.each_entry(*args);end
def self.each_slice(arg0);end
def self.each_cons(arg0);end
def self.each_with_object(arg0);end
def self.zip(*args);end
def self.take(arg0);end
def self.take_while();end
def self.drop(arg0);end
def self.drop_while();end
def self.cycle(*args);end
def self.chunk(*args);end
def self.slice_before(*args);end
def self.lazy();end
def self.[](*args);end
def self.members();end
def self.each();end
def name=(arg0);end
def passwd();end
def passwd=(arg0);end
def uid();end
def uid=(arg0);end
def gid();end
def gid=(arg0);end
def gecos();end
def gecos=(arg0);end
def dir();end
def dir=(arg0);end
def shell();end
def shell=(arg0);end
end
class Struct::Group < Struct
include Enumerable
include Kernel
def self.[](*args);end
def self.members();end
def self.each();end
def self.to_a(*args);end
def self.entries(*args);end
def self.sort();end
def self.sort_by();end
def self.grep(arg0);end
def self.count(*args);end
def self.find(*args);end
def self.detect(*args);end
def self.find_index(*args);end
def self.find_all();end
def self.reject();end
def self.collect();end
def self.map();end
def self.flat_map();end
def self.collect_concat();end
def self.inject(*args);end
def self.reduce(*args);end
def self.partition();end
def self.group_by();end
def self.first(*args);end
def self.all?();end
def self.any?();end
def self.one?();end
def self.none?();end
def self.min();end
def self.max();end
def self.minmax();end
def self.min_by();end
def self.max_by();end
def self.minmax_by();end
def self.member?(arg0);end
def self.each_with_index(*args);end
def self.reverse_each(*args);end
def self.each_entry(*args);end
def self.each_slice(arg0);end
def self.each_cons(arg0);end
def self.each_with_object(arg0);end
def self.zip(*args);end
def self.take(arg0);end
def self.take_while();end
def self.drop(arg0);end
def self.drop_while();end
def self.cycle(*args);end
def self.chunk(*args);end
def self.slice_before(*args);end
def self.lazy();end
def self.[](*args);end
def self.members();end
def self.each();end
def name=(arg0);end
def passwd();end
def passwd=(arg0);end
def gid();end
def gid=(arg0);end
def mem();end
def mem=(arg0);end
end
class WEBrick::HTTPAuth::ProxyDigestAuth < WEBrick::HTTPAuth::DigestAuth
include WEBrick::HTTPAuth::ProxyAuthenticator
include WEBrick::HTTPAuth::Authenticator
include Kernel
def self.make_passwd(realm, user, pass);end
end
module WEBrick::HTTPAuth::UserDB
def auth_type();end
def auth_type=(arg0);end
def make_passwd(realm, user, pass);end
def set_passwd(realm, user, pass);end
def get_passwd(realm, user, reload_db = nil);end
end
class WEBrick::HTTPAuth::Htpasswd < Object
include WEBrick::HTTPAuth::UserDB
include Kernel
def reload();end
def flush(*args);end
def get_passwd(realm, user, reload_db);end
def set_passwd(realm, user, pass);end
def delete_passwd(realm, user);end
def each();end
end
class WEBrick::HTTPAuth::Htdigest < Object
include WEBrick::HTTPAuth::UserDB
include Kernel
def reload();end
def flush(*args);end
def get_passwd(realm, user, reload_db);end
def set_passwd(realm, user, pass);end
def delete_passwd(realm, user);end
def each();end
end
class WEBrick::HTTPAuth::Htgroup < Object
include Kernel
def reload();end
def flush(*args);end
def members(group);end
def add(group, members);end
end
class BasicSocket < IO
include File::Constants
include Enumerable
include Kernel
def self.do_not_reverse_lookup();end
def self.do_not_reverse_lookup=(arg0);end
def self.for_fd(arg0);end
def self.sysopen(*args);end
def self.popen(*args);end
def self.foreach(*args);end
def self.read(*args);end
def self.binread(*args);end
def self.write(*args);end
def self.binwrite(*args);end
def self.pipe(*args);end
def self.try_convert(arg0);end
def self.copy_stream(*args);end
def self.do_not_reverse_lookup();end
def self.do_not_reverse_lookup=(arg0);end
def self.for_fd(arg0);end
def close_read();end
def close_write();end
def shutdown(*args);end
def setsockopt(*args);end
def getsockopt(arg0, arg1);end
def getsockname();end
def getpeername();end
def getpeereid();end
def local_address();end
def remote_address();end
def recv(*args);end
def recv_nonblock(*args);end
def do_not_reverse_lookup();end
def do_not_reverse_lookup=(arg0);end
def sendmsg(*args);end
def sendmsg_nonblock(*args);end
def recvmsg(*args);end
def recvmsg_nonblock(*args);end
def connect_address();end
end
module IO::WaitReadable
end
module IO::WaitWritable
end
class Socket < BasicSocket
include File::Constants
include Enumerable
include Kernel
def self.socketpair(*args);end
def self.pair(*args);end
def self.gethostname();end
def self.gethostbyname(arg0);end
def self.gethostbyaddr(*args);end
def self.getservbyname(*args);end
def self.getservbyport(*args);end
def self.getaddrinfo(*args);end
def self.getnameinfo(*args);end
def self.sockaddr_in(arg0, arg1);end
def self.pack_sockaddr_in(arg0, arg1);end
def self.unpack_sockaddr_in(arg0);end
def self.sockaddr_un(arg0);end
def self.pack_sockaddr_un(arg0);end
def self.unpack_sockaddr_un(arg0);end
def self.ip_address_list();end
def self.tcp(host, port, *rest);end
def self.tcp_server_sockets(host = nil, port);end
def self.accept_loop(*args);end
def self.tcp_server_loop(host = nil, port, &b);end
def self.udp_server_sockets(host = nil, port);end
def self.udp_server_recv(sockets);end
def self.udp_server_loop_on(sockets, &b);end
def self.udp_server_loop(host = nil, port, &b);end
def self.unix(path);end
def self.unix_server_socket(path);end
def self.unix_server_loop(path, &b);end
def self.do_not_reverse_lookup();end
def self.do_not_reverse_lookup=(arg0);end
def self.for_fd(arg0);end
def self.sysopen(*args);end
def self.popen(*args);end
def self.foreach(*args);end
def self.read(*args);end
def self.binread(*args);end
def self.write(*args);end
def self.binwrite(*args);end
def self.pipe(*args);end
def self.try_convert(arg0);end
def self.copy_stream(*args);end
def self.socketpair(*args);end
def self.pair(*args);end
def self.gethostname();end
def self.gethostbyname(arg0);end
def self.gethostbyaddr(*args);end
def self.getservbyname(*args);end
def self.getservbyport(*args);end
def self.getaddrinfo(*args);end
def self.getnameinfo(*args);end
def self.sockaddr_in(arg0, arg1);end
def self.pack_sockaddr_in(arg0, arg1);end
def self.unpack_sockaddr_in(arg0);end
def self.sockaddr_un(arg0);end
def self.pack_sockaddr_un(arg0);end
def self.unpack_sockaddr_un(arg0);end
def self.ip_address_list();end
def self.tcp(host, port, *rest);end
def self.tcp_server_sockets(host = nil, port);end
def self.accept_loop(*args);end
def self.tcp_server_loop(host = nil, port, &b);end
def self.udp_server_sockets(host = nil, port);end
def self.udp_server_recv(sockets);end
def self.udp_server_loop_on(sockets, &b);end
def self.udp_server_loop(host = nil, port, &b);end
def self.unix(path);end
def self.unix_server_socket(path);end
def self.unix_server_loop(path, &b);end
def connect(arg0);end
def connect_nonblock(arg0);end
def bind(arg0);end
def listen(arg0);end
def accept();end
def accept_nonblock();end
def sysaccept();end
def recvfrom(*args);end
def recvfrom_nonblock(*args);end
def ipv6only!();end
end
class Socket::Option < Object
include Kernel
def self.int(arg0, arg1, arg2, arg3);end
def self.bool(arg0, arg1, arg2, arg3);end
def self.linger(arg0, arg1);end
def self.int(arg0, arg1, arg2, arg3);end
def self.bool(arg0, arg1, arg2, arg3);end
def self.linger(arg0, arg1);end
def family();end
def level();end
def optname();end
def data();end
def int();end
def bool();end
def linger();end
def unpack(arg0);end
end
class Socket::AncillaryData < Object
include Kernel
def self.int(arg0, arg1, arg2, arg3);end
def self.unix_rights(*args);end
def self.ip_pktinfo(*args);end
def self.ipv6_pktinfo(arg0, arg1);end
def self.int(arg0, arg1, arg2, arg3);end
def self.unix_rights(*args);end
def self.ip_pktinfo(*args);end
def self.ipv6_pktinfo(arg0, arg1);end
def family();end
def level();end
def type();end
def data();end
def cmsg_is?(arg0, arg1);end
def int();end
def unix_rights();end
def timestamp();end
def ip_pktinfo();end
def ipv6_pktinfo();end
def ipv6_pktinfo_addr();end
def ipv6_pktinfo_ifindex();end
end
module Socket::Constants
end
class Socket::UDPSource < Object
include Kernel
def remote_address();end
def local_address();end
def reply(msg);end
end
module IO::WaitReadable
end
module IO::WaitWritable
end
class SocketError < StandardError
include Kernel
def self.exception(*args);end
end
class IPSocket < BasicSocket
include File::Constants
include Enumerable
include Kernel
def self.getaddress(arg0);end
def self.do_not_reverse_lookup();end
def self.do_not_reverse_lookup=(arg0);end
def self.for_fd(arg0);end
def self.sysopen(*args);end
def self.popen(*args);end
def self.foreach(*args);end
def self.read(*args);end
def self.binread(*args);end
def self.write(*args);end
def self.binwrite(*args);end
def self.pipe(*args);end
def self.try_convert(arg0);end
def self.copy_stream(*args);end
def self.getaddress(arg0);end
def addr(*args);end
def peeraddr(*args);end
def recvfrom(*args);end
end
module IO::WaitReadable
end
module IO::WaitWritable
end
class TCPSocket < IPSocket
include File::Constants
include Enumerable
include Kernel
def self.gethostbyname(arg0);end
def self.getaddress(arg0);end
def self.do_not_reverse_lookup();end
def self.do_not_reverse_lookup=(arg0);end
def self.for_fd(arg0);end
def self.sysopen(*args);end
def self.popen(*args);end
def self.foreach(*args);end
def self.read(*args);end
def self.binread(*args);end
def self.write(*args);end
def self.binwrite(*args);end
def self.pipe(*args);end
def self.try_convert(arg0);end
def self.copy_stream(*args);end
def self.gethostbyname(arg0);end
end
module IO::WaitReadable
end
module IO::WaitWritable
end
class TCPServer < TCPSocket
include File::Constants
include Enumerable
include Kernel
def self.gethostbyname(arg0);end
def self.getaddress(arg0);end
def self.do_not_reverse_lookup();end
def self.do_not_reverse_lookup=(arg0);end
def self.for_fd(arg0);end
def self.sysopen(*args);end
def self.popen(*args);end
def self.foreach(*args);end
def self.read(*args);end
def self.binread(*args);end
def self.write(*args);end
def self.binwrite(*args);end
def self.pipe(*args);end
def self.try_convert(arg0);end
def self.copy_stream(*args);end
def accept();end
def accept_nonblock();end
def sysaccept();end
def listen(arg0);end
end
module IO::WaitReadable
end
module IO::WaitWritable
end
class UDPSocket < IPSocket
include File::Constants
include Enumerable
include Kernel
def self.getaddress(arg0);end
def self.do_not_reverse_lookup();end
def self.do_not_reverse_lookup=(arg0);end
def self.for_fd(arg0);end
def self.sysopen(*args);end
def self.popen(*args);end
def self.foreach(*args);end
def self.read(*args);end
def self.binread(*args);end
def self.write(*args);end
def self.binwrite(*args);end
def self.pipe(*args);end
def self.try_convert(arg0);end
def self.copy_stream(*args);end
def connect(arg0, arg1);end
def bind(arg0, arg1);end
def recvfrom_nonblock(*args);end
end
module IO::WaitReadable
end
module IO::WaitWritable
end
class UNIXSocket < BasicSocket
include File::Constants
include Enumerable
include Kernel
def self.socketpair(*args);end
def self.pair(*args);end
def self.do_not_reverse_lookup();end
def self.do_not_reverse_lookup=(arg0);end
def self.for_fd(arg0);end
def self.sysopen(*args);end
def self.popen(*args);end
def self.foreach(*args);end
def self.read(*args);end
def self.binread(*args);end
def self.write(*args);end
def self.binwrite(*args);end
def self.pipe(*args);end
def self.try_convert(arg0);end
def self.copy_stream(*args);end
def self.socketpair(*args);end
def self.pair(*args);end
def path();end
def addr();end
def peeraddr();end
def recvfrom(*args);end
def send_io(arg0);end
def recv_io(*args);end
end
module IO::WaitReadable
end
module IO::WaitWritable
end
class UNIXServer < UNIXSocket
include File::Constants
include Enumerable
include Kernel
def self.socketpair(*args);end
def self.pair(*args);end
def self.do_not_reverse_lookup();end
def self.do_not_reverse_lookup=(arg0);end
def self.for_fd(arg0);end
def self.sysopen(*args);end
def self.popen(*args);end
def self.foreach(*args);end
def self.read(*args);end
def self.binread(*args);end
def self.write(*args);end
def self.binwrite(*args);end
def self.pipe(*args);end
def self.try_convert(arg0);end
def self.copy_stream(*args);end
def accept();end
def accept_nonblock();end
def sysaccept();end
def listen(arg0);end
end
module IO::WaitReadable
end
module IO::WaitWritable
end
class Addrinfo < Data
include Kernel
def self.getaddrinfo(*args);end
def self.ip(arg0);end
def self.tcp(arg0, arg1);end
def self.udp(arg0, arg1);end
def self.unix(*args);end
def self.foreach(nodename, service, family = nil, socktype = nil, protocol = nil, flags = nil, &block);end
def self.getaddrinfo(*args);end
def self.ip(arg0);end
def self.tcp(arg0, arg1);end
def self.udp(arg0, arg1);end
def self.unix(*args);end
def self.foreach(nodename, service, family = nil, socktype = nil, protocol = nil, flags = nil, &block);end
def inspect_sockaddr();end
def afamily();end
def pfamily();end
def socktype();end
def protocol();end
def canonname();end
def ipv4?();end
def ipv6?();end
def unix?();end
def ip?();end
def ip_unpack();end
def ip_address();end
def ip_port();end
def ipv4_private?();end
def ipv4_loopback?();end
def ipv4_multicast?();end
def ipv6_unspecified?();end
def ipv6_loopback?();end
def ipv6_multicast?();end
def ipv6_linklocal?();end
def ipv6_sitelocal?();end
def ipv6_unique_local?();end
def ipv6_v4mapped?();end
def ipv6_v4compat?();end
def ipv6_mc_nodelocal?();end
def ipv6_mc_linklocal?();end
def ipv6_mc_sitelocal?();end
def ipv6_mc_orglocal?();end
def ipv6_mc_global?();end
def ipv6_to_ipv4();end
def unix_path();end
def to_sockaddr();end
def getnameinfo(*args);end
def marshal_dump();end
def marshal_load(arg0);end
def family_addrinfo(*args);end
def connect_from(*args);end
def connect(*args);end
def connect_to(*args);end
def bind();end
def listen(*args);end
end
class Delegator < BasicObject
include #<Module:0x00000002cc6080>
def self.public_api();end
def self.delegating_block(mid);end
def self.public_api();end
def self.delegating_block(mid);end
def method_missing(m, *args, &block);end
def __getobj__();end
def __setobj__(obj);end
def marshal_dump();end
def marshal_load(data);end
end
class BasicObject
def self.allocate();end
def self.new(*args);end
def self.superclass();end
def ==(arg0);end
def equal?(arg0);end
def !();end
def !=(arg0);end
def instance_eval(*args);end
def instance_exec(*args);end
def __send__(*args);end
def __id__();end
end
class SimpleDelegator < Delegator
include #<Module:0x00000002cc6080>
def self.public_api();end
def self.delegating_block(mid);end
def __getobj__();end
def __setobj__(obj);end
end
class BasicObject
def self.allocate();end
def self.new(*args);end
def self.superclass();end
def ==(arg0);end
def equal?(arg0);end
def !();end
def !=(arg0);end
def instance_eval(*args);end
def instance_exec(*args);end
def __send__(*args);end
def __id__();end
end
module FileUtils
include FileUtils::StreamUtils_
def private_module_function(name);end
def pwd();end
def getwd();end
def cd(dir, options = nil, &block);end
def chdir(dir, options = nil, &block);end
def uptodate?(new, old_list);end
def mkdir(list, options = nil);end
def mkdir_p(list, options = nil);end
def mkpath(list, options = nil);end
def makedirs(list, options = nil);end
def rmdir(list, options = nil);end
def ln(src, dest, options = nil);end
def link(src, dest, options = nil);end
def ln_s(src, dest, options = nil);end
def symlink(src, dest, options = nil);end
def ln_sf(src, dest, options = nil);end
def cp(src, dest, options = nil);end
def copy(src, dest, options = nil);end
def cp_r(src, dest, options = nil);end
def copy_entry(src, dest, preserve = nil, dereference_root = nil, remove_destination = nil);end
def copy_file(src, dest, preserve = nil, dereference = nil);end
def copy_stream(src, dest);end
def mv(src, dest, options = nil);end
def move(src, dest, options = nil);end
def rm(list, options = nil);end
def remove(list, options = nil);end
def rm_f(list, options = nil);end
def safe_unlink(list, options = nil);end
def rm_r(list, options = nil);end
def rm_rf(list, options = nil);end
def rmtree(list, options = nil);end
def remove_entry_secure(path, force = nil);end
def remove_entry(path, force = nil);end
def remove_file(path, force = nil);end
def remove_dir(path, force = nil);end
def compare_file(a, b);end
def identical?(a, b);end
def cmp(a, b);end
def compare_stream(a, b);end
def install(src, dest, options = nil);end
def chmod(mode, list, options = nil);end
def chmod_R(mode, list, options = nil);end
def chown(user, group, list, options = nil);end
def chown_R(user, group, list, options = nil);end
def touch(list, options = nil);end
def commands();end
def options();end
def have_option?(mid, opt);end
def options_of(mid);end
def collect_method(opt);end
def self.private_module_function(name);end
def self.pwd();end
def self.getwd();end
def self.cd(dir, options = nil, &block);end
def self.chdir(dir, options = nil, &block);end
def self.uptodate?(new, old_list);end
def self.mkdir(list, options = nil);end
def self.mkdir_p(list, options = nil);end
def self.mkpath(list, options = nil);end
def self.makedirs(list, options = nil);end
def self.rmdir(list, options = nil);end
def self.ln(src, dest, options = nil);end
def self.link(src, dest, options = nil);end
def self.ln_s(src, dest, options = nil);end
def self.symlink(src, dest, options = nil);end
def self.ln_sf(src, dest, options = nil);end
def self.cp(src, dest, options = nil);end
def self.copy(src, dest, options = nil);end
def self.cp_r(src, dest, options = nil);end
def self.copy_entry(src, dest, preserve = nil, dereference_root = nil, remove_destination = nil);end
def self.copy_file(src, dest, preserve = nil, dereference = nil);end
def self.copy_stream(src, dest);end
def self.mv(src, dest, options = nil);end
def self.move(src, dest, options = nil);end
def self.rm(list, options = nil);end
def self.remove(list, options = nil);end
def self.rm_f(list, options = nil);end
def self.safe_unlink(list, options = nil);end
def self.rm_r(list, options = nil);end
def self.rm_rf(list, options = nil);end
def self.rmtree(list, options = nil);end
def self.remove_entry_secure(path, force = nil);end
def self.remove_entry(path, force = nil);end
def self.remove_file(path, force = nil);end
def self.remove_dir(path, force = nil);end
def self.compare_file(a, b);end
def self.identical?(a, b);end
def self.cmp(a, b);end
def self.compare_stream(a, b);end
def self.install(src, dest, options = nil);end
def self.chmod(mode, list, options = nil);end
def self.chmod_R(mode, list, options = nil);end
def self.chown(user, group, list, options = nil);end
def self.chown_R(user, group, list, options = nil);end
def self.touch(list, options = nil);end
def self.commands();end
def self.options();end
def self.have_option?(mid, opt);end
def self.options_of(mid);end
def self.collect_method(opt);end
end
module FileUtils::StreamUtils_
end
class FileUtils::Entry_ < Object
include FileUtils::StreamUtils_
include Kernel
def path();end
def prefix();end
def rel();end
def dereference?();end
def exist?();end
def file?();end
def directory?();end
def symlink?();end
def chardev?();end
def blockdev?();end
def socket?();end
def pipe?();end
def door?();end
def entries();end
def stat();end
def stat!();end
def lstat();end
def lstat!();end
def chmod(mode);end
def chown(uid, gid);end
def copy(dest);end
def copy_file(dest);end
def copy_metadata(path);end
def remove();end
def remove_dir1();end
def remove_file();end
def platform_support();end
def preorder_traverse();end
def traverse();end
def postorder_traverse();end
def wrap_traverse(pre, post);end
end
module FileUtils::LowMethods
end
module FileUtils::Verbose
include FileUtils
include FileUtils::StreamUtils_
def pwd();end
def getwd();end
def cd(*args);end
def chdir(*args);end
def uptodate?(new, old_list);end
def mkdir(*args);end
def mkdir_p(*args);end
def mkpath(*args);end
def makedirs(*args);end
def rmdir(*args);end
def ln(*args);end
def link(*args);end
def ln_s(*args);end
def symlink(*args);end
def ln_sf(*args);end
def cp(*args);end
def copy(*args);end
def cp_r(*args);end
def copy_entry(src, dest, preserve = nil, dereference_root = nil, remove_destination = nil);end
def copy_file(src, dest, preserve = nil, dereference = nil);end
def copy_stream(src, dest);end
def mv(*args);end
def move(*args);end
def rm(*args);end
def remove(*args);end
def rm_f(*args);end
def safe_unlink(*args);end
def rm_r(*args);end
def rm_rf(*args);end
def rmtree(*args);end
def remove_entry_secure(path, force = nil);end
def remove_entry(path, force = nil);end
def remove_file(path, force = nil);end
def remove_dir(path, force = nil);end
def compare_file(a, b);end
def identical?(a, b);end
def cmp(a, b);end
def compare_stream(a, b);end
def install(*args);end
def chmod(*args);end
def chmod_R(*args);end
def chown(*args);end
def chown_R(*args);end
def touch(*args);end
def self.pwd();end
def self.getwd();end
def self.cd(*args);end
def self.chdir(*args);end
def self.uptodate?(new, old_list);end
def self.mkdir(*args);end
def self.mkdir_p(*args);end
def self.mkpath(*args);end
def self.makedirs(*args);end
def self.rmdir(*args);end
def self.ln(*args);end
def self.link(*args);end
def self.ln_s(*args);end
def self.symlink(*args);end
def self.ln_sf(*args);end
def self.cp(*args);end
def self.copy(*args);end
def self.cp_r(*args);end
def self.copy_entry(src, dest, preserve = nil, dereference_root = nil, remove_destination = nil);end
def self.copy_file(src, dest, preserve = nil, dereference = nil);end
def self.copy_stream(src, dest);end
def self.mv(*args);end
def self.move(*args);end
def self.rm(*args);end
def self.remove(*args);end
def self.rm_f(*args);end
def self.safe_unlink(*args);end
def self.rm_r(*args);end
def self.rm_rf(*args);end
def self.rmtree(*args);end
def self.remove_entry_secure(path, force = nil);end
def self.remove_entry(path, force = nil);end
def self.remove_file(path, force = nil);end
def self.remove_dir(path, force = nil);end
def self.compare_file(a, b);end
def self.identical?(a, b);end
def self.cmp(a, b);end
def self.compare_stream(a, b);end
def self.install(*args);end
def self.chmod(*args);end
def self.chmod_R(*args);end
def self.chown(*args);end
def self.chown_R(*args);end
def self.touch(*args);end
end
module FileUtils::NoWrite
include FileUtils::LowMethods
include FileUtils
include FileUtils::StreamUtils_
def pwd(*args);end
def getwd(*args);end
def cd(*args);end
def chdir(*args);end
def uptodate?(*args);end
def mkdir(*args);end
def mkdir_p(*args);end
def mkpath(*args);end
def makedirs(*args);end
def rmdir(*args);end
def ln(*args);end
def link(*args);end
def ln_s(*args);end
def symlink(*args);end
def ln_sf(*args);end
def cp(*args);end
def copy(*args);end
def cp_r(*args);end
def copy_entry(*args);end
def copy_file(*args);end
def copy_stream(*args);end
def mv(*args);end
def move(*args);end
def rm(*args);end
def remove(*args);end
def rm_f(*args);end
def safe_unlink(*args);end
def rm_r(*args);end
def rm_rf(*args);end
def rmtree(*args);end
def remove_entry_secure(*args);end
def remove_entry(*args);end
def remove_file(*args);end
def remove_dir(*args);end
def compare_file(*args);end
def identical?(*args);end
def cmp(*args);end
def compare_stream(*args);end
def install(*args);end
def chmod(*args);end
def chmod_R(*args);end
def chown(*args);end
def chown_R(*args);end
def touch(*args);end
def self.pwd(*args);end
def self.getwd(*args);end
def self.cd(*args);end
def self.chdir(*args);end
def self.uptodate?(*args);end
def self.mkdir(*args);end
def self.mkdir_p(*args);end
def self.mkpath(*args);end
def self.makedirs(*args);end
def self.rmdir(*args);end
def self.ln(*args);end
def self.link(*args);end
def self.ln_s(*args);end
def self.symlink(*args);end
def self.ln_sf(*args);end
def self.cp(*args);end
def self.copy(*args);end
def self.cp_r(*args);end
def self.copy_entry(*args);end
def self.copy_file(*args);end
def self.copy_stream(*args);end
def self.mv(*args);end
def self.move(*args);end
def self.rm(*args);end
def self.remove(*args);end
def self.rm_f(*args);end
def self.safe_unlink(*args);end
def self.rm_r(*args);end
def self.rm_rf(*args);end
def self.rmtree(*args);end
def self.remove_entry_secure(*args);end
def self.remove_entry(*args);end
def self.remove_file(*args);end
def self.remove_dir(*args);end
def self.compare_file(*args);end
def self.identical?(*args);end
def self.cmp(*args);end
def self.compare_stream(*args);end
def self.install(*args);end
def self.chmod(*args);end
def self.chmod_R(*args);end
def self.chown(*args);end
def self.chown_R(*args);end
def self.touch(*args);end
end
module FileUtils::DryRun
include FileUtils::LowMethods
include FileUtils
include FileUtils::StreamUtils_
def pwd(*args);end
def getwd(*args);end
def cd(*args);end
def chdir(*args);end
def uptodate?(*args);end
def mkdir(*args);end
def mkdir_p(*args);end
def mkpath(*args);end
def makedirs(*args);end
def rmdir(*args);end
def ln(*args);end
def link(*args);end
def ln_s(*args);end
def symlink(*args);end
def ln_sf(*args);end
def cp(*args);end
def copy(*args);end
def cp_r(*args);end
def copy_entry(*args);end
def copy_file(*args);end
def copy_stream(*args);end
def mv(*args);end
def move(*args);end
def rm(*args);end
def remove(*args);end
def rm_f(*args);end
def safe_unlink(*args);end
def rm_r(*args);end
def rm_rf(*args);end
def rmtree(*args);end
def remove_entry_secure(*args);end
def remove_entry(*args);end
def remove_file(*args);end
def remove_dir(*args);end
def compare_file(*args);end
def identical?(*args);end
def cmp(*args);end
def compare_stream(*args);end
def install(*args);end
def chmod(*args);end
def chmod_R(*args);end
def chown(*args);end
def chown_R(*args);end
def touch(*args);end
def self.pwd(*args);end
def self.getwd(*args);end
def self.cd(*args);end
def self.chdir(*args);end
def self.uptodate?(*args);end
def self.mkdir(*args);end
def self.mkdir_p(*args);end
def self.mkpath(*args);end
def self.makedirs(*args);end
def self.rmdir(*args);end
def self.ln(*args);end
def self.link(*args);end
def self.ln_s(*args);end
def self.symlink(*args);end
def self.ln_sf(*args);end
def self.cp(*args);end
def self.copy(*args);end
def self.cp_r(*args);end
def self.copy_entry(*args);end
def self.copy_file(*args);end
def self.copy_stream(*args);end
def self.mv(*args);end
def self.move(*args);end
def self.rm(*args);end
def self.remove(*args);end
def self.rm_f(*args);end
def self.safe_unlink(*args);end
def self.rm_r(*args);end
def self.rm_rf(*args);end
def self.rmtree(*args);end
def self.remove_entry_secure(*args);end
def self.remove_entry(*args);end
def self.remove_file(*args);end
def self.remove_dir(*args);end
def self.compare_file(*args);end
def self.identical?(*args);end
def self.cmp(*args);end
def self.compare_stream(*args);end
def self.install(*args);end
def self.chmod(*args);end
def self.chmod_R(*args);end
def self.chown(*args);end
def self.chown_R(*args);end
def self.touch(*args);end
end
module Etc
def getlogin();end
def getpwuid(*args);end
def getpwnam(arg0);end
def setpwent();end
def endpwent();end
def getpwent();end
def passwd();end
def getgrgid(*args);end
def getgrnam(arg0);end
def group();end
def setgrent();end
def endgrent();end
def getgrent();end
def sysconfdir();end
def systmpdir();end
def self.getlogin();end
def self.getpwuid(*args);end
def self.getpwnam(arg0);end
def self.setpwent();end
def self.endpwent();end
def self.getpwent();end
def self.passwd();end
def self.getgrgid(*args);end
def self.getgrnam(arg0);end
def self.group();end
def self.setgrent();end
def self.endgrent();end
def self.getgrent();end
def self.sysconfdir();end
def self.systmpdir();end
end
class Struct::Passwd < Struct
include Enumerable
include Kernel
def self.[](*args);end
def self.members();end
def self.each();end
def self.to_a(*args);end
def self.entries(*args);end
def self.sort();end
def self.sort_by();end
def self.grep(arg0);end
def self.count(*args);end
def self.find(*args);end
def self.detect(*args);end
def self.find_index(*args);end
def self.find_all();end
def self.reject();end
def self.collect();end
def self.map();end
def self.flat_map();end
def self.collect_concat();end
def self.inject(*args);end
def self.reduce(*args);end
def self.partition();end
def self.group_by();end
def self.first(*args);end
def self.all?();end
def self.any?();end
def self.one?();end
def self.none?();end
def self.min();end
def self.max();end
def self.minmax();end
def self.min_by();end
def self.max_by();end
def self.minmax_by();end
def self.member?(arg0);end
def self.each_with_index(*args);end
def self.reverse_each(*args);end
def self.each_entry(*args);end
def self.each_slice(arg0);end
def self.each_cons(arg0);end
def self.each_with_object(arg0);end
def self.zip(*args);end
def self.take(arg0);end
def self.take_while();end
def self.drop(arg0);end
def self.drop_while();end
def self.cycle(*args);end
def self.chunk(*args);end
def self.slice_before(*args);end
def self.lazy();end
def self.[](*args);end
def self.members();end
def self.each();end
def name=(arg0);end
def passwd();end
def passwd=(arg0);end
def uid();end
def uid=(arg0);end
def gid();end
def gid=(arg0);end
def gecos();end
def gecos=(arg0);end
def dir();end
def dir=(arg0);end
def shell();end
def shell=(arg0);end
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
class Struct::Group < Struct
include Enumerable
include Kernel
def self.[](*args);end
def self.members();end
def self.each();end
def self.to_a(*args);end
def self.entries(*args);end
def self.sort();end
def self.sort_by();end
def self.grep(arg0);end
def self.count(*args);end
def self.find(*args);end
def self.detect(*args);end
def self.find_index(*args);end
def self.find_all();end
def self.reject();end
def self.collect();end
def self.map();end
def self.flat_map();end
def self.collect_concat();end
def self.inject(*args);end
def self.reduce(*args);end
def self.partition();end
def self.group_by();end
def self.first(*args);end
def self.all?();end
def self.any?();end
def self.one?();end
def self.none?();end
def self.min();end
def self.max();end
def self.minmax();end
def self.min_by();end
def self.max_by();end
def self.minmax_by();end
def self.member?(arg0);end
def self.each_with_index(*args);end
def self.reverse_each(*args);end
def self.each_entry(*args);end
def self.each_slice(arg0);end
def self.each_cons(arg0);end
def self.each_with_object(arg0);end
def self.zip(*args);end
def self.take(arg0);end
def self.take_while();end
def self.drop(arg0);end
def self.drop_while();end
def self.cycle(*args);end
def self.chunk(*args);end
def self.slice_before(*args);end
def self.lazy();end
def self.[](*args);end
def self.members();end
def self.each();end
def name=(arg0);end
def passwd();end
def passwd=(arg0);end
def gid();end
def gid=(arg0);end
def mem();end
def mem=(arg0);end
end
class Tempfile < #<Class:0x00000002d99f20>
include Dir::Tmpname
include #<Module:0x00000002cc6080>
def self.public_api();end
def self.delegating_block(mid);end
def close(*args);end
def close!();end
def unlink();end
def delete();end
def path();end
def size();end
def length();end
end
class Tempfile::Remover < Object
include Kernel
def call(*args);end
end
class BasicObject
def self.allocate();end
def self.new(*args);end
def self.superclass();end
def ==(arg0);end
def equal?(arg0);end
def !();end
def !=(arg0);end
def instance_eval(*args);end
def instance_exec(*args);end
def __send__(*args);end
def __id__();end
end
module Fcntl
end
module Timeout
def timeout(sec, klass = nil);end
def self.timeout(sec, klass = nil);end
end
class Timeout::Error < RuntimeError
include Kernel
def self.exception(*args);end
end
class Timeout::ExitException < Exception
include Kernel
def self.exception(*args);end
end
class Timeout::Error < RuntimeError
include Kernel
def self.exception(*args);end
end
module Singleton
def __init__(klass);end
def self.__init__(klass);end
def clone();end
def dup();end
def _dump(*args);end
end
module Singleton::SingletonClassMethods
def clone();end
def _load(str);end
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
module URI
include URI::REGEXP
def scheme_list();end
def split(uri);end
def parse(uri);end
def join(*args);end
def extract(str, schemes = nil, &block);end
def regexp(*args);end
def encode_www_form_component(str);end
def decode_www_form_component(str, enc = nil);end
def encode_www_form(enum);end
def decode_www_form(str, enc = nil);end
def escape(*args);end
def encode(*args);end
def unescape(*args);end
def decode(*args);end
def self.scheme_list();end
def self.split(uri);end
def self.parse(uri);end
def self.join(*args);end
def self.extract(str, schemes = nil, &block);end
def self.regexp(*args);end
def self.encode_www_form_component(str);end
def self.decode_www_form_component(str, enc = nil);end
def self.encode_www_form(enum);end
def self.decode_www_form(str, enc = nil);end
end
module URI::REGEXP
end
module URI::REGEXP::PATTERN
end
class URI::Parser < Object
include URI::REGEXP
include Kernel
def pattern();end
def regexp();end
def split(uri);end
def parse(uri);end
def join(*args);end
def extract(str, schemes = nil);end
def make_regexp(*args);end
def escape(str, unsafe = nil);end
def unescape(str, escaped = nil);end
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
include URI::REGEXP
include Kernel
def self.default_port();end
def self.component();end
def self.use_registry();end
def self.build2(args);end
def self.build(args);end
def self.default_port();end
def self.component();end
def self.use_registry();end
def self.build2(args);end
def self.build(args);end
def default_port();end
def scheme();end
def host();end
def port();end
def registry();end
def path();end
def query();end
def opaque();end
def fragment();end
def parser();end
def component();end
def scheme=(v);end
def userinfo=(userinfo);end
def user=(user);end
def password=(password);end
def userinfo();end
def user();end
def password();end
def host=(v);end
def hostname();end
def hostname=(v);end
def port=(v);end
def registry=(v);end
def path=(v);end
def query=(v);end
def opaque=(v);end
def fragment=(v);end
def hierarchical?();end
def absolute?();end
def absolute();end
def relative?();end
def merge!(oth);end
def merge(oth);end
def +(oth);end
def route_from(oth);end
def -(oth);end
def route_to(oth);end
def normalize();end
def normalize!();end
def coerce(oth);end
def find_proxy();end
end
class URI::FTP < URI::Generic
include URI
include URI::REGEXP
include Kernel
def self.new2(user, password, host, port, path, typecode = nil, arg_check = nil);end
def self.build(args);end
def self.default_port();end
def self.component();end
def self.use_registry();end
def self.build2(args);end
def self.new2(user, password, host, port, path, typecode = nil, arg_check = nil);end
def self.build(args);end
def typecode();end
def typecode=(typecode);end
def merge(oth);end
def path();end
end
class URI::HTTP < URI::Generic
include URI
include URI::REGEXP
include Kernel
def self.build(args);end
def self.default_port();end
def self.component();end
def self.use_registry();end
def self.build2(args);end
def self.build(args);end
def request_uri();end
end
class URI::HTTPS < URI::HTTP
include URI
include URI::REGEXP
include Kernel
def self.build(args);end
def self.default_port();end
def self.component();end
def self.use_registry();end
def self.build2(args);end
end
class URI::LDAP < URI::Generic
include URI
include URI::REGEXP
include Kernel
def self.build(args);end
def self.default_port();end
def self.component();end
def self.use_registry();end
def self.build2(args);end
def self.build(args);end
def dn();end
def dn=(val);end
def attributes();end
def attributes=(val);end
def scope();end
def scope=(val);end
def filter();end
def filter=(val);end
def extensions();end
def extensions=(val);end
def hierarchical?();end
end
class URI::LDAPS < URI::LDAP
include URI
include URI::REGEXP
include Kernel
def self.build(args);end
def self.default_port();end
def self.component();end
def self.use_registry();end
def self.build2(args);end
end
class URI::MailTo < URI::Generic
include URI
include URI::REGEXP
include Kernel
def self.build(args);end
def self.default_port();end
def self.component();end
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
module Digest
def hexencode(arg0);end
def self.hexencode(arg0);end
end
module Digest::Instance
def update(arg0);end
def <<(arg0);end
def reset();end
def digest_length();end
def block_length();end
def ==(arg0);end
def inspect();end
def new();end
def digest(*args);end
def digest!();end
def hexdigest(*args);end
def hexdigest!();end
def to_s();end
def length();end
def size();end
def file(name);end
def base64digest(*args);end
def base64digest!();end
end
class Digest::Class < Object
include Digest::Instance
include Kernel
def self.digest(*args);end
def self.hexdigest(*args);end
def self.file(name);end
def self.base64digest(str, *args);end
def self.digest(*args);end
def self.hexdigest(*args);end
def self.file(name);end
def self.base64digest(str, *args);end
end
class Digest::Base < Digest::Class
include Digest::Instance
include Kernel
def self.digest(*args);end
def self.hexdigest(*args);end
def self.file(name);end
def self.base64digest(str, *args);end
def reset();end
def update(arg0);end
def <<(arg0);end
def digest_length();end
def block_length();end
end
class Digest::MD5 < Digest::Base
include Digest::Instance
include Kernel
def self.digest(*args);end
def self.hexdigest(*args);end
def self.file(name);end
def self.base64digest(str, *args);end
end
class Digest::SHA1 < Digest::Base
include Digest::Instance
include Kernel
def self.digest(*args);end
def self.hexdigest(*args);end
def self.file(name);end
def self.base64digest(str, *args);end
end
