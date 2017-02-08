class Delegator < BasicObject
include #<Module:0x000000018c3f38>
def self.public_api();end
def self.delegating_block(mid);end
def self.public_api();end
def self.delegating_block(mid);end
def method_missing(m, *args, &block);end
def __getobj__();end
def __setobj__(obj);end
def marshal_dump();end
def marshal_load(data);end
end
class BasicObject
def self.allocate();end
def self.new(*args);end
def self.superclass();end
def ==(arg0);end
def equal?(arg0);end
def !();end
def !=(arg0);end
def instance_eval(*args);end
def instance_exec(*args);end
def __send__(*args);end
def __id__();end
end
class SimpleDelegator < Delegator
include #<Module:0x000000018c3f38>
def self.public_api();end
def self.delegating_block(mid);end
def __getobj__();end
def __setobj__(obj);end
end
class BasicObject
def self.allocate();end
def self.new(*args);end
def self.superclass();end
def ==(arg0);end
def equal?(arg0);end
def !();end
def !=(arg0);end
def instance_eval(*args);end
def instance_exec(*args);end
def __send__(*args);end
def __id__();end
end
class WeakRef < Delegator
include #<Module:0x000000018c3f38>
def self.public_api();end
def self.delegating_block(mid);end
def __getobj__();end
def __setobj__(obj);end
def weakref_alive?();end
end
class WeakRef::RefError < StandardError
include Kernel
def self.exception(*args);end
end
class BasicObject
def self.allocate();end
def self.new(*args);end
def self.superclass();end
def ==(arg0);end
def equal?(arg0);end
def !();end
def !=(arg0);end
def instance_eval(*args);end
def instance_exec(*args);end
def __send__(*args);end
def __id__();end
end
