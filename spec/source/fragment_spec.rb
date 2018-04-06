describe Solargraph::Source::Fragment do
  it "detects an instance variable from a fragment" do
    source = Solargraph::Source.load_string('@foo')
    fragment = source.fragment_at(0, 1)
    expect(fragment.word).to eq('@')
  end

  it "detects a whole instance variable from a fragment" do
    source = Solargraph::Source.load_string('@foo')
    fragment = source.fragment_at(0, 1)
    expect(fragment.whole_word).to eq('@foo')
  end

  it "detects a class variable from a fragment" do
    source = Solargraph::Source.load_string('@@foo')
    fragment = source.fragment_at(0, 2)
    expect(fragment.word).to eq('@@')
  end

  it "detects a whole class variable from a fragment" do
    source = Solargraph::Source.load_string('@@foo')
    fragment = source.fragment_at(0, 2)
    expect(fragment.whole_word).to eq('@@foo')
  end

  it "detects a namespace" do
    source = Solargraph::Source.load_string(%(
      class Foo

      end
    ))
    fragment = source.fragment_at(2, 0)
    expect(fragment.namespace).to eq('Foo')
  end

  it "detects a nested namespace" do
    source = Solargraph::Source.load_string(%(
      module Foo
        class Bar

        end
      end
    ))
    fragment = source.fragment_at(3, 0)
    expect(fragment.namespace).to eq('Foo::Bar')
  end

  it "detects a local variable in the global namespace" do
    source = Solargraph::Source.load_string(%(
      foo = bar
    ))
    fragment = source.fragment_at(2, 0)
    expect(fragment.local_variable_pins.length).to eq(1)
    expect(fragment.local_variable_pins.first.name).to eq('foo')
  end

  it "detects a string" do
    source = Solargraph::Source.load_string(%(
      "foo"
    ))
    fragment = source.fragment_at(1, 7)
    expect(fragment.string?).to be(true)
  end

  it "detects an interpolation in a string" do
    source = Solargraph::Source.load_string('
      "#{}"
    ')
    fragment = source.fragment_at(1, 9)
    expect(fragment.string?).to be(false)
  end

  it "detects an interpolation in a mixed string" do
    source = Solargraph::Source.load_string('
      "hello #{}"
    ')
    fragment = source.fragment_at(1, 15)
    expect(fragment.string?).to be(false)
  end

  it "ignores parens and brackets in signatures" do
    source = Solargraph::Source.load_string('
      foo(1).bar{|x|y}.baz()
    ')
    fragment = source.fragment_at(1, 24)
    expect(fragment.signature).to eq('foo.bar.b')
    expect(fragment.whole_signature).to eq('foo.bar.baz')
    expect(fragment.base).to eq('foo.bar')
    expect(fragment.word).to eq('b')
    expect(fragment.whole_word).to eq('baz')
  end

  it "detects a recipient of an argument" do
    source = Solargraph::Source.load_string('abc.def(g)')
    fragment = source.fragment_at(0, 8)
    # expect(fragment.argument?).to be(true)
    expect(fragment.recipient.whole_signature).to eq('abc.def')
  end

  it "detects a recipient of multiple arguments" do
    source = Solargraph::Source.load_string('abc.def(g, h)')
    fragment = source.fragment_at(0, 11)
    # expect(fragment.argument?).to be(true)
    expect(fragment.recipient.whole_signature).to eq('abc.def')
  end
end
