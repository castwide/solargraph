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
