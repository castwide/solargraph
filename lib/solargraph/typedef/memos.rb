# frozen_string_literal: true

module Solargraph
  module Typedef
    # @todo Eventually it should be possible to clear memos for specific filenames
    #
    class Memos
      def fetch key
        return cache[key] if cache.key?(key)
        cache[key] = yield
      end

      def clear
        cache.clear
      end

      def cache
        @cache ||= {}
      end
    end
  end
end
