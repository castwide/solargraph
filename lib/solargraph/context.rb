module Solargraph
  # The namespace and scope of a closure.
  #
  # @note Components that reference contexts generally expect the namespce to
  #   be fully qualified, e.g., `Foo::Bar` instead of `Bar`.
  #
  class Context
    # @return [String]
    attr_reader :namespace

    # @return [Symbol]
    attr_reader :scope

    # @param namespace [String]
    # @param scope [Symbol]
    def initialize namespace, scope
      raise ArgumentError, "Invalid scope: #{scope}" unless %i[class instance].include?(scope)
      @namespace = namespace
      @scope = scope
    end

    def == other
      return false unless self.class == other.class
      namespace == other.namespace and scope == other.scope
    end

    # @todo Is the root context's scope :class or :instance?
    ROOT = Context.new('', :class)
  end
end
