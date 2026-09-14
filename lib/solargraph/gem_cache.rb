# frozen_string_literal: true

module Solargraph
  module GemCache
    module_function

    # @param metagem [Metagem]
    def path_for metagem
      File.join(PinCache.work_dir, 'gems', "#{metagem.cache_name}.ser")
    end

    # @param metagem [Metagem]
    def load metagem
      file = File.join(PinCache.work_dir, 'gems', "#{metagem.cache_name}.ser")
      return nil unless File.file?(file)
      Marshal.load(File.read(file, mode: 'rb'))
    rescue StandardError => e
      Solargraph.logger.warn "Failed to load cached file #{file}: [#{e.class}] #{e.message}"
      FileUtils.rm_f file
      nil
    end

    # @param metagem [Metagem]
    def save metagem
      Yardoc2.cache(metagem) unless Yardoc2.cached?(metagem)
      yardoc = Yardoc2.load!(metagem)
      yard_pins = YardMap::Mapper.new(yardoc, metagem).map
      rbs_pins = RbsMap2.new(metagem).pins
      pins = if rbs_pins.empty?
        yard_pins
      else
        # GemPins.combine(yard_pins, rbs_pins)
        yard_pins
      end
      cache_path = File.join(PinCache.work_dir, 'gems', "#{metagem.cache_name}.ser")
      write(cache_path, pins)
      cache_path
    end

    # @param metagem [Metagem]
    def exist? metagem
      cache_path = File.join(PinCache.work_dir, 'gems', "#{metagem.cache_name}.ser")
      File.file?(cache_path)
    end

    # @param file [String]
    # @param pins [Array<Pin::Base>]
    # @return [void]
    def write file, pins
      base = File.dirname(file)
      FileUtils.mkdir_p base unless File.directory?(base)
      ser = Marshal.dump(pins)
      File.write file, ser, mode: 'wb'
      # @todo Fix log message
      # logger.debug { "Cache#save: Saved #{pins.length} pins to #{file}" }
    end
  end
end
