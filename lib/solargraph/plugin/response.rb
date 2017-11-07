module Solargraph
  module Plugin
    class Response
      attr_reader :status
      attr_reader :data
      attr_reader :message

      def initialize status = 'ok', data = [], message = nil
        @status = status
        @data = data
        @message = message
      end

      def ok?
        status == 'ok'
      end
    end
  end
end
