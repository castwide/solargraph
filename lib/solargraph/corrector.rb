module Solargraph
  class Corrector
    def initialize directory
      @api_map = Solargraph::ApiMap.load(File.realpath(directory))
    end

    def run
      pass = 1
      loop do
        puts "Pass ##{pass}"
        all  = process
        problems = all.select { |prob| prob.suggestion && prob.suggestion != 'undefined' }
        puts "#{all.length} problems with #{problems.length} suggestions"
        break if problems.empty?
        problems.each do |prob|
          puts "Setting #{prob.pin.path} => #{prob.suggestion}"
          prob.pin.instance_variable_set :@return_type, Solargraph::ComplexType.try_parse(prob.suggestion)
        end
        @api_map.send(:cache).clear
        pass += 1
      end
    end

    private

    def process
      problems = []
      total = @api_map.source_maps.length
      print "\e[s"
      @api_map.source_maps.each_with_index do |smap, index|
        print "\e[K\e[u#{((index.to_f / total.to_f) * 100).to_i}% complete"
        checker = Solargraph::TypeChecker.new(smap.filename, api_map: @api_map)
        problems.concat checker.return_type_problems
      end
      print "\e[K\e[u"
      problems
    end
  end
end
