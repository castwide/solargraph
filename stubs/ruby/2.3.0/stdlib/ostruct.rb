class OpenStruct < Object
include Kernel
def [](name);end
def []=(name, value);end
def method_missing(mid, *args);end
def dig(name, *names);end
def to_h();end
def each_pair();end
def marshal_dump();end
def marshal_load(x);end
def delete_field(name);end
end
