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

    # @return [Solargraph::Workspace]
    attr_reader :workspace

    # @return [Array<String>]
    attr_reader :required

    def initialize(required: [], workspace: nil)
      @workspace = workspace
      # HACK: YardMap needs its own copy of this array
      @required = required.clone
      @gem_paths = {}
      @stdlib_namespaces = []
      process_requires
      # yardocs.push CoreDocs.yardoc_file
      yardocs.uniq!
      yardocs.delete_if{ |y| y.start_with? workspace.directory } unless workspace.nil? or workspace.directory.nil?
    end

    # @return [Array<Solargraph::Pin::Base>]
    def pins
      @pins ||= []
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

    # @param paths [Array<String>]
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

    def core_pins
      @@core_pins ||= begin
        result = []
        load_yardoc CoreDocs.yardoc_file
        YARD::Registry.each do |o|
          result.push generate_pin(o)
        end
        result
      end
    end

    private

    # @return [YardMap::Cache]
    def cache
      @cache ||= YardMap::Cache.new
    end

    def recurse_namespace_object ns
      result = []
      ns.children.each do |c|
        result.push generate_pin(c)
        result.concat recurse_namespace_object(c) if c.respond_to?(:children)
      end
      result
    end

    def generate_pin code_object
      location = object_location(code_object)
      if code_object.is_a?(YARD::CodeObjects::NamespaceObject)
        Solargraph::Pin::YardPin::Namespace.new(code_object, location)
      elsif code_object.is_a?(YARD::CodeObjects::MethodObject)
        Solargraph::Pin::YardPin::Method.new(code_object, location)
      elsif code_object.is_a?(YARD::CodeObjects::ConstantObject)
        Solargraph::Pin::YardPin::Constant.new(code_object, location)
      else
        nil
      end
    end

    def process_requires
      pins.clear
      unresolved_requires.clear
      required.each do |r|
        next if r.nil? or r.empty?
        next if !workspace.nil? and workspace.would_require?(r)
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
          # @todo Ignoring dependencies for now
          # add_gem_dependencies spec
          yd = YARD::Registry.yardoc_file_for_gem(spec.name, ver)
          @gem_paths[spec.name] = spec.full_gem_path
          if yd.nil?
            unresolved_requires.push r
          else
            unless yardocs.include?(yd)
              yardocs.unshift yd
              # @todo Generate the pins
              load_yardoc yd
              YARD::Registry.each do |o|
                result.push generate_pin(o)
              end
            end
          end
        rescue Gem::LoadError => e
          next if !workspace.nil? and workspace.would_require?(r)
          stdnames = []
          @@stdlib_paths.each_pair do |path, objects|
            stdnames.concat objects if path == r or path.start_with?("#{r}/")
          end
          @stdlib_namespaces.concat stdnames
          if stdnames.empty?
            unresolved_requires.push r
          else
            yard = load_yardoc @@stdlib_yardoc
            done = []
            stdnames.each do |ns|
              next if done.include?(ns)
              done.push ns
              result.push generate_pin(ns)
              result.concat recurse_namespace_object(ns)
            end
          end
        end
        result.delete_if(&:nil?)
        unless result.empty?
          cache.set_path_pins r, result
          pins.concat result
        end
      end
      pins.concat core_pins
    end

    # @param spec [Gem::Specification]
    def add_gem_dependencies spec
      (spec.dependencies - spec.development_dependencies).each do |dep|
        depspec = Gem::Specification.find_by_name(dep.name)
        @gem_paths[spec.name] = depspec.full_gem_path unless depspec.nil?
        gy = YARD::Registry.yardoc_file_for_gem(dep.name)
        if gy.nil?
          unresolved_requires.push dep.name
        else
          yardocs.unshift gy unless yardocs.include?(gy)
        end
      end
    end

    # @param obj [YARD::CodeObjects::Base]
    # @return [Solargraph::Source::Location]
    def object_location obj
      return nil if obj.file.nil? or obj.line.nil?
      @gem_paths.values.each do |path|
        file = File.join(path, obj.file)
        return Solargraph::Source::Location.new(file, Solargraph::Source::Range.from_to(obj.line - 1, 0, obj.line - 1, 0)) if File.exist?(file)
      end
      nil
    end
  end
end
