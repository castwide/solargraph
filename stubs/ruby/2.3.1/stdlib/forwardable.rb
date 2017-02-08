module Forwardable
def debug();end
def debug=(arg0);end
def self.debug();end
def self.debug=(arg0);end
def instance_delegate(hash);end
def def_instance_delegator(accessor, method, ali = nil);end
def def_instance_delegators(accessor, *methods);end
def delegate(hash);end
def def_delegators(accessor, *methods);end
def def_delegator(accessor, method, ali = nil);end
end
module SingleForwardable
def delegate(hash);end
def def_delegators(accessor, *methods);end
def def_delegator(accessor, method, ali = nil);end
def single_delegate(hash);end
def def_single_delegator(accessor, method, ali = nil);end
def def_single_delegators(accessor, *methods);end
end
