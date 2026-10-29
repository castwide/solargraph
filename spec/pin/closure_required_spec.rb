# frozen_string_literal: true

describe Solargraph::Pin::ClosureRequired do
  let(:location) { Solargraph::Location.new('file.rb', Solargraph::Range.from_to(0, 0, 0, 0)) }

  [
    Solargraph::Pin::LocalVariable, Solargraph::Pin::Parameter, Solargraph::Pin::InstanceVariable,
    Solargraph::Pin::ClassVariable, Solargraph::Pin::GlobalVariable, Solargraph::Pin::Signature,
    Solargraph::Pin::Singleton, Solargraph::Pin::While, Solargraph::Pin::Until,
    Solargraph::Pin::Reference::Include, Solargraph::Pin::Reference::Prepend,
    Solargraph::Pin::Reference::Extend, Solargraph::Pin::Reference::Superclass
  ].each do |klass|
    it "raises on a missing #{klass} closure" do
      pin = klass.new(name: 'Foo', location: location, source: :spec)
      expect { pin.closure }.to raise_error(RuntimeError, /closure/i)
    end
  end

  it 'raises on a missing Reference::TypeAlias closure' do
    pin = Solargraph::Pin::Reference::TypeAlias.new(name: 'Foo', return_type: Solargraph::ComplexType::UNDEFINED,
                                                    location: location, source: :spec)
    expect { pin.closure }.to raise_error(RuntimeError, /closure/i)
  end

  it 'leaves a Constant closure nilable' do
    allow(Solargraph).to receive(:asserts_on?).and_return(false)
    pin = Solargraph::Pin::Constant.new(name: 'Foo', source: :spec)
    expect(pin.closure).to be_nil
  end
end
