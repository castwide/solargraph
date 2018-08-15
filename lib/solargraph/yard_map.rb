require 'yard'

module Solargraph
  # The YardMap provides access to YARD documentation for the Ruby core, the
  # stdlib, and gems.
  #
  class YardMap
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
      @namespace_yardocs = {}
      @gem_paths = {}
      @stdlib_namespaces = []
      process_requires
      yardocs.push CoreDocs.yardoc_file
      yardocs.uniq!
      yardocs.delete_if{ |y| y.start_with? workspace.directory } unless workspace.nil? or workspace.directory.nil?
    end

    def all_objects
      all = []
      yardocs.each do |y|
        load_yardoc y
        all.concat YARD::Registry.all
      end
      all
    end

    def all_pins
      result = []
      all_objects.each do |o|
        pin = generate_pin(o)
        result.push pin unless pin.nil?
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

    private

    def process_requires
      tried = []
      unresolved_requires.clear
      required.each do |r|
        next if r.nil?
        next if !workspace.nil? and workspace.would_require?(r)
        begin
          spec = Gem::Specification.find_by_path(r) || Gem::Specification.find_by_name(r.split('/').first)
          ver = spec.version.to_s
          ver = ">= 0" if ver.empty?
          add_gem_dependencies spec
          yd = YARD::Registry.yardoc_file_for_gem(spec.name, ver)
          @gem_paths[spec.name] = spec.full_gem_path
          unresolved_requires.push r if yd.nil?
          yardocs.unshift yd unless yd.nil? or yardocs.include?(yd)
        rescue Gem::LoadError => e
          next if !workspace.nil? and workspace.would_require?(r)
          stdnames = []
          @@stdlib_paths.each_pair do |path, objects|
            stdnames.concat objects if path == r or path.start_with?("#{r}/")
          end
          @stdlib_namespaces.concat stdnames
          unresolved_requires.push r if stdnames.empty?
        end
      end
    end

    # @param spec [Gem::Specification]
    def add_gem_dependencies spec
      return # @todo Ignore dependencies for now
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

    # @param namespace [String]
    # @return [Array<String>]
    def yardocs_documenting namespace
      result = []
      if namespace == ''
        result.concat yardocs
      else
        result.concat @namespace_yardocs[namespace] unless @namespace_yardocs[namespace].nil?
      end
      if @stdlib_namespaces.map(&:path).include?(namespace)
        result.push @@stdlib_yardoc
      end
      result
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
