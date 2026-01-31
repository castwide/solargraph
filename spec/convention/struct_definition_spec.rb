# frozen_string_literal: true

describe Solargraph::Convention::StructDefinition do
  describe 'parsing docs' do
    it 'supports keyword args' do
      source = Solargraph::SourceMap.load_string(%(
        # @param bar [String]
        # @param baz [Integer]
        Foo = Struct.new(:bar, :baz, keyword_init: true)
      ), 'test.rb')

      # @type [Array<Solargraph::Pin::Parameter>]
      params = source.pins.find { |p| p.path == 'Foo#initialize' }.parameters

      param_bar = params.find { |p| p.name == 'bar' }
      expect(param_bar).not_to be_nil
      expect(param_bar.keyword?).to be(true)
      expect(param_bar.return_type.tag).to eql('String')

      param_baz = params.find { |p| p.name == 'baz' }
      expect(param_baz).not_to be_nil
      expect(param_baz.keyword?).to be(true)
      expect(param_baz.return_type.tag).to eql('Integer')
    end

    it 'sets closure to method on assignment operator parameters' do
      source = Solargraph::SourceMap.load_string(%(
        # @param bar [String]
        # @param baz [Integer]
        Foo = Struct.new(:bar, :baz, keyword_init: true)
      ), 'test.rb')

      # @type [Array<Solargraph::Pin::Parameter>]
      parameters = source.pins.find { |p| p.path == 'Foo#bar=' }.parameters

      parameters.each do |param|
        expect(param.closure).to be_instance_of(Solargraph::Pin::Method)
      end
    end

    it 'supports positional args' do
      source = Solargraph::SourceMap.load_string(%(
        # @param bar [String]
        # @param baz [Integer]
        Foo = Struct.new(:bar, :baz)
      ), 'test.rb')

      # @type [Array<Solargraph::Pin::Parameter>]
      params = source.pins.find { |p| p.path == 'Foo#initialize' }.parameters

      expect(params.map(&:name)).to eql(%w[bar baz])
      expect(params.map(&:arg?)).to eql([true, true])
      expect(params.map(&:return_type).map(&:tag)).to eql(%w[String Integer])
    end

    it 'supports positional args if keyword_init: false' do
      source = Solargraph::SourceMap.load_string(%(
        # @param bar [String]
        # @param baz [Integer]
        Foo = Struct.new(:bar, :baz, keyword_init: false)
      ), 'test.rb')

      # @type [Array<Solargraph::Pin::Parameter>]
      params = source.pins.find { |p| p.path == 'Foo#initialize' }.parameters

      expect(params.map(&:name)).to eql(%w[bar baz])
      expect(params.map(&:arg?)).to eql([true, true])
      expect(params.map(&:return_type).map(&:tag)).to eql(%w[String Integer])
    end

    it 'supports comments on args' do
      source = Solargraph::SourceMap.load_string(%(
        Foo = Struct.new(
          # @return [String]
          :bar,
          # @param baz [Integer] Some text (also with arg name: baz)
          #   Extra indented text :3
          :baz
        )
      ), 'test.rb')

      # @type [Array<Solargraph::Pin::Parameter>]~
      params = source.pins.find { |p| p.path == 'Foo#initialize' }.parameters

      expect(params.map(&:name)).to eql(%w[bar baz])
      expect(params.map(&:return_type).map(&:tag)).to eql(%w[String Integer])
      expect(params[1].documentation).to eql("Some text (also with arg name: baz)\nExtra indented text :3")
    end

    it 'merges struct level comments and attribute level comments' do
      # Note on repetitions: Imo this should stay undefined
      # So if there'd be a @return statement on the bar attribute, I'd not sweat it

      source = Solargraph::SourceMap.load_string(%(
        # @param baz [String] Some text
        Foo = Struct.new(
          # @return [Integer]
          :bar,
          :baz
        )
      ), 'test.rb')

      # @type [Array<Solargraph::Pin::Parameter>]
      params = source.pins.find { |p| p.path == 'Foo#initialize' }.parameters

      expect(params.map(&:name)).to eql(%w[bar baz])
      expect(params.map(&:return_type).map(&:tag)).to eql(%w[Integer String])
      expect(params[1].documentation).to eql('Some text')
    end

    [true, false].each do |kw_args|
      it "supports assignment with #{kw_args ? 'keyword' : 'positional'} arg mode" do
        # Both positional & kwargs init mode should act the same for assignment

        source = Solargraph::SourceMap.load_string(%(
          # @param bar [String]
          # @param baz [Integer]
          Foo = Struct.new(:bar, :baz, keyword_init: #{kw_args})
        ), 'test.rb')

        params_bar = source.pins.find { |p| p.path == 'Foo#bar=' }.parameters
        expect(params_bar.length).to be(1)
        expect(params_bar.first.return_type.tag).to eql('String')
        expect(params_bar.first.arg?).to be(true)

        params_baz = source.pins.find { |p| p.path == 'Foo#baz=' }.parameters
        expect(params_baz.length).to be(1)
        expect(params_baz.first.return_type.tag).to eql('Integer')
        expect(params_baz.first.arg?).to be(true)

        iv_bar = source.pins.find { |p| p.name == '@bar' }
        expect(iv_bar.return_type.tag).to eql('String')

        iv_baz = source.pins.find { |p| p.name == '@baz' }
        expect(iv_baz.return_type.tag).to eql('Integer')
      end
    end
  end

  context 'with typechecking' do
    def type_checker code
      Solargraph::TypeChecker.load_string(code, 'test.rb', :strong)
    end

    it "doesn't crash" do
      checker = type_checker(%(
        Foo = Struct.new(:bar, :baz)
      ))
      expect { checker.problems }.not_to raise_error
    end
  end
end
