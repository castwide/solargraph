module Zlib
def deflate(*args);end
def inflate(arg0);end
def zlib_version();end
def adler32(*args);end
def adler32_combine(arg0, arg1, arg2);end
def crc32(*args);end
def crc32_combine(arg0, arg1, arg2);end
def crc_table();end
def self.deflate(*args);end
def self.inflate(arg0);end
def self.zlib_version();end
def self.adler32(*args);end
def self.adler32_combine(arg0, arg1, arg2);end
def self.crc32(*args);end
def self.crc32_combine(arg0, arg1, arg2);end
def self.crc_table();end
end
class Zlib::Error < StandardError
include Kernel
def self.exception(*args);end
end
class Zlib::StreamEnd < Zlib::Error
include Kernel
def self.exception(*args);end
end
class Zlib::NeedDict < Zlib::Error
include Kernel
def self.exception(*args);end
end
class Zlib::DataError < Zlib::Error
include Kernel
def self.exception(*args);end
end
class Zlib::StreamError < Zlib::Error
include Kernel
def self.exception(*args);end
end
class Zlib::MemError < Zlib::Error
include Kernel
def self.exception(*args);end
end
class Zlib::BufError < Zlib::Error
include Kernel
def self.exception(*args);end
end
class Zlib::VersionError < Zlib::Error
include Kernel
def self.exception(*args);end
end
class Zlib::ZStream < Object
include Kernel
def end();end
def finish();end
def close();end
def closed?();end
def reset();end
def avail_out();end
def avail_out=(arg0);end
def avail_in();end
def total_in();end
def total_out();end
def data_type();end
def adler();end
def finished?();end
def stream_end?();end
def ended?();end
def flush_next_in();end
def flush_next_out();end
end
class Zlib::Deflate < Zlib::ZStream
include Kernel
def self.deflate(*args);end
def self.deflate(*args);end
def <<(arg0);end
def flush(*args);end
def deflate(*args);end
def params(arg0, arg1);end
def set_dictionary(arg0);end
end
class Zlib::Inflate < Zlib::ZStream
include Kernel
def self.inflate(arg0);end
def self.inflate(arg0);end
def <<(arg0);end
def sync(arg0);end
def inflate(arg0);end
def set_dictionary(arg0);end
def add_dictionary(arg0);end
def sync_point?();end
end
class Zlib::GzipFile < Object
include Kernel
def self.wrap(*args);end
def self.wrap(*args);end
def to_io();end
def finish();end
def sync();end
def sync=(arg0);end
def close();end
def closed?();end
def mtime();end
def crc();end
def level();end
def os_code();end
def orig_name();end
def comment();end
end
class Zlib::GzipFile::Error < Zlib::Error
include Kernel
def self.exception(*args);end
def input();end
end
class Zlib::GzipFile::NoFooter < Zlib::GzipFile::Error
include Kernel
def self.exception(*args);end
end
class Zlib::GzipFile::CRCError < Zlib::GzipFile::Error
include Kernel
def self.exception(*args);end
end
class Zlib::GzipFile::LengthError < Zlib::GzipFile::Error
include Kernel
def self.exception(*args);end
end
class Zlib::GzipWriter < Zlib::GzipFile
include Kernel
def self.wrap(*args);end
def <<(arg0);end
def write(arg0);end
def flush(*args);end
def tell();end
def pos();end
def mtime=(arg0);end
def orig_name=(arg0);end
def comment=(arg0);end
end
class Zlib::GzipReader < Zlib::GzipFile
include Enumerable
include Kernel
def self.wrap(*args);end
def each(*args);end
def getbyte();end
def lines(*args);end
def bytes();end
def each_line(*args);end
def each_byte();end
def each_char();end
def read(*args);end
def getc();end
def readpartial(*args);end
def lineno();end
def lineno=(arg0);end
def readchar();end
def readbyte();end
def ungetbyte(arg0);end
def ungetc(arg0);end
def tell();end
def rewind();end
def pos();end
def eof();end
def eof?();end
def external_encoding();end
def unused();end
end
