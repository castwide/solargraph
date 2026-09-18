# frozen_string_literal: true

module Solargraph
  class External
    module Core
      class << self
        # @return [Array<Pin::Base>]
        def pins
          if File.exist?(cache_file)
            Marshal.load(File.read(cache_file, mode: 'rb'))
          else
            save_cache
          end
        end

        private

        def cache_file
          File.join CacheDir.work_dir, 'core.ser'
        end

        def save_cache
          pins = RbsMap::Core.pins
          serial = Marshal.dump(pins)
          File.write cache_file, serial, mode: 'wb'
          pins
        end
      end
    end
  end
end
