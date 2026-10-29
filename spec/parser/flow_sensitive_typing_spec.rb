# frozen_string_literal: true

# @todo These tests depend on `Clip`, but we're putting the tests here to
#   avoid overloading clip_spec.rb.
describe Solargraph::Parser::FlowSensitiveTyping do
  it 'uses is_a? in a simple if() to refine types' do
    source = Solargraph::Source.load_string(%(
      class ReproBase; end
      class Repro < ReproBase; end
      # @param repr [ReproBase]
      def verify_repro(repr)
        if repr.is_a?(Repro)
          repr
        else
          repr
        end
      end
  ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [6, 10])
    expect(clip.infer.to_s).to eq('Repro')

    clip = api_map.clip_at('test.rb', [8, 10])
    expect(clip.infer.to_s).to eq('ReproBase')
  end

  it 'uses is_a? in a simple if() with a union to refine types' do
    source = Solargraph::Source.load_string(%(
      class ReproBase; end
      class Repro1 < ReproBase; end
      class Repro2 < ReproBase; end
      # @param repr [Repro1, Repro2]
      def verify_repro(repr)
        if repr.is_a?(Repro1)
          repr
        else
          repr
        end
      end
  ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [7, 10])
    expect(clip.infer.to_s).to eq('Repro1')

    clip = api_map.clip_at('test.rb', [9, 10])
    expect(clip.infer.to_s).to eq('Repro2')
  end

  it 'uses is_a? in a simple if() to refine types on a module-scoped class' do
    source = Solargraph::Source.load_string(%(
      class ReproBase; end
      module Foo
        class Repro < ReproBase; end
      end
      # @param repr [ReproBase]
      def verify_repro(repr)
        if repr.is_a?(Foo::Repro)
          repr
        else
          repr
        end
      end
  ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [8, 10])
    expect(clip.infer.to_s).to eq('Foo::Repro')

    clip = api_map.clip_at('test.rb', [10, 10])
    expect(clip.infer.to_s).to eq('ReproBase')
  end

  it 'uses is_a? in a simple if() to refine types on a double-module-scoped class' do
    source = Solargraph::Source.load_string(%(
      class ReproBase; end
      module Foo
        module Bar
          class Repro < ReproBase; end
        end
      end
      # @param repr [ReproBase]
      def verify_repro(repr)
        if repr.is_a?(Foo::Bar::Repro)
          repr
        else
          repr
        end
      end
  ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [10, 10])
    expect(clip.infer.to_s).to eq('Foo::Bar::Repro')

    clip = api_map.clip_at('test.rb', [12, 10])
    expect(clip.infer.to_s).to eq('ReproBase')
  end

  it 'uses is_a? in a simple unless statement to refine types' do
    source = Solargraph::Source.load_string(%(
      class ReproBase; end
      class Repro < ReproBase; end
      # @param repr [ReproBase]
      def verify_repro(repr)
        unless repr.is_a?(Repro)
          repr
        else
          repr
        end
      end
  ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [6, 10])
    expect(clip.infer.to_s).to eq('ReproBase')

    clip = api_map.clip_at('test.rb', [8, 10])
    expect(clip.infer.to_s).to eq('Repro')
  end

  it 'uses is_a? in an if-then-else() to refine types' do
    source = Solargraph::Source.load_string(%(
      class ReproBase; end
      class Repro1 < ReproBase; end
      # @param repr [ReproBase]
      def verify_repro(repr)
        if repr.is_a?(Repro1)
          repr
        else
          repr
        end
      end
  ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [6, 10])
    expect(clip.infer.to_s).to eq('Repro1')

    clip = api_map.clip_at('test.rb', [8, 10])
    expect(clip.infer.to_s).to eq('ReproBase')
  end

  it 'uses is_a? in a if-then-elsif-else() to refine types' do
    source = Solargraph::Source.load_string(%(
      class ReproBase; end
      class Repro1 < ReproBase; end
      class Repro2 < ReproBase; end
      # @param repr [ReproBase]
      def verify_repro(repr)
        if repr.is_a?(Repro1)
          repr
        elsif repr.is_a?(Repro2)
          repr
        else
          repr
        end
      end
  ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [7, 10])
    expect(clip.infer.to_s).to eq('Repro1')

    clip = api_map.clip_at('test.rb', [9, 10])
    expect(clip.infer.to_s).to eq('Repro2')

    clip = api_map.clip_at('test.rb', [11, 10])
    expect(clip.infer.to_s).to eq('ReproBase')
  end

  it 'uses is_a? in a "break unless" statement in an .each block to refine types' do
    source = Solargraph::Source.load_string(%(
      class ReproBase; end
      class Repro < ReproBase; end
      # @type [Array<ReproBase>]
      foo = bar
      foo.each do |value|
        break unless value.is_a? Repro
        value
      end
  ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [7, 8])
    expect(clip.infer.to_s).to eq('Repro')
  end

  it 'uses is_a? in a "break unless" statement in an until to refine types' do
    source = Solargraph::Source.load_string(%(
      class ReproBase; end
      class Repro < ReproBase; end
      # @type [ReproBase]
      value = bar
      until is_done()
        break unless value.is_a? Repro
        value
      end
  ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [7, 8])
    expect(clip.infer.to_s).to eq('Repro')
  end

  it 'uses is_a? in a "break unless" statement in a while to refine types' do
    source = Solargraph::Source.load_string(%(
      class ReproBase; end
      class Repro < ReproBase; end
      # @type [ReproBase]
      value = bar
      while !is_done()
        break unless value.is_a? Repro
        value
      end
  ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [7, 8])
    expect(clip.infer.to_s).to eq('Repro')
  end

  it 'uses unless is_a? in a ".each" block to refine types' do
    source = Solargraph::Source.load_string(%(
      # @type [Array<Numeric>]
      arr = [1, 2, 4, 4.5]
      arr
      arr.each do |value|
        value
        break unless value.is_a? Float

        value
      end
  ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [3, 6])
    expect(clip.infer.to_s).to eq('Array<Numeric>')

    clip = api_map.clip_at('test.rb', [5, 8])
    expect(clip.infer.to_s).to eq('Numeric')

    clip = api_map.clip_at('test.rb', [7, 8])
    expect(clip.infer.to_s).to eq('Float')
  end

  it 'uses varname in a simple if()' do
    source = Solargraph::Source.load_string(%(
      # @param repr [Integer, nil]
      # @param throw_the_dice [Boolean]
      def verify_repro(repr, throw_the_dice)
        repr
        if repr
          repr
        else
          repr
        end
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [4, 8])
    expect(clip.infer.rooted_tags).to eq('::Integer, nil')

    clip = api_map.clip_at('test.rb', [6, 10])
    expect(clip.infer.rooted_tags).to eq('::Integer')

    clip = api_map.clip_at('test.rb', [8, 10])
    expect(clip.infer.rooted_tags).to eq('nil')
  end

  it 'uses varname in a "break unless" statement in a while to refine types' do
    source = Solargraph::Source.load_string(%(
      class ReproBase; end
      class Repro < ReproBase; end
      # @type [ReproBase, nil]
      value = bar
      while !is_done()
        break unless value
        value
      end
  ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [7, 8])
    expect(clip.infer.to_s).to eq('ReproBase')
  end

  it 'uses varname in a "break if" statement in a while to refine types' do
    source = Solargraph::Source.load_string(%(
      class ReproBase; end
      class Repro < ReproBase; end
      # @type [ReproBase, nil]
      value = bar
      while !is_done()
        break if value.nil?
        value
      end
  ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [7, 8])
    expect(clip.infer.to_s).to eq('ReproBase')
  end

  it 'understands compatible reassignments' do
    source = Solargraph::Source.load_string(%(
      class Foo
        # @return [Foo]
        def baz; end
      end
      bar = Foo.new
      bar
      bar = Foo.new
      bar
  ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [6, 6])
    expect(clip.infer.to_s).to eq('Foo')

    clip = api_map.clip_at('test.rb', [8, 6])
    expect(clip.infer.to_s).to eq('Foo')
  end

  it 'skips is_a? without a receiver' do
    source = Solargraph::Source.load_string(%(
    if is_a? Object
      x
    end
  ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [2, 6])
    expect { clip.infer.to_s }.not_to raise_error
  end

  it 'handles is_a? with a receiver and no argument' do
    source = Solargraph::Source.load_string(%(
    r = '1'
    if r.is_a?
      x
    end
  ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [3, 6])
    expect { clip.infer.to_s }.not_to raise_error
  end

  it 'uses nil? in a simple if() to refine nilness' do
    source = Solargraph::Source.load_string(%(
      # @param repr [Integer, nil]
      def verify_repro(repr)
        repr = 10 if floop
        repr
        if repr.nil?
          repr
        else
          repr
        end
      end
  ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [4, 8])
    expect(clip.infer.rooted_tags).to eq('::Integer, nil')

    clip = api_map.clip_at('test.rb', [6, 10])
    expect(clip.infer.rooted_tags).to eq('nil')

    clip = api_map.clip_at('test.rb', [8, 10])
    expect(clip.infer.rooted_tags).to eq('::Integer')
  end

  it 'uses nil? and && in a simple if() to refine nilness - nil? first' do
    source = Solargraph::Source.load_string(%(
      # @param repr [Integer, nil]
      # @param throw_the_dice [Boolean]
      def verify_repro(repr, throw_the_dice)
        repr
        if repr.nil? && throw_the_dice
          repr
        else
          repr
        end
      end
  ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [4, 8])
    expect(clip.infer.rooted_tags).to eq('::Integer, nil')

    clip = api_map.clip_at('test.rb', [6, 10])
    expect(clip.infer.rooted_tags).to eq('nil')

    clip = api_map.clip_at('test.rb', [8, 10])
    expect(clip.infer.rooted_tags).to eq('::Integer, nil')
  end

  it 'uses nil? and && in a simple if() to refine nilness - nil? second' do
    source = Solargraph::Source.load_string(%(
      # @param repr [Integer, nil]
      # @param throw_the_dice [Boolean]
      def verify_repro(repr, throw_the_dice)
        repr
        if throw_the_dice && repr.nil?
          repr
        else
          repr
        end
      end
  ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [4, 8])
    expect(clip.infer.rooted_tags).to eq('::Integer, nil')

    clip = api_map.clip_at('test.rb', [6, 10])
    expect(clip.infer.rooted_tags).to eq('nil')

    clip = api_map.clip_at('test.rb', [8, 10])
    expect(clip.infer.rooted_tags).to eq('::Integer, nil')
  end

  it 'uses nil? and || in a simple if() - nil? first' do
    source = Solargraph::Source.load_string(%(
      # @param repr [Integer, nil]
      # @param throw_the_dice [Boolean]
      def verify_repro(repr, throw_the_dice)
        repr
        if repr.nil? || throw_the_dice
          repr
        else
          repr
        end
      end
  ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [4, 8])
    expect(clip.infer.rooted_tags).to eq('::Integer, nil')

    clip = api_map.clip_at('test.rb', [6, 10])
    expect(clip.infer.rooted_tags).to eq('::Integer, nil')

    clip = api_map.clip_at('test.rb', [8, 10])
    expect(clip.infer.rooted_tags).to eq('::Integer')
  end

  it 'uses nil? and || in a simple if() - nil? second' do
    source = Solargraph::Source.load_string(%(
      # @param repr [Integer, nil]
      # @param throw_the_dice [Boolean]
      def verify_repro(repr, throw_the_dice)
        repr
        if throw_the_dice || repr.nil?
          repr
        else
          repr
        end
      end
  ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [4, 8])
    expect(clip.infer.rooted_tags).to eq('::Integer, nil')

    clip = api_map.clip_at('test.rb', [6, 10])
    expect(clip.infer.rooted_tags).to eq('::Integer, nil')

    clip = api_map.clip_at('test.rb', [8, 10])
    expect(clip.infer.rooted_tags).to eq('::Integer')
  end

  it 'uses varname and || in a simple if() - varname first' do
    source = Solargraph::Source.load_string(%(
      # @param repr [Integer, nil]
      # @param throw_the_dice [Boolean]
      def verify_repro(repr, throw_the_dice)
        repr
        if repr || throw_the_dice
          repr
        else
          repr
        end
      end
  ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [4, 8])
    expect(clip.infer.rooted_tags).to eq('::Integer, nil')

    clip = api_map.clip_at('test.rb', [6, 10])
    expect(clip.infer.rooted_tags).to eq('::Integer, nil')

    clip = api_map.clip_at('test.rb', [8, 10])
    expect(clip.infer.rooted_tags).to eq('nil')
  end

  it 'uses varname and || in a simple if() - varname second' do
    source = Solargraph::Source.load_string(%(
      # @param repr [Integer, nil]
      # @param throw_the_dice [Boolean]
      def verify_repro(repr, throw_the_dice)
        repr
        if throw_the_dice || repr
          repr
        else
          repr
        end
      end
  ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [4, 8])
    expect(clip.infer.rooted_tags).to eq('::Integer, nil')

    clip = api_map.clip_at('test.rb', [6, 10])
    expect(clip.infer.rooted_tags).to eq('::Integer, nil')

    clip = api_map.clip_at('test.rb', [8, 10])
    expect(clip.infer.rooted_tags).to eq('nil')
  end

  it 'uses .nil? and or in an unless' do
    source = Solargraph::Source.load_string(%(
      # @param repr [String, nil]
      # @param throw_the_dice [Boolean]
      def verify_repro(repr)
        repr unless repr.nil? || repr.downcase
        repr
      end
  ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [4, 33])
    expect(clip.infer.rooted_tags).to eq('::String')

    clip = api_map.clip_at('test.rb', [4, 8])
    expect(clip.infer.rooted_tags).to eq('::String')

    clip = api_map.clip_at('test.rb', [5, 8])
    expect(clip.infer.rooted_tags).to eq('::String, nil')
  end

  it 'uses varname and && in a simple if() - varname first' do
    source = Solargraph::Source.load_string(%(
      # @param repr [Integer, nil]
      # @param throw_the_dice [Boolean]
      def verify_repro(repr, throw_the_dice)
        repr
        if repr && throw_the_dice
          repr
        else
          repr
        end
      end
  ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [4, 8])
    expect(clip.infer.rooted_tags).to eq('::Integer, nil')

    clip = api_map.clip_at('test.rb', [6, 10])
    expect(clip.infer.rooted_tags).to eq('::Integer')

    clip = api_map.clip_at('test.rb', [8, 10])
    expect(clip.infer.rooted_tags).to eq('::Integer, nil')
  end

  it 'uses varname and && in a simple if() - varname second' do
    source = Solargraph::Source.load_string(%(
      # @param repr [Integer, nil]
      # @param throw_the_dice [Boolean]
      def verify_repro(repr, throw_the_dice)
        repr
        if throw_the_dice && repr
          repr
        else
          repr
        end
      end
  ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [4, 8])
    expect(clip.infer.rooted_tags).to eq('::Integer, nil')

    clip = api_map.clip_at('test.rb', [6, 10])
    expect(clip.infer.rooted_tags).to eq('::Integer')

    clip = api_map.clip_at('test.rb', [8, 10])
    expect(clip.infer.rooted_tags).to eq('::Integer, nil')
  end

  it 'uses variable in a simple if() to refine types' do
    source = Solargraph::Source.load_string(%(
      # @param repr [Integer, nil]
      def verify_repro(repr)
        repr = 10 if floop
        repr
        if repr
          repr
        else
          repr
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [4, 8])
    expect(clip.infer.rooted_tags).to eq('::Integer, nil')

    clip = api_map.clip_at('test.rb', [6, 10])
    expect(clip.infer.rooted_tags).to eq('::Integer')

    clip = api_map.clip_at('test.rb', [8, 10])
    expect(clip.infer.rooted_tags).to eq('nil')
  end

  it 'uses variable in a simple if() to refine types using nil checks' do
    source = Solargraph::Source.load_string(%(
      def verify_repro(repr = nil)
        repr = 10 if floop
        repr
        if repr
          repr
        else
          repr
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [3, 8])
    expect(clip.infer.rooted_tags).to eq('nil, ::Integer')

    clip = api_map.clip_at('test.rb', [5, 10])
    expect(clip.infer.rooted_tags).to eq('::Integer')

    clip = api_map.clip_at('test.rb', [7, 10])
    # @todo `false` might be acceptable here
    expect(clip.infer.rooted_tags).to eq('nil, ::Boolean')
  end

  it 'uses .nil? in a return if() in an if to refine types using nil checks' do
    source = Solargraph::Source.load_string(%(
      class Foo
        # @param baz [::Boolean, nil]
        # @return [void]
        def bar(baz: nil)
          if rand
            return if baz.nil?
            baz
          end
          baz
        end
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [7, 12])
    expect(clip.infer.rooted_tags).to eq('::Boolean')
  end

  # https://cse.buffalo.edu/~regan/cse305/RubyBNF.pdf
  # https://ruby-doc.org/docs/ruby-doc-bundle/Manual/man-1.4/syntax.html
  it 'uses .nil? in a return if() in a method to refine types using nil checks' do
    source = Solargraph::Source.load_string(%(
      class Foo
        # @param baz [::Boolean, nil]
        # @return [void]
        def bar(baz: nil)
          return if baz.nil?
          baz
        end
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [6, 10])
    expect(clip.infer.rooted_tags).to eq('::Boolean')
  end

  it 'uses .nil? in a return if() in a block to refine types using nil checks' do
    source = Solargraph::Source.load_string(%(
      class Foo
        # @param baz [::Boolean, nil]
        # @param arr [Array<Integer>]
        # @return [void]
        def bar(arr, baz: nil)
          baz
          arr.each do |item|
            return if baz.nil?
            baz
          end
          baz
        end
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [6, 10])
    expect(clip.infer.rooted_tags).to eq('::Boolean, nil')

    clip = api_map.clip_at('test.rb', [9, 12])
    expect(clip.infer.rooted_tags).to eq('::Boolean')

    clip = api_map.clip_at('test.rb', [11, 10])
    expect(clip.infer.rooted_tags).to eq('::Boolean, nil')
  end

  it 'uses .nil? in a return if() in an unless to refine types using nil checks' do
    source = Solargraph::Source.load_string(%(
      class Foo
        # @param baz [::Boolean, nil]
        # @return [void]
        def bar(baz: nil)
          baz
          unless rand
            return if baz.nil?
            baz
          end
          baz
        end
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [5, 10])
    expect(clip.infer.rooted_tags).to eq('::Boolean, nil')

    clip = api_map.clip_at('test.rb', [8, 12])
    expect(clip.infer.rooted_tags).to eq('::Boolean')

    clip = api_map.clip_at('test.rb', [10, 10])
    expect(clip.infer.rooted_tags).to eq('::Boolean, nil')
  end

  it 'uses .nil? in a return if() in a while to refine types using nil checks' do
    source = Solargraph::Source.load_string(%(
      class Foo
        # @param baz [::Boolean, nil]
        # @return [void]
        def bar(baz: nil)
          while rand do
            return if baz.nil?
            baz
          end
          baz
        end
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [7, 12])
    expect(clip.infer.rooted_tags).to eq('::Boolean')

    clip = api_map.clip_at('test.rb', [9, 10])
    expect(clip.infer.rooted_tags).to eq('::Boolean, nil')
  end

  it 'uses foo in a a while to refine types using nil checks' do
    source = Solargraph::Source.load_string(%(
      class Foo
        # @param baz [::Boolean, nil]
        # @param other [::Boolean, nil]
        # @return [void]
        def bar(baz: nil, other: nil)
          baz
          while baz do
            baz
            baz = other
          end
          baz
        end
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [6, 10])
    expect(clip.infer.rooted_tags).to eq('::Boolean, nil')

    clip = api_map.clip_at('test.rb', [8, 12])
    expect(clip.infer.rooted_tags).to eq('::Boolean')

    clip = api_map.clip_at('test.rb', [11, 10])
    expect(clip.infer.rooted_tags).to eq('::Boolean, nil')
  end

  it 'uses .nil? in a return if() in an until to refine types using nil checks' do
    source = Solargraph::Source.load_string(%(
      class Foo
        # @param baz [::Boolean, nil]
        # @return [void]
        def bar(baz: nil)
          until rand do
            return if baz.nil?
            baz
          end
          baz
        end
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [7, 12])
    expect(clip.infer.rooted_tags).to eq('::Boolean')

    clip = api_map.clip_at('test.rb', [9, 10])
    expect(clip.infer.rooted_tags).to eq('::Boolean, nil')
  end

  it 'uses .nil? in a return if() in a switch/case/else to refine types using nil checks' do
    source = Solargraph::Source.load_string(%(
      class Foo
        # @param baz [::Boolean, nil]
        # @return [void]
        def bar(baz: nil)
          case rand
          when 0..0.5
            return if baz.nil?
            baz
          else
            baz
          end
          baz
        end
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [8, 12])
    expect(clip.infer.rooted_tags).to eq('::Boolean')

    clip = api_map.clip_at('test.rb', [10, 12])
    expect(clip.infer.rooted_tags).to eq('::Boolean, nil')

    clip = api_map.clip_at('test.rb', [12, 10])
    expect(clip.infer.rooted_tags).to eq('::Boolean, nil')
  end

  it 'uses .nil? in a return if() in a ternary operator to refine types using nil checks' do
    source = Solargraph::Source.load_string(%(
      class Foo
        # @param baz [::Boolean, nil]
        # @return [void]
        def bar(baz: nil)
          baz
          rand > 0.5 ? (return if baz.nil?; baz) : baz
          baz
        end
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [5, 10])
    expect(clip.infer.rooted_tags).to eq('::Boolean, nil')

    clip = api_map.clip_at('test.rb', [6, 44])
    expect(clip.infer.rooted_tags).to eq('::Boolean')

    clip = api_map.clip_at('test.rb', [6, 51])
    expect(clip.infer.rooted_tags).to eq('::Boolean, nil')

    clip = api_map.clip_at('test.rb', [7, 10])
    expect(clip.infer.rooted_tags).to eq('::Boolean, nil')
  end

  it 'uses .nil? in a return if() in a begin/end to refine types using nil checks' do
    source = Solargraph::Source.load_string(%(
      class Foo
        # @param baz [::Boolean, nil]
        # @return [void]
        def bar(baz: nil)
          baz
          begin
            return if baz.nil?
            baz
          end
          baz
        end
      end
        ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)

    clip = api_map.clip_at('test.rb', [5, 10])
    expect(clip.infer.rooted_tags).to eq('::Boolean, nil')

    clip = api_map.clip_at('test.rb', [8, 12])
    expect(clip.infer.rooted_tags).to eq('::Boolean')

    clip = api_map.clip_at('test.rb', [10, 10])
    expect(clip.infer.rooted_tags).to eq('::Boolean')
  end

  it 'uses .nil? in a return if() in a ||= to refine types using nil checks' do
    source = Solargraph::Source.load_string(%(
      class Foo
        # @param baz [::Boolean, nil]
        # @return [void]
        def bar(baz: nil)
          baz
          baz ||= begin
            return if baz.nil?
            baz
          end
          baz
        end
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [5, 10])
    expect(clip.infer.rooted_tags).to eq('::Boolean, nil')

    clip = api_map.clip_at('test.rb', [8, 12])
    expect(clip.infer.rooted_tags).to eq('::Boolean')

    clip = api_map.clip_at('test.rb', [10, 10])
    expect(clip.infer.rooted_tags).to eq('::Boolean')
  end

  it 'uses .nil? in a return if() in a try / rescue / ensure to refine types using nil checks' do
    source = Solargraph::Source.load_string(%(
      class Foo
        # @param baz [::Boolean, nil]
        # @return [void]
        def bar(baz: nil)
          baz
          begin
            return if baz.nil?
            baz
          rescue StandardError
            baz
          ensure
            baz
          end
          baz
        end
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [5, 10])
    expect(clip.infer.rooted_tags).to eq('::Boolean, nil')

    clip = api_map.clip_at('test.rb', [8, 12])
    expect(clip.infer.rooted_tags).to eq('::Boolean')

    clip = api_map.clip_at('test.rb', [10, 12])
    expect(clip.infer.rooted_tags).to eq('::Boolean')

    pending('better scoping of return if in begin/rescue/ensure')

    clip = api_map.clip_at('test.rb', [12, 12])
    expect(clip.infer.rooted_tags).to eq('::Boolean, nil')

    clip = api_map.clip_at('test.rb', [14, 10])
    expect(clip.infer.rooted_tags).to eq('::Boolean, nil')
  end

  it 'provides a useful pin after a return if .nil?' do
    source = Solargraph::Source.load_string(%(
      class A
        # @param b [Hash{String => String}]
        # @return [void]
        def a b
          c = b["123"]
          c
          return c if c.nil?
          c
        end
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)

    clip = api_map.clip_at('test.rb', [6, 10])
    expect(clip.infer.to_s).to eq('String, nil')

    clip = api_map.clip_at('test.rb', [7, 17])
    expect(clip.infer.to_s).to eq('nil')

    clip = api_map.clip_at('test.rb', [8, 10])
    expect(clip.infer.to_s).to eq('String')
  end

  it 'uses ! to detect nilness' do
    source = Solargraph::Source.load_string(%(
      class A
        # @param a [Integer, nil]
        # @return [Integer]
        def foo a
          return a unless !a
          123
        end
      end
  ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [5, 17])
    expect(clip.infer.to_s).to eq('Integer')
  end

  it 'supports !@x.nil && @x.y' do
    source = Solargraph::Source.load_string(%(
      class Bar
        # @param foo [String, nil]
        def initialize(foo)
          @foo = foo
        end

        def foo?
          out = !@foo.nil? && @foo.upcase == 'FOO'
          out
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [9, 10])
    expect(clip.infer.to_s).to eq('Boolean')
  end

  it 'uses is_a? with instance variables to refine types' do
    source = Solargraph::Source.load_string(%(
      class ReproBase; end
      class Repro < ReproBase; end
      class Example
        # @param value [ReproBase]
        def initialize(value)
          @value = value
        end

        def check
          if @value.is_a?(Repro)
            @value
          else
            @value
          end
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [11, 12])
    expect(clip.infer.to_s).to eq('Repro')

    clip = api_map.clip_at('test.rb', [13, 12])
    expect(clip.infer.to_s).to eq('ReproBase')
  end

  it 'uses is_a? with a fully-qualified type name to refine types' do
    source = Solargraph::Source.load_string(%(
      # @param x [Object]
      def verify_repro(x)
        if x.is_a?(::Integer)
          x
        else
          x
        end
      end
  ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [4, 10])
    expect(clip.infer.rooted_tags).to eq('::Integer')

    clip = api_map.clip_at('test.rb', [6, 10])
    expect(clip.infer.rooted_tags).to eq('::Object')
  end

  context 'with a Hash key guard' do
    # @param code [String]
    # @param position [Array(Integer, Integer)]
    # @return [String]
    def infer_at code, position
      api_map = Solargraph::ApiMap.new.map(Solargraph::Source.load_string(code, 'test.rb'))
      api_map.clip_at('test.rb', position).infer.to_s
    end

    it 'drops nil from a lookup after return unless key?' do
      code = %(
        # @param h [Hash{String => Integer}]
        # @param k [String]
        def foo h, k
          return 0 unless h.key?(k)
          v = h[k]
          v
        end
      )
      expect(infer_at(code, [6, 10])).to eq('Integer')
    end

    it 'does not offer the narrowed lookup as a local variable completion' do
      code = %(
        # @param h [Hash{String => Integer}]
        # @param k [String]
        def foo h, k
          return 0 unless h.key?(k)
          h
        end
      )
      api_map = Solargraph::ApiMap.new.map(Solargraph::Source.load_string(code, 'test.rb'))
      names = api_map.clip_at('test.rb', [5, 11]).complete.pins.map(&:name)
      expect(names).to include('h')
      expect(names).not_to include('h[k]')
    end

    it 'keeps nil that the Hash values themselves allow' do
      code = %(
        # @param h [Hash{String => Integer, nil}]
        # @param k [String]
        def foo h, k
          w = h[k]
          return 0 unless h.key?(k)
          v = h[k]
          v
          w
        end
      )
      expect(infer_at(code, [7, 10])).to eq(infer_at(code, [8, 10]))
      expect(infer_at(code, [7, 10])).to end_with('nil')
    end

    it 'keeps nil on a lookup without a guard' do
      code = %(
        # @param h [Hash{String => Integer}]
        # @param k [String]
        def foo h, k
          v = h[k]
          v
        end
      )
      expect(infer_at(code, [5, 10])).to eq('Integer, nil')
    end

    it 'narrows only the then clause of if has_key?' do
      code = %(
        # @param h [Hash{String => Integer}]
        # @param k [String]
        def foo h, k
          if h.has_key?(k)
            a = h[k]
            a
          else
            b = h[k]
            b
          end
        end
      )
      expect(infer_at(code, [6, 12])).to eq('Integer')
      expect(infer_at(code, [9, 12])).to eq('Integer, nil')
    end

    it 'narrows the right side of member? &&' do
      code = %(
        # @param h [Hash{Symbol => String}]
        def foo h
          h.member?(:a) && (v = h[:a]) && v
        end
      )
      expect(infer_at(code, [3, 41])).to eq('String')
    end

    it 'does not narrow a lookup of a different key' do
      code = %(
        # @param h [Hash{String => Integer}]
        # @param k [String]
        # @param j [String]
        def foo h, k, j
          return 0 unless h.include?(k)
          v = h[j]
          v
        end
      )
      expect(infer_at(code, [7, 10])).to eq('Integer, nil')
    end

    it 'does not narrow Array#include?' do
      code = %(
        # @param a [Array<String>]
        # @param i [Integer]
        def foo a, i
          return 0 unless a.include?(i)
          v = a[i]
          v
        end
      )
      expect(infer_at(code, [6, 10])).to eq('String, nil')
    end

    it 'stops narrowing once the receiver is reassigned' do
      code = %(
        # @param h [Hash{String => Integer}]
        # @param g [Hash{String => Integer}]
        # @param k [String]
        def foo h, g, k
          return 0 unless h.key?(k)
          h = g
          v = h[k]
          v
        end
      )
      expect(infer_at(code, [8, 10])).to eq('Integer, nil')
    end

    it 'stops narrowing once the key is reassigned' do
      code = %(
        # @param h [Hash{String => Integer}]
        # @param k [String]
        # @param j [String]
        def foo h, k, j
          return 0 unless h.key?(k)
          k = j
          v = h[k]
          v
        end
      )
      expect(infer_at(code, [8, 10])).to eq('Integer, nil')
    end

    it 'stops narrowing once an attr_reader receiver is reassigned' do
      code = %(
        class Foo
          # @return [Hash{String => Integer}]
          attr_reader :table

          # @param k [String]
          def foo k
            return 0 unless table.key?(k)
            a = table[k]
            @table = {}
            b = table[k]
            a
            b
          end
        end
      )
      expect(infer_at(code, [11, 12])).to eq('Integer')
      expect(infer_at(code, [12, 12])).to eq('Integer, nil')
    end

    it 'stops narrowing once a key may have been removed' do
      code = %(
        # @param h [Hash{String => Integer}]
        # @param k [String]
        def foo h, k
          return 0 unless h.key?(k)
          a = h[k]
          h.delete(k)
          b = h[k]
          a
          b
        end
      )
      expect(infer_at(code, [8, 10])).to eq('Integer')
      expect(infer_at(code, [9, 10])).to eq('Integer, nil')
    end

    it 'stops narrowing once a key may have been removed through the ivar of an attr_reader' do
      code = %(
        class Foo
          # @return [Hash{String => Integer}]
          attr_reader :table

          # @param k [String]
          def foo k
            return 0 unless table.key?(k)
            a = table[k]
            @table.delete(k)
            b = table[k]
            a
            b
          end
        end
      )
      expect(infer_at(code, [11, 12])).to eq('Integer')
      expect(infer_at(code, [12, 12])).to eq('Integer, nil')
    end

    it 'stops narrowing once a key may have been removed through self' do
      code = %(
        class Foo
          # @return [Hash{String => Integer}]
          attr_reader :table

          # @param k [String]
          def foo k
            return 0 unless table.key?(k)
            self.table.delete(k)
            v = table[k]
            v
          end
        end
      )
      expect(infer_at(code, [10, 12])).to eq('Integer, nil')
    end

    it 'stops narrowing once a key may have been removed with &.' do
      code = %(
        # @param h [Hash{String => Integer}]
        # @param k [String]
        def foo h, k
          return 0 unless h.key?(k)
          h&.delete(k)
          v = h[k]
          v
        end
      )
      expect(infer_at(code, [7, 10])).to eq('Integer, nil')
    end

    it 'keeps narrowing after a key is removed from another Hash' do
      code = %(
        class Foo
          # @return [Hash{String => Integer}]
          attr_reader :table

          # @param k [String]
          # @param other [Hash{String => Integer}]
          def foo k, other
            return 0 unless table.key?(k)
            @other.delete(k)
            other&.delete(k)
            v = table[k]
            v
          end
        end
      )
      expect(infer_at(code, [12, 12])).to eq('Integer')
    end

    it 'stops narrowing once the keys may have been rewritten' do
      code = %(
        # @param h [Hash{String => Integer}]
        # @param k [String]
        def foo h, k
          return 0 unless h.key?(k)
          h.transform_keys!(&:upcase)
          v = h[k]
          v
        end
      )
      expect(infer_at(code, [7, 10])).to eq('Integer, nil')
    end

    it 'narrows a lookup on an attr_reader but not on another method' do
      code = %(
        class Foo
          # @return [Hash{String => Integer}]
          attr_reader :table

          # @return [Hash{String => Integer}]
          def fresh_table
            {}
          end

          # @param k [String]
          def foo k
            return 0 unless table.key?(k) && fresh_table.key?(k)
            a = table[k]
            b = fresh_table[k]
            a
            b
          end
        end
      )
      expect(infer_at(code, [15, 12])).to eq('Integer')
      expect(infer_at(code, [16, 12])).to eq('Integer, nil')
    end

    it 'does not narrow a key computed by a method call' do
      code = %(
        # @param h [Hash{String => Integer}]
        # @param k [Symbol]
        def foo h, k
          return 0 unless h.key?(k.to_s)
          v = h[k.to_s]
          v
        end
      )
      expect(infer_at(code, [6, 10])).to eq('Integer, nil')
    end

    it 'drops nil from a lookup after an ||= on it' do
      code = %(
        # @param h [Hash{String => Array<Integer>}]
        # @param k [String]
        def foo h, k
          h[k] ||= []
          v = h[k]
          v
        end
      )
      expect(infer_at(code, [6, 10])).to eq('Array<Integer>')
    end

    it 'does not narrow a lookup after an ||= inside an expression' do
      code = %(
        # @param h [Hash{String => Array<Integer>}]
        # @param k [String]
        def foo h, k
          bar && (h[k] ||= [])
          v = h[k]
          v
        end
      )
      expect(infer_at(code, [6, 10])).to eq('Array<Integer>, nil')
    end

    it 'ends the ||= fact at a write to the key' do
      code = %(
        # @param h [Hash{String => Array<Integer>}]
        # @param k [String]
        def foo h, k
          h[k] ||= []
          k = 'other'
          v = h[k]
          v
        end
      )
      expect(infer_at(code, [7, 10])).to eq('Array<Integer>, nil')
    end

    it 'narrows a class variable lookup after an ||= on it' do
      code = %(
        class Foo
          # @type [Hash{Symbol => Array<Integer>}]
          @@table = {}

          # @param k [Symbol]
          def self.foo k
            @@table[k] ||= []
            v = @@table[k]
            v
          end
        end
      )
      expect(infer_at(code, [9, 12])).to eq('Array<Integer>')
    end

    it 'still defines a guarded lookup as Hash#[]' do
      code = %(
        # @param h [Hash{String => Integer}]
        # @param k [String]
        def foo h, k
          return 0 unless h.key?(k)
          h[k]
        end
      )
      api_map = Solargraph::ApiMap.new.map(Solargraph::Source.load_string(code, 'test.rb'))
      expect(api_map.clip_at('test.rb', [5, 14]).define.map(&:path)).to eq(['Hash#[]'])
    end

    it 'still offers Hash#[] signatures in a guarded lookup' do
      code = %(
        # @param h [Hash{String => Integer}]
        # @param k [String]
        def foo h, k
          return 0 unless h.key?(k)
          h.[](k)
        end
      )
      api_map = Solargraph::ApiMap.new.map(Solargraph::Source.load_string(code, 'test.rb'))
      expect(api_map.clip_at('test.rb', [5, 15]).signify.map(&:path)).to eq(['Hash#[]'])
    end

    it 'does not add a local variable for the guarded lookup' do
      code = %(
        # @param h [Hash{String => Integer}]
        # @param k [String]
        def foo h, k
          return 0 unless h.key?(k)
          h[k]
        end
      )
      api_map = Solargraph::ApiMap.new.map(Solargraph::Source.load_string(code, 'test.rb'))
      names = api_map.source_map('test.rb').locals.grep(Solargraph::Pin::LocalVariable).map(&:name)
      expect(names.uniq).to contain_exactly('h', 'k')
    end

    it 'does not narrow a local that shadows a guarded attr_reader' do
      code = %(
        class Foo
          # @return [Hash{String => Integer}]
          attr_reader :table

          # @param k [String]
          # @param other [Hash{String => Integer}]
          def foo k, other
            return 0 unless table.key?(k)
            table = other
            v = table[k]
            v
          end
        end
      )
      expect(infer_at(code, [11, 12])).to eq('Integer, nil')
    end

    it 'narrows self.table after a table.key? guard' do
      code = %(
        class Foo
          # @return [Hash{String => Integer}]
          attr_reader :table

          # @param k [String]
          # @param other [Hash{String => Integer}]
          def foo k, other
            return 0 unless table.key?(k)
            a = self.table[k]
            table = other
            b = self.table[k]
            a
            b
          end
        end
      )
      expect(infer_at(code, [12, 12])).to eq('Integer')
      expect(infer_at(code, [13, 12])).to eq('Integer')
    end
  end

  describe '#parse_receiver_chain' do
    let(:typing) { described_class.new([], [], nil, nil) }

    # @param code [String]
    # @return [Array<String>, nil]
    def chain_of code
      typing.send(:parse_receiver_chain, Solargraph::Parser.parse(code))
    end

    it 'names a bare call' do
      expect(chain_of('foo')).to eq(['foo'])
    end

    it 'names a chain of argument-less calls on a variable' do
      expect(chain_of('@foo.bar.baz')).to eq(['@foo', 'bar', 'baz'])
    end

    it 'rejects a call with arguments' do
      expect(chain_of('foo.bar(1)')).to be_nil
    end

    it 'rejects a chain rooted at a call with arguments' do
      expect(chain_of('foo(1).bar')).to be_nil
    end
  end
end
