# describe 'Agnostic Node Chaining' do
#   it 'recognizes zsuper' do
#     source = Solargraph::Source.load_string(%(
#       class Foo
#         def initialize
#           super
#         end
#       end
#     ), 'test.rb')
#     node = source.node_at(3, 6)
#     chain = Solargraph::Parser.chain(node)
#     expect(chain.links.length).to eq(1)
#     expect(chain.links.first.word).to eq('super')
#   end

#   it 'recognizes super' do
#     source = Solargraph::Source.load_string(%(
#       class Foo
#         def initialize
#           super()
#         end
#       end
#     ), 'test.rb')
#     node = source.node_at(3, 6)
#     chain = Solargraph::Parser.chain(node)
#     expect(chain.links.length).to eq(1)
#     expect(chain.links.first.word).to eq('super')
#   end

#   it 'recognizes super arguments' do
#     source = Solargraph::Source.load_string(%(
#       class Foo
#         def initialize
#           super(arg)
#         end
#       end
#     ), 'test.rb')
#     node = source.node_at(3, 6)
#     chain = Solargraph::Parser.chain(node)
#     expect(chain.links.length).to eq(1)
#     expect(chain.links.first.word).to eq('super')
#     expect(chain.links.first.arguments.length).to eq(1)
#   end
# end
