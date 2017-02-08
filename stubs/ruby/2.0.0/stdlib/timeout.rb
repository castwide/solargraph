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
