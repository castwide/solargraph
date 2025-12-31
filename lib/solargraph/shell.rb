# frozen_string_literal: true

require 'benchmark'
require 'thor'
require 'yard'

module Solargraph
  class Shell < Thor
    include Solargraph::ServerMethods

    # Tell Thor to ensure the process exits with status 1 if any error happens.
    def self.exit_on_failure?
      true
    end

    map %w[--version -v] => :version

    desc "--version, -v", "Print the version"
    # @return [void]
    def version
      puts Solargraph::VERSION
    end

    desc 'socket', 'Run a Solargraph socket server'
    option :host, type: :string, aliases: :h, desc: 'The server host', default: '127.0.0.1'
    option :port, type: :numeric, aliases: :p, desc: 'The server port', default: 7658
    # @return [void]
    def socket
      require 'backport'
      port = options[:port]
      port = available_port if port.zero?
      Backport.run do
        Signal.trap("INT") do
          Backport.stop
        end
        Signal.trap("TERM") do
          Backport.stop
        end
        # @sg-ignore Wrong argument type for Backport.prepare_tcp_server: adapter expected Backport::Adapter, received Module<Solargraph::LanguageServer::Transport::Adapter>
        Backport.prepare_tcp_server host: options[:host], port: port, adapter: Solargraph::LanguageServer::Transport::Adapter
        STDERR.puts "Solargraph is listening PORT=#{port} PID=#{Process.pid}"
      end
    end

    desc 'stdio', 'Run a Solargraph stdio server'
    # @return [void]
    def stdio
      require 'backport'
      Backport.run do
        Signal.trap("INT") do
          Backport.stop
        end
        Signal.trap("TERM") do
          Backport.stop
        end
        # @sg-ignore Wrong argument type for Backport.prepare_stdio_server: adapter expected Backport::Adapter, received Module<Solargraph::LanguageServer::Transport::Adapter>
        Backport.prepare_stdio_server adapter: Solargraph::LanguageServer::Transport::Adapter
        STDERR.puts "Solargraph is listening on stdio PID=#{Process.pid}"
      end
    end

    desc 'config [DIRECTORY]', 'Create or overwrite a default configuration file'
    option :extensions, type: :boolean, aliases: :e, desc: 'Add installed extensions', default: true
    # @param directory [String]
    # @return [void]
    def config(directory = '.')
      matches = []
      if options[:extensions]
        Gem::Specification.each do |g|
          if g.name.match(/^solargraph\-[A-Za-z0-9_\-]*?\-ext/)
            require g.name
            matches.push g.name
          end
        end
      end
      conf = Solargraph::Workspace::Config.new.raw_data
      unless matches.empty?
        matches.each do |m|
          conf['extensions'].push m
        end
      end
      # @param file [File]
      File.open(File.join(directory, '.solargraph.yml'), 'w') do |file|
        file.puts conf.to_yaml
      end
      STDOUT.puts "Configuration file initialized."
    end

    desc 'clear', 'Delete all cached documentation'
    long_desc %(
      This command will delete all core and gem documentation from the cache.
    )
    # @return [void]
    def clear
      puts "Deleting all cached documentation (gems, core and stdlib)"
      Solargraph::PinCache.clear
    end
    map 'clear-cache' => :clear
    map 'clear-cores' => :clear

    desc 'cache', 'Cache a gem', hide: true
    option :rebuild, type: :boolean, desc: 'Rebuild existing documentation', default: false
    # @return [void]
    # @param gem [String]
    # @param version [String, nil]
    def cache gem, version = nil
      api_map = Solargraph::ApiMap.load(Dir.pwd)
      spec = Gem::Specification.find_by_name(gem, version)
      api_map.cache_gem(spec, rebuild: options[:rebuild], out: $stdout)
    end

    desc 'uncache GEM [...GEM]', "Delete specific cached gem documentation"
    long_desc %(
      Specify one or more gem names to clear. 'core' or 'stdlib' may
      also be specified to clear cached system documentation.
      Documentation will be regenerated as needed.
    )
    # @param gems [Array<String>]
    # @return [void]
    def uncache *gems
      raise ArgumentError, 'No gems specified.' if gems.empty?
      gems.each do |gem|
        if gem == 'core'
          PinCache.uncache_core
          next
        end

        if gem == 'stdlib'
          PinCache.uncache_stdlib
          next
        end

        spec = Gem::Specification.find_by_name(gem)
        PinCache.uncache_gem(spec, out: $stdout)
      end
    end

    desc 'gems [GEM[=VERSION]]', 'Cache documentation for installed gems'
    option :rebuild, type: :boolean, desc: 'Rebuild existing documentation', default: false
    # @param names [Array<String>]
    # @return [void]
    def gems *names
      api_map = ApiMap.load('.')
      if names.empty?
        Gem::Specification.to_a.each { |spec| do_cache spec, api_map }
        STDERR.puts "Documentation cached for all #{Gem::Specification.count} gems."
      else
        names.each do |name|
          spec = Gem::Specification.find_by_name(*name.split('='))
          do_cache spec, api_map
        rescue Gem::MissingSpecError
          warn "Gem '#{name}' not found"
        end
        STDERR.puts "Documentation cached for #{names.count} gems."
      end
    end

    desc 'reporters', 'Get a list of diagnostics reporters'
    # @return [void]
    def reporters
      puts Solargraph::Diagnostics.reporters
    end

    desc 'typecheck [FILE(s)]', 'Run the type checker'
    long_desc %(
      Perform type checking on one or more files in a workspace. Check the
      entire workspace if no files are specified.

      Type checking levels are normal, typed, strict, and strong.
    )
    option :level, type: :string, aliases: [:mode, :m, :l], desc: 'Type checking level', default: 'normal'
    option :directory, type: :string, aliases: :d, desc: 'The workspace directory', default: '.'
    # @return [void]
    def typecheck *files
      directory = File.realpath(options[:directory])
      workspace = Solargraph::Workspace.new(directory)
      level = options[:level].to_sym
      rules = workspace.rules(level)
      api_map = Solargraph::ApiMap.load_with_cache(directory, $stdout)
      probcount = 0
      if files.empty?
        files = api_map.source_maps.map(&:filename)
      else
        files.map! { |file| File.realpath(file) }
      end
      filecount = 0

      time = Benchmark.measure {
        files.each do |file|
          checker = TypeChecker.new(file, api_map: api_map, level: options[:level].to_sym, workspace: workspace)
          problems = checker.problems
          next if problems.empty?
          problems.sort! { |a, b| a.location.range.start.line <=> b.location.range.start.line }
          puts problems.map { |prob| "#{prob.location.filename}:#{prob.location.range.start.line + 1} - #{prob.message}" }.join("\n")
          filecount += 1
          probcount += problems.length
        end
        # "
      }
      puts "Typecheck finished in #{time.real} seconds."
      puts "#{probcount} problem#{probcount != 1 ? 's' : ''} found#{files.length != 1 ? " in #{filecount} of #{files.length} files" : ''}."
      # "
      exit 1 if probcount > 0
    end

    desc 'scan', 'Test the workspace for problems'
    long_desc %(
      A scan loads the entire workspace to make sure that the ASTs and
      maps do not raise errors during analysis. It does not perform any type
      checking or validation; it only confirms that the analysis itself is
      error-free.
    )
    option :directory, type: :string, aliases: :d, desc: 'The workspace directory', default: '.'
    option :verbose, type: :boolean, aliases: :v, desc: 'Verbose output', default: false
    # @return [void]
    def scan
      directory = File.realpath(options[:directory])
      # @type [Solargraph::ApiMap, nil]
      api_map = nil
      time = Benchmark.measure {
        api_map = Solargraph::ApiMap.load_with_cache(directory, $stdout)
        api_map.pins.each do |pin|
          begin
            puts pin_description(pin) if options[:verbose]
            pin.typify api_map
            pin.probe api_map
          rescue StandardError => e
            STDERR.puts "Error testing #{pin_description(pin)} #{pin.location ? "at #{pin.location.filename}:#{pin.location.range.start.line + 1}" : ''}"
            STDERR.puts "[#{e.class}]: #{e.message}"
            STDERR.puts e.backtrace.join("\n")
            exit 1
          end
        end
      }
      puts "Scanned #{directory} (#{api_map.pins.length} pins) in #{time.real} seconds."
    end

    desc 'list', 'List the files in the workspace and the total count'
    option :count, type: :boolean, aliases: :c, desc: 'Display the file count only', default: false
    option :directory, type: :string, aliases: :d, desc: 'The directory to read', default: '.'
    # @return [void]
    def list
      workspace = Solargraph::Workspace.new(options[:directory])
      puts workspace.filenames unless options[:count]
      puts "#{workspace.filenames.length} files total."
    end

    desc 'pin [PATH]', 'Describe a pin', hide: true
    option :rbs, type: :boolean, desc: 'Output the pin as RBS', default: false
    option :typify, type: :boolean, desc: 'Output the calculated return type of the pin from annotations', default: false
    option :references, type: :boolean, desc: 'Show references', default: false
    option :probe, type: :boolean, desc: 'Output the calculated return type of the pin from annotations and inference', default: false
    option :stack, type: :boolean, desc: 'Show entire stack of a method pin by including definitions in superclasses', default: false
    # @param path [String] The path to the method pin, e.g. 'Class#method' or 'Class.method'
    # @return [void]
    def pin path
      api_map = Solargraph::ApiMap.load_with_cache('.', $stderr)
      is_method = path.include?('#') || path.include?('.')
      if is_method && options[:stack]
        scope, ns, meth = if path.include? '#'
                            [:instance, *path.split('#', 2)]
                          else
                            [:class, *path.split('.', 2)]
                          end

        # @sg-ignore Wrong argument type for
        #   Solargraph::ApiMap#get_method_stack: rooted_tag
        #   expected String, received Array<String>
        pins = api_map.get_method_stack(ns, meth, scope: scope)
      else
        pins = api_map.get_path_pins path
      end
      # @type [Hash{Symbol => Pin::Base}]
      references = {}
      pin = pins.first
      case pin
      when nil
        $stderr.puts "Pin not found for path '#{path}'"
        exit 1
      when Pin::Namespace
        if options[:references]
          superclass_tag = api_map.qualify_superclass(pin.return_type.tag)
          superclass_pin = api_map.get_path_pins(superclass_tag).first if superclass_tag
          references[:superclass] = superclass_pin if superclass_pin
        end
      end

      pins.each do |pin|
        if options[:typify] || options[:probe]
          type = ComplexType::UNDEFINED
          type = pin.typify(api_map) if options[:typify]
          type = pin.probe(api_map) if options[:probe] && type.undefined?
          print_type(type)
          next
        end

        print_pin(pin)
      end
      references.each do |key, refpin|
        puts "\n# #{key.to_s.capitalize}:\n\n"
        print_pin(refpin)
      end
    end

    private

    # @param pin [Solargraph::Pin::Base]
    # @return [String]
    def pin_description pin
      desc = if pin.path.nil? || pin.path.empty?
        if pin.closure
          "#{pin.closure.path} | #{pin.name}"
        else
          "#{pin.context.namespace} | #{pin.name}"
        end
      else
        pin.path
      end
      desc += " (#{pin.location.filename} #{pin.location.range.start.line})" if pin.location
      desc
    end

    # @param gemspec [Gem::Specification]
    # @param api_map [ApiMap]
    # @return [void]
    def do_cache gemspec, api_map
      # @todo if the rebuild: option is passed as a positional arg,
      #   typecheck doesn't complain on the below line
      api_map.cache_gem(gemspec, rebuild: options.rebuild, out: $stdout)
    end

    # @param type [ComplexType]
    # @return [void]
    def print_type(type)
      if options[:rbs]
        puts type.to_rbs
      else
        puts type.rooted_tag
      end
    end

    # @param pin [Solargraph::Pin::Base]
    # @return [void]
    def print_pin(pin)
      if options[:rbs]
        puts pin.to_rbs
      else
        puts pin.inspect
      end
    end
  end
end
