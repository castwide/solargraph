require 'tmpdir'

describe Solargraph::CodeMap do
  before :all do
    @workspace = Dir.mktmpdir
    @filename = "#{@workspace}/test.rb"

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
    # Instance variable assignment at 63
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

    # Type tag
    @type_tag = %(
# @type [String]
my_var = some_method_call
my_var.
    )

    # Nested class
    @nested = %(
      class Foo
        class Bar
        end
      end
      Foo::Bar.
    )

    # Class variable 48/50
    @classvar = %(
      class Foo
        @@var = ''
        @@var.a
      end
    )
  end

  after :all do
    FileUtils.remove_entry @workspace
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

  it "detects class variables" do
    code_map = Solargraph::CodeMap.new(code: @classvar)
    result = code_map.suggest_at(48)
    expect(result.map(&:to_s)).to include('@@var')
  end

  it "detects local variables and instance methods" do
    code_map = Solargraph::CodeMap.new(code: @lvar_code)
    result = code_map.suggest_at(111)
    expect(result.map(&:to_s)).to include('bar')
    expect(result.map(&:to_s)).to include('baz')
    expect(result.map(&:to_s)).to include('boo')
  end

  it "gets instance methods for literals" do
    code_map = Solargraph::CodeMap.new(code: "'string'.")
    result = code_map.suggest_at(9)
    expect(result.map(&:to_s)).to include('upcase')
  end

  it "stubs unfinished instance variables" do
    code_map = Solargraph::CodeMap.new(code: "puts @")
    expect(code_map.parsed).to eq("puts _")
  end

  it "stubs unfinished symbols" do
    code_map = Solargraph::CodeMap.new(code: "symbol :")
    expect(code_map.parsed).to eq("symbol _")
  end

  it "adds missing end keyword" do
    code_map = Solargraph::CodeMap.new(code: "if true\nString.\nend")
    expect(code_map.parsed).to eq("if true\nString.\nend;end")
  end

  it "stubs extra end keyword" do
    code_map = Solargraph::CodeMap.new(code: "if true\nend\nend")
    # @hack CodeMap tries to add an end on the first pass. Thus, the result
    # of the parse has "#nd;end" instead of "#nd"
    expect(code_map.parsed).to eq("if true\nend\n#nd;end")
  end

  it "resolves signatures to documentation" do
    code_map = Solargraph::CodeMap.new(code: "x = [];x.join")
    suggestions = code_map.resolve_object_at(12)
    expect(suggestions.length).to eq(1)
    expect(suggestions[0].path).to eq('Array#join')
  end

  it "detects variable types from @type tags" do
    code_map = Solargraph::CodeMap.new(code: @type_tag)
    sugg = code_map.suggest_at(51)
    expect(sugg.map{ |s| s.label }).to include('upcase')
    sugg = code_map.resolve_object_at(49)
    expect(sugg[0].path).to eq('String')
  end

  it "infers the type of an instance variable" do
    code_map = Solargraph::CodeMap.new(code: @cvar_code)
    sugg = code_map.resolve_object_at(63)
    expect(sugg.length).to eq(1)
    expect(sugg[0].path).to eq('String')
  end

  it "detects a nested class name" do
    code_map = Solargraph::CodeMap.new(code: @nested)
    sugg = code_map.suggest_at(69)
    expect(sugg.map(&:to_s)).to include('Bar')
  end

  it "detects a nested class method" do
    code_map = Solargraph::CodeMap.new(code: @nested)
    sugg = code_map.suggest_at(72)
    expect(sugg.map(&:to_s)).to include('new')
  end

  it "accepts a filename without a workspace" do
    code_map = Solargraph::CodeMap.new(code: @ivar_code, filename: @filename)
    expect(code_map.filename).to eq(@filename)
    expect(code_map.workspace).to be(nil)
  end

  it "accepts a workspace without a filename" do
    code_map = Solargraph::CodeMap.new(code: @ivar_code, workspace: @workspace)
    expect(code_map.filename).to be(nil)
    expect(code_map.workspace).to eq(@workspace)
  end

  it "accepts a workspace and a filename" do
    code_map = Solargraph::CodeMap.new(code: @ivar_code, workspace: @workspace, filename: @filename)
    expect(code_map.filename).to eq(@filename)
    expect(code_map.workspace).to eq(@workspace)
  end
end
