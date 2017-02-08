class PrettyPrint < Object
include Kernel
def self.singleline_format(*args);end
def self.singleline_format(*args);end
def output();end
def maxwidth();end
def newline();end
def genspace();end
def indent();end
def group_queue();end
def current_group();end
def first?();end
def break_outmost_groups();end
def text(obj, width = nil);end
def fill_breakable(*args);end
def breakable(*args);end
def group(*args);end
def group_sub();end
def nest(indent);end
def flush();end
end
class PrettyPrint::Text < Object
include Kernel
def width();end
def output(out, output_width);end
def add(obj, width);end
end
class PrettyPrint::Breakable < Object
include Kernel
def obj();end
def width();end
def indent();end
def output(out, output_width);end
end
class PrettyPrint::Group < Object
include Kernel
def depth();end
def breakables();end
def break();end
def break?();end
def first?();end
end
class PrettyPrint::GroupQueue < Object
include Kernel
def enq(group);end
def deq();end
def delete(group);end
end
class PrettyPrint::SingleLine < Object
include Kernel
def text(obj, width = nil);end
def breakable(*args);end
def nest(indent);end
def group(*args);end
def flush();end
def first?();end
end
