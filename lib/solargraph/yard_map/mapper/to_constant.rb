# frozen_string_literal: true

module Solargraph
  class YardMap
    class Mapper
      module ToConstant
        extend YardMap::Helpers

        # @param code_object [YARD::CodeObjects::Base]
        # @param closure [Pin::Closure, nil]
        # @param spec [Gem::Specification, nil]
        # @return [Pin::Constant]
        def self.make code_object, closure = nil, spec = nil
          closure ||= create_closure_namespace_for(code_object, spec)

          Pin::Constant.new(
            location: object_location(code_object, spec),
            closure: closure,
            name: code_object.name.to_s,
            comments: code_object.docstring ? code_object.docstring.all.to_s : '',
            visibility: code_object.visibility,
            source: :yardoc
          )
        end
      end
    end
  end
end
