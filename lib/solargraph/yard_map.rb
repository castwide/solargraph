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
    def change new_requires, new_gemset
      if new_requires.uniq.sort == required.uniq.sort && new_gemset == gemset
        false
      else
        required.clear
        required.concat new_requires
        @gemset = new_gemset
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
        load_yardoc CoreDocs.yardoc_file
        result = Mapper.new(YARD::Registry.all).map
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

    def yardoc_file_for_spec spec
      cache_dir = File.join(Solargraph::YardMap::CoreDocs.cache_dir, 'gems', "#{spec.name}-#{spec.version}", 'yardoc')
      if File.exist?(cache_dir)
        Solargraph.logger.info "Using cached documentation for #{spec.name} at #{cache_dir}"
        cache_dir
      else
        YARD::Registry.yardoc_file_for_gem(spec.name, "= #{spec.version}")
      end
    end

    def spec_for_require path
      spec = Gem::Specification.find_by_path(path) || Gem::Specification.find_by_name(path.split('/').first)
      if @gemset[spec.name]
        begin
          return Gem::Specification.find_by_name(spec.name, "= #{@gemset[spec.name]}")
        rescue Gem::LoadError
          Solargraph.logger.warn "Unable to load #{spec.name} #{@gemset[spec.name]} specified by workspace, using #{spec.version} instead"
        end
      end
      spec
    end
  end
end

Solargraph::YardMap::CoreDocs.require_minimum
# Change YARD log IO to avoid sending unexpected messages to STDOUT
YARD::Logger.instance.io = File.new(File::NULL, 'w')
