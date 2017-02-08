module OpenSSL
def fips_mode=(arg0);end
def debug();end
def debug=(arg0);end
def errors();end
def Digest(name);end
def self.fips_mode=(arg0);end
def self.debug();end
def self.debug=(arg0);end
def self.errors();end
def self.Digest(name);end
end
class OpenSSL::OpenSSLError < StandardError
include Kernel
def self.exception(*args);end
end
class OpenSSL::BNError < OpenSSL::OpenSSLError
include Kernel
def self.exception(*args);end
end
class OpenSSL::BN < Object
include Comparable
include Kernel
def self.pseudo_rand(*args);end
def self.rand_range(arg0);end
def self.pseudo_rand_range(arg0);end
def self.generate_prime(*args);end
def self.pseudo_rand(*args);end
def self.rand_range(arg0);end
def self.pseudo_rand_range(arg0);end
def self.generate_prime(*args);end
def copy(arg0);end
def num_bytes();end
def num_bits();end
def +(arg0);end
def -(arg0);end
def *(arg0);end
def sqr();end
def /(arg0);end
def %(arg0);end
def mod_add(arg0, arg1);end
def mod_sub(arg0, arg1);end
def mod_mul(arg0, arg1);end
def mod_sqr(arg0);end
def **(arg0);end
def mod_exp(arg0, arg1);end
def gcd(arg0);end
def cmp(arg0);end
def ucmp(arg0);end
def zero?();end
def one?();end
def odd?();end
def prime?(*args);end
def set_bit!(arg0);end
def clear_bit!(arg0);end
def bit_set?(arg0);end
def mask_bits!(arg0);end
def <<(arg0);end
def >>(arg0);end
def lshift!(arg0);end
def rshift!(arg0);end
def to_i();end
def to_int();end
def to_bn();end
def coerce(arg0);end
def mod_inverse(arg0);end
def prime_fasttest?(*args);end
end
class OpenSSL::Cipher < Object
include Kernel
def self.ciphers();end
def self.ciphers();end
def reset();end
def encrypt(*args);end
def decrypt(*args);end
def pkcs5_keyivgen(*args);end
def update(*args);end
def final();end
def key=(arg0);end
def auth_data=(arg0);end
def auth_tag=(arg0);end
def auth_tag(*args);end
def authenticated?();end
def key_len=(arg0);end
def key_len();end
def iv=(arg0);end
def iv_len();end
def block_size();end
def padding=(arg0);end
def random_key();end
def random_iv();end
end
class OpenSSL::Cipher::CipherError < OpenSSL::OpenSSLError
include Kernel
def self.exception(*args);end
end
class OpenSSL::Cipher::AES < OpenSSL::Cipher
include Kernel
def self.ciphers();end
end
class OpenSSL::Cipher::CAST5 < OpenSSL::Cipher
include Kernel
def self.ciphers();end
end
class OpenSSL::Cipher::BF < OpenSSL::Cipher
include Kernel
def self.ciphers();end
end
class OpenSSL::Cipher::DES < OpenSSL::Cipher
include Kernel
def self.ciphers();end
end
class OpenSSL::Cipher::IDEA < OpenSSL::Cipher
include Kernel
def self.ciphers();end
end
class OpenSSL::Cipher::RC2 < OpenSSL::Cipher
include Kernel
def self.ciphers();end
end
class OpenSSL::Cipher::RC4 < OpenSSL::Cipher
include Kernel
def self.ciphers();end
end
class OpenSSL::Cipher::RC5 < OpenSSL::Cipher
include Kernel
def self.ciphers();end
end
class OpenSSL::Cipher::AES128 < OpenSSL::Cipher
include Kernel
def self.ciphers();end
end
class OpenSSL::Cipher::AES192 < OpenSSL::Cipher
include Kernel
def self.ciphers();end
end
class OpenSSL::Cipher::AES256 < OpenSSL::Cipher
include Kernel
def self.ciphers();end
end
class OpenSSL::Cipher::Cipher < OpenSSL::Cipher
include Kernel
def self.ciphers();end
end
class OpenSSL::ConfigError < OpenSSL::OpenSSLError
include Kernel
def self.exception(*args);end
end
class OpenSSL::Config < Object
include Enumerable
include Kernel
def self.parse(str);end
def self.parse_config(io);end
def self.get_key_string(data, section, key);end
def self.parse(str);end
def self.parse_config(io);end
def self.get_key_string(data, section, key);end
def get_value(section, key);end
def value(arg1, arg2 = nil);end
def add_value(section, key, value);end
def [](section);end
def section(name);end
def []=(section, pairs);end
def sections();end
def each();end
end
class OpenSSL::Digest < Digest::Class
include Digest::Instance
include Kernel
def self.digest(name, data);end
def self.hexdigest(*args);end
def self.file(name);end
def self.base64digest(str, *args);end
def self.digest(name, data);end
def reset();end
def update(arg0);end
def <<(arg0);end
def digest_length();end
def block_length();end
end
class OpenSSL::Digest::DigestError < OpenSSL::OpenSSLError
include Kernel
def self.exception(*args);end
end
class OpenSSL::Digest::DSS < OpenSSL::Digest
include Digest::Instance
include Kernel
def self.digest(data);end
def self.hexdigest(data);end
def self.file(name);end
def self.base64digest(str, *args);end
def self.digest(data);end
def self.hexdigest(data);end
end
class OpenSSL::Digest::DSS1 < OpenSSL::Digest
include Digest::Instance
include Kernel
def self.digest(data);end
def self.hexdigest(data);end
def self.file(name);end
def self.base64digest(str, *args);end
def self.digest(data);end
def self.hexdigest(data);end
end
class OpenSSL::Digest::MD2 < OpenSSL::Digest
include Digest::Instance
include Kernel
def self.digest(data);end
def self.hexdigest(data);end
def self.file(name);end
def self.base64digest(str, *args);end
def self.digest(data);end
def self.hexdigest(data);end
end
class OpenSSL::Digest::MD4 < OpenSSL::Digest
include Digest::Instance
include Kernel
def self.digest(data);end
def self.hexdigest(data);end
def self.file(name);end
def self.base64digest(str, *args);end
def self.digest(data);end
def self.hexdigest(data);end
end
class OpenSSL::Digest::MD5 < OpenSSL::Digest
include Digest::Instance
include Kernel
def self.digest(data);end
def self.hexdigest(data);end
def self.file(name);end
def self.base64digest(str, *args);end
def self.digest(data);end
def self.hexdigest(data);end
end
class OpenSSL::Digest::MDC2 < OpenSSL::Digest
include Digest::Instance
include Kernel
def self.digest(data);end
def self.hexdigest(data);end
def self.file(name);end
def self.base64digest(str, *args);end
def self.digest(data);end
def self.hexdigest(data);end
end
class OpenSSL::Digest::RIPEMD160 < OpenSSL::Digest
include Digest::Instance
include Kernel
def self.digest(data);end
def self.hexdigest(data);end
def self.file(name);end
def self.base64digest(str, *args);end
def self.digest(data);end
def self.hexdigest(data);end
end
class OpenSSL::Digest::SHA < OpenSSL::Digest
include Digest::Instance
include Kernel
def self.digest(data);end
def self.hexdigest(data);end
def self.file(name);end
def self.base64digest(str, *args);end
def self.digest(data);end
def self.hexdigest(data);end
end
class OpenSSL::Digest::SHA1 < OpenSSL::Digest
include Digest::Instance
include Kernel
def self.digest(data);end
def self.hexdigest(data);end
def self.file(name);end
def self.base64digest(str, *args);end
def self.digest(data);end
def self.hexdigest(data);end
end
class OpenSSL::Digest::SHA224 < OpenSSL::Digest
include Digest::Instance
include Kernel
def self.digest(data);end
def self.hexdigest(data);end
def self.file(name);end
def self.base64digest(str, *args);end
def self.digest(data);end
def self.hexdigest(data);end
end
class OpenSSL::Digest::SHA256 < OpenSSL::Digest
include Digest::Instance
include Kernel
def self.digest(data);end
def self.hexdigest(data);end
def self.file(name);end
def self.base64digest(str, *args);end
def self.digest(data);end
def self.hexdigest(data);end
end
class OpenSSL::Digest::SHA384 < OpenSSL::Digest
include Digest::Instance
include Kernel
def self.digest(data);end
def self.hexdigest(data);end
def self.file(name);end
def self.base64digest(str, *args);end
def self.digest(data);end
def self.hexdigest(data);end
end
class OpenSSL::Digest::SHA512 < OpenSSL::Digest
include Digest::Instance
include Kernel
def self.digest(data);end
def self.hexdigest(data);end
def self.file(name);end
def self.base64digest(str, *args);end
def self.digest(data);end
def self.hexdigest(data);end
end
class OpenSSL::Digest::Digest < OpenSSL::Digest
include Digest::Instance
include Kernel
def self.digest(name, data);end
def self.hexdigest(*args);end
def self.file(name);end
def self.base64digest(str, *args);end
end
class OpenSSL::HMACError < OpenSSL::OpenSSLError
include Kernel
def self.exception(*args);end
end
class OpenSSL::HMAC < Object
include Kernel
def self.digest(arg0, arg1, arg2);end
def self.hexdigest(arg0, arg1, arg2);end
def self.digest(arg0, arg1, arg2);end
def self.hexdigest(arg0, arg1, arg2);end
def reset();end
def update(arg0);end
def <<(arg0);end
def digest();end
def hexdigest();end
end
module OpenSSL::Netscape
end
class OpenSSL::Netscape::SPKIError < OpenSSL::OpenSSLError
include Kernel
def self.exception(*args);end
end
class OpenSSL::Netscape::SPKI < Object
include Kernel
def to_der();end
def to_pem();end
def to_text();end
def public_key();end
def public_key=(arg0);end
def sign(arg0, arg1);end
def verify(arg0);end
def challenge();end
def challenge=(arg0);end
end
class OpenSSL::PKCS12 < Object
include Kernel
def self.create(*args);end
def self.create(*args);end
def key();end
def certificate();end
def ca_certs();end
def to_der();end
end
class OpenSSL::PKCS12::PKCS12Error < OpenSSL::OpenSSLError
include Kernel
def self.exception(*args);end
end
class OpenSSL::PKCS7 < Object
include Kernel
def self.read_smime(arg0);end
def self.write_smime(*args);end
def self.sign(*args);end
def self.encrypt(*args);end
def self.read_smime(arg0);end
def self.write_smime(*args);end
def self.sign(*args);end
def self.encrypt(*args);end
def data();end
def error_string();end
def error_string=(arg0);end
def type=(arg0);end
def type();end
def detached=(arg0);end
def detached();end
def detached?();end
def cipher=(arg0);end
def add_signer(arg0);end
def signers();end
def add_recipient(arg0);end
def recipients();end
def add_certificate(arg0);end
def certificates=(arg0);end
def certificates();end
def add_crl(arg0);end
def crls=(arg0);end
def crls();end
def add_data(arg0);end
def data=(arg0);end
def verify(*args);end
def decrypt(*args);end
def to_pem();end
def to_der();end
end
class OpenSSL::PKCS7::PKCS7Error < OpenSSL::OpenSSLError
include Kernel
def self.exception(*args);end
end
class OpenSSL::PKCS7::SignerInfo < Object
include Kernel
def issuer();end
def serial();end
def signed_time();end
end
class OpenSSL::PKCS7::RecipientInfo < Object
include Kernel
def issuer();end
def serial();end
def enc_key();end
end
module OpenSSL::PKCS5
def pbkdf2_hmac(arg0, arg1, arg2, arg3, arg4);end
def pbkdf2_hmac_sha1(arg0, arg1, arg2, arg3);end
def self.pbkdf2_hmac(arg0, arg1, arg2, arg3, arg4);end
def self.pbkdf2_hmac_sha1(arg0, arg1, arg2, arg3);end
end
class OpenSSL::PKCS5::PKCS5Error < OpenSSL::OpenSSLError
include Kernel
def self.exception(*args);end
end
module OpenSSL::PKey
def read(*args);end
def self.read(*args);end
end
class OpenSSL::PKey::PKeyError < OpenSSL::OpenSSLError
include Kernel
def self.exception(*args);end
end
class OpenSSL::PKey::PKey < Object
include Kernel
def sign(arg0, arg1);end
def verify(arg0, arg1, arg2);end
end
class OpenSSL::PKey::RSAError < OpenSSL::PKey::PKeyError
include Kernel
def self.exception(*args);end
end
class OpenSSL::PKey::RSA < OpenSSL::PKey::PKey
include Kernel
def self.generate(*args);end
def self.generate(*args);end
def public?();end
def private?();end
def to_text();end
def export(*args);end
def to_pem(*args);end
def to_der();end
def public_key();end
def public_encrypt(*args);end
def public_decrypt(*args);end
def private_encrypt(*args);end
def private_decrypt(*args);end
def n();end
def n=(arg0);end
def e();end
def e=(arg0);end
def d();end
def d=(arg0);end
def p=(arg0);end
def q();end
def q=(arg0);end
def dmp1();end
def dmp1=(arg0);end
def dmq1();end
def dmq1=(arg0);end
def iqmp();end
def iqmp=(arg0);end
def params();end
end
class OpenSSL::PKey::DSAError < OpenSSL::PKey::PKeyError
include Kernel
def self.exception(*args);end
end
class OpenSSL::PKey::DSA < OpenSSL::PKey::PKey
include Kernel
def self.generate(arg0);end
def self.generate(arg0);end
def public?();end
def private?();end
def to_text();end
def export(*args);end
def to_pem(*args);end
def to_der();end
def public_key();end
def syssign(arg0);end
def sysverify(arg0, arg1);end
def p=(arg0);end
def q();end
def q=(arg0);end
def g();end
def g=(arg0);end
def pub_key();end
def pub_key=(arg0);end
def priv_key();end
def priv_key=(arg0);end
def params();end
end
class OpenSSL::PKey::DHError < OpenSSL::PKey::PKeyError
include Kernel
def self.exception(*args);end
end
class OpenSSL::PKey::DH < OpenSSL::PKey::PKey
include Kernel
def self.generate(*args);end
def self.generate(*args);end
def public?();end
def private?();end
def to_text();end
def export();end
def to_pem();end
def to_der();end
def public_key();end
def params_ok?();end
def generate_key!();end
def compute_key(arg0);end
def p=(arg0);end
def g();end
def g=(arg0);end
def pub_key();end
def pub_key=(arg0);end
def priv_key();end
def priv_key=(arg0);end
def params();end
end
class OpenSSL::PKey::ECError < OpenSSL::PKey::PKeyError
include Kernel
def self.exception(*args);end
end
class OpenSSL::PKey::EC < OpenSSL::PKey::PKey
include Kernel
def self.builtin_curves();end
def self.builtin_curves();end
def group();end
def group=(arg0);end
def private_key();end
def private_key=(arg0);end
def public_key();end
def public_key=(arg0);end
def private_key?();end
def public_key?();end
def generate_key();end
def check_key();end
def dh_compute_key(arg0);end
def dsa_sign_asn1(arg0);end
def dsa_verify_asn1(arg0, arg1);end
def export(*args);end
def to_pem(*args);end
def to_der();end
def to_text();end
end
class OpenSSL::PKey::EC::Group < Object
include Kernel
def generator();end
def set_generator(arg0, arg1, arg2);end
def order();end
def cofactor();end
def curve_name();end
def asn1_flag();end
def asn1_flag=(arg0);end
def point_conversion_form();end
def point_conversion_form=(arg0);end
def seed();end
def seed=(arg0);end
def degree();end
def to_pem();end
def to_der();end
def to_text();end
end
class OpenSSL::PKey::EC::Group::Error < OpenSSL::OpenSSLError
include Kernel
def self.exception(*args);end
end
class OpenSSL::PKey::EC::Point < Object
include Kernel
def group();end
def infinity?();end
def on_curve?();end
def make_affine!();end
def invert!();end
def set_to_infinity!();end
def to_bn();end
def mul(*args);end
end
class OpenSSL::PKey::EC::Point::Error < OpenSSL::OpenSSLError
include Kernel
def self.exception(*args);end
end
module OpenSSL::Random
def seed(arg0);end
def random_add(arg0, arg1);end
def load_random_file(arg0);end
def write_random_file(arg0);end
def random_bytes(arg0);end
def pseudo_bytes(arg0);end
def egd(arg0);end
def egd_bytes(arg0, arg1);end
def status?();end
def self.seed(arg0);end
def self.random_add(arg0, arg1);end
def self.load_random_file(arg0);end
def self.write_random_file(arg0);end
def self.random_bytes(arg0);end
def self.pseudo_bytes(arg0);end
def self.egd(arg0);end
def self.egd_bytes(arg0, arg1);end
def self.status?();end
def seed(arg0);end
def random_add(arg0, arg1);end
def load_random_file(arg0);end
def write_random_file(arg0);end
def random_bytes(arg0);end
def pseudo_bytes(arg0);end
def egd(arg0);end
def egd_bytes(arg0, arg1);end
def status?();end
end
class OpenSSL::Random::RandomError < OpenSSL::OpenSSLError
include Kernel
def self.exception(*args);end
end
module OpenSSL::SSL
def verify_certificate_identity(cert, hostname);end
def verify_hostname(hostname, san);end
def verify_wildcard(domain_component, san_component);end
def self.verify_certificate_identity(cert, hostname);end
def self.verify_hostname(hostname, san);end
def self.verify_wildcard(domain_component, san_component);end
end
class OpenSSL::SSL::SSLError < OpenSSL::OpenSSLError
include Kernel
def self.exception(*args);end
end
class OpenSSL::SSL::Session < Object
include Kernel
def time();end
def time=(arg0);end
def timeout();end
def timeout=(arg0);end
def id();end
def to_der();end
def to_pem();end
def to_text();end
end
class OpenSSL::SSL::Session::SessionError < OpenSSL::OpenSSLError
include Kernel
def self.exception(*args);end
end
class OpenSSL::SSL::SSLContext < Object
include Kernel
def cert();end
def cert=(arg0);end
def key();end
def key=(arg0);end
def client_ca();end
def client_ca=(arg0);end
def ca_file();end
def ca_file=(arg0);end
def ca_path();end
def ca_path=(arg0);end
def timeout();end
def timeout=(arg0);end
def verify_mode();end
def verify_mode=(arg0);end
def verify_depth();end
def verify_depth=(arg0);end
def verify_callback();end
def verify_callback=(arg0);end
def options();end
def options=(arg0);end
def cert_store();end
def cert_store=(arg0);end
def extra_chain_cert();end
def extra_chain_cert=(arg0);end
def client_cert_cb();end
def client_cert_cb=(arg0);end
def tmp_dh_callback();end
def tmp_dh_callback=(arg0);end
def session_id_context();end
def session_id_context=(arg0);end
def session_get_cb();end
def session_get_cb=(arg0);end
def session_new_cb();end
def session_new_cb=(arg0);end
def session_remove_cb();end
def session_remove_cb=(arg0);end
def servername_cb();end
def servername_cb=(arg0);end
def renegotiation_cb();end
def renegotiation_cb=(arg0);end
def npn_protocols();end
def npn_protocols=(arg0);end
def npn_select_cb();end
def npn_select_cb=(arg0);end
def ssl_timeout();end
def ssl_timeout=(arg0);end
def ssl_version=(arg0);end
def ciphers();end
def ciphers=(arg0);end
def setup();end
def session_add(arg0);end
def session_remove(arg0);end
def session_cache_mode();end
def session_cache_mode=(arg0);end
def session_cache_size();end
def session_cache_size=(arg0);end
def session_cache_stats();end
def flush_sessions(*args);end
def set_params(*args);end
end
class OpenSSL::SSL::SSLSocket < Object
include OpenSSL::SSL::Nonblock
include OpenSSL::SSL::SocketForwarder
include OpenSSL::Buffering
include Enumerable
include Kernel
def io();end
def context();end
def hostname();end
def hostname=(arg0);end
def sync_close();end
def sync_close=(arg0);end
def to_io();end
def connect();end
def connect_nonblock();end
def accept();end
def accept_nonblock();end
def sysread(*args);end
def syswrite(arg0);end
def sysclose();end
def cert();end
def peer_cert();end
def peer_cert_chain();end
def ssl_version();end
def cipher();end
def state();end
def pending();end
def session_reused?();end
def session=(arg0);end
def verify_result();end
def client_ca();end
def npn_protocol();end
def post_connection_check(hostname);end
def session();end
end
module OpenSSL::SSL::SocketForwarder
def addr();end
def peeraddr();end
def setsockopt(level, optname, optval);end
def getsockopt(level, optname);end
def fcntl(*args);end
def closed?();end
def do_not_reverse_lookup=(flag);end
end
module OpenSSL::SSL::Nonblock
end
class OpenSSL::SSL::SSLServer < Object
include OpenSSL::SSL::SocketForwarder
include Kernel
def start_immediately();end
def start_immediately=(arg0);end
def to_io();end
def listen(*args);end
def shutdown(*args);end
def accept();end
def close();end
end
module OpenSSL::X509
end
class OpenSSL::X509::AttributeError < OpenSSL::OpenSSLError
include Kernel
def self.exception(*args);end
end
class OpenSSL::X509::Attribute < Object
include Kernel
def oid=(arg0);end
def oid();end
def value=(arg0);end
def value();end
def to_der();end
end
class OpenSSL::X509::CertificateError < OpenSSL::OpenSSLError
include Kernel
def self.exception(*args);end
end
class OpenSSL::X509::Certificate < Object
include Kernel
def to_der();end
def to_pem();end
def to_text();end
def version();end
def version=(arg0);end
def signature_algorithm();end
def serial();end
def serial=(arg0);end
def subject();end
def subject=(arg0);end
def issuer();end
def issuer=(arg0);end
def not_before();end
def not_before=(arg0);end
def not_after();end
def not_after=(arg0);end
def public_key();end
def public_key=(arg0);end
def sign(arg0, arg1);end
def verify(arg0);end
def check_private_key(arg0);end
def extensions();end
def extensions=(arg0);end
def add_extension(arg0);end
end
class OpenSSL::X509::CRLError < OpenSSL::OpenSSLError
include Kernel
def self.exception(*args);end
end
class OpenSSL::X509::CRL < Object
include Kernel
def version();end
def version=(arg0);end
def signature_algorithm();end
def issuer();end
def issuer=(arg0);end
def last_update();end
def last_update=(arg0);end
def next_update();end
def next_update=(arg0);end
def revoked();end
def revoked=(arg0);end
def add_revoked(arg0);end
def sign(arg0, arg1);end
def verify(arg0);end
def to_der();end
def to_pem();end
def to_text();end
def extensions();end
def extensions=(arg0);end
def add_extension(arg0);end
end
class OpenSSL::X509::ExtensionError < OpenSSL::OpenSSLError
include Kernel
def self.exception(*args);end
end
class OpenSSL::X509::ExtensionFactory < Object
include Kernel
def issuer_certificate();end
def subject_certificate();end
def subject_request();end
def crl();end
def config();end
def issuer_certificate=(arg0);end
def subject_certificate=(arg0);end
def subject_request=(arg0);end
def crl=(arg0);end
def config=(arg0);end
def create_ext(*args);end
def create_extension(*args);end
def create_ext_from_array(ary);end
def create_ext_from_string(str);end
def create_ext_from_hash(hash);end
end
class OpenSSL::X509::Extension < Object
include Kernel
def oid=(arg0);end
def value=(arg0);end
def critical=(arg0);end
def oid();end
def value();end
def critical?();end
def to_der();end
def to_h();end
def to_a();end
end
class OpenSSL::X509::NameError < OpenSSL::OpenSSLError
include Kernel
def self.exception(*args);end
end
class OpenSSL::X509::Name < Object
include Comparable
include Kernel
def self.parse_rfc2253(str, template = nil);end
def self.parse_openssl(str, template = nil);end
def self.parse(str, template = nil);end
def self.parse_rfc2253(str, template = nil);end
def self.parse_openssl(str, template = nil);end
def self.parse(str, template = nil);end
def add_entry(*args);end
def to_a();end
def cmp(arg0);end
def hash_old();end
def to_der();end
end
module OpenSSL::X509::Name::RFC2253DN
def expand_pair(str);end
def expand_hexstring(str);end
def expand_value(str1, str2, str3);end
def scan(dn);end
def self.expand_pair(str);end
def self.expand_hexstring(str);end
def self.expand_value(str1, str2, str3);end
def self.scan(dn);end
end
class OpenSSL::X509::RequestError < OpenSSL::OpenSSLError
include Kernel
def self.exception(*args);end
end
class OpenSSL::X509::Request < Object
include Kernel
def to_pem();end
def to_der();end
def to_text();end
def version();end
def version=(arg0);end
def subject();end
def subject=(arg0);end
def signature_algorithm();end
def public_key();end
def public_key=(arg0);end
def sign(arg0, arg1);end
def verify(arg0);end
def attributes();end
def attributes=(arg0);end
def add_attribute(arg0);end
end
class OpenSSL::X509::RevokedError < OpenSSL::OpenSSLError
include Kernel
def self.exception(*args);end
end
class OpenSSL::X509::Revoked < Object
include Kernel
def serial();end
def serial=(arg0);end
def time();end
def time=(arg0);end
def extensions();end
def extensions=(arg0);end
def add_extension(arg0);end
end
class OpenSSL::X509::StoreError < OpenSSL::OpenSSLError
include Kernel
def self.exception(*args);end
end
class OpenSSL::X509::Store < Object
include Kernel
def verify_callback();end
def error();end
def error_string();end
def chain();end
def verify_callback=(arg0);end
def flags=(arg0);end
def purpose=(arg0);end
def trust=(arg0);end
def time=(arg0);end
def add_path(arg0);end
def add_file(arg0);end
def set_default_paths();end
def add_cert(arg0);end
def add_crl(arg0);end
def verify(*args);end
end
class OpenSSL::X509::StoreContext < Object
include Kernel
def verify();end
def chain();end
def error();end
def error=(arg0);end
def error_string();end
def error_depth();end
def current_cert();end
def current_crl();end
def flags=(arg0);end
def purpose=(arg0);end
def trust=(arg0);end
def time=(arg0);end
def cleanup();end
end
module OpenSSL::OCSP
end
class OpenSSL::OCSP::OCSPError < OpenSSL::OpenSSLError
include Kernel
def self.exception(*args);end
end
class OpenSSL::OCSP::Request < Object
include Kernel
def add_nonce(*args);end
def check_nonce(arg0);end
def add_certid(arg0);end
def certid();end
def sign(*args);end
def verify(*args);end
def to_der();end
end
class OpenSSL::OCSP::Response < Object
include Kernel
def self.create(arg0, arg1);end
def self.create(arg0, arg1);end
def status();end
def status_string();end
def basic();end
def to_der();end
end
class OpenSSL::OCSP::BasicResponse < Object
include Kernel
def copy_nonce(arg0);end
def add_nonce(*args);end
def add_status(arg0, arg1, arg2, arg3, arg4, arg5, arg6);end
def status();end
def sign(*args);end
def verify(*args);end
end
class OpenSSL::OCSP::CertificateId < Object
include Kernel
def cmp(arg0);end
def cmp_issuer(arg0);end
def serial();end
end
class OpenSSL::Engine < Object
include Kernel
def self.cleanup();end
def self.engines();end
def self.by_id(arg0);end
def self.cleanup();end
def self.engines();end
def self.by_id(arg0);end
def id();end
def finish();end
def cipher(arg0);end
def digest(arg0);end
def load_private_key(*args);end
def load_public_key(*args);end
def set_default(arg0);end
def ctrl_cmd(*args);end
def cmds();end
end
class OpenSSL::Engine::EngineError < OpenSSL::OpenSSLError
include Kernel
def self.exception(*args);end
end
module OpenSSL::ASN1
def traverse(arg0);end
def decode(arg0);end
def decode_all(arg0);end
def Boolean(*args);end
def Enumerated(*args);end
def BitString(*args);end
def OctetString(*args);end
def UTF8String(*args);end
def NumericString(*args);end
def PrintableString(*args);end
def T61String(*args);end
def VideotexString(*args);end
def IA5String(*args);end
def GraphicString(*args);end
def ISO64String(*args);end
def GeneralString(*args);end
def UniversalString(*args);end
def BMPString(*args);end
def Null(*args);end
def ObjectId(*args);end
def UTCTime(*args);end
def GeneralizedTime(*args);end
def Sequence(*args);end
def Set(*args);end
def EndOfContent(*args);end
def self.traverse(arg0);end
def self.decode(arg0);end
def self.decode_all(arg0);end
def self.Boolean(*args);end
def self.Enumerated(*args);end
def self.BitString(*args);end
def self.OctetString(*args);end
def self.UTF8String(*args);end
def self.NumericString(*args);end
def self.PrintableString(*args);end
def self.T61String(*args);end
def self.VideotexString(*args);end
def self.IA5String(*args);end
def self.GraphicString(*args);end
def self.ISO64String(*args);end
def self.GeneralString(*args);end
def self.UniversalString(*args);end
def self.BMPString(*args);end
def self.Null(*args);end
def self.ObjectId(*args);end
def self.UTCTime(*args);end
def self.GeneralizedTime(*args);end
def self.Sequence(*args);end
def self.Set(*args);end
def self.EndOfContent(*args);end
end
class OpenSSL::ASN1::ASN1Error < OpenSSL::OpenSSLError
include Kernel
def self.exception(*args);end
end
class OpenSSL::ASN1::ASN1Data < Object
include Kernel
def value();end
def value=(arg0);end
def tag();end
def tag=(arg0);end
def tag_class();end
def tag_class=(arg0);end
def infinite_length();end
def infinite_length=(arg0);end
def to_der();end
end
class OpenSSL::ASN1::Primitive < OpenSSL::ASN1::ASN1Data
include Kernel
def tagging();end
def tagging=(arg0);end
def to_der();end
end
class OpenSSL::ASN1::Constructive < OpenSSL::ASN1::ASN1Data
include Enumerable
include Kernel
def tagging();end
def tagging=(arg0);end
def to_der();end
def each();end
end
class OpenSSL::ASN1::Boolean < OpenSSL::ASN1::Primitive
include Kernel
end
class OpenSSL::ASN1::Integer < OpenSSL::ASN1::Primitive
include Kernel
end
class OpenSSL::ASN1::Enumerated < OpenSSL::ASN1::Primitive
include Kernel
end
class OpenSSL::ASN1::BitString < OpenSSL::ASN1::Primitive
include Kernel
def unused_bits();end
def unused_bits=(arg0);end
end
class OpenSSL::ASN1::OctetString < OpenSSL::ASN1::Primitive
include Kernel
end
class OpenSSL::ASN1::UTF8String < OpenSSL::ASN1::Primitive
include Kernel
end
class OpenSSL::ASN1::NumericString < OpenSSL::ASN1::Primitive
include Kernel
end
class OpenSSL::ASN1::PrintableString < OpenSSL::ASN1::Primitive
include Kernel
end
class OpenSSL::ASN1::T61String < OpenSSL::ASN1::Primitive
include Kernel
end
class OpenSSL::ASN1::VideotexString < OpenSSL::ASN1::Primitive
include Kernel
end
class OpenSSL::ASN1::IA5String < OpenSSL::ASN1::Primitive
include Kernel
end
class OpenSSL::ASN1::GraphicString < OpenSSL::ASN1::Primitive
include Kernel
end
class OpenSSL::ASN1::ISO64String < OpenSSL::ASN1::Primitive
include Kernel
end
class OpenSSL::ASN1::GeneralString < OpenSSL::ASN1::Primitive
include Kernel
end
class OpenSSL::ASN1::UniversalString < OpenSSL::ASN1::Primitive
include Kernel
end
class OpenSSL::ASN1::BMPString < OpenSSL::ASN1::Primitive
include Kernel
end
class OpenSSL::ASN1::Null < OpenSSL::ASN1::Primitive
include Kernel
end
class OpenSSL::ASN1::ObjectId < OpenSSL::ASN1::Primitive
include Kernel
def self.register(arg0, arg1, arg2);end
def self.register(arg0, arg1, arg2);end
def sn();end
def ln();end
def oid();end
def short_name();end
def long_name();end
end
class OpenSSL::ASN1::UTCTime < OpenSSL::ASN1::Primitive
include Kernel
end
class OpenSSL::ASN1::GeneralizedTime < OpenSSL::ASN1::Primitive
include Kernel
end
class OpenSSL::ASN1::Sequence < OpenSSL::ASN1::Constructive
include Enumerable
include Kernel
end
class OpenSSL::ASN1::Set < OpenSSL::ASN1::Constructive
include Enumerable
include Kernel
end
class OpenSSL::ASN1::EndOfContent < OpenSSL::ASN1::ASN1Data
include Kernel
end
module OpenSSL::Buffering
include Enumerable
def sync();end
def sync=(arg0);end
def read(*args);end
def readpartial(maxlen, buf = nil);end
def read_nonblock(maxlen, buf = nil);end
def gets(*args);end
def each(*args);end
def each_line(*args);end
def readlines(*args);end
def readline(*args);end
def getc();end
def each_byte();end
def readchar();end
def ungetc(c);end
def eof?();end
def eof();end
def write(s);end
def write_nonblock(s);end
def <<(s);end
def puts(*args);end
def print(*args);end
def printf(s, *args);end
def flush();end
def close();end
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
module Fcntl
end
