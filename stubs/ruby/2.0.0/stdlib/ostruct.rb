class OpenStruct < Object
include Kernel
def to_h();end
def each_pair();end
def marshal_dump();end
def marshal_load(x);end
def method_missing(mid, *args);end
def [](name);end
def []=(name, value);end
def delete_field(name);end
end
