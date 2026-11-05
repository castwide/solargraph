# frozen_string_literal: true

describe Solargraph::Pin::DuckMethod do
  let(:api_map) do
    Solargraph::ApiMap.new.tap do |map|
      map.map Solargraph::Source.load_string(%(
        class ClassTest
          # @param clazz [#new]
          def create_object(clazz)
            clazz.new
          end
        end
      ))
    end
  end

  # The one place these are built: a duck-type tag reaches ApiMap via its
  # parsed ComplexType, not via the source that declared it.
  let(:duck_new) do
    api_map.get_complex_type_methods(Solargraph::ComplexType.parse('#new'))
           .grep(described_class).first
  end

  # ApiMap leaves #closure nil; the call site is what gives an ancestor
  # walk somewhere to go, since ClassTest inherits its own Class#new.
  let(:duck_new_at_call_site) do
    described_class.new(name: 'new', source: :api_map,
                        closure: api_map.get_path_pins('ClassTest#create_object').first)
  end

  it 'synthesizes a signature that accepts any arguments' do
    expect(duck_new.signatures.first.parameters.map(&:decl)).to eq(%i[restarg kwrestarg])
  end

  it 'has no ancestor chain of its own to walk' do
    expect(duck_new_at_call_site.rest_of_stack(api_map)).to be_empty
  end

  it "infers nothing rather than the call site's own inherited #new" do
    expect(duck_new_at_call_site.typify(api_map)).to be_undefined
  end
end
