`./bin/solargraph-ruby scope test.rb > test.stub`
info = JSON.parse(`./bin/solargraph-ruby info test.rb -i 40`)
if info['instance_method']
  puts `./bin/solargraph-ruby instance-methods #{info['namespace']} -a private`
end
