# frozen_string_literal: true

module Solargraph
  module Typedef
    module Memoizer
      # A store of memoized values for Typedef::Dictionary definitions
      #
      class Cache
        # @param key [Key]
        # @param default [Typeset, Array(Array<Pin::Base>, Pin::Closure), nil]
        # @return [Typeset, Array(Array<Pin::Base>, Pin::Closure), nil]
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

        # Remove memos with the filename in their stack
        #
        # @param filename [String]
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
end
