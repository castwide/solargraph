class Module < Object
include Kernel
def self.constants(*args);end
def self.nesting();end
def self.new(*args);end
def self.allocate();end
def self.superclass();end
def self.constants(*args);end
def self.nesting();end
def <=>(arg0);end
def module_exec(*args);end
def class_exec(*args);end
def <=(arg0);end
def >=(arg0);end
def ==(arg0);end
def ===(arg0);end
def include?(arg0);end
def included_modules();end
def ancestors();end
def name();end
def public_instance_methods(*args);end
def instance_methods(*args);end
def private_instance_methods(*args);end
def protected_instance_methods(*args);end
def const_get(*args);end
def constants(*args);end
def const_defined?(*args);end
def const_set(arg0, arg1);end
def class_variables(*args);end
def class_variable_get(arg0);end
def remove_class_variable(arg0);end
def class_variable_defined?(arg0);end
def class_variable_set(arg0, arg1);end
def private_constant(*args);end
def public_constant(*args);end
def singleton_class?();end
def deprecate_constant(*args);end
def freeze();end
def inspect();end
def module_eval(*args);end
def const_missing(arg0);end
def prepend(*args);end
def method_defined?(arg0);end
def class_eval(*args);end
def public_method_defined?(arg0);end
def private_method_defined?(arg0);end
def <(arg0);end
def public_class_method(*args);end
def >(arg0);end
def protected_method_defined?(arg0);end
def private_class_method(*args);end
def to_s();end
def autoload(arg0, arg1);end
def autoload?(arg0);end
def instance_method(arg0);end
def public_instance_method(arg0);end
def include(*args);end
end
class Object < BasicObject
include Kernel
def self.new(*args);end
def self.allocate();end
def self.superclass();end
end
class Class < Module
include Kernel
end
class BasicObject
def self.new(*args);end
def self.allocate();end
def self.superclass();end
def !();end
def ==(arg0);end
def !=(arg0);end
def __send__(*args);end
def equal?(arg0);end
def instance_eval(*args);end
def instance_exec(*args);end
def __id__();end
end
module Kernel
def self.`(arg0);end
def self.gets(*args);end
def self.proc();end
def self.lambda();end
def self.sprintf(*args);end
def self.format(*args);end
def self.Integer(*args);end
def self.Float(arg0);end
def self.String(arg0);end
def self.Array(arg0);end
def self.Hash(arg0);end
def self.select(*args);end
def self.local_variables();end
def self.warn(*args);end
def self.raise(*args);end
def self.fail(*args);end
def self.global_variables();end
def self.__method__();end
def self.__callee__();end
def self.__dir__();end
def self.eval(*args);end
def self.iterator?();end
def self.block_given?();end
def self.catch(*args);end
def self.throw(*args);end
def self.loop();end
def self.trace_var(*args);end
def self.untrace_var(*args);end
def self.at_exit();end
def self.load(*args);end
def self.syscall(*args);end
def self.open(*args);end
def self.printf(*args);end
def self.print(*args);end
def self.putc(arg0);end
def self.puts(*args);end
def self.readline(*args);end
def self.readlines(*args);end
def self.p(*args);end
def self.test(*args);end
def self.rand(*args);end
def self.srand(*args);end
def self.trap(*args);end
def self.require(arg0);end
def self.require_relative(arg0);end
def self.autoload(arg0, arg1);end
def self.autoload?(arg0);end
def self.binding();end
def self.caller(*args);end
def self.caller_locations(*args);end
def self.fork();end
def self.exit(*args);end
def self.sleep(*args);end
def self.exec(*args);end
def self.exit!(*args);end
def self.system(*args);end
def self.spawn(*args);end
def self.abort(*args);end
def self.Rational(*args);end
def self.Complex(*args);end
def self.set_trace_func(arg0);end
def instance_of?(arg0);end
def public_send(*args);end
def instance_variable_get(arg0);end
def instance_variable_set(arg0, arg1);end
def instance_variable_defined?(arg0);end
def remove_instance_variable(arg0);end
def private_methods(*args);end
def kind_of?(arg0);end
def instance_variables();end
def tap();end
def singleton_method(arg0);end
def is_a?(arg0);end
def define_singleton_method(*args);end
def extend(*args);end
def method(arg0);end
def public_method(arg0);end
def to_enum(*args);end
def enum_for(*args);end
def <=>(arg0);end
def ===(arg0);end
def =~(arg0);end
def !~(arg0);end
def eql?(arg0);end
def respond_to?(*args);end
def freeze();end
def inspect();end
def display(*args);end
def object_id();end
def send(*args);end
def to_s();end
def nil?();end
def hash();end
def class();end
def singleton_class();end
def clone();end
def dup();end
def itself();end
def taint();end
def tainted?();end
def untaint();end
def untrust();end
def trust();end
def untrusted?();end
def methods(*args);end
def protected_methods(*args);end
def frozen?();end
def public_methods(*args);end
def singleton_methods(*args);end
end
class NilClass < Object
include Kernel
def &(arg0);end
def ^(arg0);end
def |(arg0);end
def to_a();end
def to_i();end
def to_f();end
def to_h();end
def to_r();end
def rationalize(*args);end
def to_c();end
end
class Data < Object
include Kernel
end
class TrueClass < Object
include Kernel
def &(arg0);end
def ^(arg0);end
def |(arg0);end
end
class FalseClass < Object
include Kernel
def &(arg0);end
def ^(arg0);end
def |(arg0);end
end
class Encoding < Object
include Kernel
def self.list();end
def self.name_list();end
def self.aliases();end
def self.find(arg0);end
def self.compatible?(arg0, arg1);end
def self._load(arg0);end
def self.default_external();end
def self.default_external=(arg0);end
def self.default_internal();end
def self.default_internal=(arg0);end
def self.locale_charmap();end
def self.list();end
def self.name_list();end
def self.aliases();end
def self.find(arg0);end
def self.compatible?(arg0, arg1);end
def self._load(arg0);end
def self.default_external();end
def self.default_external=(arg0);end
def self.default_internal();end
def self.default_internal=(arg0);end
def self.locale_charmap();end
def names();end
def dummy?();end
def ascii_compatible?();end
def replicate(arg0);end
def _dump(*args);end
end
class Encoding::CompatibilityError < EncodingError
include Kernel
def self.exception(*args);end
end
class Encoding::UndefinedConversionError < EncodingError
include Kernel
def self.exception(*args);end
def source_encoding();end
def destination_encoding();end
def source_encoding_name();end
def destination_encoding_name();end
def error_char();end
end
class Encoding::InvalidByteSequenceError < EncodingError
include Kernel
def self.exception(*args);end
def source_encoding();end
def destination_encoding();end
def source_encoding_name();end
def destination_encoding_name();end
def error_bytes();end
def readagain_bytes();end
def incomplete_input?();end
end
class Encoding::ConverterNotFoundError < EncodingError
include Kernel
def self.exception(*args);end
end
class Encoding::Converter < Data
include Kernel
def self.asciicompat_encoding(arg0);end
def self.search_convpath(*args);end
def self.asciicompat_encoding(arg0);end
def self.search_convpath(*args);end
def convpath();end
def source_encoding();end
def destination_encoding();end
def primitive_convert(*args);end
def convert(arg0);end
def finish();end
def primitive_errinfo();end
def insert_output(arg0);end
def putback(*args);end
def last_error();end
def replacement();end
def replacement=(arg0);end
end
module Comparable
def <(arg0);end
def >(arg0);end
def <=(arg0);end
def >=(arg0);end
def ==(arg0);end
def between?(arg0, arg1);end
end
module Enumerable
def to_a(*args);end
def to_h(*args);end
def include?(arg0);end
def find(*args);end
def entries(*args);end
def sort();end
def sort_by();end
def grep(arg0);end
def grep_v(arg0);end
def count(*args);end
def detect(*args);end
def find_index(*args);end
def find_all();end
def select();end
def reject();end
def collect();end
def map();end
def flat_map();end
def collect_concat();end
def inject(*args);end
def reduce(*args);end
def partition();end
def group_by();end
def first(*args);end
def all?();end
def any?();end
def one?();end
def none?();end
def min(*args);end
def max(*args);end
def minmax();end
def min_by(*args);end
def max_by(*args);end
def minmax_by();end
def member?(arg0);end
def each_with_index(*args);end
def reverse_each(*args);end
def each_entry(*args);end
def each_slice(arg0);end
def each_cons(arg0);end
def each_with_object(arg0);end
def zip(*args);end
def take(arg0);end
def take_while();end
def drop(arg0);end
def drop_while();end
def cycle(*args);end
def chunk();end
def slice_before(*args);end
def slice_after(*args);end
def slice_when();end
def chunk_while();end
def lazy();end
end
class String < Object
include Comparable
include Kernel
def self.try_convert(arg0);end
def self.try_convert(arg0);end
def %(arg0);end
def *(arg0);end
def +(arg0);end
def unicode_normalize(*args);end
def to_c();end
def unicode_normalize!(*args);end
def unicode_normalized?(*args);end
def count(*args);end
def partition(arg0);end
def unpack(arg0);end
def encode(*args);end
def encode!(*args);end
def next();end
def casecmp(arg0);end
def insert(arg0, arg1);end
def bytesize();end
def match(*args);end
def succ!();end
def next!();end
def upto(*args);end
def index(*args);end
def rindex(*args);end
def replace(arg0);end
def clear();end
def chr();end
def +@();end
def -@();end
def setbyte(arg0, arg1);end
def getbyte(arg0);end
def <<(arg0);end
def scrub(*args);end
def scrub!(*args);end
def byteslice(*args);end
def dump();end
def downcase();end
def [](*args);end
def []=(*args);end
def upcase();end
def downcase!();end
def capitalize();end
def swapcase();end
def upcase!();end
def oct();end
def empty?();end
def hex();end
def chars();end
def split(*args);end
def capitalize!();end
def swapcase!();end
def concat(arg0);end
def codepoints();end
def reverse();end
def lines(*args);end
def bytes();end
def scan(arg0);end
def ord();end
def reverse!();end
def center(*args);end
def sub(*args);end
def intern();end
def end_with?(*args);end
def gsub(*args);end
def chop();end
def crypt(arg0);end
def gsub!(*args);end
def start_with?(*args);end
def rstrip();end
def sub!(*args);end
def ljust(*args);end
def length();end
def size();end
def strip!();end
def succ();end
def rstrip!();end
def chomp(*args);end
def strip();end
def rjust(*args);end
def lstrip!();end
def tr!(arg0, arg1);end
def chomp!(*args);end
def squeeze(*args);end
def lstrip();end
def tr_s!(arg0, arg1);end
def to_str();end
def to_sym();end
def chop!();end
def each_byte();end
def each_char();end
def each_codepoint();end
def to_i(*args);end
def tr_s(arg0, arg1);end
def delete(*args);end
def encoding();end
def force_encoding(arg0);end
def sum(*args);end
def delete!(*args);end
def squeeze!(*args);end
def tr(arg0, arg1);end
def to_f();end
def valid_encoding?();end
def slice(*args);end
def slice!(*args);end
def rpartition(arg0);end
def each_line(*args);end
def b();end
def ascii_only?();end
def to_r();end
end
class Symbol < Object
include Comparable
include Kernel
def self.all_symbols();end
def self.all_symbols();end
def [](*args);end
def empty?();end
def intern();end
def length();end
def size();end
def succ();end
def to_sym();end
def to_proc();end
def next();end
def casecmp(arg0);end
def match(arg0);end
def upcase();end
def downcase();end
def capitalize();end
def swapcase();end
def slice(*args);end
def encoding();end
def id2name();end
end
class Exception < Object
include Kernel
def self.exception(*args);end
def self.exception(*args);end
def exception(*args);end
def message();end
def backtrace();end
def backtrace_locations();end
def set_backtrace(arg0);end
def cause();end
end
class SystemExit < Exception
include Kernel
def self.exception(*args);end
def status();end
def success?();end
end
class SignalException < Exception
include Kernel
def self.exception(*args);end
def signo();end
def signm();end
end
class Interrupt < SignalException
include Kernel
def self.exception(*args);end
end
class StandardError < Exception
include Kernel
def self.exception(*args);end
end
class TypeError < StandardError
include Kernel
def self.exception(*args);end
end
class ArgumentError < StandardError
include Kernel
def self.exception(*args);end
end
class IndexError < StandardError
include Kernel
def self.exception(*args);end
end
class KeyError < IndexError
include Kernel
def self.exception(*args);end
end
class RangeError < StandardError
include Kernel
def self.exception(*args);end
end
class ScriptError < Exception
include Kernel
def self.exception(*args);end
end
class SyntaxError < ScriptError
include Kernel
def self.exception(*args);end
end
class LoadError < ScriptError
include Kernel
def self.exception(*args);end
def path();end
end
class NotImplementedError < ScriptError
include Kernel
def self.exception(*args);end
end
class NameError < StandardError
include DidYouMean::Correctable
include Kernel
def self.exception(*args);end
def receiver();end
end
class NoMethodError < NameError
include DidYouMean::Correctable
include Kernel
def self.exception(*args);end
def args();end
end
class RuntimeError < StandardError
include Kernel
def self.exception(*args);end
end
class SecurityError < Exception
include Kernel
def self.exception(*args);end
end
class NoMemoryError < Exception
include Kernel
def self.exception(*args);end
end
class EncodingError < StandardError
include Kernel
def self.exception(*args);end
end
class SystemCallError < StandardError
include Kernel
def self.exception(*args);end
def errno();end
end
module Errno
end
class Errno::NOERROR < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EPERM < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENOENT < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ESRCH < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EINTR < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EIO < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENXIO < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::E2BIG < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENOEXEC < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EBADF < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ECHILD < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EAGAIN < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENOMEM < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EACCES < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EFAULT < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENOTBLK < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EBUSY < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EEXIST < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EXDEV < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENODEV < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENOTDIR < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EISDIR < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EINVAL < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENFILE < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EMFILE < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENOTTY < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ETXTBSY < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EFBIG < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENOSPC < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ESPIPE < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EROFS < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EMLINK < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EPIPE < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EDOM < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ERANGE < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EDEADLK < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENAMETOOLONG < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENOLCK < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENOSYS < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENOTEMPTY < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ELOOP < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENOMSG < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EIDRM < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ECHRNG < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EL2NSYNC < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EL3HLT < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EL3RST < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ELNRNG < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EUNATCH < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENOCSI < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EL2HLT < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EBADE < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EBADR < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EXFULL < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENOANO < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EBADRQC < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EBADSLT < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EBFONT < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENOSTR < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENODATA < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ETIME < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENOSR < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENONET < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENOPKG < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EREMOTE < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENOLINK < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EADV < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ESRMNT < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ECOMM < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EPROTO < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EMULTIHOP < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EDOTDOT < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EBADMSG < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EOVERFLOW < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENOTUNIQ < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EBADFD < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EREMCHG < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ELIBACC < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ELIBBAD < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ELIBSCN < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ELIBMAX < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ELIBEXEC < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EILSEQ < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ERESTART < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ESTRPIPE < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EUSERS < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENOTSOCK < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EDESTADDRREQ < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EMSGSIZE < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EPROTOTYPE < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENOPROTOOPT < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EPROTONOSUPPORT < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ESOCKTNOSUPPORT < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EOPNOTSUPP < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EPFNOSUPPORT < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EAFNOSUPPORT < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EADDRINUSE < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EADDRNOTAVAIL < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENETDOWN < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENETUNREACH < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENETRESET < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ECONNABORTED < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ECONNRESET < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENOBUFS < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EISCONN < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENOTCONN < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ESHUTDOWN < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ETOOMANYREFS < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ETIMEDOUT < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ECONNREFUSED < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EHOSTDOWN < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EHOSTUNREACH < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EALREADY < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EINPROGRESS < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ESTALE < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EUCLEAN < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENOTNAM < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENAVAIL < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EISNAM < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EREMOTEIO < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EDQUOT < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ECANCELED < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EKEYEXPIRED < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EKEYREJECTED < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EKEYREVOKED < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EMEDIUMTYPE < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENOKEY < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENOMEDIUM < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ENOTRECOVERABLE < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EOWNERDEAD < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::ERFKILL < SystemCallError
include Kernel
def self.exception(*args);end
end
class Errno::EHWPOISON < SystemCallError
include Kernel
def self.exception(*args);end
end
class UncaughtThrowError < ArgumentError
include Kernel
def self.exception(*args);end
def tag();end
def value();end
end
class ZeroDivisionError < StandardError
include Kernel
def self.exception(*args);end
end
class FloatDomainError < RangeError
include Kernel
def self.exception(*args);end
end
class Numeric < Object
include Comparable
include Kernel
def %(arg0);end
def +@();end
def -@();end
def singleton_method_added(arg0);end
def to_int();end
def div(arg0);end
def coerce(arg0);end
def divmod(arg0);end
def i();end
def fdiv(arg0);end
def modulo(arg0);end
def remainder(arg0);end
def abs();end
def magnitude();end
def real?();end
def integer?();end
def zero?();end
def nonzero?();end
def floor();end
def ceil();end
def round(*args);end
def truncate();end
def step(*args);end
def positive?();end
def negative?();end
def quo(arg0);end
def numerator();end
def denominator();end
def arg();end
def rectangular();end
def rect();end
def polar();end
def real();end
def imaginary();end
def imag();end
def abs2();end
def angle();end
def phase();end
def conjugate();end
def conj();end
def to_c();end
end
class Integer < Numeric
include Comparable
include Kernel
def succ();end
def to_int();end
def to_i();end
def next();end
def upto(arg0);end
def chr(*args);end
def ord();end
def integer?();end
def floor();end
def ceil();end
def round(*args);end
def truncate();end
def odd?();end
def even?();end
def downto(arg0);end
def times();end
def pred();end
def to_r();end
def numerator();end
def denominator();end
def rationalize(*args);end
def gcd(arg0);end
def lcm(arg0);end
def gcdlcm(arg0);end
end
class Fixnum < Integer
include Comparable
include Kernel
def %(arg0);end
def &(arg0);end
def *(arg0);end
def +(arg0);end
def -(arg0);end
def /(arg0);end
def ^(arg0);end
def |(arg0);end
def ~();end
def -@();end
def **(arg0);end
def <<(arg0);end
def >>(arg0);end
def [](arg0);end
def size();end
def succ();end
def to_f();end
def div(arg0);end
def divmod(arg0);end
def fdiv(arg0);end
def modulo(arg0);end
def abs();end
def magnitude();end
def zero?();end
def odd?();end
def even?();end
def bit_length();end
end
class Float < Numeric
include Comparable
include Kernel
def %(arg0);end
def *(arg0);end
def +(arg0);end
def -(arg0);end
def /(arg0);end
def -@();end
def **(arg0);end
def to_int();end
def to_i();end
def to_f();end
def coerce(arg0);end
def divmod(arg0);end
def fdiv(arg0);end
def modulo(arg0);end
def abs();end
def magnitude();end
def zero?();end
def floor();end
def ceil();end
def round(*args);end
def truncate();end
def positive?();end
def negative?();end
def quo(arg0);end
def nan?();end
def infinite?();end
def finite?();end
def next_float();end
def prev_float();end
def to_r();end
def numerator();end
def denominator();end
def rationalize(*args);end
def arg();end
def angle();end
def phase();end
end
class Bignum < Integer
include Comparable
include Kernel
def %(arg0);end
def &(arg0);end
def *(arg0);end
def +(arg0);end
def -(arg0);end
def /(arg0);end
def ^(arg0);end
def |(arg0);end
def ~();end
def -@();end
def **(arg0);end
def <<(arg0);end
def >>(arg0);end
def [](arg0);end
def size();end
def to_f();end
def div(arg0);end
def coerce(arg0);end
def divmod(arg0);end
def fdiv(arg0);end
def modulo(arg0);end
def remainder(arg0);end
def abs();end
def magnitude();end
def odd?();end
def even?();end
def bit_length();end
end
class Array < Object
include Enumerable
include Kernel
def self.[](*args);end
def self.try_convert(arg0);end
def self.[](*args);end
def self.try_convert(arg0);end
def fill(*args);end
def assoc(arg0);end
def rassoc(arg0);end
def uniq();end
def uniq!();end
def compact();end
def compact!();end
def flatten(*args);end
def to_h();end
def flatten!(*args);end
def shuffle!(*args);end
def shuffle(*args);end
def combination(arg0);end
def repeated_permutation(arg0);end
def permutation(*args);end
def product(*args);end
def sample(*args);end
def repeated_combination(arg0);end
def bsearch_index();end
def bsearch();end
def select!();end
def &(arg0);end
def *(arg0);end
def +(arg0);end
def -(arg0);end
def sort();end
def count(*args);end
def find_index(*args);end
def reject();end
def collect();end
def map();end
def pack(arg0);end
def first(*args);end
def any?();end
def reverse_each();end
def zip(*args);end
def take(arg0);end
def take_while();end
def drop(arg0);end
def drop_while();end
def cycle(*args);end
def insert(*args);end
def |(arg0);end
def index(*args);end
def rindex(*args);end
def replace(arg0);end
def clear();end
def <<(arg0);end
def [](*args);end
def []=(*args);end
def reverse();end
def empty?();end
def concat(arg0);end
def reverse!();end
def delete(arg0);end
def length();end
def size();end
def each();end
def slice(*args);end
def slice!(*args);end
def to_ary();end
def to_a();end
def dig(*args);end
def at(arg0);end
def fetch(*args);end
def last(*args);end
def push(*args);end
def pop(*args);end
def shift(*args);end
def unshift(*args);end
def each_index();end
def join(*args);end
def rotate(*args);end
def rotate!(*args);end
def sort!();end
def collect!();end
def map!();end
def sort_by!();end
def keep_if();end
def values_at(*args);end
def delete_at(arg0);end
def delete_if();end
def reject!();end
def transpose();end
end
class Hash < Object
include Enumerable
include Kernel
def self.[](*args);end
def self.try_convert(arg0);end
def self.[](*args);end
def self.try_convert(arg0);end
def [](arg0);end
def []=(arg0, arg1);end
def empty?();end
def length();end
def size();end
def each();end
def to_hash();end
def to_proc();end
def to_a();end
def dig(*args);end
def to_h();end
def reject();end
def any?();end
def member?(arg0);end
def index(arg0);end
def replace(arg0);end
def clear();end
def delete(arg0);end
def fetch(*args);end
def shift();end
def select!();end
def keep_if();end
def values_at(*args);end
def delete_if();end
def reject!();end
def assoc(arg0);end
def rassoc(arg0);end
def flatten(*args);end
def default(*args);end
def rehash();end
def store(arg0, arg1);end
def default=(arg0);end
def default_proc();end
def default_proc=(arg0);end
def key(arg0);end
def each_value();end
def each_key();end
def each_pair();end
def keys();end
def values();end
def fetch_values(*args);end
def invert();end
def update(arg0);end
def merge!(arg0);end
def merge(arg0);end
def has_key?(arg0);end
def has_value?(arg0);end
def key?(arg0);end
def value?(arg0);end
def compare_by_identity();end
def compare_by_identity?();end
end
class Struct < Object
include Enumerable
include Kernel
def [](arg0);end
def []=(arg0, arg1);end
def length();end
def size();end
def each();end
def to_a();end
def dig(*args);end
def to_h();end
def values_at(*args);end
def each_pair();end
def values();end
def members();end
end
class Process::Tms < Struct
include Enumerable
include Kernel
def self.[](*args);end
def self.members();end
def self.[](*args);end
def self.members();end
def utime();end
def utime=(_);end
def stime();end
def stime=(_);end
def cutime();end
def cutime=(_);end
def cstime();end
def cstime=(_);end
end
class RegexpError < StandardError
include Kernel
def self.exception(*args);end
end
class Regexp < Object
include Kernel
def self.try_convert(arg0);end
def self.compile(*args);end
def self.quote(arg0);end
def self.escape(arg0);end
def self.union(*args);end
def self.last_match(*args);end
def self.try_convert(arg0);end
def self.compile(*args);end
def self.quote(arg0);end
def self.escape(arg0);end
def self.union(*args);end
def self.last_match(*args);end
def ~();end
def names();end
def match(*args);end
def encoding();end
def source();end
def casefold?();end
def options();end
def fixed_encoding?();end
def named_captures();end
end
class MatchData < Object
include Kernel
def [](*args);end
def length();end
def size();end
def to_a();end
def names();end
def values_at(*args);end
def regexp();end
def offset(arg0);end
def begin(arg0);end
def end(arg0);end
def captures();end
def pre_match();end
def post_match();end
def string();end
end
module Marshal
def dump(*args);end
def restore(*args);end
def self.dump(*args);end
def self.restore(*args);end
end
class Range < Object
include Enumerable
include Kernel
def size();end
def each();end
def first(*args);end
def min(*args);end
def max(*args);end
def member?(arg0);end
def step(*args);end
def last(*args);end
def bsearch();end
def begin();end
def end();end
def exclude_end?();end
def cover?(arg0);end
end
class IOError < StandardError
include Kernel
def self.exception(*args);end
end
class EOFError < IOError
include Kernel
def self.exception(*args);end
end
class IO < Object
include File::Constants
include Enumerable
include Kernel
def self.try_convert(arg0);end
def self.read(*args);end
def self.write(*args);end
def self.sysopen(*args);end
def self.for_fd(*args);end
def self.popen(*args);end
def self.foreach(*args);end
def self.binread(*args);end
def self.binwrite(*args);end
def self.pipe(*args);end
def self.copy_stream(*args);end
def self.try_convert(arg0);end
def self.read(*args);end
def self.write(*args);end
def self.sysopen(*args);end
def self.for_fd(*args);end
def self.popen(*args);end
def self.foreach(*args);end
def self.binread(*args);end
def self.binwrite(*args);end
def self.pipe(*args);end
def self.copy_stream(*args);end
def read_nonblock(len, buf = nil);end
def getbyte();end
def <<(arg0);end
def lines(*args);end
def bytes();end
def chars();end
def codepoints();end
def read(*args);end
def write(arg0);end
def binmode();end
def getc();end
def flush();end
def readpartial(*args);end
def set_encoding(*args);end
def stat();end
def write_nonblock(buf);end
def each_line(*args);end
def each(*args);end
def each_byte();end
def each_char();end
def each_codepoint();end
def reopen(*args);end
def to_io();end
def syswrite(arg0);end
def sysread(*args);end
def to_i();end
def fsync();end
def fileno();end
def sync();end
def fdatasync();end
def lineno();end
def lineno=(arg0);end
def readchar();end
def readbyte();end
def ungetbyte(arg0);end
def ungetc(arg0);end
def sync=(arg0);end
def seek(*args);end
def tell();end
def rewind();end
def pos();end
def pos=(arg0);end
def eof();end
def eof?();end
def close_on_exec?();end
def close_on_exec=(arg0);end
def close();end
def closed?();end
def close_read();end
def close_write();end
def isatty();end
def tty?();end
def binmode?();end
def sysseek(*args);end
def advise(*args);end
def ioctl(*args);end
def fcntl(*args);end
def pid();end
def external_encoding();end
def internal_encoding();end
def autoclose?();end
def autoclose=(arg0);end
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
module FileTest
def size(arg0);end
def zero?(arg0);end
def directory?(arg0);end
def exist?(arg0);end
def exists?(arg0);end
def readable?(arg0);end
def readable_real?(arg0);end
def world_readable?(arg0);end
def writable?(arg0);end
def writable_real?(arg0);end
def world_writable?(arg0);end
def executable?(arg0);end
def executable_real?(arg0);end
def file?(arg0);end
def size?(arg0);end
def owned?(arg0);end
def grpowned?(arg0);end
def pipe?(arg0);end
def symlink?(arg0);end
def socket?(arg0);end
def blockdev?(arg0);end
def chardev?(arg0);end
def setuid?(arg0);end
def setgid?(arg0);end
def sticky?(arg0);end
def identical?(arg0, arg1);end
def self.size(arg0);end
def self.zero?(arg0);end
def self.directory?(arg0);end
def self.exist?(arg0);end
def self.exists?(arg0);end
def self.readable?(arg0);end
def self.readable_real?(arg0);end
def self.world_readable?(arg0);end
def self.writable?(arg0);end
def self.writable_real?(arg0);end
def self.world_writable?(arg0);end
def self.executable?(arg0);end
def self.executable_real?(arg0);end
def self.file?(arg0);end
def self.size?(arg0);end
def self.owned?(arg0);end
def self.grpowned?(arg0);end
def self.pipe?(arg0);end
def self.symlink?(arg0);end
def self.socket?(arg0);end
def self.blockdev?(arg0);end
def self.chardev?(arg0);end
def self.setuid?(arg0);end
def self.setgid?(arg0);end
def self.sticky?(arg0);end
def self.identical?(arg0, arg1);end
end
class File < IO
include File::Constants
include Enumerable
include Kernel
def self.size(arg0);end
def self.split(arg0);end
def self.delete(*args);end
def self.path(arg0);end
def self.zero?(arg0);end
def self.truncate(arg0, arg1);end
def self.join(*args);end
def self.directory?(arg0);end
def self.exist?(arg0);end
def self.exists?(arg0);end
def self.readable?(arg0);end
def self.readable_real?(arg0);end
def self.world_readable?(arg0);end
def self.writable?(arg0);end
def self.writable_real?(arg0);end
def self.world_writable?(arg0);end
def self.executable?(arg0);end
def self.executable_real?(arg0);end
def self.file?(arg0);end
def self.size?(arg0);end
def self.owned?(arg0);end
def self.grpowned?(arg0);end
def self.pipe?(arg0);end
def self.symlink?(arg0);end
def self.socket?(arg0);end
def self.blockdev?(arg0);end
def self.chardev?(arg0);end
def self.setuid?(arg0);end
def self.setgid?(arg0);end
def self.sticky?(arg0);end
def self.identical?(arg0, arg1);end
def self.stat(arg0);end
def self.lstat(arg0);end
def self.ftype(arg0);end
def self.atime(arg0);end
def self.mtime(arg0);end
def self.ctime(arg0);end
def self.birthtime();end
def self.utime(*args);end
def self.chmod(*args);end
def self.chown(*args);end
def self.lchmod();end
def self.lchown(*args);end
def self.link(arg0, arg1);end
def self.symlink(arg0, arg1);end
def self.readlink(arg0);end
def self.unlink(*args);end
def self.rename(arg0, arg1);end
def self.umask(*args);end
def self.mkfifo(*args);end
def self.expand_path(*args);end
def self.absolute_path(*args);end
def self.realpath(*args);end
def self.realdirpath(*args);end
def self.basename(*args);end
def self.dirname(arg0);end
def self.extname(arg0);end
def self.fnmatch(*args);end
def self.fnmatch?(*args);end
def self.try_convert(arg0);end
def self.read(*args);end
def self.write(*args);end
def self.sysopen(*args);end
def self.for_fd(*args);end
def self.popen(*args);end
def self.foreach(*args);end
def self.binread(*args);end
def self.binwrite(*args);end
def self.pipe(*args);end
def self.copy_stream(*args);end
def self.size(arg0);end
def self.split(arg0);end
def self.delete(*args);end
def self.path(arg0);end
def self.zero?(arg0);end
def self.truncate(arg0, arg1);end
def self.join(*args);end
def self.directory?(arg0);end
def self.exist?(arg0);end
def self.exists?(arg0);end
def self.readable?(arg0);end
def self.readable_real?(arg0);end
def self.world_readable?(arg0);end
def self.writable?(arg0);end
def self.writable_real?(arg0);end
def self.world_writable?(arg0);end
def self.executable?(arg0);end
def self.executable_real?(arg0);end
def self.file?(arg0);end
def self.size?(arg0);end
def self.owned?(arg0);end
def self.grpowned?(arg0);end
def self.pipe?(arg0);end
def self.symlink?(arg0);end
def self.socket?(arg0);end
def self.blockdev?(arg0);end
def self.chardev?(arg0);end
def self.setuid?(arg0);end
def self.setgid?(arg0);end
def self.sticky?(arg0);end
def self.identical?(arg0, arg1);end
def self.stat(arg0);end
def self.lstat(arg0);end
def self.ftype(arg0);end
def self.atime(arg0);end
def self.mtime(arg0);end
def self.ctime(arg0);end
def self.birthtime();end
def self.utime(*args);end
def self.chmod(*args);end
def self.chown(*args);end
def self.lchmod();end
def self.lchown(*args);end
def self.link(arg0, arg1);end
def self.symlink(arg0, arg1);end
def self.readlink(arg0);end
def self.unlink(*args);end
def self.rename(arg0, arg1);end
def self.umask(*args);end
def self.mkfifo(*args);end
def self.expand_path(*args);end
def self.absolute_path(*args);end
def self.realpath(*args);end
def self.realdirpath(*args);end
def self.basename(*args);end
def self.dirname(arg0);end
def self.extname(arg0);end
def self.fnmatch(*args);end
def self.fnmatch?(*args);end
def size();end
def path();end
def truncate(arg0);end
def lstat();end
def atime();end
def mtime();end
def ctime();end
def birthtime();end
def chmod(arg0);end
def chown(arg0, arg1);end
def flock(arg0);end
def to_path();end
end
module File::Constants
end
class File::Stat < Object
include Comparable
include Kernel
def size();end
def zero?();end
def directory?();end
def readable?();end
def readable_real?();end
def world_readable?();end
def writable?();end
def writable_real?();end
def world_writable?();end
def executable?();end
def executable_real?();end
def file?();end
def size?();end
def owned?();end
def grpowned?();end
def pipe?();end
def symlink?();end
def socket?();end
def blockdev?();end
def chardev?();end
def setuid?();end
def setgid?();end
def sticky?();end
def ftype();end
def atime();end
def mtime();end
def ctime();end
def birthtime();end
def dev();end
def dev_major();end
def dev_minor();end
def ino();end
def mode();end
def nlink();end
def uid();end
def gid();end
def rdev();end
def rdev_major();end
def rdev_minor();end
def blksize();end
def blocks();end
end
class Dir < Object
include Enumerable
include Kernel
def self.[](*args);end
def self.entries(*args);end
def self.delete(arg0);end
def self.foreach(*args);end
def self.exist?(arg0);end
def self.exists?(arg0);end
def self.unlink(arg0);end
def self.chdir(*args);end
def self.getwd();end
def self.pwd();end
def self.chroot(arg0);end
def self.mkdir(*args);end
def self.rmdir(arg0);end
def self.home(*args);end
def self.glob(*args);end
def self.[](*args);end
def self.entries(*args);end
def self.delete(arg0);end
def self.foreach(*args);end
def self.exist?(arg0);end
def self.exists?(arg0);end
def self.unlink(arg0);end
def self.chdir(*args);end
def self.getwd();end
def self.pwd();end
def self.chroot(arg0);end
def self.mkdir(*args);end
def self.rmdir(arg0);end
def self.home(*args);end
def self.glob(*args);end
def each();end
def path();end
def read();end
def fileno();end
def tell();end
def seek(arg0);end
def rewind();end
def pos();end
def pos=(arg0);end
def close();end
def to_path();end
end
class Time < Object
include Comparable
include Kernel
def self.at(*args);end
def self.now();end
def self.utc(*args);end
def self.gm(*args);end
def self.local(*args);end
def self.mktime(*args);end
def self.at(*args);end
def self.now();end
def self.utc(*args);end
def self.gm(*args);end
def self.local(*args);end
def self.mktime(*args);end
def +(arg0);end
def -(arg0);end
def succ();end
def to_a();end
def to_i();end
def to_f();end
def min();end
def round(*args);end
def ctime();end
def zone();end
def utc();end
def to_r();end
def localtime(*args);end
def gmtime();end
def getlocal(*args);end
def getgm();end
def getutc();end
def asctime();end
def sec();end
def hour();end
def mday();end
def day();end
def mon();end
def month();end
def year();end
def wday();end
def yday();end
def isdst();end
def dst?();end
def gmtoff();end
def gmt_offset();end
def utc_offset();end
def utc?();end
def gmt?();end
def sunday?();end
def monday?();end
def tuesday?();end
def wednesday?();end
def thursday?();end
def friday?();end
def saturday?();end
def tv_sec();end
def tv_usec();end
def usec();end
def tv_nsec();end
def nsec();end
def subsec();end
def strftime(arg0);end
end
class Random < Object
include Random::Formatter
include Kernel
def self.new_seed();end
def self.raw_seed(arg0);end
def self.new_seed();end
def self.raw_seed(arg0);end
def bytes(arg0);end
def seed();end
end
module Random::Formatter
def random_number(*args);end
end
module Signal
def list();end
def signame(arg0);end
def self.list();end
def self.signame(arg0);end
end
class Proc < Object
include Kernel
def [](*args);end
def to_proc();end
def call(*args);end
def yield(*args);end
def arity();end
def lambda?();end
def curry(*args);end
def source_location();end
def parameters();end
end
class LocalJumpError < StandardError
include Kernel
def self.exception(*args);end
def exit_value();end
def reason();end
end
class SystemStackError < Exception
include Kernel
def self.exception(*args);end
end
class Method < Object
include Kernel
def [](*args);end
def to_proc();end
def call(*args);end
def receiver();end
def arity();end
def curry(*args);end
def source_location();end
def parameters();end
def original_name();end
def owner();end
def unbind();end
def super_method();end
end
class UnboundMethod < Object
include Kernel
def arity();end
def source_location();end
def parameters();end
def original_name();end
def owner();end
def super_method();end
def bind(arg0);end
end
class Binding < Object
include Kernel
def receiver();end
def local_variable_get(arg0);end
def local_variable_set(arg0, arg1);end
def local_variable_defined?(arg0);end
end
module Math
def atan2(arg0, arg1);end
def cos(arg0);end
def sin(arg0);end
def tan(arg0);end
def acos(arg0);end
def asin(arg0);end
def atan(arg0);end
def cosh(arg0);end
def sinh(arg0);end
def tanh(arg0);end
def acosh(arg0);end
def asinh(arg0);end
def atanh(arg0);end
def exp(arg0);end
def log(*args);end
def log2(arg0);end
def log10(arg0);end
def sqrt(arg0);end
def cbrt(arg0);end
def frexp(arg0);end
def ldexp(arg0, arg1);end
def hypot(arg0, arg1);end
def erf(arg0);end
def erfc(arg0);end
def gamma(arg0);end
def lgamma(arg0);end
def self.atan2(arg0, arg1);end
def self.cos(arg0);end
def self.sin(arg0);end
def self.tan(arg0);end
def self.acos(arg0);end
def self.asin(arg0);end
def self.atan(arg0);end
def self.cosh(arg0);end
def self.sinh(arg0);end
def self.tanh(arg0);end
def self.acosh(arg0);end
def self.asinh(arg0);end
def self.atanh(arg0);end
def self.exp(arg0);end
def self.log(*args);end
def self.log2(arg0);end
def self.log10(arg0);end
def self.sqrt(arg0);end
def self.cbrt(arg0);end
def self.frexp(arg0);end
def self.ldexp(arg0, arg1);end
def self.hypot(arg0, arg1);end
def self.erf(arg0);end
def self.erfc(arg0);end
def self.gamma(arg0);end
def self.lgamma(arg0);end
end
class Math::DomainError < StandardError
include Kernel
def self.exception(*args);end
end
module GC
def count();end
def stat(*args);end
def start(*args);end
def enable();end
def disable();end
def stress();end
def stress=(arg0);end
def latest_gc_info(*args);end
def verify_internal_consistency();end
def self.count();end
def self.stat(*args);end
def self.start(*args);end
def self.enable();end
def self.disable();end
def self.stress();end
def self.stress=(arg0);end
def self.latest_gc_info(*args);end
def self.verify_internal_consistency();end
def garbage_collect(*args);end
end
module GC::Profiler
def clear();end
def result();end
def enable();end
def disable();end
def enabled?();end
def raw_data();end
def report(*args);end
def total_time();end
def self.clear();end
def self.result();end
def self.enable();end
def self.disable();end
def self.enabled?();end
def self.raw_data();end
def self.report(*args);end
def self.total_time();end
end
module ObjectSpace
def garbage_collect(*args);end
def each_object(*args);end
def define_finalizer(*args);end
def undefine_finalizer(arg0);end
def _id2ref(arg0);end
def count_objects(*args);end
def self.garbage_collect(*args);end
def self.each_object(*args);end
def self.define_finalizer(*args);end
def self.undefine_finalizer(arg0);end
def self._id2ref(arg0);end
def self.count_objects(*args);end
end
class ObjectSpace::WeakMap < Object
include Enumerable
include Kernel
def [](arg0);end
def []=(arg0, arg1);end
def length();end
def size();end
def each();end
def member?(arg0);end
def each_value();end
def each_key();end
def each_pair();end
def keys();end
def values();end
def key?(arg0);end
end
class Enumerator < Object
include Enumerable
include Kernel
def size();end
def each(*args);end
def each_with_index();end
def each_with_object(arg0);end
def next();end
def rewind();end
def with_index(*args);end
def with_object(arg0);end
def next_values();end
def peek_values();end
def peek();end
def feed(arg0);end
end
class Enumerator::Lazy < Enumerator
include Enumerable
include Kernel
def grep(arg0);end
def grep_v(arg0);end
def find_all();end
def reject();end
def collect();end
def map();end
def flat_map();end
def collect_concat();end
def zip(*args);end
def take(arg0);end
def take_while();end
def drop(arg0);end
def drop_while();end
def chunk(*args);end
def slice_before(*args);end
def slice_after(*args);end
def slice_when(*args);end
def lazy();end
def force(*args);end
end
class Enumerator::Generator < Object
include Enumerable
include Kernel
def each(*args);end
end
class Enumerator::Yielder < Object
include Kernel
def <<(*args);end
def yield(*args);end
end
class StopIteration < IndexError
include Kernel
def self.exception(*args);end
def result();end
end
class RubyVM < Object
include Kernel
def self.stat(*args);end
def self.stat(*args);end
end
class RubyVM::Env < Object
include Kernel
end
class RubyVM::InstructionSequence < Object
include Kernel
def self.compile(*args);end
def self.disasm(arg0);end
def self.disassemble(arg0);end
def self.load_from_binary(arg0);end
def self.load_from_binary_extra_data(arg0);end
def self.compile_file(*args);end
def self.compile_option();end
def self.compile_option=(arg0);end
def self.of(arg0);end
def self.compile(*args);end
def self.disasm(arg0);end
def self.disassemble(arg0);end
def self.load_from_binary(arg0);end
def self.load_from_binary_extra_data(arg0);end
def self.compile_file(*args);end
def self.compile_option();end
def self.compile_option=(arg0);end
def self.of(arg0);end
def to_a();end
def path();end
def absolute_path();end
def label();end
def base_label();end
def disasm();end
def disassemble();end
def to_binary(*args);end
def first_lineno();end
end
class Thread < Object
include Kernel
def self.list();end
def self.start(*args);end
def self.main();end
def self.current();end
def self.stop();end
def self.kill(arg0);end
def self.pass();end
def self.abort_on_exception();end
def self.abort_on_exception=(arg0);end
def self.handle_interrupt(arg0);end
def self.pending_interrupt?(*args);end
def self.exclusive();end
def self.list();end
def self.start(*args);end
def self.main();end
def self.current();end
def self.stop();end
def self.kill(arg0);end
def self.pass();end
def self.abort_on_exception();end
def self.abort_on_exception=(arg0);end
def self.handle_interrupt(arg0);end
def self.pending_interrupt?(*args);end
def self.exclusive();end
def [](arg0);end
def []=(arg0, arg1);end
def backtrace(*args);end
def backtrace_locations(*args);end
def status();end
def value();end
def join(*args);end
def keys();end
def key?(arg0);end
def kill();end
def abort_on_exception();end
def abort_on_exception=(arg0);end
def pending_interrupt?(*args);end
def terminate();end
def run();end
def wakeup();end
def priority();end
def priority=(arg0);end
def thread_variable_get(arg0);end
def thread_variable_set(arg0, arg1);end
def thread_variables();end
def thread_variable?(arg0);end
def alive?();end
def stop?();end
def safe_level();end
def group();end
def name=(arg0);end
def add_trace_func(arg0);end
end
class Thread::Backtrace < Object
include Kernel
end
class Thread::Backtrace::Location < Object
include Kernel
def path();end
def lineno();end
def absolute_path();end
def label();end
def base_label();end
end
class Thread::Mutex < Object
include Kernel
def owned?();end
def locked?();end
def try_lock();end
def lock();end
def unlock();end
def synchronize();end
end
class Thread::Queue < Object
include Kernel
def <<(arg0);end
def empty?();end
def length();end
def size();end
def clear();end
def push(arg0);end
def pop(*args);end
def shift(*args);end
def marshal_dump();end
def close();end
def closed?();end
def num_waiting();end
def enq(arg0);end
def deq(*args);end
end
class Thread::SizedQueue < Thread::Queue
include Kernel
def <<(*args);end
def max();end
def clear();end
def push(*args);end
def pop(*args);end
def shift(*args);end
def close();end
def num_waiting();end
def enq(*args);end
def deq(*args);end
def max=(arg0);end
end
class Thread::ConditionVariable < Object
include Kernel
def marshal_dump();end
def wait(*args);end
def signal();end
def broadcast();end
end
class ThreadGroup < Object
include Kernel
def list();end
def enclose();end
def enclosed?();end
def add(arg0);end
end
class ThreadError < StandardError
include Kernel
def self.exception(*args);end
end
class ClosedQueueError < StopIteration
include Kernel
def self.exception(*args);end
end
module Process
def times();end
def pid();end
def uid();end
def gid();end
def kill(*args);end
def wait(*args);end
def wait2(*args);end
def waitpid(*args);end
def waitpid2(*args);end
def waitall();end
def detach(arg0);end
def ppid();end
def getpgrp();end
def setpgrp();end
def getpgid(arg0);end
def setpgid(arg0, arg1);end
def getsid(*args);end
def setsid();end
def getpriority(arg0, arg1);end
def setpriority(arg0, arg1, arg2);end
def getrlimit(arg0);end
def setrlimit(*args);end
def uid=(arg0);end
def gid=(arg0);end
def euid();end
def euid=(arg0);end
def egid();end
def egid=(arg0);end
def initgroups(arg0, arg1);end
def groups();end
def groups=(arg0);end
def maxgroups();end
def maxgroups=(arg0);end
def daemon(*args);end
def clock_gettime(*args);end
def clock_getres(*args);end
def argv0();end
def setproctitle(arg0);end
def self.times();end
def self.pid();end
def self.uid();end
def self.gid();end
def self.kill(*args);end
def self.wait(*args);end
def self.wait2(*args);end
def self.waitpid(*args);end
def self.waitpid2(*args);end
def self.waitall();end
def self.detach(arg0);end
def self.ppid();end
def self.getpgrp();end
def self.setpgrp();end
def self.getpgid(arg0);end
def self.setpgid(arg0, arg1);end
def self.getsid(*args);end
def self.setsid();end
def self.getpriority(arg0, arg1);end
def self.setpriority(arg0, arg1, arg2);end
def self.getrlimit(arg0);end
def self.setrlimit(*args);end
def self.uid=(arg0);end
def self.gid=(arg0);end
def self.euid();end
def self.euid=(arg0);end
def self.egid();end
def self.egid=(arg0);end
def self.initgroups(arg0, arg1);end
def self.groups();end
def self.groups=(arg0);end
def self.maxgroups();end
def self.maxgroups=(arg0);end
def self.daemon(*args);end
def self.clock_gettime(*args);end
def self.clock_getres(*args);end
def self.argv0();end
def self.setproctitle(arg0);end
end
class Process::Waiter < Thread
include Kernel
def self.list();end
def self.start(*args);end
def self.main();end
def self.current();end
def self.stop();end
def self.kill(arg0);end
def self.pass();end
def self.abort_on_exception();end
def self.abort_on_exception=(arg0);end
def self.handle_interrupt(arg0);end
def self.pending_interrupt?(*args);end
def self.exclusive();end
def pid();end
end
class Process::Status < Object
include Kernel
def &(arg0);end
def >>(arg0);end
def to_i();end
def success?();end
def pid();end
def stopped?();end
def stopsig();end
def signaled?();end
def termsig();end
def exited?();end
def exitstatus();end
def coredump?();end
end
module Process::UID
def rid();end
def eid();end
def change_privilege(arg0);end
def grant_privilege(arg0);end
def eid=(arg0);end
def re_exchange();end
def re_exchangeable?();end
def sid_available?();end
def switch();end
def from_name(arg0);end
def self.rid();end
def self.eid();end
def self.change_privilege(arg0);end
def self.grant_privilege(arg0);end
def self.eid=(arg0);end
def self.re_exchange();end
def self.re_exchangeable?();end
def self.sid_available?();end
def self.switch();end
def self.from_name(arg0);end
end
module Process::GID
def rid();end
def eid();end
def change_privilege(arg0);end
def grant_privilege(arg0);end
def eid=(arg0);end
def re_exchange();end
def re_exchangeable?();end
def sid_available?();end
def switch();end
def from_name(arg0);end
def self.rid();end
def self.eid();end
def self.change_privilege(arg0);end
def self.grant_privilege(arg0);end
def self.eid=(arg0);end
def self.re_exchange();end
def self.re_exchangeable?();end
def self.sid_available?();end
def self.switch();end
def self.from_name(arg0);end
end
module Process::Sys
def getuid();end
def geteuid();end
def getgid();end
def getegid();end
def setuid(arg0);end
def setgid(arg0);end
def setruid();end
def setrgid();end
def seteuid(arg0);end
def setegid(arg0);end
def setreuid(arg0, arg1);end
def setregid(arg0, arg1);end
def setresuid(arg0, arg1, arg2);end
def setresgid(arg0, arg1, arg2);end
def issetugid();end
def self.getuid();end
def self.geteuid();end
def self.getgid();end
def self.getegid();end
def self.setuid(arg0);end
def self.setgid(arg0);end
def self.setruid();end
def self.setrgid();end
def self.seteuid(arg0);end
def self.setegid(arg0);end
def self.setreuid(arg0, arg1);end
def self.setregid(arg0, arg1);end
def self.setresuid(arg0, arg1, arg2);end
def self.setresgid(arg0, arg1, arg2);end
def self.issetugid();end
end
class Fiber < Object
include Kernel
def self.yield(*args);end
def self.yield(*args);end
def resume(*args);end
end
class FiberError < StandardError
include Kernel
def self.exception(*args);end
end
class Rational < Numeric
include Comparable
include Kernel
def *(arg0);end
def +(arg0);end
def -(arg0);end
def /(arg0);end
def **(arg0);end
def to_i();end
def to_f();end
def coerce(arg0);end
def fdiv(arg0);end
def floor(*args);end
def ceil(*args);end
def round(*args);end
def truncate(*args);end
def quo(arg0);end
def to_r();end
def numerator();end
def denominator();end
def rationalize(*args);end
end
class Complex < Numeric
include Comparable
include Kernel
def self.rectangular(*args);end
def self.rect(*args);end
def self.polar(*args);end
def self.rectangular(*args);end
def self.rect(*args);end
def self.polar(*args);end
def *(arg0);end
def +(arg0);end
def -(arg0);end
def /(arg0);end
def -@();end
def **(arg0);end
def to_i();end
def to_f();end
def coerce(arg0);end
def fdiv(arg0);end
def abs();end
def magnitude();end
def real?();end
def quo(arg0);end
def to_r();end
def numerator();end
def denominator();end
def rationalize(*args);end
def arg();end
def rectangular();end
def rect();end
def polar();end
def real();end
def imaginary();end
def imag();end
def abs2();end
def angle();end
def phase();end
def conjugate();end
def conj();end
def to_c();end
end
class TracePoint < Object
include Kernel
def self.stat();end
def self.trace(*args);end
def self.stat();end
def self.trace(*args);end
def path();end
def lineno();end
def enable();end
def disable();end
def enabled?();end
def event();end
def method_id();end
def defined_class();end
def self();end
def return_value();end
def raised_exception();end
end
module Gem
def load_plugin_files(plugins);end
def load_plugins();end
def load_env_plugins();end
def use_gemdeps(*args);end
def detect_gemdeps(*args);end
def gemdeps();end
def register_default_spec(spec);end
def default_gems_use_full_paths?();end
def find_unresolved_default_spec(path);end
def remove_unresolved_default_spec(spec);end
def clear_default_specs();end
def post_build_hooks();end
def post_install_hooks();end
def done_installing_hooks();end
def post_reset_hooks();end
def post_uninstall_hooks();end
def pre_install_hooks();end
def pre_reset_hooks();end
def pre_uninstall_hooks();end
def default_spec_cache_dir();end
def ruby_engine();end
def default_ext_dir_for(base_dir);end
def default_rubygems_dirs();end
def user_dir();end
def path_separator();end
def default_path();end
def vendor_dir();end
def default_exec_format();end
def default_key_path();end
def default_cert_path();end
def install_extension_in_lib();end
def try_activate(path);end
def needs();end
def finish_resolve(*args);end
def bin_path(name, exec_name = nil, *requirements);end
def loaded_specs();end
def binary_mode();end
def bindir(*args);end
def dir();end
def default_dir();end
def default_bindir();end
def clear_paths();end
def config_file();end
def user_home();end
def configuration();end
def configuration=(config);end
def datadir(gem_name);end
def deflate(data);end
def paths();end
def paths=(env);end
def spec_cache_dir();end
def ensure_gem_subdirectories(*args);end
def ensure_subdirectories(dir, mode, subdirs);end
def ensure_default_gem_subdirectories(*args);end
def extension_api_version();end
def ruby_api_version();end
def find_files(glob, check_load_path = nil);end
def find_files_from_load_path(glob);end
def suffix_pattern();end
def find_latest_files(glob, check_load_path = nil);end
def gunzip(data);end
def gzip(data);end
def inflate(data);end
def install(name, version = nil, *options);end
def host();end
def host=(host);end
def load_path_insert_index();end
def load_yaml();end
def location_of_caller();end
def marshal_version();end
def platforms=(platforms);end
def platforms();end
def post_build(&hook);end
def post_install(&hook);end
def done_installing(&hook);end
def post_reset(&hook);end
def post_uninstall(&hook);end
def pre_install(&hook);end
def pre_reset(&hook);end
def pre_uninstall(&hook);end
def prefix();end
def refresh();end
def read_binary(path);end
def ruby();end
def latest_spec_for(name);end
def path();end
def latest_rubygems_version();end
def latest_version_for(name);end
def ruby_version();end
def rubygems_version();end
def sources();end
def default_sources();end
def sources=(new_sources);end
def suffixes();end
def time(msg, width = nil, display = nil);end
def ui();end
def use_paths(home, *paths);end
def win_platform?();end
def self.load_plugin_files(plugins);end
def self.load_plugins();end
def self.load_env_plugins();end
def self.use_gemdeps(*args);end
def self.detect_gemdeps(*args);end
def self.gemdeps();end
def self.register_default_spec(spec);end
def self.default_gems_use_full_paths?();end
def self.find_unresolved_default_spec(path);end
def self.remove_unresolved_default_spec(spec);end
def self.clear_default_specs();end
def self.post_build_hooks();end
def self.post_install_hooks();end
def self.done_installing_hooks();end
def self.post_reset_hooks();end
def self.post_uninstall_hooks();end
def self.pre_install_hooks();end
def self.pre_reset_hooks();end
def self.pre_uninstall_hooks();end
def self.default_spec_cache_dir();end
def self.ruby_engine();end
def self.default_ext_dir_for(base_dir);end
def self.default_rubygems_dirs();end
def self.user_dir();end
def self.path_separator();end
def self.default_path();end
def self.vendor_dir();end
def self.default_exec_format();end
def self.default_key_path();end
def self.default_cert_path();end
def self.install_extension_in_lib();end
def self.try_activate(path);end
def self.needs();end
def self.finish_resolve(*args);end
def self.bin_path(name, exec_name = nil, *requirements);end
def self.loaded_specs();end
def self.binary_mode();end
def self.bindir(*args);end
def self.dir();end
def self.default_dir();end
def self.default_bindir();end
def self.clear_paths();end
def self.config_file();end
def self.user_home();end
def self.configuration();end
def self.configuration=(config);end
def self.datadir(gem_name);end
def self.deflate(data);end
def self.paths();end
def self.paths=(env);end
def self.spec_cache_dir();end
def self.ensure_gem_subdirectories(*args);end
def self.ensure_subdirectories(dir, mode, subdirs);end
def self.ensure_default_gem_subdirectories(*args);end
def self.extension_api_version();end
def self.ruby_api_version();end
def self.find_files(glob, check_load_path = nil);end
def self.find_files_from_load_path(glob);end
def self.suffix_pattern();end
def self.find_latest_files(glob, check_load_path = nil);end
def self.gunzip(data);end
def self.gzip(data);end
def self.inflate(data);end
def self.install(name, version = nil, *options);end
def self.host();end
def self.host=(host);end
def self.load_path_insert_index();end
def self.load_yaml();end
def self.location_of_caller();end
def self.marshal_version();end
def self.platforms=(platforms);end
def self.platforms();end
def self.post_build(&hook);end
def self.post_install(&hook);end
def self.done_installing(&hook);end
def self.post_reset(&hook);end
def self.post_uninstall(&hook);end
def self.pre_install(&hook);end
def self.pre_reset(&hook);end
def self.pre_uninstall(&hook);end
def self.prefix();end
def self.refresh();end
def self.read_binary(path);end
def self.ruby();end
def self.latest_spec_for(name);end
def self.path();end
def self.latest_rubygems_version();end
def self.latest_version_for(name);end
def self.ruby_version();end
def self.rubygems_version();end
def self.sources();end
def self.default_sources();end
def self.sources=(new_sources);end
def self.suffixes();end
def self.time(msg, width = nil, display = nil);end
def self.ui();end
def self.use_paths(home, *paths);end
def self.win_platform?();end
end
module Gem::Deprecate
def skip();end
def skip=(v);end
def skip_during();end
def deprecate(name, repl, year, month);end
def self.skip();end
def self.skip=(v);end
def self.skip_during();end
def self.deprecate(name, repl, year, month);end
end
class Gem::LoadError < LoadError
include Kernel
def self.exception(*args);end
def name=(arg0);end
def requirement();end
def requirement=(arg0);end
end
class Gem::ConflictError < Gem::LoadError
include Kernel
def self.exception(*args);end
def target();end
def conflicts();end
end
class Gem::ErrorReason < Object
include Kernel
end
class Gem::PlatformMismatch < Gem::ErrorReason
include Kernel
def version();end
def platforms();end
def add_platform(platform);end
def wordy();end
end
class Gem::SourceFetchProblem < Gem::ErrorReason
include Kernel
def exception();end
def source();end
def wordy();end
def error();end
end
class Gem::ConfigFile < Object
include Gem::UserInteraction
include Gem::DefaultUserInteraction
include Kernel
def [](key);end
def []=(key, value);end
def each(&block);end
def backtrace();end
def path();end
def args();end
def write();end
def home();end
def verbose();end
def really_verbose();end
def to_yaml();end
def path=(arg0);end
def bulk_threshold();end
def update_sources();end
def disable_default_gem_server();end
def ssl_verify_mode();end
def ssl_ca_cert();end
def ssl_client_cert();end
def load_file(filename);end
def config_file_name();end
def handle_arguments(arg_list);end
def api_keys();end
def load_api_keys();end
def check_credentials_permissions();end
def credentials_path();end
def rubygems_api_key();end
def rubygems_api_key=(api_key);end
def home=(arg0);end
def backtrace=(arg0);end
def bulk_threshold=(arg0);end
def verbose=(arg0);end
def update_sources=(arg0);end
def disable_default_gem_server=(arg0);end
def ssl_ca_cert=(arg0);end
end
class Gem::Dependency < Object
include Kernel
def merge(other);end
def name=(arg0);end
def matches_spec?(spec);end
def matching_specs(*args);end
def requirement();end
def to_spec();end
def to_specs();end
def prerelease?();end
def type();end
def runtime?();end
def pretty_print(q);end
def requirements_list();end
def match?(obj, version = nil, allow_prerelease = nil);end
def specific?();end
def latest_version?();end
def prerelease=(arg0);end
end
class Gem::DependencyList < Object
include TSort
include Enumerable
include Kernel
def self.from_specs();end
def self.from_specs();end
def each(&block);end
def clear();end
def add(*args);end
def specs();end
def development();end
def dependency_order();end
def find_name(full_name);end
def ok?();end
def why_not_ok?(*args);end
def ok_to_remove?(full_name, check_dev = nil);end
def remove_specs_unsatisfied_by(dependencies);end
def remove_by_name(full_name);end
def spec_predecessors();end
def tsort_each_node(&block);end
def tsort_each_child(node);end
def development=(arg0);end
end
class TSort::Cyclic < StandardError
include Kernel
def self.exception(*args);end
end
class Gem::Resolver < Object
include Gem::Resolver::Molinillo::SpecificationProvider
include Gem::Resolver::Molinillo::UI
include Kernel
def self.compose_sets(*args);end
def self.for_current_gems(needed);end
def self.compose_sets(*args);end
def self.for_current_gems(needed);end
def development();end
def output();end
def development=(arg0);end
def development_shallow();end
def ignore_dependencies();end
def missing();end
def stats();end
def skip_gems();end
def soft_missing();end
def explain(stage, *data);end
def explain_list(stage);end
def activation_request(dep, possible);end
def requests(s, act, reqs = nil);end
def debug?();end
def resolve();end
def find_possible(dependency);end
def select_local_platforms(specs);end
def search_for(dependency);end
def dependencies_for(specification);end
def requirement_satisfied_by?(requirement, activated, spec);end
def name_for(dependency);end
def allow_missing?(dependency);end
def development_shallow=(arg0);end
def ignore_dependencies=(arg0);end
def skip_gems=(arg0);end
def soft_missing=(arg0);end
end
module Gem::Resolver::Molinillo
end
class Gem::Resolver::Molinillo::ResolverError < StandardError
include Kernel
def self.exception(*args);end
end
class Gem::Resolver::Molinillo::NoSuchDependencyError < Gem::Resolver::Molinillo::ResolverError
include Kernel
def self.exception(*args);end
def message();end
def dependency();end
def required_by();end
def dependency=(arg0);end
def required_by=(arg0);end
end
class Gem::Resolver::Molinillo::CircularDependencyError < Gem::Resolver::Molinillo::ResolverError
include Kernel
def self.exception(*args);end
def dependencies();end
end
class Gem::Resolver::Molinillo::VersionConflict < Gem::Resolver::Molinillo::ResolverError
include Kernel
def self.exception(*args);end
def conflicts();end
end
class Gem::Resolver::Molinillo::DependencyGraph < Object
include TSort
include Enumerable
include Kernel
def self.tsort(vertices);end
def self.tsort(vertices);end
def each();end
def tsort_each_node();end
def tsort_each_child(vertex, &block);end
def vertices();end
def add_vertex(name, payload, root = nil);end
def vertex_named(name);end
def add_child_vertex(name, payload, parent_names, requirement);end
def add_edge(origin, destination, requirement);end
def detach_vertex_named(name);end
def root_vertex_named(name);end
end
class Gem::Resolver::Molinillo::DependencyGraph::Edge < Struct
include Enumerable
include Kernel
def self.[](*args);end
def self.members();end
def self.[](*args);end
def self.members();end
def requirement();end
def requirement=(_);end
def origin();end
def destination();end
def origin=(_);end
def destination=(_);end
end
class Etc::Passwd < Struct
include Enumerable
include Kernel
def self.[](*args);end
def self.each();end
def self.members();end
def self.to_a(*args);end
def self.to_h(*args);end
def self.find(*args);end
def self.entries(*args);end
def self.sort();end
def self.sort_by();end
def self.grep(arg0);end
def self.grep_v(arg0);end
def self.count(*args);end
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
def self.min(*args);end
def self.max(*args);end
def self.minmax();end
def self.min_by(*args);end
def self.max_by(*args);end
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
def self.chunk();end
def self.slice_before(*args);end
def self.slice_after(*args);end
def self.slice_when();end
def self.chunk_while();end
def self.lazy();end
def self.to_set(*args);end
def self.[](*args);end
def self.each();end
def self.members();end
def uid();end
def gid();end
def name=(_);end
def uid=(_);end
def gid=(_);end
def dir();end
def passwd();end
def passwd=(_);end
def gecos();end
def gecos=(_);end
def dir=(_);end
def shell();end
def shell=(_);end
end
class Etc::Group < Struct
include Enumerable
include Kernel
def self.[](*args);end
def self.each();end
def self.members();end
def self.to_a(*args);end
def self.to_h(*args);end
def self.find(*args);end
def self.entries(*args);end
def self.sort();end
def self.sort_by();end
def self.grep(arg0);end
def self.grep_v(arg0);end
def self.count(*args);end
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
def self.min(*args);end
def self.max(*args);end
def self.minmax();end
def self.min_by(*args);end
def self.max_by(*args);end
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
def self.chunk();end
def self.slice_before(*args);end
def self.slice_after(*args);end
def self.slice_when();end
def self.chunk_while();end
def self.lazy();end
def self.to_set(*args);end
def self.[](*args);end
def self.each();end
def self.members();end
def gid();end
def name=(_);end
def gid=(_);end
def passwd();end
def passwd=(_);end
def mem();end
def mem=(_);end
end
class Gem::Resolver::Molinillo::DependencyGraph::Vertex < Object
include Kernel
def name=(arg0);end
def requirements();end
def payload();end
def successors();end
def outgoing_edges();end
def root?();end
def explicit_requirements();end
def root();end
def root=(arg0);end
def incoming_edges();end
def predecessors();end
def path_to?(other);end
def recursive_predecessors();end
def recursive_successors();end
def shallow_eql?(other);end
def descendent?(other);end
def ancestor?(other);end
def is_reachable_from?(other);end
def payload=(arg0);end
def outgoing_edges=(arg0);end
def incoming_edges=(arg0);end
end
class Gem::Resolver::Molinillo::Resolver < Object
include Kernel
def resolve(requested, base = nil);end
def specification_provider();end
def resolver_ui();end
end
class Gem::Resolver::Molinillo::Resolver::Resolution < Object
include Kernel
def base();end
def resolve();end
def specification_provider();end
def resolver_ui();end
def original_requested();end
def iteration_rate=(arg0);end
def started_at=(arg0);end
def states=(arg0);end
end
class Gem::Resolver::Molinillo::Resolver::Resolution::Conflict < Struct
include Enumerable
include Kernel
def self.[](*args);end
def self.members();end
def self.[](*args);end
def self.members();end
def requirements();end
def requirement();end
def requirement=(_);end
def requirements=(_);end
def requirement_trees();end
def existing();end
def possibility();end
def locked_requirement();end
def activated_by_name();end
def existing=(_);end
def possibility=(_);end
def locked_requirement=(_);end
def requirement_trees=(_);end
def activated_by_name=(_);end
end
class Gem::Resolver::Molinillo::ResolutionState < Struct
include Enumerable
include Kernel
def self.[](*args);end
def self.members();end
def self.empty();end
def self.[](*args);end
def self.members();end
def self.empty();end
def name=(_);end
def requirements();end
def requirement();end
def conflicts();end
def requirement=(_);end
def activated();end
def activated=(_);end
def requirements=(_);end
def depth();end
def possibilities();end
def conflicts=(_);end
def possibilities=(_);end
def depth=(_);end
end
class Gem::Resolver::Molinillo::DependencyState < Gem::Resolver::Molinillo::ResolutionState
include Enumerable
include Kernel
def self.[](*args);end
def self.members();end
def self.empty();end
def pop_possibility_state();end
end
class Gem::Resolver::Molinillo::PossibilityState < Gem::Resolver::Molinillo::ResolutionState
include Enumerable
include Kernel
def self.[](*args);end
def self.members();end
def self.empty();end
end
module Gem::Resolver::Molinillo::SpecificationProvider
def search_for(dependency);end
def dependencies_for(specification);end
def requirement_satisfied_by?(requirement, activated, spec);end
def name_for(dependency);end
def allow_missing?(dependency);end
def name_for_explicit_dependency_source();end
def sort_dependencies(dependencies, activated, conflicts);end
def name_for_locking_dependency_source();end
end
module Gem::Resolver::Molinillo::UI
def output();end
def debug(*args);end
def debug?();end
def indicate_progress();end
def before_resolution();end
def after_resolution();end
def progress_rate();end
end
class Gem::Resolver::ActivationRequest < Object
include Kernel
def spec();end
def full_spec();end
def version();end
def full_name();end
def pretty_print(q);end
def request();end
def development?();end
def parent();end
def download(path);end
def installed?();end
def others_possible?();end
end
class Gem::Resolver::Conflict < Object
include Kernel
def dependency();end
def activated();end
def pretty_print(q);end
def conflicting_dependencies();end
def explanation();end
def requester();end
def explain();end
def failed_dep();end
def request_path(current);end
def for_spec?(spec);end
end
class Gem::Resolver::DependencyRequest < Object
include Kernel
def matches_spec?(spec);end
def dependency();end
def requirement();end
def type();end
def pretty_print(q);end
def match?(spec, allow_prerelease = nil);end
def requester();end
def explicit?();end
def request_context();end
def development?();end
def implicit?();end
end
class Gem::Resolver::RequirementList < Object
include Enumerable
include Kernel
def empty?();end
def size();end
def each();end
def add(req);end
def remove();end
def next5();end
end
class Gem::Resolver::Stats < Object
include Kernel
def requirement!();end
def record_requirements(reqs);end
def record_depth(stack);end
def backtracking!();end
def iteration!();end
end
class Gem::Resolver::Set < Object
include Kernel
def find_all(req);end
def prerelease();end
def errors();end
def errors=(arg0);end
def prerelease=(arg0);end
def prefetch(reqs);end
def remote();end
def remote?();end
def remote=(arg0);end
end
class Gem::Resolver::APISet < Gem::Resolver::Set
include Kernel
def find_all(req);end
def source();end
def uri();end
def pretty_print(q);end
def prefetch(reqs);end
def dep_uri();end
def prefetch_now();end
def versions(name);end
end
class Gem::Resolver::ComposedSet < Gem::Resolver::Set
include Kernel
def find_all(req);end
def errors();end
def prerelease=(allow_prerelease);end
def sets();end
def prefetch(reqs);end
def remote=(remote);end
end
class Gem::Resolver::BestSet < Gem::Resolver::ComposedSet
include Kernel
def find_all(req);end
def pretty_print(q);end
def prefetch(reqs);end
def pick_sets();end
def replace_failed_api_set(error);end
end
class Gem::Resolver::CurrentSet < Gem::Resolver::Set
include Kernel
def find_all(req);end
end
class Gem::Resolver::GitSet < Gem::Resolver::Set
include Kernel
def find_all(req);end
def specs();end
def pretty_print(q);end
def prefetch(reqs);end
def root_dir();end
def need_submodules();end
def repositories();end
def add_git_gem(name, repository, reference, submodules);end
def add_git_spec(name, version, repository, reference, submodules);end
def root_dir=(arg0);end
end
class Gem::Resolver::IndexSet < Gem::Resolver::Set
include Kernel
def find_all(req);end
def pretty_print(q);end
end
class Gem::Resolver::InstallerSet < Gem::Resolver::Set
include Kernel
def find_all(req);end
def pretty_print(q);end
def errors();end
def prerelease=(allow_prerelease);end
def ignore_dependencies();end
def prefetch(reqs);end
def ignore_dependencies=(arg0);end
def remote=(remote);end
def always_install();end
def ignore_installed();end
def remote_set();end
def consider_remote?();end
def add_always_install(dependency);end
def local?(dep_name);end
def add_local(dep_name, spec, source);end
def consider_local?();end
def load_spec(name, ver, platform, source);end
def ignore_installed=(arg0);end
end
class Gem::Resolver::LockSet < Gem::Resolver::Set
include Kernel
def find_all(req);end
def add(name, version, platform);end
def specs();end
def pretty_print(q);end
def load_spec(name, version, platform, source);end
end
class Gem::Resolver::VendorSet < Gem::Resolver::Set
include Kernel
def find_all(req);end
def specs();end
def pretty_print(q);end
def load_spec(name, version, platform, source);end
def add_vendor_gem(name, directory);end
end
class Gem::Resolver::Specification < Object
include Kernel
def source();end
def spec();end
def install(*args);end
def version();end
def dependencies();end
def full_name();end
def platform();end
def installable_platform?();end
def set();end
def fetch_development_dependencies();end
def local?();end
end
class Gem::Resolver::SpecSpecification < Gem::Resolver::Specification
include Kernel
def version();end
def dependencies();end
def full_name();end
def platform();end
end
class Gem::Resolver::APISpecification < Gem::Resolver::Specification
include Kernel
def source();end
def spec();end
def pretty_print(q);end
def installable_platform?();end
def fetch_development_dependencies();end
end
class Gem::Resolver::GitSpecification < Gem::Resolver::SpecSpecification
include Kernel
def install(*args);end
def add_dependency(dependency);end
def pretty_print(q);end
end
class Gem::Resolver::IndexSpecification < Gem::Resolver::Specification
include Kernel
def spec();end
def dependencies();end
def pretty_print(q);end
end
class Gem::Resolver::InstalledSpecification < Gem::Resolver::SpecSpecification
include Kernel
def source();end
def install(*args);end
def pretty_print(q);end
def installable_platform?();end
end
class Gem::Resolver::LocalSpecification < Gem::Resolver::SpecSpecification
include Kernel
def pretty_print(q);end
def installable_platform?();end
def local?();end
end
class Gem::Resolver::LockSpecification < Gem::Resolver::Specification
include Kernel
def spec();end
def install(*args);end
def add_dependency(dependency);end
def pretty_print(q);end
end
class Gem::Resolver::VendorSpecification < Gem::Resolver::SpecSpecification
include Kernel
def install(*args);end
end
class Gem::Installer < Object
include Gem::UserInteraction
include Gem::DefaultUserInteraction
include Kernel
def self.at(path, options = nil);end
def self.exec_format();end
def self.for_spec(spec, options = nil);end
def self.path_warning();end
def self.install_lock();end
def self.path_warning=(arg0);end
def self.exec_format=(arg0);end
def self.at(path, options = nil);end
def self.exec_format();end
def self.for_spec(spec, options = nil);end
def self.path_warning();end
def self.install_lock();end
def self.path_warning=(arg0);end
def self.exec_format=(arg0);end
def options();end
def unpack(directory);end
def spec();end
def dir();end
def install();end
def gem();end
def bin_dir();end
def gem_dir();end
def build_extensions();end
def spec_file();end
def shebang(bin_file_name);end
def run_pre_install_hooks();end
def run_post_build_hooks();end
def generate_bin();end
def run_post_install_hooks();end
def build_root();end
def gem_home();end
def extract_files();end
def process_options();end
def check_that_user_bin_dir_is_in_path();end
def check_executable_overwrite(filename);end
def formatted_program_filename(filename);end
def pre_install_checks();end
def default_spec_file();end
def extract_bin();end
def write_default_spec();end
def write_build_info_file();end
def write_spec();end
def write_cache_file();end
def installed_specs();end
def ensure_dependency(spec, dependency);end
def installation_satisfies_dependency?(dependency);end
def generate_windows_script(filename, bindir);end
def windows_stub_script(bindir, bin_file_name);end
def generate_bin_script(filename, bindir);end
def generate_bin_symlink(filename, bindir);end
def app_script_text(bin_file_name);end
def ensure_loadable_spec();end
def ensure_required_ruby_version_met();end
def ensure_required_rubygems_version_met();end
def ensure_dependencies_met();end
def verify_gem_home(*args);end
def extension_build_error(build_dir, output, backtrace = nil);end
end
class Gem::Ext::BuildError < Gem::InstallError
include Kernel
def self.exception(*args);end
end
class Gem::Installer::FakePackage < Object
include Kernel
def spec();end
def spec=(arg0);end
def extract_files(destination_dir, pattern = nil);end
def copy_to(path);end
end
class Gem::Licenses < Object
include Kernel
def self.match?(license);end
def self.match?(license);end
end
class Gem::PathSupport < Object
include Kernel
def path();end
def home();end
def spec_cache_dir();end
end
class Gem::Platform < Object
include Kernel
def self.match(platform);end
def self.local();end
def self.installable?(spec);end
def self.match(platform);end
def self.local();end
def self.installable?(spec);end
def to_a();end
def version();end
def version=(arg0);end
def cpu();end
def os();end
def cpu=(arg0);end
def os=(arg0);end
end
class Gem::RequestSet < Object
include TSort
include Kernel
def import(deps);end
def resolve_current();end
def specs();end
def install_dir();end
def install(options, &block);end
def gem(name, *reqs);end
def load_gemdeps(path, without_groups = nil, installing = nil);end
def dependencies();end
def development();end
def prerelease();end
def pretty_print(q);end
def errors();end
def prerelease=(arg0);end
def tsort_each_node(&block);end
def tsort_each_child(node);end
def development=(arg0);end
def development_shallow();end
def ignore_dependencies();end
def soft_missing();end
def sets();end
def resolve(*args);end
def development_shallow=(arg0);end
def ignore_dependencies=(arg0);end
def soft_missing=(arg0);end
def remote();end
def remote=(arg0);end
def always_install();end
def git_set();end
def resolver();end
def vendor_set();end
def install_into(dir, force = nil, options = nil);end
def sorted_requests();end
def install_from_gemdeps(options, &block);end
def specs_in(dir);end
def always_install=(arg0);end
end
class Gem::RequestSet::GemDependencyAPI < Object
include Kernel
def source(url);end
def group(*args);end
def gem(name, *requirements);end
def platforms(*args);end
def ruby(version, options = nil);end
def dependencies();end
def platform(*args);end
def gemspec(*args);end
def git_set();end
def vendor_set();end
def without_groups();end
def installing=(installing);end
def without_groups=(arg0);end
def requires();end
def git_source(name, &callback);end
def find_gemspec(name, path);end
def git(repository);end
def gem_deps_file();end
end
class Gem::RequestSet::Lockfile < Object
include Kernel
def self.build(request_set, gem_deps_file, dependencies = nil);end
def self.requests_to_deps(requests);end
def self.build(request_set, gem_deps_file, dependencies = nil);end
def self.requests_to_deps(requests);end
def write();end
def platforms();end
def add_DEPENDENCIES(out);end
def add_GEM(out, spec_groups);end
def spec_groups();end
def add_GIT(out, git_requests);end
def relative_path_from(dest, base);end
def add_PATH(out, path_requests);end
def add_PLATFORMS(out);end
end
class Gem::RequestSet::Lockfile::ParseError < Gem::Exception
include Kernel
def self.exception(*args);end
def path();end
def line();end
def column();end
end
class Gem::RequestSet::Lockfile::Parser < Object
include Kernel
def parse();end
def get(*args);end
def parse_DEPENDENCIES();end
def parse_GIT();end
def parse_GEM();end
def parse_PATH();end
def parse_PLATFORMS();end
def parse_dependency(name, op);end
end
class Gem::RequestSet::Lockfile::Tokenizer < Object
include Kernel
def self.from_file(file);end
def self.from_file(file);end
def empty?();end
def to_a();end
def shift();end
def unshift(token);end
def skip(type);end
def peek();end
def make_parser(set, platforms);end
def token_pos(byte_offset);end
def next_token();end
end
class Gem::RequestSet::Lockfile::Tokenizer::Token < Struct
include Enumerable
include Kernel
def self.[](*args);end
def self.members();end
def self.[](*args);end
def self.members();end
def value();end
def type();end
def value=(_);end
def line();end
def type=(_);end
def column();end
def column=(_);end
def line=(_);end
end
class Gem::Requirement < Object
include Kernel
def self.default();end
def self.create(input);end
def self.source_set();end
def self.parse(obj);end
def self.default();end
def self.create(input);end
def self.source_set();end
def self.parse(obj);end
def none?();end
def concat(new);end
def marshal_dump();end
def marshal_load(array);end
def requirements();end
def prerelease?();end
def encode_with(coder);end
def init_with(coder);end
def yaml_initialize(tag, vals);end
def pretty_print(q);end
def as_list();end
def satisfied_by?(version);end
def to_yaml_properties();end
def for_lockfile();end
def exact?();end
def specific?();end
end
class Gem::Requirement::BadRequirementError < ArgumentError
include Kernel
def self.exception(*args);end
end
class Gem::Source < Object
include Comparable
include Kernel
def uri();end
def cache_dir(uri);end
def pretty_print(q);end
def download(spec, dir = nil);end
def dependency_resolver_set();end
def fetch_spec(name_tuple);end
def api_uri();end
def update_cache?();end
def load_specs(type);end
end
class Gem::Source::Git < Gem::Source
include Comparable
include Kernel
def specs();end
def install_dir();end
def base_dir();end
def pretty_print(q);end
def download(full_spec, path);end
def remote();end
def remote=(arg0);end
def root_dir();end
def need_submodules();end
def repository();end
def reference();end
def root_dir=(arg0);end
def rev_parse();end
def checkout();end
def cache();end
def repo_cache_dir();end
def dir_shortref();end
def uri_hash();end
end
class Gem::Source::Installed < Gem::Source
include Comparable
include Kernel
def pretty_print(q);end
def download(spec, path);end
end
class Gem::Source::SpecificFile < Gem::Source
include Comparable
include Kernel
def path();end
def spec();end
def pretty_print(q);end
def download(spec, dir = nil);end
def fetch_spec(name);end
def load_specs(*args);end
end
class Gem::Source::Local < Gem::Source
include Comparable
include Kernel
def pretty_print(q);end
def download(spec, cache_dir = nil);end
def find_gem(gem_name, version = nil, prerelease = nil);end
def fetch_spec(name);end
def load_specs(type);end
end
class Gem::Source::Lock < Gem::Source
include Comparable
include Kernel
def uri();end
def fetch_spec(name_tuple);end
def wrapped();end
end
class Gem::Source::Vendor < Gem::Source::Installed
include Comparable
include Kernel
end
class Gem::SourceList < Object
include Enumerable
include Kernel
def self.from(ary);end
def self.from(ary);end
def <<(obj);end
def empty?();end
def each();end
def to_ary();end
def to_a();end
def first();end
def replace(other);end
def clear();end
def delete(source);end
def sources();end
def each_source(&b);end
end
class Gem::SpecFetcher < Object
include Gem::Text
include Gem::UserInteraction
include Gem::DefaultUserInteraction
include Kernel
def self.fetcher();end
def self.fetcher=(fetcher);end
def self.fetcher();end
def self.fetcher=(fetcher);end
def detect(*args);end
def specs();end
def latest_specs();end
def spec_for_dependency(dependency, matching_platform = nil);end
def sources();end
def search_for_dependency(dependency, matching_platform = nil);end
def available_specs(type);end
def suggest_gems_from_name(gem_name);end
def prerelease_specs();end
def tuples_for(source, type, gracefully_ignore = nil);end
end
class Gem::Specification < Gem::BasicSpecification
include Kernel
def self.each();end
def self._load(str);end
def self.find_by_path(path);end
def self.find_by_name(name, *requirements);end
def self.unresolved_deps();end
def self.reset();end
def self.dirs();end
def self.dirs=(dirs);end
def self.stubs();end
def self.latest_specs(*args);end
def self.load_defaults();end
def self._all();end
def self._clear_load_cache();end
def self.each_gemspec(dirs);end
def self.each_spec(dirs);end
def self._resort!(specs);end
def self.stubs_for(name);end
def self.add_spec(spec);end
def self.add_specs(*args);end
def self.all();end
def self.all=(specs);end
def self.all_names();end
def self.array_attributes();end
def self.attribute_names();end
def self.find_all_by_name(name, *requirements);end
def self.find_inactive_by_path(path);end
def self.find_active_stub_by_path(path);end
def self.find_in_unresolved(path);end
def self.find_in_unresolved_tree(path);end
def self.from_yaml(input);end
def self.normalize_yaml_input(input);end
def self._latest_specs(specs, prerelease = nil);end
def self.non_nil_attributes();end
def self.outdated();end
def self.outdated_and_latest_version();end
def self.remove_spec(spec);end
def self.required_attribute?(name);end
def self.required_attributes();end
def self.to_a(*args);end
def self.to_h(*args);end
def self.find(*args);end
def self.entries(*args);end
def self.sort();end
def self.sort_by();end
def self.grep(arg0);end
def self.grep_v(arg0);end
def self.count(*args);end
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
def self.min(*args);end
def self.max(*args);end
def self.minmax();end
def self.min_by(*args);end
def self.max_by(*args);end
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
def self.chunk();end
def self.slice_before(*args);end
def self.slice_after(*args);end
def self.slice_when();end
def self.chunk_while();end
def self.lazy();end
def self.to_set(*args);end
def self.default_specifications_dir();end
def self.each();end
def self._load(str);end
def self.find_by_path(path);end
def self.find_by_name(name, *requirements);end
def self.unresolved_deps();end
def self.reset();end
def self.dirs();end
def self.dirs=(dirs);end
def self.stubs();end
def self.latest_specs(*args);end
def self.load_defaults();end
def self._all();end
def self._clear_load_cache();end
def self.each_gemspec(dirs);end
def self.each_spec(dirs);end
def self._resort!(specs);end
def self.stubs_for(name);end
def self.add_spec(spec);end
def self.add_specs(*args);end
def self.all();end
def self.all=(specs);end
def self.all_names();end
def self.array_attributes();end
def self.attribute_names();end
def self.find_all_by_name(name, *requirements);end
def self.find_inactive_by_path(path);end
def self.find_active_stub_by_path(path);end
def self.find_in_unresolved(path);end
def self.find_in_unresolved_tree(path);end
def self.from_yaml(input);end
def self.normalize_yaml_input(input);end
def self._latest_specs(specs, prerelease = nil);end
def self.non_nil_attributes();end
def self.outdated();end
def self.outdated_and_latest_version();end
def self.remove_spec(spec);end
def self.required_attribute?(name);end
def self.required_attributes();end
def date=(date);end
def sort_obj();end
def raise_if_conflicts();end
def activate_dependencies();end
def add_self_to_load_path();end
def runtime_dependencies();end
def abbreviate();end
def files=(files);end
def rdoc_options=(options);end
def extra_rdoc_files=(files);end
def cert_chain=(arg0);end
def sanitize();end
def normalize();end
def sanitize_string(string);end
def description=(str);end
def _dump(limit);end
def post_install_message=(arg0);end
def summary=(str);end
def add_dependency(gem, *requirements);end
def source();end
def author();end
def bin_dir();end
def gem_dir();end
def rubygems_version=(arg0);end
def bindir=(arg0);end
def build_info_file();end
def email=(arg0);end
def homepage=(arg0);end
def base_dir();end
def build_args();end
def signing_key=(arg0);end
def metadata=(arg0);end
def build_extensions();end
def autorequire=(arg0);end
def default_executable=(arg0);end
def original_platform=(arg0);end
def rubyforge_project=(arg0);end
def cache_dir();end
def build_info_dir();end
def bundled_gem_in_old_ruby?();end
def satisfies_requirement?(dependency);end
def cache_file();end
def activated?();end
def activate();end
def dependent_gems();end
def conflicts();end
def dependent_specs();end
def default_value(name);end
def development_dependencies();end
def dependencies();end
def doc_dir(*args);end
def encode_with(coder);end
def full_name();end
def mark_version();end
def platform();end
def requirements();end
def executable();end
def executable=(o);end
def executables=(value);end
def extensions=(extensions);end
def file_name();end
def bin_file(name);end
def name=(arg0);end
def has_rdoc();end
def has_rdoc=(ignored);end
def executables();end
def has_rdoc?();end
def has_unit_tests?();end
def bindir();end
def for_cache();end
def has_test_suite?();end
def specification_version();end
def date();end
def summary();end
def init_with(coder);end
def authors();end
def autorequire();end
def cert_chain();end
def description();end
def extensions();end
def extra_rdoc_files();end
def homepage();end
def metadata();end
def email();end
def post_install_message();end
def required_ruby_version();end
def required_rubygems_version();end
def rdoc_options();end
def rubyforge_project();end
def signing_key();end
def name_tuple();end
def lib_files();end
def license();end
def internal_init();end
def require_path();end
def licenses();end
def requirements=(req);end
def missing_extensions?();end
def require_path=(path);end
def ri_dir();end
def require_paths=(val);end
def author=(o);end
def authors=(value);end
def platform=(platform);end
def spec_name();end
def spec_dir();end
def files();end
def raw_require_paths();end
def pretty_print(q);end
def add_bindir(executables);end
def method_missing(sym, *a, &b);end
def test_file=(file);end
def to_spec();end
def add_development_dependency(gem, *requirements);end
def test_file();end
def add_runtime_dependency(gem, *requirements);end
def to_yaml(*args);end
def installed_by_version();end
def version();end
def installed_by_version=(version);end
def license=(o);end
def licenses=(licenses);end
def to_ruby();end
def required_ruby_version=(req);end
def spec_file();end
def required_rubygems_version=(req);end
def validate(*args);end
def to_ruby_for_cache();end
def test_files=(files);end
def activated();end
def default_executable();end
def original_platform();end
def warning(statement);end
def activated=(arg0);end
def validate_permissions();end
def version=(version);end
def validate_dependencies();end
def gems_dir();end
def test_files();end
def yaml_initialize(tag, vals);end
def stubbed?();end
def original_name();end
def specification_version=(arg0);end
def rubygems_version();end
def traverse(*args);end
def has_conflicts?();end
def conficts_when_loaded_with?(list_of_specs);end
def reset_nil_attributes_to_default();end
end
class Gem::Version < Object
include Comparable
include Kernel
def self.create(input);end
def self.correct?(version);end
def self.create(input);end
def self.correct?(version);end
def marshal_dump();end
def marshal_load(array);end
def version();end
def prerelease?();end
def encode_with(coder);end
def init_with(coder);end
def yaml_initialize(tag, map);end
def pretty_print(q);end
def segments();end
def bump();end
def to_yaml_properties();end
def release();end
def approximate_recommendation();end
end
class Gem::BasicSpecification < Object
include Kernel
def self.default_specifications_dir();end
def self.default_specifications_dir();end
def activated?();end
def datadir();end
def matches_for_glob(glob);end
def version();end
def require_paths();end
def base_dir();end
def full_name();end
def platform();end
def to_spec();end
def gems_dir();end
def contains_requirable_file?(file);end
def loaded_from();end
def loaded_from=(arg0);end
def default_gem?();end
def full_require_paths();end
def gem_dir();end
def gem_build_complete_path();end
def internal_init();end
def raw_require_paths();end
def stubbed?();end
def extension_dir();end
def full_gem_path();end
def extensions_dir();end
def to_fullpath(path);end
def source_paths();end
def lib_dirs_glob();end
def base_dir=(arg0);end
def extension_dir=(arg0);end
def ignored=(arg0);end
def full_gem_path=(arg0);end
end
class Gem::StubSpecification < Gem::BasicSpecification
include Kernel
def self.default_gemspec_stub(filename, base_dir, gems_dir);end
def self.gemspec_stub(filename, base_dir, gems_dir);end
def self.default_specifications_dir();end
def self.default_gemspec_stub(filename, base_dir, gems_dir);end
def self.gemspec_stub(filename, base_dir, gems_dir);end
def activated?();end
def version();end
def base_dir();end
def full_name();end
def platform();end
def extensions();end
def to_spec();end
def this();end
def valid?();end
def gems_dir();end
def default_gem?();end
def build_extensions();end
def missing_extensions?();end
def raw_require_paths();end
def stubbed?();end
end
class Gem::StubSpecification::StubLine < Object
include Kernel
def version();end
def require_paths();end
def full_name();end
def platform();end
def extensions();end
end
class Gem::List < Object
include Enumerable
include Kernel
def each();end
def to_a();end
def value();end
def pretty_print(q);end
def tail();end
def value=(arg0);end
def tail=(arg0);end
end
class Gem::Exception < RuntimeError
include Kernel
def self.exception(*args);end
def source_exception();end
def source_exception=(arg0);end
end
class Gem::CommandLineError < Gem::Exception
include Kernel
def self.exception(*args);end
end
class Gem::DependencyError < Gem::Exception
include Kernel
def self.exception(*args);end
end
class Gem::DependencyRemovalException < Gem::Exception
include Kernel
def self.exception(*args);end
end
class Gem::DependencyResolutionError < Gem::DependencyError
include Kernel
def self.exception(*args);end
def conflict();end
def conflicting_dependencies();end
end
class Gem::GemNotInHomeException < Gem::Exception
include Kernel
def self.exception(*args);end
def spec();end
def spec=(arg0);end
end
class Gem::DocumentError < Gem::Exception
include Kernel
def self.exception(*args);end
end
class Gem::EndOfYAMLException < Gem::Exception
include Kernel
def self.exception(*args);end
end
class Gem::FilePermissionError < Gem::Exception
include Kernel
def self.exception(*args);end
def directory();end
end
class Gem::FormatException < Gem::Exception
include Kernel
def self.exception(*args);end
def file_path();end
def file_path=(arg0);end
end
class Gem::GemNotFoundException < Gem::Exception
include Kernel
def self.exception(*args);end
end
class Gem::SpecificGemNotFoundException < Gem::GemNotFoundException
include Kernel
def self.exception(*args);end
def version();end
def errors();end
end
class Gem::ImpossibleDependenciesError < Gem::Exception
include Kernel
def self.exception(*args);end
def dependency();end
def conflicts();end
def request();end
def build_message();end
end
class Gem::InstallError < Gem::Exception
include Kernel
def self.exception(*args);end
end
class Gem::InvalidSpecificationException < Gem::Exception
include Kernel
def self.exception(*args);end
end
class Gem::OperationNotSupportedError < Gem::Exception
include Kernel
def self.exception(*args);end
end
class Gem::RemoteError < Gem::Exception
include Kernel
def self.exception(*args);end
end
class Gem::RemoteInstallationCancelled < Gem::Exception
include Kernel
def self.exception(*args);end
end
class Gem::RemoteInstallationSkipped < Gem::Exception
include Kernel
def self.exception(*args);end
end
class Gem::RemoteSourceException < Gem::Exception
include Kernel
def self.exception(*args);end
end
class Gem::RubyVersionMismatch < Gem::Exception
include Kernel
def self.exception(*args);end
end
class Gem::VerificationError < Gem::Exception
include Kernel
def self.exception(*args);end
end
class Gem::SystemExitException < SystemExit
include Kernel
def self.exception(*args);end
def exit_code();end
def exit_code=(arg0);end
end
class Gem::UnsatisfiableDependencyError < Gem::DependencyError
include Kernel
def self.exception(*args);end
def version();end
def dependency();end
def errors();end
def errors=(arg0);end
end
module DidYouMean
end
module DidYouMean::Correctable
def to_s();end
def original_message();end
def corrections();end
def spell_checker();end
end
module DidYouMean::Levenshtein
def distance(str1, str2);end
def min3(a, b, c);end
def self.distance(str1, str2);end
def self.min3(a, b, c);end
end
module DidYouMean::Jaro
def distance(str1, str2);end
def self.distance(str1, str2);end
end
module DidYouMean::JaroWinkler
def distance(str1, str2);end
def self.distance(str1, str2);end
end
module DidYouMean::SpellCheckable
def corrections();end
def candidates();end
end
class DidYouMean::ClassNameChecker < Object
include DidYouMean::SpellCheckable
include Kernel
def corrections();end
def candidates();end
def class_name();end
def class_names();end
def scopes();end
end
class DidYouMean::VariableNameChecker < Object
include DidYouMean::SpellCheckable
include Kernel
def candidates();end
def method_names();end
def lvar_names();end
def ivar_names();end
def cvar_names();end
end
module DidYouMean::NameErrorCheckers
def included(*args);end
def self.included(*args);end
end
class DidYouMean::MethodNameChecker < Object
include DidYouMean::SpellCheckable
include Kernel
def receiver();end
def candidates();end
def method_names();end
def method_name();end
end
class DidYouMean::NullChecker < Object
include Kernel
def corrections();end
end
class DidYouMean::Formatter < Object
include Kernel
end
module RbConfig
def ruby();end
def expand(val, config = nil);end
def self.ruby();end
def self.expand(val, config = nil);end
end
class StringIO < Data
include IO::generic_writable
include IO::generic_readable
include Enumerable
include Kernel
def length();end
def size();end
def each(*args);end
def getbyte();end
def lines(*args);end
def bytes();end
def chars();end
def codepoints();end
def each_line(*args);end
def each_byte();end
def each_char();end
def each_codepoint();end
def truncate(arg0);end
def string();end
def read(*args);end
def write(arg0);end
def binmode();end
def getc();end
def flush();end
def set_encoding(*args);end
def reopen(*args);end
def fileno();end
def fsync();end
def sync();end
def sync=(arg0);end
def lineno();end
def lineno=(arg0);end
def ungetbyte(arg0);end
def ungetc(arg0);end
def tell();end
def seek(*args);end
def rewind();end
def pos();end
def pos=(arg0);end
def eof();end
def eof?();end
def close();end
def closed?();end
def close_read();end
def close_write();end
def isatty();end
def tty?();end
def fcntl(*args);end
def pid();end
def external_encoding();end
def internal_encoding();end
def string=(arg0);end
def closed_read?();end
def closed_write?();end
end
module MonitorMixin
def extend_object(obj);end
def self.extend_object(obj);end
def synchronize();end
def mon_try_enter();end
def try_mon_enter();end
def mon_enter();end
def mon_exit();end
def mon_synchronize();end
def new_cond();end
end
class MonitorMixin::ConditionVariable < Object
include Kernel
def wait(*args);end
def signal();end
def broadcast();end
def wait_while();end
def wait_until();end
end
class MonitorMixin::ConditionVariable::Timeout < Exception
include Kernel
def self.exception(*args);end
end
class Monitor < Object
include MonitorMixin
include Kernel
def enter();end
def try_enter();end
end
class Delegator < BasicObject
include #<Module:0x007f5ffc80ad28>
def self.public_api();end
def self.delegating_block(mid);end
def self.public_api();end
def self.delegating_block(mid);end
def method_missing(m, *args, &block);end
def marshal_dump();end
def marshal_load(data);end
def __getobj__();end
def __setobj__(obj);end
end
class SimpleDelegator < Delegator
include #<Module:0x007f5ffc80ad28>
def self.public_api();end
def self.delegating_block(mid);end
def __getobj__();end
def __setobj__(obj);end
end
