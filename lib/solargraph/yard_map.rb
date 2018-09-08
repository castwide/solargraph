require 'yard'

module Solargraph
  # The YardMap provides access to YARD documentation for the Ruby core, the
  # stdlib, and gems.
  #
  class YardMap
    autoload :Cache,    'solargraph/yard_map/cache'
    autoload :CoreDocs, 'solargraph/yard_map/core_docs'

    CoreDocs.require_minimum
    @@stdlib_yardoc = CoreDocs.yard_stdlib_file
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

    # @param required [Array<String>]
    # @param workspace [Solargraph::Workspace, nil]
    def initialize(required: [])
      # HACK: YardMap needs its own copy of this array
      @required = required.clone
      @gem_paths = {}
      @stdlib_namespaces = []
      process_requires
      yardocs.uniq!
    end

    # @return [Array<Solargraph::Pin::Base>]
    def pins
      @pins ||= []
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
      begin
        if y.kind_of?(Array)
          YARD::Registry.load y, true
        else
          YARD::Registry.load! y
        end
      rescue Exception => e
        STDERR.puts "Error loading yardoc '#{y}' #{e.class} #{e.message}"
        yardocs.delete y
        nil
      end
    end

    # @return [Array<Solargraph::Pin::Base>]
    def core_pins
      @@core_pins ||= begin
        result = []
        load_yardoc CoreDocs.yardoc_file
        YARD::Registry.each do |o|
          result.concat generate_pins(o)
        end
        result
      end
    end

    # @param path [String]
    # @return [Pin::Base]
    def path_pin path
      pins.select{ |p| p.path == path }.first
    end

    private

    # @return [YardMap::Cache]
    def cache
      @cache ||= YardMap::Cache.new
    end

    # @param ns [YARD::CodeObjects::Namespace]
    # @return [Array<Solargraph::Pin::Base>]
    def recurse_namespace_object ns
      result = []
      ns.children.each do |c|
        result.concat generate_pins(c)
        result.concat recurse_namespace_object(c) if c.respond_to?(:children)
      end
      result
    end

    # @param code_object [YARD::CodeObjects::Base]
    # @return [Solargraph::Pin::Base]
    def generate_pins code_object
      result = []
      location = object_location(code_object)
      if code_object.is_a?(YARD::CodeObjects::NamespaceObject)
        result.push Solargraph::Pin::YardPin::Namespace.new(code_object, location)
      elsif code_object.is_a?(YARD::CodeObjects::MethodObject)
        if code_object.name == :initialize && code_object.scope == :instance
          # @todo Check the visibility of <Class>.new
          result.push Solargraph::Pin::YardPin::Method.new(code_object, location, 'new', :class, :public)
          result.push Solargraph::Pin::YardPin::Method.new(code_object, location, 'initialize', :instance, :private)
        else
          result.push Solargraph::Pin::YardPin::Method.new(code_object, location)
        end
      elsif code_object.is_a?(YARD::CodeObjects::ConstantObject)
        result.push Solargraph::Pin::YardPin::Constant.new(code_object, location)
      end
      result
    end

    # @return [void]
    def process_requires
      pins.clear
      unresolved_requires.clear
      stdnames = {}
      required.each do |r|
        next if r.nil? or r.empty?
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
          result.concat add_gem_dependencies spec
          yd = YARD::Registry.yardoc_file_for_gem(spec.name, ver)
          @gem_paths[spec.name] = spec.full_gem_path
          if yd.nil?
            unresolved_requires.push r
          else
            unless yardocs.include?(yd)
              yardocs.unshift yd
              load_yardoc yd
              YARD::Registry.each do |o|
                result.concat generate_pins(o)
              end
            end
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
            result.concat generate_pins(ns)
            result.concat recurse_namespace_object(ns)
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
          @gem_paths[depspec.name] = depspec.full_gem_path unless depspec.nil?
          gy = YARD::Registry.yardoc_file_for_gem(dep.name)
          if gy.nil?
            unresolved_requires.push dep.name
          else
            unless yardocs.include?(gy)
              yardocs.unshift gy
              load_yardoc gy
              YARD::Registry.each do |o|
                result.concat generate_pins(o)
              end
              result.concat add_gem_dependencies(depspec)
            end
          end
        rescue Gem::LoadError
          # This error probably indicates a bug in an installed gem
          STDERR.puts "Warning: failed to resolve #{dep.name} gem dependency for #{spec.name}"
        end
      end
      result
    end

    # @param obj [YARD::CodeObjects::Base]
    # @return [Solargraph::Location]
    def object_location obj
      return nil if obj.file.nil? or obj.line.nil?
      @gem_paths.values.each do |path|
        file = File.join(path, obj.file)
        return Solargraph::Location.new(file, Solargraph::Range.from_to(obj.line, 0, obj.line, 0)) if File.exist?(file)
      end
      nil
    end
  end
end
