# frozen_string_literal: true

require 'fileutils'

module Solargraph
  module GemCache
    extend self

    # @param metagem [Metagem]
    def path_for metagem
      File.join(CacheDir.gem_dir, "#{metagem.cache_name}.ser")
    end

    # @param metagem [Metagem]
    def load metagem
      file = path_for(metagem)
      return nil unless File.file?(file)
      Marshal.load(File.read(file, mode: 'rb'))
    rescue StandardError => e
      Solargraph.logger.warn "Failed to load cached file #{file}: [#{e.class}] #{e.message}"
      FileUtils.rm_f file
      nil
    end

    # @param metagem [Metagem]
    def cache metagem
      Yardoc.cache(metagem) unless Yardoc.cached?(metagem)
      yardoc = Yardoc.load!(metagem)
      yard_pins = YardMap::Mapper.new(yardoc, metagem).map
      rbs_pins = RbsMap::Gem.new(metagem).pins
      pins = if rbs_pins.empty?
        yard_pins
      else
        GemPins.combine(yard_pins, rbs_pins)
      end
      cache_path = path_for(metagem)
      base = File.dirname(cache_path)
      ser = Marshal.dump(pins)
      File.write cache_path, ser, mode: 'wb'
      # @todo Fix log message
      # logger.debug { "Cache#save: Saved #{pins.length} pins to #{file}" }
      cache_path
    end

    # @param metagem [Metagem]
    def uncache metagem
      FileUtils.rm_f path_for(metagem)
    end

    # @param metagem [Metagem]
    def cached? metagem
      File.file? path_for(metagem)
    end
    alias exist? cached?
  end
end
