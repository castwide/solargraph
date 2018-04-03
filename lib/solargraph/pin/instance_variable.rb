module Solargraph
  module Pin
    class InstanceVariable < BaseVariable
      attr_reader :scope

      def initialize source, node, namespace, scope
        super(source, node, namespace)
        @scope = scope
      end
    end

    # @todo Determine if the BaseVariable#resolve works or it needs to be
    # overridden to pass the scope
    # def resolve api_map
    #   if return_type.nil?
    #     @return_type = api_map.infer_signature_type(resolve_node_signature(assignment_node), namespace, scope: scope, call_node: node)
    #   end
    # end
  end
end
