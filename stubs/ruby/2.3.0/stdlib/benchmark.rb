module Benchmark
def benchmark(*args);end
def bm(*args);end
def bmbm(*args);end
def measure(*args);end
def realtime();end
def self.benchmark(*args);end
def self.bm(*args);end
def self.bmbm(*args);end
def self.measure(*args);end
def self.realtime();end
end
class Benchmark::Job < Object
include Kernel
def list();end
def report(*args);end
def width();end
def item(*args);end
end
class Benchmark::Report < Object
include Kernel
def list();end
def report(*args);end
def item(*args);end
end
class Benchmark::Tms < Object
include Kernel
def *(x);end
def +(other);end
def -(other);end
def /(x);end
def to_a();end
def utime();end
def label();end
def add(&blk);end
def stime();end
def cutime();end
def cstime();end
def real();end
def total();end
def add!(&blk);end
end
