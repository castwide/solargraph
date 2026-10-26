# frozen_string_literal: true

describe Solargraph::Typedef::Expansions::Inference do
  def dictionary_for code, position
    source = Solargraph::Source.load_string(code, 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    Solargraph::Typedef::Dictionary.new(api_map, 'test.rb', position)
  end

  it 'detects block parameter return types from @yieldparam tags' do
    code = %(
      # @yieldparam [Array]
      def yielder; end
      yielder do |things|
        things
      end
    )
    
    typeset = dictionary_for(code, [4, 11]).infer
    expect(typeset.to_s).to eq('Array')
  end
end
