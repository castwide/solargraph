# frozen_string_literal: true

module Solargraph
  module Pin
    module YardPin
      module YardMixin
        attr_reader :code_object

        @@gate_cache ||= {}

        def comments
          @comments ||= code_object.docstring ? code_object.docstring.all : ''
        end

        private

        def split_to_gates namespace
          @@gate_cache[namespace] || begin
            parts = namespace.split('::')
            result = []
            until parts.empty?
              result.push parts.join('::')
              parts.pop
            end
            result.push ''
            @@gate_cache[namespace] = result.freeze
            result
          end
        end
      end
    end
  end
end
