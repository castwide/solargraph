# frozen_string_literal: true

describe Solargraph::YardMap::Directives::DomainDirective do
  # @param code [String]
  # @return [Array<Solargraph::Pin::Base>]
  def pins_for code
    Solargraph::SourceMap.map(Solargraph::Source.load_string(code, 'domain_directive_spec.rb')).pins
  end

  describe '.closure_at' do
    it 'returns nil when no namespace pin contains the position' do
      pins = pins_for(<<~RUBY)
        class Foo
        end
      RUBY
      position = Solargraph::Position.new(100, 0)
      expect(described_class.closure_at(pins, position)).to be_nil
    end

    it 'returns the innermost namespace pin containing the position' do
      pins = pins_for(<<~RUBY)
        class Foo
          class Bar
          end
        end
      RUBY
      position = Solargraph::Position.new(1, 4)
      result = described_class.closure_at(pins, position)
      expect(result.path).to eq('Foo::Bar')
    end
  end

  describe '.process_directive' do
    it 'adds the directive tag types to the enclosing namespace domains' do
      pins = pins_for(<<~RUBY)
        class Foo
        end
      RUBY
      namespace = pins.find { |pin| pin.path == 'Foo' }
      tag = instance_double(YARD::Tags::Tag, types: ['Bar'])
      directive = instance_double(YARD::Tags::Directive, tag: tag)

      result = described_class.process_directive(nil, pins, namespace.location.range.start, nil, directive)

      expect(namespace.domains).to include('Bar')
      expect(result).to eq([])
    end

    it 'falls back to the root pin when no namespace contains the position' do
      pins = pins_for(<<~RUBY)
        class Foo
        end
      RUBY
      tag = instance_double(YARD::Tags::Tag, types: ['Bar'])
      directive = instance_double(YARD::Tags::Directive, tag: tag)

      result = described_class.process_directive(nil, pins, Solargraph::Position.new(100, 0), nil, directive)

      expect(Solargraph::Pin::ROOT_PIN.domains).to include('Bar')
      expect(result).to eq([])
    end
  end
end
