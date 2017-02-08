module Benchmark
def benchmark(*args);end
def measure(*args);end
def realtime();end
def bm(*args);end
def bmbm(*args);end
def self.benchmark(*args);end
def self.measure(*args);end
def self.realtime();end
def self.bm(*args);end
def self.bmbm(*args);end
end
class Benchmark::Job < Object
include Kernel
def item(*args);end
def report(*args);end
def list();end
def width();end
end
class Benchmark::Report < Object
include Kernel
def item(*args);end
def report(*args);end
def list();end
end
class Benchmark::Tms < Object
include Kernel
def utime();end
def stime();end
def cutime();end
def cstime();end
def real();end
def total();end
def label();end
def add(&blk);end
def add!(&blk);end
def +(other);end
def -(other);end
def *(x);end
def /(x);end
def to_a();end
end
