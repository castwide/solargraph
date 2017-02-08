module Timeout
def timeout(sec, klass = nil);end
def self.timeout(sec, klass = nil);end
end
class Timeout::Error < RuntimeError
include Kernel
def self.exception(*args);end
def exception(*args);end
def thread();end
end
class Timeout::Error < RuntimeError
include Kernel
def self.exception(*args);end
def exception(*args);end
def thread();end
end
