# frozen_string_literal: true

module Solargraph
  module Typedef
    module Linker
      class Or < Base
        def resolve
          # @todo Lots of unnecessary conversion here
          types = link.links.map do |link|
            range = Solargraph::Range.from_node(link.node)
            Dictionary.new(api_map, dictionary.source_map.filename, range.start, chain: link).infer.types
          end
          .flatten.map(&:to_complex_type)
          combined_type = Solargraph::ComplexType.new(types)
          unless types.flatten.all?(&:nullable?)
            # @sg-ignore flow sensitive typing should be able to handle redefinition
            combined_type = combined_type.without_nil
          end

          [Solargraph::Pin::ProxyType.anonymous(combined_type, source: :chain)]
        end
      end
    end
  end
end
