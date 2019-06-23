require 'yard'
require 'bundler'

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
    @@stdlib_yardoc = CoreDocs.yardoc_stdlib_file
    @@stdlib_paths = {}
    YARD::Registry.load! @@stdlib_yardoc
    YARD::Registry.all(:class, :module).each do |ns|
      next if ns.file.nil?
      path = ns.file.sub(/^(ext|lib)\//, '').sub(/\.(rb|c)$/, '')
      next if path.start_with?('-')
      @@stdlib_paths[path] ||= []
      @@stdlib_paths[path].push ns
    end

    # @return [Array<String>]
    attr_reader :required

    attr_writer :with_dependencies

    # @param required [Array<String>]
    # @param with_dependencies [Boolean]
    def initialize(directory: '.', required: [], with_dependencies: true)
      @directory = directory
      # HACK: YardMap needs its own copy of this array
      @required = required.clone
      @with_dependencies = with_dependencies
      @gem_paths = {}
      @stdlib_namespaces = []
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
    # @return [Boolean]
    def change new_requires
      if new_requires.uniq.sort == required.uniq.sort
        false
      else
        required.clear
        required.concat new_requires
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
      if y.kind_of?(Array)
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
        load_yardoc CoreDocs.yardoc_file
        result = Mapper.new(YARD::Registry.all).map
        CoreFills::OVERRIDES.each do |ovr|
          pin = result.select { |p| p.path == ovr.name }.first
          next if pin.nil?
          pin.docstring.delete_tags(:overload)
          pin.docstring.delete_tags(:return)
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
      spec = Gem::Specification.find_by_path(path) || Gem::Specification.find_by_name(path.split('/').first)
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

    # @param ns [YARD::CodeObjects::Namespace]
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
      stdnames = {}
      done = []
      pins.concat(bundler_require) if required.include?('bundler/require')
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
          spec = Gem::Specification.find_by_path(r) || Gem::Specification.find_by_name(r.split('/').first)
          ver = spec.version.to_s
          ver = ">= 0" if ver.empty?
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
          end
        rescue Gem::LoadError => e
          stdtmp = []
          @@stdlib_paths.each_pair do |path, objects|
            stdtmp.concat objects if path == r || path.start_with?("#{r}/")
          end
          if stdtmp.empty?
            unresolved_requires.push r
          else
            stdnames[r] = stdtmp
          end
        end
        result.delete_if(&:nil?)
        unless result.empty?
          cache.set_path_pins r, result
          pins.concat result
        end
      end
      pins.concat process_stdlib(stdnames)
      pins.concat core_pins
    end

    # @param required_namespaces [Array<YARD::CodeObjects::Namespace>]
    # @return [Array<Solargraph::Pin::Base>]
    def process_stdlib required_namespaces
      pins = []
      unless required_namespaces.empty?
        yard = load_yardoc @@stdlib_yardoc
        done = []
        required_namespaces.each_pair do |r, objects|
          result = []
          objects.each do |ns|
            next if done.include?(ns.path)
            done.push ns.path
            all = [ns]
            all.concat recurse_namespace_object(ns)
            result.concat Mapper.new(all).map
          end
          result.delete_if(&:nil?)
          cache.set_path_pins(r, result) unless result.empty?
          pins.concat result
        end
      end
      pins
    end

    # @param spec [Gem::Specification]
    # @return [void]
    def add_gem_dependencies spec
      result = []
      (spec.dependencies - spec.development_dependencies).each do |dep|
        begin
          depspec = Gem::Specification.find_by_name(dep.name)
          next if depspec.nil? || @gem_paths.key?(depspec.name)
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
    # @return [Array<Pin::Base>]
    def process_yardoc y, spec = nil
      return [] if y.nil?
      size = Dir.glob(File.join(y, '**', '*'))
        .map{ |f| File.size(f) }
        .inject(:+)
      if !size.nil? && size > 20_000_000
        Solargraph::Logging.logger.warn "Yardoc at #{y} is too large to process (#{size} bytes)"
        return []
      end
      load_yardoc y
      Mapper.new(YARD::Registry.all, spec).map
    end

    def bundler_require
      Solargraph.logger.debug "Using bundler/require"
      result = []
      Dir.chdir @directory do
        # @type [Array<Gem::Specification>]
        specs = Bundler.with_original_env do
          Bundler.reset!
          Bundler.definition.specs_for([:default])
        end
        specs.each do |spec|
          ver = spec.version.to_s
          ver = ">= 0" if ver.empty?
          yd = YARD::Registry.yardoc_file_for_spec(spec)
          # YARD detects gems for certain libraries that do not have a yardoc
          # but exist in the stdlib. `fileutils` is an example. Treat those
          # cases as errors and check the stdlib yardoc.
          if yd.nil?
            Solargraph.logger.warn "Failed to load gem #{spec.name} #{ver} via bundler/require"
            next
          end
          @gem_paths[spec.name] = spec.full_gem_path
          unless yardocs.include?(yd)
            yardocs.unshift yd
            result.concat process_yardoc yd, spec
            result.concat add_gem_dependencies(spec) if with_dependencies?
          end
        end
      end
      Bundler.reset!
      result.reject(&:nil?)
    end

    def yardoc_file_for_spec spec
      cache_dir = File.join(Solargraph::YardMap::CoreDocs.cache_dir, 'gems', "#{spec.name}-#{spec.version}", 'yardoc')
      File.exist?(cache_dir) ? cache_dir : YARD::Registry.yardoc_file_for_gem(spec.name, spec.version)
    end
  end
end
