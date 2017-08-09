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
              if arg.start_with?('-')
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
  end
end
