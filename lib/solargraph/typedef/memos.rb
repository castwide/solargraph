# frozen_string_literal: true

module Solargraph
  module Typedef
    class Memos
      class Key < Data.define(:filename, :api_map, :chain, :position, :action)
        def ==(other)
          other.instance_of?(Key) &&
            filename == other.filename &&
            api_map == other.api_map &&
            chain == other.chain &&
            position == other.position &&
            action == other.action
        end
      end

      def fetch key, default = nil
        return cache[key].value if cache.key?(key)
        if pending.add?(key)
          cache[key] = Memo.new(yield, stack)
          pending.delete(key)
          cache[key].value
        else
          Solargraph.logger.warn "Recursive definition detected: #{key}"
          default
        end
      ensure
        pending.delete key
      end

      def clear
        cache.clear
      end

      def filter filename
        cache.delete_if { |_key, memo| memo.stack.include?(filename) }
      end

      def cache
        @cache ||= {}
      end

      def pending
        @pending ||= Set.new
      end

      private

      def stack
        pending.map(&:filename).to_set
      end
    end
  end
end
