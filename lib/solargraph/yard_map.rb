# frozen_string_literal: true

require 'yard'
require 'yard-solargraph'
require 'rubygems/package'
require 'set'

module Solargraph
  # The YardMap provides access to YARD documentation for the Ruby core, the
  # stdlib, and gems.
  #
  class YardMap
    autoload :Cache,       'solargraph/yard_map/cache'
    autoload :CoreDocs,    'solargraph/yard_map/core_docs'
    autoload :CoreGen,     'solargraph/yard_map/core_gen'
    autoload :Mapper,      'solargraph/yard_map/mapper'
    autoload :RdocToYard,  'solargraph/yard_map/rdoc_to_yard'
    autoload :CoreFills,   'solargraph/yard_map/core_fills'
    autoload :StdlibFills, 'solargraph/yard_map/stdlib_fills'
    autoload :Helpers,     'solargraph/yard_map/helpers'
    autoload :ToMethod,    'solargraph/yard_map/to_method'

    include ApiMap::BundlerMethods

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

    # @return [Boolean]
    attr_writer :with_dependencies

    # @param required [Array<String>, Set<String>]
    # @param directory [String]
    # @param source_gems [Array<String>, Set<String>]
    # @param with_dependencies [Boolean]
    def initialize(required: [], directory: '', source_gems: [], with_dependencies: true)
      @with_dependencies = with_dependencies
      change required.to_set, directory, source_gems.to_set
    end

    # @return [Array<Solargraph::Pin::Base>]
    def pins
      @pins ||= []
    end

    def with_dependencies?
      @with_dependencies ||= true unless @with_dependencies == false
      @with_dependencies
    end

    # @param new_requires [Set<String>] Required paths to use for loading gems
    # @param new_directory [String] The workspace directory
    # @param new_source_gems [Set<String>] Gems under local development (i.e., part of the workspace)
    # @return [Boolean]
    def change new_requires, new_directory, new_source_gems
      return false if new_requires == base_required && new_directory == @directory && new_source_gems == @source_gems
      @gem_paths = {}
      base_required.replace new_requires
      required.replace new_requires
      # HACK: Hardcoded YAML handling
      required.add 'psych' if new_requires.include?('yaml')
      @source_gems = new_source_gems
      @directory = new_directory
      process_requires
      @rebindable_method_names = nil
      @pin_class_hash = nil
      @pin_select_cache = {}
      true
    end

    # @return [Set<String>]
    def rebindable_method_names
      @rebindable_method_names ||= pins_by_class(Pin::Method)
        .select { |pin| pin.comments && pin.comments.include?('@yieldself') }
        .map(&:name)
        .concat(['instance_eval', 'instance_exec', 'class_eval', 'class_exec', 'module_eval', 'module_exec'])
        .to_set
    end

    # @return [Array<String>]
    def yardocs
      @yardocs ||= []
    end

    # @return [Set<String>]
    def required
      @required ||= Set.new
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
    rescue StandardError => e
      Solargraph::Logging.logger.warn "Error loading yardoc '#{y}' #{e.class} #{e.message}"
      yardocs.delete y
      nil
    end

    # @return [Array<Solargraph::Pin::Base>]
    def core_pins
      # Using a class variable to reduce loads
      @@core_pins ||= load_core_pins
    end

    # @param path [String]
    # @return [Pin::Base]
    def path_pin path
      pins.select { |p| p.path == path }.first
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

    def stdlib_pins
      @stdlib_pins ||= []
    end

    def base_required
      @base_required ||= Set.new
    end

    def directory
      @directory ||= ''
    end

    private

    # @return [YardMap::Cache]
    def cache
      @cache ||= YardMap::Cache.new
    end

    # @return [Hash]
    def pin_class_hash
      @pin_class_hash ||= pins.to_set.classify(&:class).transform_values(&:to_a)
    end

    # @return [Array<Pin::Base>]
    def pins_by_class klass
      @pin_select_cache[klass] ||= pin_class_hash.select { |key, _| key <= klass }.values.flatten
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
      @gemset = if required.include?('bundler/require')
        require_from_bundle(directory)
      else
        {}
      end
      pins.replace core_pins
      unresolved_requires.clear
      stdlib_pins.clear
      environ = Convention.for_global(self)
      done = []
      from_std = []
      (required + environ.requires).each do |r|
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
          end
        rescue Gem::LoadError => e
          base = r.split('/').first
          next if from_std.include?(base)
          from_std.push base
          stdtmp = load_stdlib_pins(base)
          if stdtmp.empty?
            unresolved_requires.push r
          else
            stdlib_pins.concat stdtmp
            result.concat stdtmp
          end
        end
        result.delete_if(&:nil?)
        unless result.empty?
          cache.set_path_pins r, result
          pins.concat result
        end
      end
      if required.include?('yaml') && required.include?('psych')
        # HACK: Hardcoded YAML handling
        # @todo Why can't this be handled with an override or a virtual pin?
        pin = path_pin('YAML')
        pin.instance_variable_set(:@return_type, ComplexType.parse('Module<Psych>')) unless pin.nil?
      end
      pins.concat environ.pins
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
          Solargraph.logger.info "Loading #{spec.name} #{spec.version} from cache"
          file = File.open(ser, 'rb')
          dump = file.read
          file.close
          begin
            return Marshal.load(dump)
          rescue StandardError => e
            Solargraph.logger.warn "Error loading pin cache: [#{e.class}] #{e.message}"
            File.unlink ser
          end
        end
      end
      if !size.nil? && size > 20_000_000
        Solargraph::Logging.logger.warn "Yardoc at #{y} is too large to process (#{size} bytes)"
        return []
      end
      load_yardoc y
      Solargraph.logger.info "Loading #{spec.name} #{spec.version} from yardoc"
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

    def load_core_pins
      yd = CoreDocs.yardoc_file
      ser = File.join(File.dirname(yd), 'core.ser')
      result = if File.file?(ser)
        file = File.open(ser, 'rb')
        dump = file.read
        file.close
        begin
          Marshal.load(dump)
        rescue StandardError => e
          Solargraph.logger.warn "Error loading core pin cache: [#{e.class}] #{e.message}"
          File.unlink ser
          read_core_and_save_cache(yd, ser)
        end
      else
        read_core_and_save_cache(yd, ser)
      end
      ApiMap::Store.new(result + CoreFills::ALL).pins.reject { |pin| pin.is_a?(Pin::Reference::Override) }
    end

    def read_core_and_save_cache yd, ser
      result = []
      load_yardoc yd
      result.concat Mapper.new(YARD::Registry.all).map
      # HACK: Assume core methods with a single `args` parameter accept restarg
      result.select { |pin| pin.is_a?(Solargraph::Pin::Method )}.each do |pin|
        if pin.parameters.length == 1 && pin.parameters.first.name == 'args' && pin.parameters.first.decl == :arg
          # @todo Smelly instance variable access
          pin.parameters.first.instance_variable_set(:@decl, :restarg)
        end
      end
      # HACK: Set missing parameters on `==` methods, e.g., `Symbol#==`
      result.select { |pin| pin.name == '==' && pin.parameters.empty? }.each do |pin|
        pin.parameters.push Pin::Parameter.new(decl: :arg, name: 'obj2')
      end
      dump = Marshal.dump(result)
      file = File.open(ser, 'wb')
      file.write dump
      file.close
      result
    end

    def load_stdlib_pins base
      ser = File.join(File.dirname(CoreDocs.yardoc_stdlib_file), "#{base}.ser")
      result = if File.file?(ser)
        Solargraph.logger.info "Loading #{base} stdlib from cache"
        file = File.open(ser, 'rb')
        dump = file.read
        file.close
        begin
          Marshal.load(dump)
        rescue StandardError => e
          Solargraph.logger.warn "Error loading #{base} stdlib pin cache: [#{e.class}] #{e.message}"
          File.unlink ser
          read_stdlib_and_save_cache(base, ser)
        end
      else
        read_stdlib_and_save_cache(base, ser)
      end
      fills = StdlibFills.get(base)
      unless fills.empty?
        result = ApiMap::Store.new(result + fills).pins.reject { |pin| pin.is_a?(Pin::Reference::Override) }
      end
      result
    end

    def read_stdlib_and_save_cache base, ser
      result = []
      if stdlib_paths[base]
        Solargraph.logger.info "Loading #{base} stdlib from yardoc"
        result.concat Mapper.new(stdlib_paths[base]).map
        unless result.empty?
          dump = Marshal.dump(result)
          file = File.open(ser, 'wb')
          file.write dump
          file.close
        end
      end
      result
    end
  end
end

Solargraph::YardMap::CoreDocs.require_minimum
# Change YARD log IO to avoid sending unexpected messages to STDOUT
YARD::Logger.instance.io = File.new(File::NULL, 'w')
