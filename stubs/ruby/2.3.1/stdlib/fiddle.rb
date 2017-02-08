module Fiddle
def last_error();end
def last_error=(error);end
def dlopen(library);end
def dlwrap(arg0);end
def dlunwrap(arg0);end
def malloc(arg0);end
def realloc(arg0, arg1);end
def free(arg0);end
def self.last_error();end
def self.last_error=(error);end
def self.dlopen(library);end
def self.dlwrap(arg0);end
def self.dlunwrap(arg0);end
def self.malloc(arg0);end
def self.realloc(arg0, arg1);end
def self.free(arg0);end
end
class Fiddle::DLError < StandardError
include Kernel
def self.exception(*args);end
end
class Fiddle::Function < Object
include Kernel
def to_i();end
def call(*args);end
def ptr();end
def abi();end
end
class Fiddle::Closure < Object
include Kernel
def to_i();end
def args();end
def ctype();end
end
class Fiddle::Closure::BlockCaller < Fiddle::Closure
include Kernel
def call(*args);end
end
class Fiddle::Handle < Object
include Kernel
def self.[](arg0);end
def self.sym(arg0);end
def self.[](arg0);end
def self.sym(arg0);end
def [](arg0);end
def to_i();end
def close();end
def sym(arg0);end
def disable_close();end
def enable_close();end
def close_enabled?();end
end
class Fiddle::Pointer < Object
include Kernel
def self.[](arg0);end
def self.malloc(*args);end
def self.to_ptr(arg0);end
def self.[](arg0);end
def self.malloc(*args);end
def self.to_ptr(arg0);end
def +(arg0);end
def -(arg0);end
def +@();end
def -@();end
def [](*args);end
def []=(*args);end
def size();end
def to_int();end
def to_str(*args);end
def to_i();end
def free();end
def free=(arg0);end
def to_value();end
def ptr();end
def ref();end
def null?();end
def size=(arg0);end
end
