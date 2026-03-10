# frozen_string_literal: true

require 'benchmark'
require 'concurrent-ruby'
require 'thor'
require 'yard'
require 'yaml'

module Solargraph
  class Shell < Thor
    include Solargraph::ServerMethods

    # Tell Thor to ensure the process exits with status 1 if any error happens.
    def self.exit_on_failure?
      true
    end

    map %w[--version -v] => :version

    desc '--version, -v', 'Print the version'
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
        Signal.trap('INT') do
          Backport.stop
        end
        Signal.trap('TERM') do
          Backport.stop
        end
        # @sg-ignore Wrong argument type for Backport.prepare_tcp_server: adapter expected Backport::Adapter, received Module<Solargraph::LanguageServer::Transport::Adapter>
        Backport.prepare_tcp_server host: options[:host], port: port, adapter: Solargraph::LanguageServer::Transport::Adapter
        warn "Solargraph is listening PORT=#{port} PID=#{Process.pid}"
      end
    end

    desc 'stdio', 'Run a Solargraph stdio server'
    # @return [void]
    def stdio
      require 'backport'
      Backport.run do
        Signal.trap('INT') do
          Backport.stop
        end
        Signal.trap('TERM') do
          Backport.stop
        end
        # @sg-ignore Wrong argument type for Backport.prepare_stdio_server: adapter expected Backport::Adapter, received Module<Solargraph::LanguageServer::Transport::Adapter>
        Backport.prepare_stdio_server adapter: Solargraph::LanguageServer::Transport::Adapter
        warn "Solargraph is listening on stdio PID=#{Process.pid}"
      end
    end

    desc 'config [DIRECTORY]', 'Create or overwrite a default configuration file'
    option :extensions, type: :boolean, aliases: :e, desc: 'Add installed extensions', default: true
    # @param directory [String]
    # @return [void]
    def config directory = '.'
      matches = []
      if options[:extensions]
        Gem::Specification.each do |g|
          if g.name.match(/^solargraph-[A-Za-z0-9_-]*?-ext/)
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
      $stdout.puts 'Configuration file initialized.'
    end

    desc 'clear', 'Delete all cached documentation'
    long_desc %(
      This command will delete all core and gem documentation from the cache.
    )
    # @return [void]
    def clear
      puts 'Deleting all cached documentation (gems, core and stdlib)'
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
      gems(gem + (version ? "=#{version}" : ''))
      # '
    end

    desc 'uncache GEM [...GEM]', 'Delete specific cached gem documentation'
    long_desc %(
      Specify one or more gem names to clear. 'core' or 'stdlib' may
      also be specified to clear cached system documentation.
      Documentation will be regenerated as needed.
    )
    # @param gems [Array<String>]
    # @return [void]
    def uncache *gems
      raise ArgumentError, 'No gems specified.' if gems.empty?
      workspace = Solargraph::Workspace.new(Dir.pwd)

      gems.each do |gem|
        if gem == 'core'
          PinCache.uncache_core(out: $stdout)
          next
        end

        if gem == 'stdlib'
          PinCache.uncache_stdlib(out: $stdout)
          next
        end

        spec = workspace.find_gem(gem)
        raise Thor::InvocationError, "Gem '#{gem}' not found" if spec.nil?

        # @sg-ignore flow sensitive typing needs to handle 'raise if'
        workspace.uncache_gem(spec, out: $stdout)
      end
    end

    desc 'gems [GEM[=VERSION]...] [STDLIB...] [core]', 'Cache documentation for
         installed libraries'
    long_desc %( This command will cache the
    generated type documentation for the specified libraries.  While
    Solargraph will generate this on the fly when needed, it takes
    time.  This command will generate it in advance, which can be
    useful for CI scenarios.

        With no arguments, it will cache all libraries in the current
        workspace.  If a gem or standard library name is specified, it
        will cache that library's type documentation.

        An equals sign after a gem will allow a specific gem version
        to be cached.

        The 'core' argument can be used to cache the type
        documentation for the core Ruby libraries.

        The literal 'stdlib' argument will cache all standard
        libraries available.

        'bundler/require' as a gem name will cache all auto-required
        gems.

        'default' will cache all gems used by Solargraph absent
        specific requires in the files being looked at.

        If the library is already cached, it will be rebuilt if the
        --rebuild option is set.

        Cached documentation is stored in #{PinCache.base_dir}, which
        can be stored between CI runs.
    )
    option :workspace, type: :boolean, desc: 'Rebuild all accessible gems, not just those used', default: false
    option :rebuild, type: :boolean, desc: 'Rebuild existing documentation', default: false
    # @param names [Array<String>]
    # @return [void]
    def gems *names
      # print time with ms
      api_map = Solargraph::ApiMap.new
      workspace = api_map.workspace

      if names.empty?
        if options[:workspace]
          workspace.cache_all_for_workspace!($stdout, rebuild: options[:rebuild])
        else
          api_map.cache_all_for_doc_map!(out: $stdout, rebuild: options[:rebuild])
        end
      else
        # run in parallel with a thread pool

        # create thread pool
        pool_size = Concurrent.processor_count # roughly your CPU count
        pool = Concurrent::FixedThreadPool.new(pool_size)
        warn("Caching these gems with #{pool_size} workers: #{names}")

        # Using 'names' as queue, run!
        futures = names.map do |name|
          Concurrent::Promises.future_on(pool, name) do |_x|
            cache_library(workspace, name)
          rescue Gem::MissingSpecError
            warn "Gem '#{name}' not found"
          rescue Gem::Requirement::BadRequirementError => e
            warn "Gem '#{name}' failed while loading"
            warn e.message
            # @sg-ignore Need to add nil check here
            warn e.backtrace.join("\n")
          end
        end

        Concurrent::Promises.zip(*futures).value! # raises if any failed
        pool.shutdown
        pool.wait_for_termination

        warn "Documentation cached for #{names.count} gems."
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
    option :level, type: :string, aliases: %i[mode m l], desc: 'Type checking level', default: 'normal'
    option :directory, type: :string, aliases: :d, desc: 'The workspace directory', default: '.'
    # @return [void]
    def typecheck *files
      directory = File.realpath(options[:directory])
      workspace = Solargraph::Workspace.new(directory)
      level = options[:level].to_sym
      rules = workspace.rules(level)
      api_map =
        Solargraph::ApiMap.load_with_cache(directory, $stdout,
                                           loose_unions:
                                             !rules.require_all_unique_types_support_call?)
      probcount = 0
      if files.empty?
        files = api_map.source_maps.map(&:filename)
      else
        files.map! { |file| File.realpath(file) }
      end
      filecount = 0
      time = Benchmark.measure do
        files.each do |file|
          checker = TypeChecker.new(file, api_map: api_map, rules: rules, level: options[:level].to_sym,
                                          workspace: workspace)
          problems = checker.problems
          next if problems.empty?
          problems.sort! { |a, b| a.location.range.start.line <=> b.location.range.start.line }
          puts problems.map { |prob|
            "#{prob.location.filename}:#{prob.location.range.start.line + 1} - #{prob.message}"
          }.join("\n")
          filecount += 1
          probcount += problems.length
        end
      end
      puts "Typecheck finished in #{time.real} seconds."
      puts "#{probcount} problem#{if probcount != 1
                                    's'
                                  end} found#{if files.length != 1
                                                                  " in #{filecount} of #{files.length} files"
                                                                end}."
      # "
      exit 1 if probcount.positive?
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
      time = Benchmark.measure do
        api_map = Solargraph::ApiMap.load_with_cache(directory, $stdout)
        # @sg-ignore flow sensitive typing should be able to handle redefinition
        api_map.pins.each do |pin|
          puts pin_description(pin) if options[:verbose]
          pin.typify api_map
          pin.probe api_map
        rescue StandardError => e
          # @todo to add nil check here
          # @todo should warn on nil dereference below
          warn "Error testing #{pin_description(pin)} #{if pin.location
                                                          "at #{pin.location.filename}:#{pin.location.range.start.line + 1}"
                                                        end}"
          warn "[#{e.class}]: #{e.message}"
          # @todo Need to add nil check here
          # @todo flow sensitive typing should be able to handle redefinition
          warn e.backtrace.join("\n")
          exit 1
        end
      end
      # @sg-ignore Need to add nil check here
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

    desc 'pin [PATH]', 'Describe a pin'
    option :rbs, type: :boolean, desc: 'Output the pin as RBS', default: false
    option :typify, type: :boolean, desc: 'Output the calculated return type of the pin from annotations',
                    default: false
    option :references, type: :boolean, desc: 'Show references', default: false
    option :probe, type: :boolean, desc: 'Output the calculated return type of the pin from annotations and inference',
                   default: false
    option :stack, type: :boolean, desc: 'Show entire stack of a method pin by including definitions in superclasses',
                   default: false
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
        warn "Pin not found for path '#{path}'"
        exit 1
      when Pin::Namespace
        if options[:references]
          # @sg-ignore Need to add nil check here
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

    desc 'profile [FILE]', 'Profile go-to-definition performance using vernier'
    option :directory, type: :string, aliases: :d, desc: 'The workspace directory', default: '.'
    option :output_dir, type: :string, aliases: :o, desc: 'The output directory for profiles', default: './tmp/profiles'
    option :line, type: :numeric, aliases: :l, desc: 'Line number (0-based)', default: 4
    option :column, type: :numeric, aliases: :c, desc: 'Column number', default: 10
    option :memory, type: :boolean, aliases: :m, desc: 'Include memory usage counter', default: true
    # @param file [String, nil]
    # @return [void]
    def profile file = nil
      begin
        require 'vernier'
      rescue LoadError
        $stderr.puts 'vernier gem not found. Please install this dependency:'
        $stderr.puts
        $stderr.puts "  gem 'vernier', '>1.0', '<2'"

        return
      end

      hooks = []
      hooks << :memory_usage if options[:memory]

      directory = File.realpath(options[:directory])
      FileUtils.mkdir_p(options[:output_dir])

      host = Solargraph::LanguageServer::Host.new
      host.client_capabilities.merge!({ 'window' => { 'workDoneProgress' => true } })
      # @param method [String] The message method
      # @param params [Hash] The method parameters
      # @return [void]
      def host.send_notification method, params
        puts "Notification: #{method} - #{params}"
      end

      puts 'Parsing and mapping source files...'
      prepare_start = Time.now
      Vernier.profile(out: "#{options[:output_dir]}/parse_benchmark.json.gz", hooks: hooks) do
        puts 'Mapping libraries'
        host.prepare(directory)
        sleep 0.2 until host.libraries.all?(&:mapped?)
      end
      prepare_time = Time.now - prepare_start

      puts 'Building the catalog...'
      catalog_start = Time.now
      Vernier.profile(out: "#{options[:output_dir]}/catalog_benchmark.json.gz", hooks: hooks) do
        host.catalog
      end
      catalog_time = Time.now - catalog_start

      # Determine test file
      if file
        test_file = File.join(directory, file)
      else
        test_file = File.join(directory, 'lib', 'other.rb')
        unless File.exist?(test_file)
          # Fallback to any Ruby file in the workspace
          workspace = Solargraph::Workspace.new(directory)
          test_file = workspace.filenames.find { |f| f.end_with?('.rb') }
          unless test_file
            warn 'No Ruby files found in workspace'
            return
          end
        end
      end

      file_uri = Solargraph::LanguageServer::UriHelpers.file_to_uri(File.absolute_path(test_file))

      puts "Profiling go-to-definition for #{test_file}"
      puts "Position: line #{options[:line]}, column #{options[:column]}"

      definition_start = Time.now
      Vernier.profile(out: "#{options[:output_dir]}/definition_benchmark.json.gz", hooks: hooks) do
        message = Solargraph::LanguageServer::Message::TextDocument::Definition.new(
          host, {
            'params' => {
              'textDocument' => { 'uri' => file_uri },
              'position' => { 'line' => options[:line], 'character' => options[:column] }
            }
          }
        )
        puts 'Processing go-to-definition request...'
        result = message.process

        puts "Result: #{result.inspect}"
      end
      definition_time = Time.now - definition_start

      puts "\n=== Timing Results ==="
      puts "Parsing & mapping: #{(prepare_time * 1000).round(2)}ms"
      puts "Catalog building: #{(catalog_time * 1000).round(2)}ms"
      puts "Go-to-definition: #{(definition_time * 1000).round(2)}ms"
      total_time = prepare_time + catalog_time + definition_time
      puts "Total time: #{(total_time * 1000).round(2)}ms"

      puts "\nProfiles saved to:"
      puts "  - #{File.expand_path('parse_benchmark.json.gz', options[:output_dir])}"
      puts "  - #{File.expand_path('catalog_benchmark.json.gz', options[:output_dir])}"
      puts "  - #{File.expand_path('definition_benchmark.json.gz', options[:output_dir])}"

      puts "\nUpload the JSON files to https://vernier.prof/ to view the profiles."
      puts 'Or use https://rubygems.org/gems/profile-viewer to view them locally.'
    end

    private

    # @param name [String]
    # @param [Workspace] workspace
    #
    # @return [void]
    def cache_library workspace, name
      if name == 'core'
        PinCache.cache_core(out: $stdout) if !PinCache.core? || options[:rebuild]
        return
      end

      if name == 'stdlib'
        workspace.cache_all_stdlibs(out: $stdout, rebuild: options[:rebuild])
        return
      end

      if name == 'default'
        doc_map = Solargraph::DocMap.new([], workspace)
        doc_map.cache_doc_map_gems! $stdout
        return
      end

      if name == 'bundler/require'
        gemspecs = workspace.resolve_require(name)
        gemspecs&.each do |gs|
          workspace.cache_gem(gs, rebuild: options[:rebuild], out: $stdout)
        end
        return
      end

      gemspec = workspace.find_gem(*name.split('='))
      if gemspec.nil?
        warn "Gem '#{name}' not found"
      else
        workspace.cache_gem(gemspec, rebuild: options[:rebuild], out: $stdout)
      end
    end

    # @param pin [Solargraph::Pin::Base]
    # @return [String]
    def pin_description pin
      desc = if pin.path.nil? || pin.path.empty?
               if pin.closure
                 # @sg-ignore Need to add nil check here
                 "#{pin.closure.path} | #{pin.name}"
               else
                 "#{pin.context.namespace} | #{pin.name}"
               end
             else
               pin.path
             end
      # @sg-ignore Need to add nil check here
      desc += " (#{pin.location.filename} #{pin.location.range.start.line})" if pin.location
      desc
    end

    # @param type [ComplexType, ComplexType::UniqueType]
    # @return [void]
    def print_type type
      if options[:rbs]
        puts type.to_rbs
      else
        puts type.rooted_tag
      end
    end

    # @param pin [Solargraph::Pin::Base]
    # @return [void]
    def print_pin pin
      if options[:rbs]
        puts pin.to_rbs
      else
        puts pin.inspect
      end
    end
  end
end
