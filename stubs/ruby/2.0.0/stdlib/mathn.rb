module CMath
include Math
def exp!(arg0);end
def exp(z);end
def log!(*args);end
def log(*args);end
def log2!(arg0);end
def log2(z);end
def log10!(arg0);end
def log10(z);end
def sqrt!(arg0);end
def cbrt!(arg0);end
def cbrt(z);end
def sin!(arg0);end
def sin(z);end
def cos!(arg0);end
def cos(z);end
def tan!(arg0);end
def tan(z);end
def sinh!(arg0);end
def sinh(z);end
def cosh!(arg0);end
def cosh(z);end
def tanh!(arg0);end
def tanh(z);end
def asin!(arg0);end
def asin(z);end
def acos!(arg0);end
def acos(z);end
def atan!(arg0);end
def atan(z);end
def atan2!(arg0, arg1);end
def atan2(y, x);end
def asinh!(arg0);end
def asinh(z);end
def acosh!(arg0);end
def acosh(z);end
def atanh!(arg0);end
def atanh(z);end
def frexp(arg0);end
def ldexp(arg0, arg1);end
def hypot(arg0, arg1);end
def erf(arg0);end
def erfc(arg0);end
def gamma(arg0);end
def lgamma(arg0);end
def handle_no_method_error();end
def sqrt(a);end
def rsqrt(a);end
def self.exp!(arg0);end
def self.exp(z);end
def self.log!(*args);end
def self.log(*args);end
def self.log2!(arg0);end
def self.log2(z);end
def self.log10!(arg0);end
def self.log10(z);end
def self.sqrt!(arg0);end
def self.cbrt!(arg0);end
def self.cbrt(z);end
def self.sin!(arg0);end
def self.sin(z);end
def self.cos!(arg0);end
def self.cos(z);end
def self.tan!(arg0);end
def self.tan(z);end
def self.sinh!(arg0);end
def self.sinh(z);end
def self.cosh!(arg0);end
def self.cosh(z);end
def self.tanh!(arg0);end
def self.tanh(z);end
def self.asin!(arg0);end
def self.asin(z);end
def self.acos!(arg0);end
def self.acos(z);end
def self.atan!(arg0);end
def self.atan(z);end
def self.atan2!(arg0, arg1);end
def self.atan2(y, x);end
def self.asinh!(arg0);end
def self.asinh(z);end
def self.acosh!(arg0);end
def self.acosh(z);end
def self.atanh!(arg0);end
def self.atanh(z);end
def self.frexp(arg0);end
def self.ldexp(arg0, arg1);end
def self.hypot(arg0, arg1);end
def self.erf(arg0);end
def self.erfc(arg0);end
def self.gamma(arg0);end
def self.lgamma(arg0);end
def self.handle_no_method_error();end
def self.sqrt(a);end
def self.rsqrt(a);end
end
class Math::DomainError < StandardError
include Kernel
def self.exception(*args);end
end
module Exception2MessageMapper
def extend_object(cl);end
def def_e2message(k, c, m);end
def def_exception(k, n, m, s = nil);end
def Raise(*args);end
def Fail(*args);end
def e2mm_message(klass, exp);end
def message(klass, exp);end
def self.extend_object(cl);end
def self.def_e2message(k, c, m);end
def self.def_exception(k, n, m, s = nil);end
def self.Raise(*args);end
def self.Fail(*args);end
def self.e2mm_message(klass, exp);end
def self.message(klass, exp);end
def bind(cl);end
def Raise(*args);end
def Fail(*args);end
def fail(*args);end
def def_e2message(c, m);end
def def_exception(n, m, s = nil);end
end
class Exception2MessageMapper::ErrNotRegisteredException < StandardError
include Kernel
def self.exception(*args);end
end
module ExceptionForMatrix
def included(mod);end
def bind(cl);end
def Raise(*args);end
def Fail(*args);end
def def_e2message(c, m);end
def def_exception(n, m, s = nil);end
def self.included(mod);end
def Raise(*args);end
def Fail(*args);end
end
class ExceptionForMatrix::ErrDimensionMismatch < StandardError
include Kernel
def self.exception(*args);end
end
class ExceptionForMatrix::ErrNotRegular < StandardError
include Kernel
def self.exception(*args);end
end
class ExceptionForMatrix::ErrOperationNotDefined < StandardError
include Kernel
def self.exception(*args);end
end
class ExceptionForMatrix::ErrOperationNotImplemented < StandardError
include Kernel
def self.exception(*args);end
end
class Matrix < Object
include Matrix::CoercionHelper
include ExceptionForMatrix
include Enumerable
include Kernel
def self.included(mod);end
def self.[](*args);end
def self.rows(rows, copy = nil);end
def self.columns(columns);end
def self.build(row_count, column_count = nil);end
def self.diagonal(*args);end
def self.scalar(n, value);end
def self.identity(n);end
def self.unit(n);end
def self.I(n);end
def self.zero(row_count, column_count = nil);end
def self.row_vector(row);end
def self.column_vector(column);end
def self.empty(*args);end
def self.bind(cl);end
def self.Raise(*args);end
def self.Fail(*args);end
def self.def_e2message(c, m);end
def self.def_exception(n, m, s = nil);end
def self.included(mod);end
def self.[](*args);end
def self.rows(rows, copy = nil);end
def self.columns(columns);end
def self.build(row_count, column_count = nil);end
def self.diagonal(*args);end
def self.scalar(n, value);end
def self.identity(n);end
def self.unit(n);end
def self.I(n);end
def self.zero(row_count, column_count = nil);end
def self.row_vector(row);end
def self.column_vector(column);end
def self.empty(*args);end
def Raise(*args);end
def Fail(*args);end
def [](i, j);end
def element(i, j);end
def component(i, j);end
def row_count();end
def row_size();end
def column_count();end
def column_size();end
def row(i, &block);end
def column(j);end
def collect(&block);end
def map(&block);end
def each(*args);end
def each_with_index(*args);end
def index(*args);end
def find_index(*args);end
def minor(*args);end
def diagonal?();end
def empty?();end
def hermitian?();end
def lower_triangular?();end
def normal?();end
def orthogonal?();end
def permutation?();end
def real?();end
def regular?();end
def singular?();end
def square?();end
def symmetric?();end
def unitary?();end
def upper_triangular?();end
def zero?();end
def *(m);end
def +(m);end
def -(m);end
def /(other);end
def inverse();end
def inv();end
def **(other);end
def determinant();end
def det();end
def determinant_e();end
def det_e();end
def rank();end
def rank_e();end
def round(*args);end
def trace();end
def tr();end
def transpose();end
def t();end
def eigensystem();end
def eigen();end
def lup();end
def lup_decomposition();end
def conjugate();end
def conj();end
def imaginary();end
def imag();end
def real();end
def rect();end
def rectangular();end
def coerce(other);end
def row_vectors();end
def column_vectors();end
def to_a();end
def elements_to_f();end
def elements_to_i();end
def elements_to_r();end
end
class Matrix::EigenvalueDecomposition < Object
include Kernel
def eigenvector_matrix();end
def v();end
def eigenvector_matrix_inv();end
def v_inv();end
def eigenvalues();end
def eigenvectors();end
def eigenvalue_matrix();end
def d();end
def to_ary();end
def to_a();end
end
class Matrix::LUPDecomposition < Object
include Matrix::ConversionHelper
include Kernel
def l();end
def u();end
def to_ary();end
def to_a();end
def pivots();end
def singular?();end
def det();end
def determinant();end
def solve(b);end
end
module Matrix::ConversionHelper
end
module Matrix::CoercionHelper
def coerce_to(obj, cls, meth);end
def coerce_to_int(obj);end
def self.coerce_to(obj, cls, meth);end
def self.coerce_to_int(obj);end
end
class Matrix::Scalar < Numeric
include Matrix::CoercionHelper
include ExceptionForMatrix
include Comparable
include Kernel
def self.included(mod);end
def self.bind(cl);end
def self.Raise(*args);end
def self.Fail(*args);end
def self.def_e2message(c, m);end
def self.def_exception(n, m, s = nil);end
def self.included(mod);end
def Raise(*args);end
def Fail(*args);end
def +(other);end
def -(other);end
def *(other);end
def /(other);end
def **(other);end
end
class ExceptionForMatrix::ErrDimensionMismatch < StandardError
include Kernel
def self.exception(*args);end
end
class ExceptionForMatrix::ErrNotRegular < StandardError
include Kernel
def self.exception(*args);end
end
class ExceptionForMatrix::ErrOperationNotDefined < StandardError
include Kernel
def self.exception(*args);end
end
class ExceptionForMatrix::ErrOperationNotImplemented < StandardError
include Kernel
def self.exception(*args);end
end
class Vector < Object
include Matrix::CoercionHelper
include Enumerable
include ExceptionForMatrix
include Kernel
def self.included(mod);end
def self.[](*args);end
def self.elements(array, copy = nil);end
def self.bind(cl);end
def self.Raise(*args);end
def self.Fail(*args);end
def self.def_e2message(c, m);end
def self.def_exception(n, m, s = nil);end
def self.included(mod);end
def self.[](*args);end
def self.elements(array, copy = nil);end
def Raise(*args);end
def Fail(*args);end
def [](i);end
def element(i);end
def component(i);end
def size();end
def each(&block);end
def each2(v);end
def collect2(v);end
def *(x);end
def +(v);end
def -(v);end
def /(x);end
def inner_product(v);end
def collect(&block);end
def map(&block);end
def magnitude();end
def r();end
def norm();end
def map2(v, &block);end
def normalize();end
def covector();end
def to_a();end
def elements_to_f();end
def elements_to_i();end
def elements_to_r();end
def coerce(other);end
end
class Vector::ZeroVectorError < StandardError
include Kernel
def self.exception(*args);end
end
class ExceptionForMatrix::ErrDimensionMismatch < StandardError
include Kernel
def self.exception(*args);end
end
class ExceptionForMatrix::ErrNotRegular < StandardError
include Kernel
def self.exception(*args);end
end
class ExceptionForMatrix::ErrOperationNotDefined < StandardError
include Kernel
def self.exception(*args);end
end
class ExceptionForMatrix::ErrOperationNotImplemented < StandardError
include Kernel
def self.exception(*args);end
end
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
def instance_delegate(hash);end
def def_instance_delegators(accessor, *methods);end
def def_instance_delegator(accessor, method, ali = nil);end
def delegate(hash);end
def def_delegators(accessor, *methods);end
def def_delegator(accessor, method, ali = nil);end
end
module SingleForwardable
def single_delegate(hash);end
def def_single_delegators(accessor, *methods);end
def def_single_delegator(accessor, method, ali = nil);end
def delegate(hash);end
def def_delegators(accessor, *methods);end
def def_delegator(accessor, method, ali = nil);end
end
class Prime < Object
include Enumerable
include Kernel
def self.instance();end
def self.method_added(method);end
def self.each(*args);end
def self.prime?(*args);end
def self.int_from_prime_division(*args);end
def self.prime_division(*args);end
def self.to_a(*args);end
def self.entries(*args);end
def self.sort();end
def self.sort_by();end
def self.grep(arg0);end
def self.count(*args);end
def self.find(*args);end
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
def self.min();end
def self.max();end
def self.minmax();end
def self.min_by();end
def self.max_by();end
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
def self.chunk(*args);end
def self.slice_before(*args);end
def self.lazy();end
def self.instance();end
def self.method_added(method);end
def self.each(*args);end
def self.prime?(*args);end
def self.int_from_prime_division(*args);end
def self.prime_division(*args);end
def each(*args);end
def prime?(value, generator = nil);end
def int_from_prime_division(pd);end
def prime_division(value, generator = nil);end
end
class Prime::PseudoPrimeGenerator < Object
include Enumerable
include Kernel
def upper_bound=(ubound);end
def upper_bound();end
def succ();end
def next();end
def rewind();end
def each(&block);end
def with_index(*args);end
def with_object(obj);end
end
class Prime::EratosthenesGenerator < Prime::PseudoPrimeGenerator
include Enumerable
include Kernel
def succ();end
def rewind();end
def next();end
end
class Prime::TrialDivisionGenerator < Prime::PseudoPrimeGenerator
include Enumerable
include Kernel
def succ();end
def rewind();end
def next();end
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
def cache();end
def primes();end
def primes_so_far();end
def [](index);end
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
def next_to(n);end
end
module Prime::OldCompatibility
def succ();end
def next();end
def each(&block);end
end
