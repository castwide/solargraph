# frozen_string_literal: true

module Solargraph
  module Typedef
    # @todo Eventually it should be possible to clear memos for specific filenames
    #
    class Memos
      def fetch key, default = nil
        return cache[key] if cache.key?(key)
        if pending.add?(key)
          cache[key] = yield.tap { pending.delete(key) }
        else
          default
        end
      ensure
        pending.delete key
      end

      def clear
        cache.clear
      end

      def cache
        @cache ||= {}
      end

      def pending
        @processing ||= Set.new
      end
    end
  end
end
