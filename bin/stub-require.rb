#!/usr/bin/env ruby

$LOAD_PATH.unshift '/home/fred/solargraph-ruby/lib'
require 'solargraph'

parser = Solargraph::LiveParser.new
original = Module.constants
if (ARGV[0] == 'core')
  File.open(ARGV[1], "w") { |f|
    f.write parser.parse
  }
else
  require ARGV[0]
  added = Module.constants - original
  File.open(ARGV[1], "w") { |f|
    added.each { |constant|
      f.write parser.parse(constant)
    }
}
end
