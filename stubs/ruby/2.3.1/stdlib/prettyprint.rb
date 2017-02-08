class PrettyPrint < Object
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
include Kernel
def add(obj, width);end
def width();end
def output(out, output_width);end
end
class PrettyPrint::Breakable < Object
include Kernel
def width();end
def obj();end
def output(out, output_width);end
def indent();end
end
class PrettyPrint::Group < Object
include Kernel
def breakables();end
def break?();end
def depth();end
def break();end
def first?();end
end
class PrettyPrint::GroupQueue < Object
include Kernel
def delete(group);end
def enq(group);end
def deq();end
end
class PrettyPrint::SingleLine < Object
include Kernel
def text(obj, width = nil);end
def flush();end
def group(*args);end
def breakable(*args);end
def nest(indent);end
def first?();end
end
