module Scanf
end
class Scanf::FormatSpecifier < Object
include Kernel
def match(str);end
def width();end
def re_string();end
def matched_string();end
def conversion();end
def matched();end
def count_space?();end
def to_re();end
def letter();end
def mid_match?();end
end
class Scanf::FormatString < Object
include Kernel
def match(str);end
def string_left();end
def last_spec_tried();end
def last_match_tried();end
def matched_count();end
def space();end
def prune(*args);end
def spec_count();end
def last_spec();end
end
