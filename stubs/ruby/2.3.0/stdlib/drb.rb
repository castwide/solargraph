class BasicSocket < IO
include File::Constants
include Enumerable
include Kernel
def self.for_fd(arg0);end
def self.do_not_reverse_lookup();end
def self.do_not_reverse_lookup=(arg0);end
def self.try_convert(arg0);end
def self.read(*args);end
def self.write(*args);end
def self.sysopen(*args);end
def self.popen(*args);end
def self.foreach(*args);end
def self.binread(*args);end
def self.binwrite(*args);end
def self.pipe(*args);end
def self.copy_stream(*args);end
def self.for_fd(arg0);end
def self.do_not_reverse_lookup();end
def self.do_not_reverse_lookup=(arg0);end
def close_read();end
def close_write();end
def shutdown(*args);end
def setsockopt(*args);end
def connect_address();end
def local_address();end
def sendmsg(mesg, flags = nil, dest_sockaddr = nil, *controls);end
def sendmsg_nonblock(mesg, flags = nil, dest_sockaddr = nil, *controls);end
def recv_nonblock(len, flag = nil, str = nil);end
def recvmsg(*args);end
def recvmsg_nonblock(*args);end
def remote_address();end
def do_not_reverse_lookup();end
def do_not_reverse_lookup=(arg0);end
def getsockopt(arg0, arg1);end
def getsockname();end
def getpeername();end
def getpeereid();end
def recv(*args);end
end
module IO::WaitReadable
end
module IO::WaitWritable
end
class IO::EAGAINWaitReadable < Errno::EAGAIN
include IO::WaitReadable
include Kernel
def self.exception(*args);end
end
class IO::EAGAINWaitWritable < Errno::EAGAIN
include IO::WaitWritable
include Kernel
def self.exception(*args);end
end
class IO::EINPROGRESSWaitReadable < Errno::EINPROGRESS
include IO::WaitReadable
include Kernel
def self.exception(*args);end
end
class IO::EINPROGRESSWaitWritable < Errno::EINPROGRESS
include IO::WaitWritable
include Kernel
def self.exception(*args);end
end
class Socket < BasicSocket
include File::Constants
include Enumerable
include Kernel
def self.gethostname();end
def self.gethostbyname(arg0);end
def self.getaddrinfo(*args);end
def self.unix(path);end
def self.tcp(host, port, *rest);end
def self.tcp_server_sockets(host = nil, port);end
def self.accept_loop(*args);end
def self.tcp_server_loop(host = nil, port, &b);end
def self.udp_server_sockets(host = nil, port);end
def self.ip_address_list();end
def self.udp_server_recv(sockets);end
def self.udp_server_loop_on(sockets, &b);end
def self.udp_server_loop(host = nil, port, &b);end
def self.unix_server_socket(path);end
def self.unix_server_loop(path, &b);end
def self.socketpair(*args);end
def self.pair(*args);end
def self.getnameinfo(*args);end
def self.getifaddrs();end
def self.gethostbyaddr(*args);end
def self.getservbyname(*args);end
def self.getservbyport(*args);end
def self.sockaddr_in(arg0, arg1);end
def self.pack_sockaddr_in(arg0, arg1);end
def self.unpack_sockaddr_in(arg0);end
def self.sockaddr_un(arg0);end
def self.pack_sockaddr_un(arg0);end
def self.unpack_sockaddr_un(arg0);end
def self.for_fd(arg0);end
def self.do_not_reverse_lookup();end
def self.do_not_reverse_lookup=(arg0);end
def self.try_convert(arg0);end
def self.read(*args);end
def self.write(*args);end
def self.sysopen(*args);end
def self.popen(*args);end
def self.foreach(*args);end
def self.binread(*args);end
def self.binwrite(*args);end
def self.pipe(*args);end
def self.copy_stream(*args);end
def self.gethostname();end
def self.gethostbyname(arg0);end
def self.getaddrinfo(*args);end
def self.unix(path);end
def self.tcp(host, port, *rest);end
def self.tcp_server_sockets(host = nil, port);end
def self.accept_loop(*args);end
def self.tcp_server_loop(host = nil, port, &b);end
def self.udp_server_sockets(host = nil, port);end
def self.ip_address_list();end
def self.udp_server_recv(sockets);end
def self.udp_server_loop_on(sockets, &b);end
def self.udp_server_loop(host = nil, port, &b);end
def self.unix_server_socket(path);end
def self.unix_server_loop(path, &b);end
def self.socketpair(*args);end
def self.pair(*args);end
def self.getnameinfo(*args);end
def self.getifaddrs();end
def self.gethostbyaddr(*args);end
def self.getservbyname(*args);end
def self.getservbyport(*args);end
def self.sockaddr_in(arg0, arg1);end
def self.pack_sockaddr_in(arg0, arg1);end
def self.unpack_sockaddr_in(arg0);end
def self.sockaddr_un(arg0);end
def self.pack_sockaddr_un(arg0);end
def self.unpack_sockaddr_un(arg0);end
def bind(arg0);end
def accept();end
def ipv6only!();end
def connect_nonblock(addr);end
def connect(arg0);end
def listen(arg0);end
def recvfrom_nonblock(len, flag = nil, str = nil);end
def accept_nonblock(*args);end
def recvfrom(*args);end
def sysaccept();end
end
class Socket::Option < Object
include Kernel
def self.int(arg0, arg1, arg2, arg3);end
def self.byte(arg0, arg1, arg2, arg3);end
def self.bool(arg0, arg1, arg2, arg3);end
def self.linger(arg0, arg1);end
def self.ipv4_multicast_ttl(arg0);end
def self.ipv4_multicast_loop(arg0);end
def self.int(arg0, arg1, arg2, arg3);end
def self.byte(arg0, arg1, arg2, arg3);end
def self.bool(arg0, arg1, arg2, arg3);end
def self.linger(arg0, arg1);end
def self.ipv4_multicast_ttl(arg0);end
def self.ipv4_multicast_loop(arg0);end
def unpack(arg0);end
def data();end
def level();end
def family();end
def optname();end
def int();end
def byte();end
def bool();end
def linger();end
def ipv4_multicast_ttl();end
def ipv4_multicast_loop();end
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
def data();end
def type();end
def level();end
def family();end
def cmsg_is?(arg0, arg1);end
def ipv6_pktinfo_addr();end
def int();end
def unix_rights();end
def timestamp();end
def ip_pktinfo();end
def ipv6_pktinfo();end
def ipv6_pktinfo_ifindex();end
end
class Socket::Ifaddr < Data
include Kernel
def flags();end
def addr();end
def ifindex();end
def netmask();end
def broadaddr();end
def dstaddr();end
end
module Socket::Constants
end
class Socket::UDPSource < Object
include Kernel
def local_address();end
def remote_address();end
def reply(msg);end
end
module IO::WaitReadable
end
module IO::WaitWritable
end
class IO::EAGAINWaitReadable < Errno::EAGAIN
include IO::WaitReadable
include Kernel
def self.exception(*args);end
end
class IO::EAGAINWaitWritable < Errno::EAGAIN
include IO::WaitWritable
include Kernel
def self.exception(*args);end
end
class IO::EINPROGRESSWaitReadable < Errno::EINPROGRESS
include IO::WaitReadable
include Kernel
def self.exception(*args);end
end
class IO::EINPROGRESSWaitWritable < Errno::EINPROGRESS
include IO::WaitWritable
include Kernel
def self.exception(*args);end
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
def self.for_fd(arg0);end
def self.do_not_reverse_lookup();end
def self.do_not_reverse_lookup=(arg0);end
def self.try_convert(arg0);end
def self.read(*args);end
def self.write(*args);end
def self.sysopen(*args);end
def self.popen(*args);end
def self.foreach(*args);end
def self.binread(*args);end
def self.binwrite(*args);end
def self.pipe(*args);end
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
class IO::EAGAINWaitReadable < Errno::EAGAIN
include IO::WaitReadable
include Kernel
def self.exception(*args);end
end
class IO::EAGAINWaitWritable < Errno::EAGAIN
include IO::WaitWritable
include Kernel
def self.exception(*args);end
end
class IO::EINPROGRESSWaitReadable < Errno::EINPROGRESS
include IO::WaitReadable
include Kernel
def self.exception(*args);end
end
class IO::EINPROGRESSWaitWritable < Errno::EINPROGRESS
include IO::WaitWritable
include Kernel
def self.exception(*args);end
end
class TCPSocket < IPSocket
include File::Constants
include Enumerable
include Kernel
def self.gethostbyname(arg0);end
def self.getaddress(arg0);end
def self.for_fd(arg0);end
def self.do_not_reverse_lookup();end
def self.do_not_reverse_lookup=(arg0);end
def self.try_convert(arg0);end
def self.read(*args);end
def self.write(*args);end
def self.sysopen(*args);end
def self.popen(*args);end
def self.foreach(*args);end
def self.binread(*args);end
def self.binwrite(*args);end
def self.pipe(*args);end
def self.copy_stream(*args);end
def self.gethostbyname(arg0);end
end
module IO::WaitReadable
end
module IO::WaitWritable
end
class IO::EAGAINWaitReadable < Errno::EAGAIN
include IO::WaitReadable
include Kernel
def self.exception(*args);end
end
class IO::EAGAINWaitWritable < Errno::EAGAIN
include IO::WaitWritable
include Kernel
def self.exception(*args);end
end
class IO::EINPROGRESSWaitReadable < Errno::EINPROGRESS
include IO::WaitReadable
include Kernel
def self.exception(*args);end
end
class IO::EINPROGRESSWaitWritable < Errno::EINPROGRESS
include IO::WaitWritable
include Kernel
def self.exception(*args);end
end
class TCPServer < TCPSocket
include File::Constants
include Enumerable
include Kernel
def self.gethostbyname(arg0);end
def self.getaddress(arg0);end
def self.for_fd(arg0);end
def self.do_not_reverse_lookup();end
def self.do_not_reverse_lookup=(arg0);end
def self.try_convert(arg0);end
def self.read(*args);end
def self.write(*args);end
def self.sysopen(*args);end
def self.popen(*args);end
def self.foreach(*args);end
def self.binread(*args);end
def self.binwrite(*args);end
def self.pipe(*args);end
def self.copy_stream(*args);end
def accept();end
def listen(arg0);end
def accept_nonblock(*args);end
def sysaccept();end
end
module IO::WaitReadable
end
module IO::WaitWritable
end
class IO::EAGAINWaitReadable < Errno::EAGAIN
include IO::WaitReadable
include Kernel
def self.exception(*args);end
end
class IO::EAGAINWaitWritable < Errno::EAGAIN
include IO::WaitWritable
include Kernel
def self.exception(*args);end
end
class IO::EINPROGRESSWaitReadable < Errno::EINPROGRESS
include IO::WaitReadable
include Kernel
def self.exception(*args);end
end
class IO::EINPROGRESSWaitWritable < Errno::EINPROGRESS
include IO::WaitWritable
include Kernel
def self.exception(*args);end
end
class UDPSocket < IPSocket
include File::Constants
include Enumerable
include Kernel
def self.getaddress(arg0);end
def self.for_fd(arg0);end
def self.do_not_reverse_lookup();end
def self.do_not_reverse_lookup=(arg0);end
def self.try_convert(arg0);end
def self.read(*args);end
def self.write(*args);end
def self.sysopen(*args);end
def self.popen(*args);end
def self.foreach(*args);end
def self.binread(*args);end
def self.binwrite(*args);end
def self.pipe(*args);end
def self.copy_stream(*args);end
def bind(arg0, arg1);end
def connect(arg0, arg1);end
def recvfrom_nonblock(len, flag = nil, outbuf = nil);end
end
module IO::WaitReadable
end
module IO::WaitWritable
end
class IO::EAGAINWaitReadable < Errno::EAGAIN
include IO::WaitReadable
include Kernel
def self.exception(*args);end
end
class IO::EAGAINWaitWritable < Errno::EAGAIN
include IO::WaitWritable
include Kernel
def self.exception(*args);end
end
class IO::EINPROGRESSWaitReadable < Errno::EINPROGRESS
include IO::WaitReadable
include Kernel
def self.exception(*args);end
end
class IO::EINPROGRESSWaitWritable < Errno::EINPROGRESS
include IO::WaitWritable
include Kernel
def self.exception(*args);end
end
class UNIXSocket < BasicSocket
include File::Constants
include Enumerable
include Kernel
def self.socketpair(*args);end
def self.pair(*args);end
def self.for_fd(arg0);end
def self.do_not_reverse_lookup();end
def self.do_not_reverse_lookup=(arg0);end
def self.try_convert(arg0);end
def self.read(*args);end
def self.write(*args);end
def self.sysopen(*args);end
def self.popen(*args);end
def self.foreach(*args);end
def self.binread(*args);end
def self.binwrite(*args);end
def self.pipe(*args);end
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
class IO::EAGAINWaitReadable < Errno::EAGAIN
include IO::WaitReadable
include Kernel
def self.exception(*args);end
end
class IO::EAGAINWaitWritable < Errno::EAGAIN
include IO::WaitWritable
include Kernel
def self.exception(*args);end
end
class IO::EINPROGRESSWaitReadable < Errno::EINPROGRESS
include IO::WaitReadable
include Kernel
def self.exception(*args);end
end
class IO::EINPROGRESSWaitWritable < Errno::EINPROGRESS
include IO::WaitWritable
include Kernel
def self.exception(*args);end
end
class UNIXServer < UNIXSocket
include File::Constants
include Enumerable
include Kernel
def self.socketpair(*args);end
def self.pair(*args);end
def self.for_fd(arg0);end
def self.do_not_reverse_lookup();end
def self.do_not_reverse_lookup=(arg0);end
def self.try_convert(arg0);end
def self.read(*args);end
def self.write(*args);end
def self.sysopen(*args);end
def self.popen(*args);end
def self.foreach(*args);end
def self.binread(*args);end
def self.binwrite(*args);end
def self.pipe(*args);end
def self.copy_stream(*args);end
def accept();end
def listen(arg0);end
def accept_nonblock(*args);end
def sysaccept();end
end
module IO::WaitReadable
end
module IO::WaitWritable
end
class IO::EAGAINWaitReadable < Errno::EAGAIN
include IO::WaitReadable
include Kernel
def self.exception(*args);end
end
class IO::EAGAINWaitWritable < Errno::EAGAIN
include IO::WaitWritable
include Kernel
def self.exception(*args);end
end
class IO::EINPROGRESSWaitReadable < Errno::EINPROGRESS
include IO::WaitReadable
include Kernel
def self.exception(*args);end
end
class IO::EINPROGRESSWaitWritable < Errno::EINPROGRESS
include IO::WaitWritable
include Kernel
def self.exception(*args);end
end
class Addrinfo < Data
include Kernel
def self.foreach(nodename, service, family = nil, socktype = nil, protocol = nil, flags = nil, &block);end
def self.getaddrinfo(*args);end
def self.unix(*args);end
def self.tcp(arg0, arg1);end
def self.ip(arg0);end
def self.udp(arg0, arg1);end
def self.foreach(nodename, service, family = nil, socktype = nil, protocol = nil, flags = nil, &block);end
def self.getaddrinfo(*args);end
def self.unix(*args);end
def self.tcp(arg0, arg1);end
def self.ip(arg0);end
def self.udp(arg0, arg1);end
def marshal_dump();end
def marshal_load(arg0);end
def bind();end
def family_addrinfo(*args);end
def pfamily();end
def socktype();end
def ip?();end
def protocol();end
def unix?();end
def ipv6?();end
def connect(*args);end
def connect_from(*args);end
def connect_to(*args);end
def listen(*args);end
def afamily();end
def ip_port();end
def ip_address();end
def unix_path();end
def ipv4?();end
def to_sockaddr();end
def inspect_sockaddr();end
def canonname();end
def ip_unpack();end
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
def getnameinfo(*args);end
end
module DRb
def config();end
def uri();end
def to_obj(ref);end
def to_id(obj);end
def mutex();end
def here?(uri);end
def current_server();end
def fetch_server(uri);end
def front();end
def regist_server(server);end
def thread();end
def stop_service();end
def remove_server(server);end
def start_service(*args);end
def primary_server();end
def primary_server=(arg0);end
def install_id_conv(idconv);end
def install_acl(acl);end
def self.config();end
def self.uri();end
def self.to_obj(ref);end
def self.to_id(obj);end
def self.mutex();end
def self.here?(uri);end
def self.current_server();end
def self.fetch_server(uri);end
def self.front();end
def self.regist_server(server);end
def self.thread();end
def self.stop_service();end
def self.remove_server(server);end
def self.start_service(*args);end
def self.primary_server();end
def self.primary_server=(arg0);end
def self.install_id_conv(idconv);end
def self.install_acl(acl);end
end
class DRb::DRbObject < Object
include Kernel
def self._load(s);end
def self.new_with(uri, ref);end
def self.new_with_uri(uri);end
def self.with_friend(uri);end
def self.prepare_backtrace(uri, result);end
def self._load(s);end
def self.new_with(uri, ref);end
def self.new_with_uri(uri);end
def self.with_friend(uri);end
def self.prepare_backtrace(uri, result);end
def method_missing(msg_id, *a, &b);end
def _dump(lv);end
def pretty_print(q);end
def __drbref();end
def __drburi();end
def pretty_print_cycle(q);end
end
class DRb::DRbError < RuntimeError
include Kernel
def self.exception(*args);end
end
class DRb::DRbConnError < DRb::DRbError
include Kernel
def self.exception(*args);end
end
class DRb::DRbIdConv < Object
include Kernel
def to_obj(ref);end
def to_id(obj);end
end
module DRb::DRbUndumped
def _dump(dummy);end
end
class DRb::DRbServerNotFound < DRb::DRbError
include Kernel
def self.exception(*args);end
end
class DRb::DRbBadURI < DRb::DRbError
include Kernel
def self.exception(*args);end
end
class DRb::DRbBadScheme < DRb::DRbError
include Kernel
def self.exception(*args);end
end
class DRb::DRbUnknownError < DRb::DRbError
include Kernel
def self._load(s);end
def self.exception(*args);end
def self._load(s);end
def _dump(lv);end
def unknown();end
end
class DRb::DRbRemoteError < DRb::DRbError
include Kernel
def self.exception(*args);end
def reason();end
end
class DRb::DRbUnknown < Object
include Kernel
def self._load(s);end
def self._load(s);end
def exception();end
def _dump(lv);end
def buf();end
def reload();end
end
class DRb::DRbArray < Object
include Kernel
def self._load(s);end
def self._load(s);end
def _dump(lv);end
end
class DRb::DRbMessage < Object
include Kernel
def dump(obj, error = nil);end
def send_request(stream, ref, msg_id, arg, b);end
def recv_request(stream);end
def send_reply(stream, succ, result);end
def recv_reply(stream);end
end
module DRb::DRbProtocol
def add_protocol(prot);end
def auto_load(uri);end
def open_server(uri, config, first = nil);end
def uri_option(uri, config, first = nil);end
def self.add_protocol(prot);end
def self.auto_load(uri);end
def self.open_server(uri, config, first = nil);end
def self.uri_option(uri, config, first = nil);end
end
class DRb::DRbTCPSocket < Object
include Kernel
def self.open_server(uri, config);end
def self.uri_option(uri, config);end
def self.parse_uri(uri);end
def self.getservername();end
def self.open_server_inaddr_any(host, port);end
def self.open_server(uri, config);end
def self.uri_option(uri, config);end
def self.parse_uri(uri);end
def self.getservername();end
def self.open_server_inaddr_any(host, port);end
def close();end
def alive?();end
def uri();end
def accept();end
def send_request(ref, msg_id, arg, b);end
def stream();end
def recv_request();end
def send_reply(succ, result);end
def recv_reply();end
def set_sockopt(soc);end
def peeraddr();end
def shutdown();end
end
class DRb::DRbURIOption < Object
include Kernel
def option();end
end
class DRb::DRbConn < Object
include Kernel
def close();end
def alive?();end
def uri();end
def send_message(ref, msg_id, arg, block);end
end
class DRb::DRbServer < Object
include Kernel
def self.verbose();end
def self.default_argc_limit(argc);end
def self.default_load_limit(sz);end
def self.default_acl(acl);end
def self.default_id_conv(idconv);end
def self.default_safe_level(level);end
def self.verbose=(on);end
def self.make_config(*args);end
def self.verbose();end
def self.default_argc_limit(argc);end
def self.default_load_limit(sz);end
def self.default_acl(acl);end
def self.default_id_conv(idconv);end
def self.default_safe_level(level);end
def self.verbose=(on);end
def self.make_config(*args);end
def alive?();end
def safe_level();end
def config();end
def verbose();end
def uri();end
def to_obj(ref);end
def to_id(obj);end
def here?(uri);end
def check_insecure_method(obj, msg_id);end
def verbose=(v);end
def front();end
def thread();end
def stop_service();end
end
class DRb::DRbServer::InvokeMethod < Object
include DRb::DRbServer::InvokeMethod18Mixin
include Kernel
def perform();end
end
module DRb::DRbServer::InvokeMethod18Mixin
def perform_with_block();end
def block_yield(x);end
end
class DRb::DRbObject < Object
include Kernel
def self._load(s);end
def self.new_with(uri, ref);end
def self.new_with_uri(uri);end
def self.with_friend(uri);end
def self.prepare_backtrace(uri, result);end
def self._load(s);end
def self.new_with(uri, ref);end
def self.new_with_uri(uri);end
def self.with_friend(uri);end
def self.prepare_backtrace(uri, result);end
def method_missing(msg_id, *a, &b);end
def _dump(lv);end
def pretty_print(q);end
def __drbref();end
def __drburi();end
def pretty_print_cycle(q);end
end
module DRb::DRbUndumped
def _dump(dummy);end
end
class DRb::DRbIdConv < Object
include Kernel
def to_obj(ref);end
def to_id(obj);end
end
