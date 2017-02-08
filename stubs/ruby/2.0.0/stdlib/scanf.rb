module Scanf
end
class Scanf::FormatSpecifier < Object
include Kernel
def re_string();end
def matched_string();end
def conversion();end
def matched();end
def count_space?();end
def to_re();end
def match(str);end
def letter();end
def width();end
def mid_match?();end
end
class Scanf::FormatString < Object
include Kernel
def string_left();end
def last_spec_tried();end
def last_match_tried();end
def matched_count();end
def space();end
def prune(*args);end
def spec_count();end
def last_spec();end
def match(str);end
end
