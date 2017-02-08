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
