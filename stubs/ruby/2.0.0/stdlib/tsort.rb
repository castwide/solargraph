module TSort
def tsort();end
def tsort_each();end
def strongly_connected_components();end
def each_strongly_connected_component();end
def each_strongly_connected_component_from(node, id_map = nil, stack = nil);end
def tsort_each_node();end
def tsort_each_child(node);end
end
class TSort::Cyclic < StandardError
include Kernel
def self.exception(*args);end
end
