# describe Solargraph::Pin::MethodParameter do
#   it "detects method parameter return types from @param tags" do
#     source = Solargraph::Source.load_string(%(
#       # @param bar [String]
#       def foo bar
#       end
#     ), 'file.rb')
#     map = Solargraph::SourceMap.map(source)
#     expect(map.locals.length).to eq(1)
#     expect(map.locals.first.name).to eq('bar')
#     expect(map.locals.first.return_type.tag).to eq('String')
#   end

#   it "tracks its index" do
#     smap = Solargraph::SourceMap.load_string(%(
#       def foo bar
#       end
#     ))
#     pin = smap.locals.select{|p| p.name == 'bar'}.first
#     expect(pin.index).to eq(0)
#   end

#   it "detects unnamed @param tag types" do
#     smap = Solargraph::SourceMap.load_string(%(
#       # @param [String]
#       def foo bar
#       end
#     ))
#     pin = smap.locals.select{|p| p.name == 'bar'}.first
#     expect(pin.return_complex_type.tag).to eq('String')
#   end
# end
