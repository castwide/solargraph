module Solargraph
  module YardMethods
    def yard_options
      if @yard_options.nil?
        @yard_options = {
          include: [],
          exclude: [],
          flags: []
        }
        unless workspace.nil?
          yardopts_file = File.join(workspace, '.yardopts')
          if File.exist?(yardopts_file)
            yardopts = File.read(yardopts_file)
            yardopts.lines.each { |line|
              arg = line.strip
              if arg.start_with?('--exclude')
                @yard_options[:exclude].concat arg.split(/[\s]+/)[1..-1]
              elsif arg.start_with?('-')
                @yard_options[:flags].push arg
              else
                @yard_options[:include].push arg
              end
            }
          end
        end
        @yard_options[:include].concat ['app/**/*.rb', 'lib/**/*.rb'] if @yard_options[:include].empty?
      end
      @yard_options
    end

    def yard_files
      if @yard_files.nil?
        @yard_files = []
        yard_options[:include].each do |glob|
          if File.file?(glob)
            @yard_files.push File.realpath(glob)
          elsif File.directory?(glob)
            @yard_files.concat Dir["#{glob}/**/*"].map{ |f| File.realpath(f) }
          else
            @yard_files.concat Dir[glob].map{ |f| File.realpath(f) }
          end
        end
        yard_options[:exclude].each do |glob|
          if File.file?(glob)
            @yard_files.delete File.realpath(glob)
          elsif File.directory?(glob)
            @yard_files -= Dir["#{glob}/**/*"].map{ |f| File.realpath(f) }
          else
            @yard_files -= Dir[glob].map{ |f| File.realpath(f) }
          end
        end
      end
      @yard_files
    end
  end
end
