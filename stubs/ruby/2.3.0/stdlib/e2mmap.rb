module Exception2MessageMapper
def extend_object(cl);end
def message(klass, exp);end
def Raise(*args);end
def Fail(*args);end
def def_e2message(k, c, m);end
def def_exception(k, n, m, s = nil);end
def e2mm_message(klass, exp);end
def self.extend_object(cl);end
def self.message(klass, exp);end
def self.Raise(*args);end
def self.Fail(*args);end
def self.def_e2message(k, c, m);end
def self.def_exception(k, n, m, s = nil);end
def self.e2mm_message(klass, exp);end
def fail(*args);end
def bind(cl);end
def Raise(*args);end
def Fail(*args);end
def def_e2message(c, m);end
def def_exception(n, m, s = nil);end
end
class Exception2MessageMapper::ErrNotRegisteredException < StandardError
include Kernel
def self.exception(*args);end
end
