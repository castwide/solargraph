require 'yard'

class CoreMethodHandler < YARD::Handlers::C::Base
  MATCH = /define_filetest_function\s*\(
			\s*"([^"]+)",
			\s*(?:RUBY_METHOD_FUNC\(|VALUEFUNC\(|\(\w+\))?(\w+)\)?,
			\s*(-?\w+)\s*\)/xm
  handles MATCH
  statement_class BodyStatement

  process do
    statement.source.scan(MATCH) do |name, func_name, _param_count|
      handle_method("singleton_method", "rb_cFile", name, func_name)
    end
  end
end
