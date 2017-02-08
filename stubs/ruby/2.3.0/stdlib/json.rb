module JSON
def [](object, opts = nil);end
def dump(obj, anIO = nil, limit = nil);end
def restore(source, proc = nil, options = nil);end
def state();end
def parse(source, opts = nil);end
def parser();end
def generate(obj, opts = nil);end
def parser=(parser);end
def deep_const_get(path);end
def generator=(generator);end
def generator();end
def state=(arg0);end
def create_id();end
def create_id=(arg0);end
def parse!(source, opts = nil);end
def unparse(obj, opts = nil);end
def fast_generate(obj, opts = nil);end
def fast_unparse(obj, opts = nil);end
def pretty_generate(obj, opts = nil);end
def pretty_unparse(obj, opts = nil);end
def load_default_options();end
def load_default_options=(arg0);end
def recurse_proc(result, &proc);end
def dump_default_options();end
def dump_default_options=(arg0);end
def iconv(to, from, string);end
def self.[](object, opts = nil);end
def self.dump(obj, anIO = nil, limit = nil);end
def self.restore(source, proc = nil, options = nil);end
def self.state();end
def self.parse(source, opts = nil);end
def self.parser();end
def self.generate(obj, opts = nil);end
def self.parser=(parser);end
def self.deep_const_get(path);end
def self.generator=(generator);end
def self.generator();end
def self.state=(arg0);end
def self.create_id();end
def self.create_id=(arg0);end
def self.parse!(source, opts = nil);end
def self.unparse(obj, opts = nil);end
def self.fast_generate(obj, opts = nil);end
def self.fast_unparse(obj, opts = nil);end
def self.pretty_generate(obj, opts = nil);end
def self.pretty_unparse(obj, opts = nil);end
def self.load_default_options();end
def self.load_default_options=(arg0);end
def self.recurse_proc(result, &proc);end
def self.dump_default_options();end
def self.dump_default_options=(arg0);end
def self.iconv(to, from, string);end
end
class JSON::GenericObject < OpenStruct
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.[](*args);end
def self.dump(obj, *args);end
def self.json_create(data);end
def self.from_hash(object);end
def self.json_creatable=(arg0);end
def self.[](*args);end
def self.dump(obj, *args);end
def self.json_create(data);end
def self.from_hash(object);end
def self.json_creatable=(arg0);end
def |(other);end
def to_hash();end
def as_json(*args);end
end
class JSON::JSONError < StandardError
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.wrap(exception);end
def self.exception(*args);end
def self.wrap(exception);end
end
class JSON::ParserError < JSON::JSONError
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.wrap(exception);end
def self.exception(*args);end
end
class JSON::NestingError < JSON::ParserError
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.wrap(exception);end
def self.exception(*args);end
end
class JSON::CircularDatastructure < JSON::NestingError
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.wrap(exception);end
def self.exception(*args);end
end
class JSON::GeneratorError < JSON::JSONError
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.wrap(exception);end
def self.exception(*args);end
end
class JSON::MissingUnicodeSupport < JSON::JSONError
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.wrap(exception);end
def self.exception(*args);end
end
module JSON::Ext
end
class JSON::Ext::Parser < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def source();end
def parse();end
end
module JSON::Ext::Generator
end
class JSON::Ext::Generator::State < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.from_state(arg0);end
def self.from_state(arg0);end
def [](arg0);end
def []=(arg0, arg1);end
def to_hash();end
def to_h();end
def ascii_only?();end
def merge(arg0);end
def generate(arg0);end
def indent();end
def space();end
def object_nl();end
def array_nl();end
def max_nesting();end
def configure(arg0);end
def indent=(arg0);end
def space=(arg0);end
def space_before();end
def space_before=(arg0);end
def object_nl=(arg0);end
def array_nl=(arg0);end
def max_nesting=(arg0);end
def check_circular?();end
def allow_nan?();end
def depth();end
def depth=(arg0);end
def buffer_initial_length();end
def buffer_initial_length=(arg0);end
end
module JSON::Ext::Generator::GeneratorMethods
end
module JSON::Ext::Generator::GeneratorMethods::Object
def to_json(*args);end
end
module JSON::Ext::Generator::GeneratorMethods::Hash
def to_json(*args);end
end
module JSON::Ext::Generator::GeneratorMethods::Array
def to_json(*args);end
end
module JSON::Ext::Generator::GeneratorMethods::Fixnum
def to_json(*args);end
end
module JSON::Ext::Generator::GeneratorMethods::Bignum
def to_json(*args);end
end
module JSON::Ext::Generator::GeneratorMethods::Float
def to_json(*args);end
end
module JSON::Ext::Generator::GeneratorMethods::String
def included(arg0);end
def self.included(arg0);end
def to_json(*args);end
def to_json_raw(*args);end
def to_json_raw_object();end
end
module JSON::Ext::Generator::GeneratorMethods::String::Extend
def json_create(arg0);end
end
module JSON::Ext::Generator::GeneratorMethods::TrueClass
def to_json(*args);end
end
module JSON::Ext::Generator::GeneratorMethods::FalseClass
def to_json(*args);end
end
module JSON::Ext::Generator::GeneratorMethods::NilClass
def to_json(*args);end
end
class OpenStruct < Object
include JSON::Ext::Generator::GeneratorMethods::Object
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
