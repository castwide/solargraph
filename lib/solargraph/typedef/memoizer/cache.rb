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
          return data[key].value if data.key?(key)
          if pending.add?(key)
            value = if block_given?
                      yield
                    else
                      default
                    end
            data[key] = Memo.new(value, stack)
            pending.delete(key)
            data[key].value
          else
            Solargraph.logger.warn "Recursive definition detected: #{key}"
            default
          end
        ensure
          pending.delete key
        end

        def clear
          data.clear
        end

        # Remove memos with the given filenames in their stack
        #
        # @param filenames [Array<String>]
        def filter *filenames
          filenames.each do |filename|
            data.delete_if { |_key, memo| memo.stack.include?(filename) }
          end
        end

        # @return [Hash{Key => Memo}]
        def data
          @data ||= {}
        end

        def pending
          @pending ||= Set.new
        end

        private

        def stack
          pending.to_set(&:filename)
        end
      end
    end
  end
end
