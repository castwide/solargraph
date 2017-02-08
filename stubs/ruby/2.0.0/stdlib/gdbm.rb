class GDBM < Object
include Enumerable
include Kernel
def close();end
def closed?();end
def [](arg0);end
def fetch(*args);end
def []=(arg0, arg1);end
def store(arg0, arg1);end
def index(arg0);end
def key(arg0);end
def values_at(*args);end
def length();end
def size();end
def empty?();end
def each();end
def each_value();end
def each_key();end
def each_pair();end
def keys();end
def values();end
def shift();end
def delete(arg0);end
def delete_if();end
def reject!();end
def reject();end
def clear();end
def invert();end
def update(arg0);end
def replace(arg0);end
def reorganize();end
def sync();end
def cachesize=(arg0);end
def fastmode=(arg0);end
def syncmode=(arg0);end
def has_key?(arg0);end
def member?(arg0);end
def has_value?(arg0);end
def key?(arg0);end
def value?(arg0);end
def to_a();end
def to_hash();end
end
class GDBMError < StandardError
include Kernel
def self.exception(*args);end
end
class GDBMFatalError < Exception
include Kernel
def self.exception(*args);end
end
