describe Solargraph::CodeMap do
  before :all do
    # Unfinished instance variable at 92
    @ivar_code = %(
      class Foo
        def bar
          @bar = ''
        end
        def baz
          @
        end
      end
    )

    # Unfinished class variable at 93
    @cvar_code = %(
      class Foo
        @cvar = ''
        def bar
          @bar = ''
        end
        @
      end
    )

    # Unfinished variable/method at 111
    @lvar_code = %(
      class Foo
        def bar
          @bar = ''
        end
        def baz
          boo = ''
          b
        end
      end
    )

    @string_code = 'String.new.'
  end

  it "identifies position in def node" do
    code_map = Solargraph::CodeMap.new(code: @ivar_code)
    node = code_map.node_at(92)
    expect(node.type).to eq(:def)
  end

  it "detects instance variables" do
    code_map = Solargraph::CodeMap.new(code: @ivar_code)
    result = code_map.suggest_at(92)
    expect(result.map(&:to_s)).to include('@bar')
  end

  it "identifies position in class node" do
    code_map = Solargraph::CodeMap.new(code: @cvar_code)
    node = code_map.node_at(93)
    expect(node.type).to eq(:class)
  end

  it "detects class variables" do
    code_map = Solargraph::CodeMap.new(code: @cvar_code)
    result = code_map.suggest_at(93)
    expect(result.map(&:to_s)).to include('@cvar')
    expect(result.map(&:to_s)).not_to include('@bar')
  end

  it "detects local variables and instance methods" do
    code_map = Solargraph::CodeMap.new(code: @lvar_code)
    result = code_map.suggest_at(111)
    expect(result.map(&:to_s)).to include('bar')
    expect(result.map(&:to_s)).to include('baz')
    expect(result.map(&:to_s)).to include('boo')
  end
end
