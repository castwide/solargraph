# This file results in YardMap creating a Foo#bar pin with a nil
# `docstring.all` value. When that happens, the comments attribute should still
# be an empty string. See castwide/solargraph#231
#
# @attr_reader [String] bar
class Foo
  attr_reader :foo, :bar
end
