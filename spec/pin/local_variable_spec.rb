describe Solargraph::Pin::LocalVariable do
  xit "merges presence changes so that [not currently used]" do
    map1 = Solargraph::SourceMap.load_string(%(
      class Foo
        foo = 'foo'
        @foo = foo
      end
    ))
    pin1 = map1.locals.first
    expect(pin1.presence.start.to_hash).to eq({ line: 2, character: 8 })
    expect(pin1.presence.ending.to_hash).to eq({ line: 4, character: 9 })

    map2 = Solargraph::SourceMap.load_string(%(
      class Foo
        @more = 'more'
        foo = 'foo'
        @foo = foo
      end
    ))
    pin2 = map2.locals.first
    expect(pin2.presence.start.to_hash).to eq({ line: 3, character: 8 })
    expect(pin2.presence.ending.to_hash).to eq({ line: 5, character: 9 })

    with_env_var('SOLARGRAPH_ASSERTS', 'on') do
      expect(Solargraph.asserts_on?).to be true
      expect { pin1.combine_with(pin2) }.to raise_error(RuntimeError, /Inconsistent :closure name/)
    end


    expect(combined.source).to eq(:combined)
    # no choice behavior defined yet - if/when this is to be used, we
    # should indicate which one should override in the range situation
  end

  describe '#visible_at?' do
    it 'detects scoped methods in rebound blocks' do
      source = Solargraph::Source.load_string(%(
        object = MyClass.new
        object
      ), 'test.rb')
      api_map = Solargraph::ApiMap.new
      api_map.map source
      clip = api_map.clip_at('test.rb', [2, 0])
      object_pin = api_map.source_map('test.rb').locals.find { |p| p.name == 'object' }
      expect(object_pin).not_to be_nil
      location = Solargraph::Location.new('test.rb', Solargraph::Range.from_to(2, 0, 2, 0))
      expect(object_pin.visible_at?(Solargraph::Pin::ROOT_PIN, location)).to be true
    end

    it 'does not allow access to top-level locals from top-level methods' do
      map = Solargraph::SourceMap.load_string(%(
        x = 'string'
        def foo
          x
        end
      ), 'test.rb')
      api_map = Solargraph::ApiMap.new
      api_map.map map.source
      x_pin = api_map.source_map('test.rb').locals.find { |p| p.name == 'x' }
      expect(x_pin).not_to be_nil
      foo_pin = api_map.get_path_pins('#foo').first
      expect(foo_pin).not_to be_nil
      location = Solargraph::Location.new('test.rb', Solargraph::Range.from_to(3, 9, 3, 9))
      expect(x_pin.visible_at?(foo_pin, location)).to be false
    end

    it 'scopes local variables correctly in class_eval blocks' do
      map = Solargraph::SourceMap.load_string(%(
        class Foo; end
        x = 'y'
        Foo.class_eval do
          foo = :bar
          etc
        end
      ), 'test.rb')
      api_map = Solargraph::ApiMap.new
      api_map.map map.source
      block_pin = api_map.get_block_pins.find do |b|
        b.location.range.start.line == 3
      end
      expect(block_pin).not_to be_nil
      x_pin = api_map.source_map('test.rb').locals.find { |p| p.name == 'x' }
      expect(x_pin).not_to be_nil
      location = Solargraph::Location.new('test.rb', Solargraph::Range.from_to(5, 10, 5, 10))
      expect(x_pin.visible_at?(block_pin, location)).to be true
    end

    it "understands local lookup in root scope" do
      api_map = Solargraph::ApiMap.new
      source = Solargraph::Source.load_string(%(
        # @type [Array<String>]
        arr = []


      ), "test.rb")
      api_map.map source
      arr_pin = api_map.source_map('test.rb').locals.find { |p| p.name == 'arr' }
      expect(arr_pin).not_to be_nil
      location = Solargraph::Location.new('test.rb', Solargraph::Range.from_to(3, 0, 3, 0))
      expect(arr_pin.visible_at?(Solargraph::Pin::ROOT_PIN, location)).to be true
    end

    it 'selects local variables using gated scopes' do
      source = Solargraph::Source.load_string(%(
        lvar1 = 'lvar1'
        module MyModule
          lvar2 = 'lvar2'

       end
      ), 'test.rb')
      api_map = Solargraph::ApiMap.new
      api_map.map source
      lvar1_pin = api_map.source_map('test.rb').locals.find { |p| p.name == 'lvar1' }
      expect(lvar1_pin).not_to be_nil
      my_module_pin = api_map.get_namespace_pins('MyModule', 'Class<>').first
      expect(my_module_pin).not_to be_nil
      location = Solargraph::Location.new('test.rb', Solargraph::Range.from_to(4, 0, 4, 0))
      expect(lvar1_pin.visible_at?(my_module_pin, location)).to be false

      lvar2_pin = api_map.source_map('test.rb').locals.find { |p| p.name == 'lvar2' }
      expect(lvar2_pin).not_to be_nil
      expect(lvar2_pin.visible_at?(my_module_pin, location)).to be true
    end

    it 'is visible within same method' do
      source = Solargraph::Source.load_string(%(
          class Foo
            def bar
                x = 1
                puts x
            end
          end
        ), 'test.rb')
      api_map = Solargraph::ApiMap.new
      api_map.map source
      pin = api_map.source_map('test.rb').locals.first
      bar_method = api_map.get_path_pins('Foo#bar').first
      expect(bar_method).not_to be_nil
      range = Solargraph::Range.from_to(4, 16, 4, 17)
      location = Solargraph::Location.new('test.rb', range)
      expect(pin.visible_at?(bar_method, location)).to be true
    end

    it 'is visible within each block scope inside function' do
        source = Solargraph::Source.load_string(%(
            class Foo
                def bar
                    x = 1
                    [2,3,4].each do |i|
                        puts x + i
                    end
                end
            end
          ), 'test.rb')
        api_map = Solargraph::ApiMap.new
        api_map.map source
        x = api_map.source_map('test.rb').locals.find { |p| p.name == 'x' }
        bar_method = api_map.get_path_pins('Foo#bar').first
        each_block_pin = api_map.get_block_pins.find do |b|
          b.location.range.start.line == 4
        end
        expect(each_block_pin).not_to be_nil
        range = Solargraph::Range.from_to(5, 24, 5, 25)
        location = Solargraph::Location.new('test.rb', range)
        expect(x.visible_at?(each_block_pin, location)).to be true
    end

    it 'sees block parameter inside block' do
      source = Solargraph::Source.load_string(%(
            class Foo
                def bar
                    [1,2,3].each do |i|
                        puts i
                    end
                end
            end
      ), 'test.rb')
      api_map = Solargraph::ApiMap.new
      api_map.map source
      i = api_map.source_map('test.rb').locals.find { |p| p.name == 'i' }
      bar_method = api_map.get_path_pins('Foo#bar').first
      expect(bar_method).not_to be_nil
      each_block_pin = api_map.get_block_pins.find do |b|
        b.location.range.start.line == 3
      end
      expect(each_block_pin).not_to be_nil
      range = Solargraph::Range.from_to(4, 24, 4, 25)
      location = Solargraph::Location.new('test.rb', range)
      expect(i.visible_at?(each_block_pin, location)).to be true
    end
  end
end
