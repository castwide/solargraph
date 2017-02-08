module CMath
include Math
def atan2(y, x);end
def cos(z);end
def sin(z);end
def tan(z);end
def acos(z);end
def asin(z);end
def atan(z);end
def cosh(z);end
def sinh(z);end
def tanh(z);end
def acosh(z);end
def asinh(z);end
def atanh(z);end
def exp(z);end
def log(z, b = nil);end
def log2(z);end
def log10(z);end
def sqrt(a);end
def cbrt(z);end
def frexp(arg0);end
def ldexp(arg0, arg1);end
def hypot(arg0, arg1);end
def erf(arg0);end
def erfc(arg0);end
def gamma(arg0);end
def lgamma(arg0);end
def exp!(*args);end
def rsqrt(a);end
def sqrt!(*args);end
def handle_no_method_error();end
def log!(*args);end
def log2!(*args);end
def log10!(*args);end
def cbrt!(*args);end
def sin!(*args);end
def cos!(*args);end
def tan!(*args);end
def sinh!(*args);end
def cosh!(*args);end
def tanh!(*args);end
def asin!(*args);end
def acos!(*args);end
def atan!(*args);end
def atan2!(*args);end
def asinh!(*args);end
def acosh!(*args);end
def atanh!(*args);end
def self.atan2(y, x);end
def self.cos(z);end
def self.sin(z);end
def self.tan(z);end
def self.acos(z);end
def self.asin(z);end
def self.atan(z);end
def self.cosh(z);end
def self.sinh(z);end
def self.tanh(z);end
def self.acosh(z);end
def self.asinh(z);end
def self.atanh(z);end
def self.exp(z);end
def self.log(z, b = nil);end
def self.log2(z);end
def self.log10(z);end
def self.sqrt(a);end
def self.cbrt(z);end
def self.frexp(arg0);end
def self.ldexp(arg0, arg1);end
def self.hypot(arg0, arg1);end
def self.erf(arg0);end
def self.erfc(arg0);end
def self.gamma(arg0);end
def self.lgamma(arg0);end
def self.exp!(*args);end
def self.rsqrt(a);end
def self.sqrt!(*args);end
def self.handle_no_method_error();end
def self.log!(*args);end
def self.log2!(*args);end
def self.log10!(*args);end
def self.cbrt!(*args);end
def self.sin!(*args);end
def self.cos!(*args);end
def self.tan!(*args);end
def self.sinh!(*args);end
def self.cosh!(*args);end
def self.tanh!(*args);end
def self.asin!(*args);end
def self.acos!(*args);end
def self.atan!(*args);end
def self.atan2!(*args);end
def self.asinh!(*args);end
def self.acosh!(*args);end
def self.atanh!(*args);end
end
class Math::DomainError < StandardError
include Kernel
def self.exception(*args);end
end
module Exception2MessageMapper
def extend_object(cl);end
def message(klass, exp);end
def def_e2message(k, c, m);end
def def_exception(k, n, m, s = nil);end
def Raise(*args);end
def Fail(*args);end
def e2mm_message(klass, exp);end
def self.extend_object(cl);end
def self.message(klass, exp);end
def self.def_e2message(k, c, m);end
def self.def_exception(k, n, m, s = nil);end
def self.Raise(*args);end
def self.Fail(*args);end
def self.e2mm_message(klass, exp);end
def fail(*args);end
def bind(cl);end
def def_e2message(c, m);end
def def_exception(n, m, s = nil);end
def Raise(*args);end
def Fail(*args);end
end
class Exception2MessageMapper::ErrNotRegisteredException < StandardError
include Kernel
def self.exception(*args);end
end
module ExceptionForMatrix
def included(mod);end
def bind(cl);end
def def_e2message(c, m);end
def def_exception(n, m, s = nil);end
def Raise(*args);end
def Fail(*args);end
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
def self.[](*args);end
def self.included(mod);end
def self.I(n);end
def self.rows(rows, copy = nil);end
def self.columns(columns);end
def self.build(row_count, column_count = nil);end
def self.diagonal(*args);end
def self.empty(*args);end
def self.scalar(n, value);end
def self.identity(n);end
def self.unit(n);end
def self.zero(row_count, column_count = nil);end
def self.row_vector(row);end
def self.column_vector(column);end
def self.vstack(x, *matrices);end
def self.hstack(x, *matrices);end
def self.bind(cl);end
def self.def_e2message(c, m);end
def self.def_exception(n, m, s = nil);end
def self.Raise(*args);end
def self.Fail(*args);end
def self.[](*args);end
def self.included(mod);end
def self.I(n);end
def self.rows(rows, copy = nil);end
def self.columns(columns);end
def self.build(row_count, column_count = nil);end
def self.diagonal(*args);end
def self.empty(*args);end
def self.scalar(n, value);end
def self.identity(n);end
def self.unit(n);end
def self.zero(row_count, column_count = nil);end
def self.row_vector(row);end
def self.column_vector(column);end
def self.vstack(x, *matrices);end
def self.hstack(x, *matrices);end
def coerce(other);end
def *(m);end
def +(m);end
def -(m);end
def real?();end
def /(other);end
def zero?();end
def rectangular();end
def imaginary();end
def round(*args);end
def imag();end
def rect();end
def conjugate();end
def conj();end
def real();end
def trace();end
def find_index(*args);end
def collect(&block);end
def map(&block);end
def row(i, &block);end
def each_with_index(*args);end
def row_count();end
def column_count();end
def column(j);end
def vstack(*args);end
def hstack(*args);end
def element(i, j);end
def component(i, j);end
def row_size();end
def column_size();end
def index(*args);end
def +@();end
def -@();end
def **(other);end
def minor(*args);end
def [](i, j);end
def first_minor(row, column);end
def cofactor(row, column);end
def Raise(*args);end
def square?();end
def empty?();end
def adjugate();end
def determinant();end
def cofactor_expansion(*args);end
def laplace_expansion(*args);end
def hermitian?();end
def diagonal?();end
def normal?();end
def lower_triangular?();end
def orthogonal?();end
def permutation?();end
def regular?();end
def singular?();end
def symmetric?();end
def unitary?();end
def upper_triangular?();end
def inverse();end
def inv();end
def tr();end
def eigensystem();end
def each(*args);end
def det();end
def determinant_e();end
def det_e();end
def rank();end
def rank_e();end
def eigen();end
def lup();end
def lup_decomposition();end
def to_a();end
def row_vectors();end
def column_vectors();end
def elements_to_f();end
def elements_to_i();end
def elements_to_r();end
def t();end
def Fail(*args);end
def transpose();end
end
class Matrix::EigenvalueDecomposition < Object
include Kernel
def to_ary();end
def to_a();end
def v();end
def d();end
def v_inv();end
def eigenvector_matrix();end
def eigenvector_matrix_inv();end
def eigenvalues();end
def eigenvectors();end
def eigenvalue_matrix();end
end
class Matrix::LUPDecomposition < Object
include Matrix::ConversionHelper
include Kernel
def to_ary();end
def to_a();end
def determinant();end
def singular?();end
def det();end
def l();end
def u();end
def pivots();end
def solve(b);end
end
module Matrix::ConversionHelper
end
module Matrix::CoercionHelper
def coerce_to_int(obj);end
def coerce_to(obj, cls, meth);end
def self.coerce_to_int(obj);end
def self.coerce_to(obj, cls, meth);end
end
class Matrix::Scalar < Numeric
include Matrix::CoercionHelper
include ExceptionForMatrix
include Comparable
include Kernel
def self.included(mod);end
def self.bind(cl);end
def self.def_e2message(c, m);end
def self.def_exception(n, m, s = nil);end
def self.Raise(*args);end
def self.Fail(*args);end
def self.included(mod);end
def *(other);end
def +(other);end
def -(other);end
def /(other);end
def **(other);end
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
class Vector < Object
include Matrix::CoercionHelper
include Enumerable
include ExceptionForMatrix
include Kernel
def self.[](*args);end
def self.included(mod);end
def self.elements(array, copy = nil);end
def self.basis();end
def self.independent?(*args);end
def self.bind(cl);end
def self.def_e2message(c, m);end
def self.def_exception(n, m, s = nil);end
def self.Raise(*args);end
def self.Fail(*args);end
def self.[](*args);end
def self.included(mod);end
def self.elements(array, copy = nil);end
def self.basis();end
def self.independent?(*args);end
def *(x);end
def +(v);end
def -(v);end
def /(x);end
def +@();end
def -@();end
def [](i);end
def size();end
def each(&block);end
def to_a();end
def collect(&block);end
def map(&block);end
def coerce(other);end
def magnitude();end
def round(*args);end
def normalize();end
def r();end
def element(i);end
def component(i);end
def Raise(*args);end
def elements_to_f();end
def elements_to_i();end
def elements_to_r();end
def each2(v);end
def collect2(v);end
def independent?(*args);end
def inner_product(v);end
def dot(v);end
def cross_product(*args);end
def cross(*args);end
def norm();end
def map2(v, &block);end
def angle_with(v);end
def covector();end
def Fail(*args);end
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
