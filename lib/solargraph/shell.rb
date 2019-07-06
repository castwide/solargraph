# frozen_string_literal: true

require 'thor'
require 'backport'
require 'benchmark'

module Solargraph
  class Shell < Thor
    include Solargraph::ServerMethods

    map %w[--version -v] => :version

    desc "--version, -v", "Print the version"
    def version
      puts Solargraph::VERSION
    end

    desc 'socket', 'Run a Solargraph socket server'
    
    option :host, type: :string, aliases: :h, desc: 'The server host', default: '127.0.0.1'
    option :port, type: :numeric, aliases: :p, desc: 'The server port', default: 7658
    def socket
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
    def stdio
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

    desc 'download-core [VERSION]', 'Download core documentation'
    def download_core version = nil
      ver = version || Solargraph::YardMap::CoreDocs.best_download
      puts "Downloading docs for #{ver}..."
      Solargraph::YardMap::CoreDocs.download ver
    rescue ArgumentError => e
      STDERR.puts "ERROR: #{e.message}"
      STDERR.puts "Run `solargraph available-cores` for a list."
      exit 1
    end

    desc 'list-cores', 'List the local documentation versions'
    def list_cores
      puts Solargraph::YardMap::CoreDocs.versions.join("\n")
    end

    desc 'available-cores', 'List available documentation versions'
    def available_cores
      puts Solargraph::YardMap::CoreDocs.available.join("\n")
    end

    desc 'clear', 'Delete the cached documentation'
    def clear
      puts "Deleting the cached documentation"
      Solargraph::YardMap::CoreDocs.clear
    end
    map 'clear-cache' => :clear
    map 'clear-cores' => :clear

    desc 'uncache GEM [...GEM]', "Delete cached gem documentation"
    def uncache *gems
      raise ArgumentError, 'No gems specified.' if gems.empty?
      gems.each do |gem|
        Dir[File.join(Solargraph::YardMap::CoreDocs.cache_dir, 'gems', "#{gem}-*")].each do |dir|
          puts "Deleting cache: #{dir}"
          FileUtils.remove_entry_secure dir
        end
      end
    end

    desc 'reporters', 'Get a list of diagnostics reporters'
    def reporters
      puts Solargraph::Diagnostics.reporters
    end

    desc 'typecheck [FILE]', 'Run the type checker'
    long_desc %(
      Perform type checking on one or more files is a workspace.
      A normal check reports problems with type definitions in method
      parameters and return values. A strict check performs static analysis of
      code to validate return types and arguments in method calls.
    )
    option :strict, type: :boolean, aliases: :s, desc: 'Use strict typing', default: false
    option :directory, type: :string, aliases: :d, desc: 'The workspace directory', default: '.'
    def typecheck *files
      directory = File.realpath(options[:directory])
      api_map = Solargraph::ApiMap.load(directory)
      if files.empty?
        files = api_map.source_maps.map(&:filename)
      else
        files.map! { |file| File.realpath(file) }
      end
      probcount = 0
      filecount = 0
      files.each do |file|
        checker = TypeChecker.new(file, api_map: api_map)
        problems = checker.param_type_problems + checker.return_type_problems
        problems.concat checker.strict_type_problems if options[:strict]
        next if problems.empty?
        problems.sort! { |a, b| a.location.range.start.line <=> b.location.range.start.line }
        puts problems.map { |prob| "#{prob.location.filename}:#{prob.location.range.start.line + 1} - #{prob.message}" }.join("\n")
        filecount += 1
        probcount += problems.length
      end
      puts "#{probcount} problem#{probcount != 1 ? 's' : ''} found#{files.length != 1 ? " in #{filecount} of #{files.length} files" : ''}."
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
    def scan
      directory = File.realpath(options[:directory])
      api_map = nil
      time = Benchmark.measure {
        api_map = Solargraph::ApiMap.load(directory)
        api_map.pins.each do |pin|
          begin
            puts pin_description(pin) if options[:verbose]
            pin.typify api_map
            pin.probe api_map
          rescue Exception => e
            STDERR.puts "Error testing #{pin_description(pin)} #{pin.location ? "at #{pin.location.filename}:#{pin.location.range.start.line + 1}" : ''}"
            STDERR.puts "[#{e.class}]: #{e.message}"
            STDERR.puts e.backtrace.join("\n")
            exit 1
          end
        end
      }
      puts "Scanned #{directory} (#{api_map.pins.length} pins) in #{time.real} seconds."
    end

    desc 'bundle', 'Generate documentation for bundled gems'
    option :directory, type: :string, aliases: :d, desc: 'The workspace directory', default: '.'
    option :rebuild, type: :boolean, aliases: :r, desc: 'Rebuild existing documentation', default: false
    def bundle
      Documentor.new(options[:directory], rebuild: options[:rebuild], out: STDOUT).document
    end

    desc 'rdoc GEM [VERSION]', 'Use RDoc to cache documentation'
    def rdoc gem, version = '>= 0'
      spec = Gem::Specification.find_by_name(gem, version)
      puts "Caching #{spec.name} #{spec.version} from RDoc"
      Solargraph::YardMap::RdocToYard.run(spec)
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
      desc.concat(" (#{pin.location.filename} #{pin.location.range.start.line})") if pin.location
      desc
    end
  end
end
