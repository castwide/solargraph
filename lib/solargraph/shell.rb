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
      puts "Deleting the cached documentation"
      Solargraph::Cache.clear
    end
    map 'clear-cache' => :clear
    map 'clear-cores' => :clear

    desc 'cache', 'Cache a gem', hide: true
    # @return [void]
    # @param gem [String]
    # @param version [String, nil]
    def cache gem, version = nil
      spec = Gem::Specification.find_by_name(gem, version)
      pins = GemPins.build(spec)
      Cache.save('gems', "#{spec.name}-#{spec.version}.ser", pins)
    end

    desc 'uncache GEM [...GEM]', "Delete cached gem documentation"
    # @return [void]
    def uncache *gems
      raise ArgumentError, 'No gems specified.' if gems.empty?
      gems.each do |gem|
        spec = Gem::Specification.find_by_name(gem)
        Cache.uncache('gems', "#{spec.name}-#{spec.version}.ser")
        Cache.uncache('gems', "#{spec.name}-#{spec.version}.yardoc")
      end
    end

    desc 'gems [GEM[=VERSION]]', 'Cache documentation for installed gems'
    option :rebuild, type: :boolean, desc: 'Rebuild existing documentation', default: false
    # @return [void]
    def gems *names
      if names.empty?
        Gem::Specification.to_a.each { |spec| do_cache spec }
      else
        names.each do |name|
          spec = Gem::Specification.find_by_name(*name.split('='))
          do_cache spec
        rescue Gem::MissingSpecError
          warn "Gem '#{name}' not found"
        end
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
          checker = TypeChecker.new(file, api_map: api_map, level: options[:level].to_sym)
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
    # @return [void]
    def do_cache gemspec
      cached = Yardoc.cached?(gemspec)
      if cached && !options.rebuild
        puts "Cache already exists for #{gemspec.name} #{gemspec.version}"
      else
        puts "#{cached ? 'Rebuilding' : 'Caching'} gem documentation for #{gemspec.name} #{gemspec.version}"
        pins = GemPins.build(gemspec)
        Cache.save('gems', "#{gemspec.name}-#{gemspec.version}.ser", pins)
      end
    end
  end
end
