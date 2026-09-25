# frozen_string_literal: true

# A gem may declare RBS for a method on a class Ruby core already defines --
# bigdecimal declares Integer#+ taking a BigDecimal. Core declares its own
# Integer#+, and the two are produced and cached separately, so the only place
# they meet is where a workspace asks for the method. ApiMap.load_with_cache is
# that ask, whichever layer is holding the pins underneath.
describe Solargraph::ApiMap do
  let(:directory) { File.join('spec', 'fixtures', 'gem-core-method') }
  let(:api_map) { described_class.load_with_cache(directory, nil) }

  before do
    # Whatever built the cached entry decided then how the two declarations
    # combine, so a kept entry would answer for that code rather than this.
    Solargraph::Shell.new.uncache('bigdecimal')
  end

  # @return [Array<Array<String>>] the parameter types of each signature
  def integer_plus_param_types
    api_map.get_method_stack('Integer', '+', scope: :instance)
           .first
           .signatures
           .map { |sig| sig.parameters.map { |param| param.return_type.to_s } }
  end

  it "offers the gem's signature for a method core also defines" do
    expect(integer_plus_param_types).to include(['BigDecimal'])
  end

  it "still offers core's own signatures" do
    expect(integer_plus_param_types).to include(['Integer'], ['Float'], ['Rational'], ['Complex'])
  end

  it 'accepts an argument of the type the gem declares' do
    filename = File.expand_path(File.join(directory, 'app.rb'))
    checker = Solargraph::TypeChecker.new(filename, api_map: api_map, level: :strong)

    expect(checker.problems.map(&:message)).to be_empty
  end
end
