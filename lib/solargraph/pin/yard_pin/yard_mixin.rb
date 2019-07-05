# frozen_string_literal: true

module Solargraph
  module Pin
    module YardPin
      module YardMixin
        attr_reader :code_object

        attr_reader :spec

        @@gate_cache ||= {}

        def comments
          @comments ||= code_object.docstring ? code_object.docstring.all : ''
        end

        def location
          # Guarding with @located because nil locations are valid
          return @location if @located
          @located = true
          @location = object_location
        end

        private

        # @return [Solargraph::Location, nil]
        def object_location
          return nil if spec.nil? || code_object.nil? || code_object.file.nil? || code_object.line.nil?
          file = File.join(spec.full_gem_path, code_object.file)
          Solargraph::Location.new(file, Solargraph::Range.from_to(code_object.line - 1, 0, code_object.line - 1, 0))
        end
      end
    end
  end
end
