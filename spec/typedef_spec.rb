# frozen_string_literal: true

describe Solargraph::Typedef do
  describe '.tokenize' do
    it 'creates a path' do
      token = described_class.tokenize('Foo::Bar')
      expect(token).to be_a(Solargraph::Typedef::Path)
      expect(token.name).to eq('Foo::Bar')
    end

    it 'creates a simple token' do
      token = described_class.tokenize('param')
      expect(token).to be_a(Solargraph::Typedef::Token)
      expect(token.name).to eq('param')
    end

    it 'creates a YARD generic token' do
      token = described_class.tokenize('generic<T>')
      expect(token).to be_a(Solargraph::Typedef::Token)
      expect(token.name).to eq('generic<T>')
    end
  end
end
