# describe Solargraph::Pin::ClassVariable do
#   it "always has class scope" do
#     source = Solargraph::Source.load_string(%(
#       class Foo
#         def bar
#           @@bar = 'bar'
#         end
#         @@baz = 'baz'
#       end
#     ))
#     expect(source.class_variable_pins[0].scope).to eq(:class)
#     expect(source.class_variable_pins[1].scope).to eq(:class)
#   end
# end
