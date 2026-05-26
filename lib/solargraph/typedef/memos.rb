# frozen_string_literal: true

module Solargraph
  module Typedef
    # @todo Eventually it should be possible to clear memos for specific filenames
    #
    class Memos
      def fetch key
        return cache[key] if cache.key?(key)
        raise "Recursive action detected" unless processing.add?(key)
        cache[key] = yield
      ensure
        processing.delete key
      end

      def clear
        cache.clear
      end

      def cache
        @cache ||= {}
      end

      def processing
        @processing ||= Set.new
      end
    end
  end
end
