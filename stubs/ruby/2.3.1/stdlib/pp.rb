class PrettyPrint < Object
include PP::ObjectMixin
include Kernel
def self.singleline_format(*args);end
def self.singleline_format(*args);end
def text(obj, width = nil);end
def newline();end
def flush();end
def group(*args);end
def breakable(*args);end
def output();end
def maxwidth();end
def genspace();end
def indent();end
def group_queue();end
def current_group();end
def break_outmost_groups();end
def fill_breakable(*args);end
def group_sub();end
def nest(indent);end
end
class PrettyPrint::Text < Object
include PP::ObjectMixin
include Kernel
def add(obj, width);end
def width();end
def output(out, output_width);end
end
class PrettyPrint::Breakable < Object
include PP::ObjectMixin
include Kernel
def width();end
def obj();end
def output(out, output_width);end
def indent();end
end
class PrettyPrint::Group < Object
include PP::ObjectMixin
include Kernel
def breakables();end
def break?();end
def depth();end
def break();end
def first?();end
end
class PrettyPrint::GroupQueue < Object
include PP::ObjectMixin
include Kernel
def delete(group);end
def enq(group);end
def deq();end
end
class PrettyPrint::SingleLine < Object
include PP::ObjectMixin
include Kernel
def text(obj, width = nil);end
def flush();end
def group(*args);end
def breakable(*args);end
def nest(indent);end
def first?();end
end
class PP < PrettyPrint
include PP::PPMethods
include PP::ObjectMixin
include Kernel
def self.singleline_pp(obj, out = nil);end
def self.mcall(obj, mod, meth, *args, &block);end
def self.sharing_detection();end
def self.sharing_detection=(arg0);end
def self.singleline_format(*args);end
def self.singleline_pp(obj, out = nil);end
def self.mcall(obj, mod, meth, *args, &block);end
def self.sharing_detection();end
def self.sharing_detection=(arg0);end
end
module PP::PPMethods
def pp(obj);end
def guard_inspect_key();end
def check_inspect_key(id);end
def push_inspect_key(id);end
def pop_inspect_key(id);end
def object_group(obj, &block);end
def object_address_group(obj, &block);end
def comma_breakable();end
def seplist(list, sep = nil, iter_method = nil);end
def pp_object(obj);end
def pp_hash(obj);end
end
class PP::SingleLine < PrettyPrint::SingleLine
include PP::PPMethods
include PP::ObjectMixin
include Kernel
end
module PP::ObjectMixin
def pretty_print(q);end
def pretty_print_cycle(q);end
def pretty_print_instance_variables();end
def pretty_print_inspect();end
end
class PrettyPrint::Text < Object
include PP::ObjectMixin
include Kernel
def add(obj, width);end
def width();end
def output(out, output_width);end
end
class PrettyPrint::Breakable < Object
include PP::ObjectMixin
include Kernel
def width();end
def obj();end
def output(out, output_width);end
def indent();end
end
class PrettyPrint::Group < Object
include PP::ObjectMixin
include Kernel
def breakables();end
def break?();end
def depth();end
def break();end
def first?();end
end
class PrettyPrint::GroupQueue < Object
include PP::ObjectMixin
include Kernel
def delete(group);end
def enq(group);end
def deq();end
end
