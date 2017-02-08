module Singleton
def __init__(klass);end
def self.__init__(klass);end
def clone();end
def dup();end
def _dump(*args);end
end
module Singleton::SingletonClassMethods
def clone();end
def _load(str);end
end
module Forwardable
def debug();end
def debug=(arg0);end
def self.debug();end
def self.debug=(arg0);end
def def_delegator(accessor, method, ali = nil);end
def instance_delegate(hash);end
def def_instance_delegator(accessor, method, ali = nil);end
def def_instance_delegators(accessor, *methods);end
def delegate(hash);end
def def_delegators(accessor, *methods);end
end
module SingleForwardable
def def_delegator(accessor, method, ali = nil);end
def delegate(hash);end
def def_delegators(accessor, *methods);end
def single_delegate(hash);end
def def_single_delegator(accessor, method, ali = nil);end
def def_single_delegators(accessor, *methods);end
end
class Prime < Object
include Singleton
include Enumerable
include Kernel
def self.method_added(method);end
def self.each(*args);end
def self.int_from_prime_division(*args);end
def self.prime_division(*args);end
def self.prime?(*args);end
def self.instance();end
def self.to_a(*args);end
def self.to_h(*args);end
def self.find(*args);end
def self.entries(*args);end
def self.sort();end
def self.sort_by();end
def self.grep(arg0);end
def self.grep_v(arg0);end
def self.count(*args);end
def self.detect(*args);end
def self.find_index(*args);end
def self.find_all();end
def self.reject();end
def self.collect();end
def self.map();end
def self.flat_map();end
def self.collect_concat();end
def self.inject(*args);end
def self.reduce(*args);end
def self.partition();end
def self.group_by();end
def self.first(*args);end
def self.all?();end
def self.any?();end
def self.one?();end
def self.none?();end
def self.min(*args);end
def self.max(*args);end
def self.minmax();end
def self.min_by(*args);end
def self.max_by(*args);end
def self.minmax_by();end
def self.member?(arg0);end
def self.each_with_index(*args);end
def self.reverse_each(*args);end
def self.each_entry(*args);end
def self.each_slice(arg0);end
def self.each_cons(arg0);end
def self.each_with_object(arg0);end
def self.zip(*args);end
def self.take(arg0);end
def self.take_while();end
def self.drop(arg0);end
def self.drop_while();end
def self.cycle(*args);end
def self.chunk();end
def self.slice_before(*args);end
def self.slice_after(*args);end
def self.slice_when();end
def self.chunk_while();end
def self.lazy();end
def self._load(str);end
def self.method_added(method);end
def self.each(*args);end
def self.int_from_prime_division(*args);end
def self.prime_division(*args);end
def self.prime?(*args);end
def self.instance();end
def each(*args);end
def int_from_prime_division(pd);end
def prime_division(value, generator = nil);end
def prime?(value, generator = nil);end
end
class Prime::PseudoPrimeGenerator < Object
include Enumerable
include Kernel
def size();end
def succ();end
def each();end
def next();end
def rewind();end
def with_index(*args);end
def with_object(obj);end
def upper_bound();end
def upper_bound=(ubound);end
end
class Prime::EratosthenesGenerator < Prime::PseudoPrimeGenerator
include Enumerable
include Kernel
def succ();end
def next();end
def rewind();end
end
class Prime::TrialDivisionGenerator < Prime::PseudoPrimeGenerator
include Enumerable
include Kernel
def succ();end
def next();end
def rewind();end
end
class Prime::Generator23 < Prime::PseudoPrimeGenerator
include Enumerable
include Kernel
def succ();end
def next();end
def rewind();end
end
class Prime::TrialDivision < Object
include Singleton
include Kernel
def self.instance();end
def self._load(str);end
def self.instance();end
def [](index);end
def cache();end
def primes();end
def primes_so_far();end
end
module Singleton::SingletonClassMethods
def clone();end
def _load(str);end
end
class Prime::EratosthenesSieve < Object
include Singleton
include Kernel
def self.instance();end
def self._load(str);end
def self.instance();end
def get_nth_prime(n);end
end
