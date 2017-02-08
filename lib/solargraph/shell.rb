require 'thor'
require 'json'

module Solargraph
  class Shell < Thor
    map %w[methods] => :singleton_methods
    
    desc 'stub FILE_NAME', 'Generate a stub of the specified file.'
    def stub file
      a = Analyzer.new(File.read(file))
      puts a.stub
    end
    
    desc 'methods NAMESPACE', 'Get a list of methods.'
    option :stub, type: :string, aliases: :s, desc: 'A stub to load'
    option :access, type: :string, aliases: :a, enum: ['public', 'protected', 'private'], default: 'public', desc: 'The lowest accessibility to include'
    def singleton_methods namespace
      mock options[:stub]
      a = Analyzer.new
      puts a.get_methods(namespace, options[:access])
    end
    
    desc 'instance-methods NAMESPACE', 'Get a list of instance methods.'
    option :stub, type: :string, aliases: :s, desc: 'A stub to load'
    option :access, type: :string, aliases: :a, enum: ['public', 'protected', 'private'], default: 'public', desc: 'The lowest accessibility to include'
    def instance_methods namespace
      mock options[:stub]
      a = Analyzer.new
      puts a.get_instance_methods(namespace, options[:access])
    end
    
    desc 'constants', 'Get a list of constants.'
    option :stub, type: :string, aliases: :s, desc: 'A stub to load'
    option :namespace, type: :string, aliases: :n, default: 'Module', desc: 'The namespace to search'
    def constants
      mock options[:stub]
      a = Analyzer.new
      puts a.get_constants(options[:namespace])
    end
        
    desc 'info FILE_NAME', 'Get information about a location in a file'
    option :index, type: :numeric, aliases: :i, required: true, desc: 'The location in the file'
    def info file
      a = Analyzer.new(file)
      puts a.get_info_at(options[:index]).to_json
    end
    
    desc 'complete', 'Get a list of possible completions from a location'
    #option :stub, type: :string, aliases: :s, desc: 'A stub to load'
    option :file, type: :string, aliases: :f, required: true, desc: 'The file to analyze'
    option :index, type: :numeric, aliases: :i, required: true, desc: 'The location in the file'
    def complete
      #mock options[:stub]
      a = Analyzer.new(File.read(options[:file]))
      Object.instance_eval a.stub
      word = a.get_word_at(options[:index])
      if word.start_with?('@')
        puts a.get_instance_variables_at(options[:index]).to_json
      elsif word.start_with?('$')
        puts a.get_global_variables.to_json
      elsif word.start_with?(':') and !word.begin_with?('::')
        # TODO it's a symbol
      elsif word.include?('::')
        # TODO it's in a namespace!
        ns = word
        if ns.end_with?('::')
          ns = ns[0..-3]
        end
        parts = ns.split('::')
        ns = parts[0..-2].join('::')
        if parts.last.include?('.')
          ns += '::' + parts.last[0..parts.last.index('.')-1]
          puts a.get_methods(ns).to_json
        else
          puts a.get_constants(ns).to_json
        end
      elsif word.include?('.')
        # TODO it's a method call!
        # TODO For now we're assuming only one period. That's obviously a bad assumption.
        base = word[0..word.index('.')-1]
        STDERR.puts "Trying to do something with #{base}"
        type = Object.instance_eval(base)
        if type.class == Module or type.class == Class
          STDERR.puts "Here we are!"
          puts a.get_methods(base).to_json
        end
      else
        # Just get the constants
        a.get_constants(a.namespace_at(options[:index]))).to_json
      end
      exit
      i = a.get_info_at(options[:index])
      if i[:instance_method]
        puts a.get_instance_methods(i[:namespace], 'private')
      elsif !i[:namespace].nil?
        #puts a.get_constants(i[:namespace])
      end
      #puts a.get_constants('Module')
    end
    
    desc 'sexp FILE_NAME', 'Get an s-expression of a file'
    def sexp file
      a = Analyzer.new(File.read(file))
      puts a.sexp
    end
    
    private
    def mock stub
      require_relative File.absolute_path(stub, Dir.pwd) unless stub.nil?
    end
    
  end
end
