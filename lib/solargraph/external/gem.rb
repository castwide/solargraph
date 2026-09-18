# frozen_string_literal: true

module Solargraph
  class External
    module Gem
      class << self
        def pins metagem
          file = cache_file(metagem)
          if metagem.cacheable?
            if File.exist?(file)
              Marshal.load(File.read(file, mode: 'rb'))
            else
              save_cache
            end
          else
            generate_pins metagem
          end
        end

        def cached? metagem
          File.exist? cache_file(metagem)
        end

        private

        def cache_file metagem
          File.join CacheDir.work_dir, 'gems', "#{metagem.cache_name}.ser"
        end

        def save_cache metagem
          yard_pins = Yardoc.load!(metagem)
          rbs_pins = RbsMap::Gem.pins(metagem)
          pins = GemPins.combine(yard_pins, rbs_pins)
          if metagem.cacheable?
            serial = Marshal.dump(pins)
            File.write cache_file(metagem), serial, mode: 'wb'
          end
          pins
        end

        def generate_pins metagem
          files = metagem.require_paths.flat_map { |path| Dir.glob(File.join(metagem.full_path, path, '**', '*.rb')) }
          source_maps = files.map { |file| Solargraph::SourceMap.load(file) }
          source_pins = source_maps.flat_map(&:pins)
          rbs_pins = RbsMap::Gem.pins(metagem)
          combined = GemPins.combine(source_pins, rbs_pins)
        end
      end
    end
  end
end
