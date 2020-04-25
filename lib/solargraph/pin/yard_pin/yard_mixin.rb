# frozen_string_literal: true

module Solargraph
  module Pin
    module YardPin
      module YardMixin
        attr_reader :code_object

        attr_reader :spec

        attr_reader :location

        @@gate_cache ||= {}

        private

        # @return [Solargraph::Location, nil]
        def object_location code_object, spec
          return nil if spec.nil? || code_object.nil? || code_object.file.nil? || code_object.line.nil?
          file = File.join(spec.full_gem_path, code_object.file)
          Solargraph::Location.new(file, Solargraph::Range.from_to(code_object.line - 1, 0, code_object.line - 1, 0))
        end
      end
    end
  end
end
