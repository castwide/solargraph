module Solargraph
  module Pin
    class Reference < Base
      autoload :Require,    'solargraph/pin/reference/require'
      autoload :Superclass, 'solargraph/pin/reference/superclass'
      autoload :Include,    'solargraph/pin/reference/include'
      autoload :Extend,     'solargraph/pin/reference/extend'

      # def initialize location, namespace, name
      #   super(location, namespace, name, '')
      # end

      # @todo Should Reference.new be protected?
      # class << self
      #   protected
      #   def new *args
      #     super
      #   end
      # end
    end
  end
end
