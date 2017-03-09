require 'thor'
require 'json'

module Solargraph
  class Shell < Thor
    desc 'prepare', 'Cache YARD files for the current environment'
    option :host, type: :string, aliases: :h, desc: 'The host that provides YARDOC files for download', default: 'yardoc.solargraph.org'
    def prepare
      # TODO: Download core and stdlib files from yardoc.solargraph.org
      # Maybe also generate yardoc files for bundled gems
    end
    
    desc 'serve', 'Start a Solargraph server'
    def serve
      Solargraph::Server.run!
    end
    
    desc 'suggest', 'Get code suggestions for the provided input'
    long_desc <<-LONGDESC
      This command will wait for information sent in JSON format over
      STDIN and output a list of code suggestions in JSON format.

      The input should be a JSON string with the the following properties:

        filename: The name of the file. Optional but recommended.

        text: The source code to be analyzed.

        position: The numeric location of the cursor, i.e., the location in the text where the suggestion will be inserted.

      Example of input: {"filename": "my_code.rb", "text": "class MyCode\n  inc\nEnd", "position": 18}

      The above example will return suggestions to complete a code phrase that starts with "inc".
    LONGDESC
    def suggest
      # TODO: Wait for input and return suggestions
      input = STDIN.gets
      data = JSON.parse(input)
      #STDOUT.puts data
      STDOUT.puts "Hell yeah! #{input}"
    end
  end
end
