# frozen_string_literal: true

module Solargraph
  module Typedef
    module Expansions
      # Contextual expansion of YARD macros.
      #
      class Macros < Base
        def expand
          return pin.typedef_typeset unless pin.macro_names?

          types = pin.macro_names.flat_map do |mac|
            directive = api_map.named_macro(mac)
            next unless directive
            macro = Solargraph::YardMap::Macro.from_directive(directive, pin)
            expanded = macro.macro_object.expand([pin.name, *pin.parameter_names])
            docstring = Solargraph::Source.parse_docstring(expanded).to_docstring
            docstring.tags(:return).flat_map(&:types)
          end
          ComplexType.try_parse(*types).to_typedef_typeset
        end
      end
    end
  end
end
