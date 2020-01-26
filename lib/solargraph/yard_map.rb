# frozen_string_literal: true

require 'yard'
require 'yard-solargraph'
require 'rubygems/package'

module Solargraph
  # The YardMap provides access to YARD documentation for the Ruby core, the
  # stdlib, and gems.
  #
  class YardMap
    autoload :Cache,    'solargraph/yard_map/cache'
    autoload :CoreDocs, 'solargraph/yard_map/core_docs'
    autoload :CoreGen,  'solargraph/yard_map/core_gen'
    autoload :Mapper,   'solargraph/yard_map/mapper'
    autoload :RdocToYard, 'solargraph/yard_map/rdoc_to_yard'

    CoreDocs.require_minimum

    def stdlib_paths
      @@stdlib_paths ||= begin
        result = {}
        YARD::Registry.load! CoreDocs.yardoc_stdlib_file
        YARD::Registry.all.each do |co|
          next if co.file.nil?
          path = co.file.sub(/^(ext|lib)\//, '').sub(/\.(rb|c)$/, '')
          base = path.split('/').first
          result[base] ||= []
          result[base].push co
        end
        result
      end
    end

    # @return [Array<String>]
    attr_reader :required

    # @return [Boolean]
    attr_writer :with_dependencies

    # A hash of gem names and the version numbers to include in the map.
    #
    # @return [Hash{String => String}]
    attr_reader :gemset

    # @param required [Array<String>]
    # @param gemset [Hash{String => String}]
    # @param with_dependencies [Boolean]
    def initialize(required: [], gemset: {}, with_dependencies: true)
      # HACK: YardMap needs its own copy of this array
      @required = required.clone
      @with_dependencies = with_dependencies
      @gem_paths = {}
      @stdlib_namespaces = []
      @gemset = gemset
      @source_gems = []
      process_requires
      yardocs.uniq!
    end

    # @return [Array<Solargraph::Pin::Base>]
    def pins
      @pins ||= []
    end

    def with_dependencies?
      @with_dependencies ||= true unless @with_dependencies == false
      @with_dependencies
    end

    # @param new_requires [Array<String>]
    # @param new_gemset [Hash{String => String}]
    # @return [Boolean]
    def change new_requires, new_gemset, source_gems = []
      if new_requires.uniq.sort == required.uniq.sort && new_gemset == gemset && @source_gems.uniq.sort == source_gems.uniq.sort
        false
      else
        required.clear
        required.concat new_requires
        @gemset = new_gemset
        @source_gems = source_gems
        process_requires
        true
      end
    end

    # @return [Array<String>]
    def yardocs
      @yardocs ||= []
    end

    # @return [Array<String>]
    def unresolved_requires
      @unresolved_requires ||= []
    end

    # @param y [String]
    # @return [YARD::Registry]
    def load_yardoc y
      if y.is_a?(Array)
        YARD::Registry.load y, true
      else
        YARD::Registry.load! y
      end
    rescue Exception => e
      Solargraph::Logging.logger.warn "Error loading yardoc '#{y}' #{e.class} #{e.message}"
      yardocs.delete y
      nil
    end

    # @return [Array<Solargraph::Pin::Base>]
    def core_pins
      @@core_pins ||= begin
        yd = CoreDocs.yardoc_file
        ser = File.join(File.dirname(yd), 'core.ser')
        result = []
        if File.file?(ser)
          file = File.open(ser, 'rb')
          dump = file.read
          file.close
          result.concat Marshal.load(dump)
        else
          load_yardoc CoreDocs.yardoc_file
          result.concat Mapper.new(YARD::Registry.all).map
          dump = Marshal.dump(result)
          file = File.open(ser, 'wb')
          file.write dump
          file.close
        end
        CoreFills::OVERRIDES.each do |ovr|
          pin = result.select { |p| p.path == ovr.name }.first
          next if pin.nil?
          (ovr.tags.map(&:tag_name) + ovr.delete).uniq.each do |tag|
            pin.docstring.delete_tags tag.to_sym
          end
          ovr.tags.each do |tag|
            pin.docstring.add_tag(tag)
          end
        end
        result
      end
    end

    # @param path [String]
    # @return [Pin::Base]
    def path_pin path
      pins.select{ |p| p.path == path }.first
    end

    # Get the location of a file referenced by a require path.
    #
    # @param path [String]
    # @return [Location]
    def require_reference path
      # @type [Gem::Specification]
      spec = spec_for_require(path)
      spec.full_require_paths.each do |rp|
        file = File.join(rp, "#{path}.rb")
        next unless File.file?(file)
        return Solargraph::Location.new(file, Solargraph::Range.from_to(0, 0, 0, 0))
      end
      nil
    rescue Gem::LoadError
      nil
    end

    private

    # @return [YardMap::Cache]
    def cache
      @cache ||= YardMap::Cache.new
    end

    # @param ns [YARD::CodeObjects::NamespaceObject]
    # @return [Array<YARD::CodeObjects::Base>]
    def recurse_namespace_object ns
      result = []
      ns.children.each do |c|
        result.push c
        result.concat recurse_namespace_object(c) if c.respond_to?(:children)
      end
      result
    end

    # @return [void]
    def process_requires
      pins.clear
      unresolved_requires.clear
      # stdnames = {}
      done = []
      from_std = []
      required.each do |r|
        next if r.nil? || r.empty? || done.include?(r)
        done.push r
        cached = cache.get_path_pins(r)
        unless cached.nil?
          pins.concat cached
          next
        end
        result = []
        begin
          spec = spec_for_require(r)
          if @source_gems.include?(spec.name)
            next
          end
          next if @gem_paths.key?(spec.name)
          yd = yardoc_file_for_spec(spec)
          # YARD detects gems for certain libraries that do not have a yardoc
          # but exist in the stdlib. `fileutils` is an example. Treat those
          # cases as errors and check the stdlib yardoc.
          raise Gem::LoadError if yd.nil?
          @gem_paths[spec.name] = spec.full_gem_path
          unless yardocs.include?(yd)
            yardocs.unshift yd
            result.concat process_yardoc yd, spec
            result.concat add_gem_dependencies(spec) if with_dependencies?
            stdlib_fill r, result
          end
        rescue Gem::LoadError => e
          base = r.split('/').first
          next if from_std.include?(base)
          from_std.push base
          stdtmp = []
          ser = File.join(File.dirname(CoreDocs.yardoc_stdlib_file), "#{base}.ser")
          if File.file?(ser)
            file = File.open(ser, 'rb')
            dump = file.read
            file.close
            stdtmp.concat Marshal.load(dump)
          else
            if stdlib_paths[base]
              stdtmp.concat Mapper.new(stdlib_paths[base]).map
              next if stdtmp.empty?
              dump = Marshal.dump(stdtmp)
              file = File.open(ser, 'wb')
              file.write dump
              file.close
            end
          end
          if stdtmp.empty?
            unresolved_requires.push r
          else
            stdlib_fill base, stdtmp
            result.concat stdtmp
            # stdnames[r] = stdtmp
          end
        end
        result.delete_if(&:nil?)
        unless result.empty?
          cache.set_path_pins r, result
          pins.concat result
        end
      end
      # pins.concat process_stdlib(stdnames)
      pins.concat core_pins
    end

    # @param spec [Gem::Specification]
    # @return [void]
    def add_gem_dependencies spec
      result = []
      (spec.dependencies - spec.development_dependencies).each do |dep|
        begin
          next if @source_gems.include?(dep.name) || @gem_paths.key?(dep.name)
          depspec = Gem::Specification.find_by_name(dep.name)
          next if depspec.nil?
          @gem_paths[depspec.name] = depspec.full_gem_path
          gy = yardoc_file_for_spec(depspec)
          if gy.nil?
            unresolved_requires.push dep.name
          else
            next if yardocs.include?(gy)
            yardocs.unshift gy
            result.concat process_yardoc gy, depspec
            result.concat add_gem_dependencies(depspec)
          end
        rescue Gem::LoadError
          # This error probably indicates a bug in an installed gem
          Solargraph::Logging.logger.warn "Failed to resolve #{dep.name} gem dependency for #{spec.name}"
        end
      end
      result
    end

    # @param y [String, nil]
    # @param spec [Gem::Specification, nil]
    # @return [Array<Pin::Base>]
    def process_yardoc y, spec = nil
      return [] if y.nil?
      size = Dir.glob(File.join(y, '**', '*'))
        .map{ |f| File.size(f) }
        .inject(:+)
      if spec
        ser = File.join(CoreDocs.cache_dir, 'gems', "#{spec.name}-#{spec.version}.ser")
        if File.file?(ser)
          file = File.open(ser, 'rb')
          dump = file.read
          file.close
          return Marshal.load(dump)
        end
      end
      if !size.nil? && size > 20_000_000
        Solargraph::Logging.logger.warn "Yardoc at #{y} is too large to process (#{size} bytes)"
        return []
      end
      load_yardoc y
      result = Mapper.new(YARD::Registry.all, spec).map
      if spec
        ser = File.join(CoreDocs.cache_dir, 'gems', "#{spec.name}-#{spec.version}.ser")
        file = File.open(ser, 'wb')
        file.write Marshal.dump(result)
        file.close
      end
      result
    end

    # @param spec [Gem::Specification]
    # @return [String]
    def yardoc_file_for_spec spec
      cache_dir = File.join(Solargraph::YardMap::CoreDocs.cache_dir, 'gems', "#{spec.name}-#{spec.version}", 'yardoc')
      if File.exist?(cache_dir)
        Solargraph.logger.info "Using cached documentation for #{spec.name} at #{cache_dir}"
        cache_dir
      else
        YARD::Registry.yardoc_file_for_gem(spec.name, "= #{spec.version}")
      end
    end

    # @param path [String]
    # @return [Gem::Specification]
    def spec_for_require path
      spec = Gem::Specification.find_by_path(path) || Gem::Specification.find_by_name(path.split('/').first)
      # Avoid loading the spec again if it's going to be skipped anyway
      return spec if @source_gems.include?(spec.name)
      # Avoid loading the spec again if it's already the correct version
      if @gemset[spec.name] && @gemset[spec.name] != spec.version
        begin
          return Gem::Specification.find_by_name(spec.name, "= #{@gemset[spec.name]}")
        rescue Gem::LoadError
          Solargraph.logger.warn "Unable to load #{spec.name} #{@gemset[spec.name]} specified by workspace, using #{spec.version} instead"
        end
      end
      spec
    end

    # @param path [String]
    # @param pins [Array<Pin::Base>]
    # @return [void]
    def stdlib_fill path, pins
      StdlibFills.get(path).each do |ovr|
        pin = pins.select { |p| p.path == ovr.name }.first
        next if pin.nil?
        (ovr.tags.map(&:tag_name) + ovr.delete).uniq.each do |tag|
          pin.docstring.delete_tags tag.to_sym
        end
        ovr.tags.each do |tag|
          pin.docstring.add_tag(tag)
        end
      end
    end
  end
end

Solargraph::YardMap::CoreDocs.require_minimum
# Change YARD log IO to avoid sending unexpected messages to STDOUT
YARD::Logger.instance.io = File.new(File::NULL, 'w')
