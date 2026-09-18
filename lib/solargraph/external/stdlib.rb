# frozen_string_literal: true

module Solargraph
  class External
    module Stdlib
      class << self
        def pins library
          file = cache_file(library)
          if File.exist?(file)
            Marshal.load(File.read(file, mode: 'rb'))
          else
            save_cache library
          end
        end

        private

        def cache_file library
          File.join CacheDir.work_dir, 'stdlib', "#{library}.ser"
        end

        def save_cache library
          pins = RbsMap::Stdlib.pins(library)
          serial = Marshal.dump(pins)
          File.write cache_file(library), serial, mode: 'wb'
          pins
        end
      end
    end
  end
end
