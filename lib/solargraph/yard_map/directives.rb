# frozen_string_literal: true

module Solargraph
  class YardMap
    module Directives
      autoload :AttributeDirective, 'solargraph/yard_map/directives/attribute_directive'
      autoload :MethodDirective, 'solargraph/yard_map/directives/method_directive'
      autoload :DomainDirective, 'solargraph/yard_map/directives/domain_directive'
      autoload :OverrideDirective, 'solargraph/yard_map/directives/override_directive'
      autoload :ParseDirective, 'solargraph/yard_map/directives/parse_directive'
      autoload :VisibilityDirective, 'solargraph/yard_map/directives/visibility_directive'

      # @param directive [YARD::Tags::Directive]
      # @return [Class<AttributeDirective>, Class<MethodDirective>, Class<DomainDirective>, Class<OverrideDirective>, Class<ParseDirective>, Class<VisibilityDirective>, nil]
      def self.for directive
        case directive.tag.tag_name
        when 'attribute'
          AttributeDirective
        when 'method'
          MethodDirective
        when 'domain'
          DomainDirective
        when 'override'
          OverrideDirective
        when 'parse'
          ParseDirective
        when 'visibility'
          VisibilityDirective
        else # rubocop:disable Style/EmptyElse
          nil
        end
      end
    end
  end
end
