#!/usr/bin/env ruby

$LOAD_PATH.unshift '/home/fred/solargraph-ruby/lib'
require 'solargraph'

version_dir = "#{Solargraph::STUB_PATH}/ruby/#{RUBY_VERSION}"
`rm -rf #{version_dir}` if File.exist?(version_dir)
`mkdir #{version_dir}`
`mkdir #{version_dir}/stdlib`

parser = Solargraph::LiveParser.new
File.read("corelist.txt").split("\n").each { |lib|
  print "Parsing #{lib}..."
  if lib == "core"
    file = "#{version_dir}/core.rb"
    ser = "#{version_dir}/core.ser"
  else
    begin
      require lib
      file = "#{version_dir}/stdlib/#{lib}.rb"
      ser = "#{version_dir}/stdlib/#{lib}.ser"
    rescue LoadError => e
      puts e.inspect
      puts "Skipping #{lib}."
      next
    end
  end
  `ruby #{File.dirname(__FILE__)}/stub-require.rb #{lib} #{file}`
  map = Solargraph::ApiMap.new()
  map.merge Parser::CurrentRuby.parse(File.read(file))
  File.open(ser, 'w') do |file|
    file << Marshal.dump(map)
  end
  puts "Done."
}
