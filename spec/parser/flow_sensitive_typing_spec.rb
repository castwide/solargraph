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

  context 'with pattern matching' do
    let(:source) do
      Solargraph::Source.load_string(%(
class Foo; def foo_only; end; end
# @param x [Foo, Integer]
# @param t [Array<String>]
def m(x, t)
  case x
  in Foo => f
    f
    x
  in Integer
    x
  end
  t => [s, n]
  s
  n
  f
  x
end
      ), 'test.rb')
    end

    let(:api_map) { Solargraph::ApiMap.new.map(source) }

    it 'types a const capture' do
      expect(api_map.clip_at('test.rb', [7, 4]).infer.to_s).to eq('Foo, nil')
    end

    it 'narrows the subject in the matching clause' do
      expect(api_map.clip_at('test.rb', [8, 4]).infer.to_s).to eq('Foo')
    end

    it 'narrows the subject separately in the next clause' do
      expect(api_map.clip_at('test.rb', [10, 4]).infer.to_s).to eq('Integer')
    end

    it 'types array-index captures from a one-line => match' do
      expect(api_map.clip_at('test.rb', [13, 2]).infer.to_s).to eq('String')
      expect(api_map.clip_at('test.rb', [14, 2]).infer.to_s).to eq('String')
    end

    it 'keeps a capture visible after the case ends' do
      expect(api_map.clip_at('test.rb', [15, 2]).infer.to_s).to eq('Foo, nil')
    end

    it 'leaves the subject unnarrowed after the case ends' do
      expect(api_map.clip_at('test.rb', [16, 2]).infer.to_s).to eq('Foo, Integer')
    end
  end

  it 'narrows the subject to nil and to a union with nil' do
    source = Solargraph::Source.load_string(%(
      # @param x [String, Integer, nil]
      def m(x)
        case x
        in nil
          x
        in Integer | nil
          x
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    expect(api_map.clip_at('test.rb', [5, 10]).infer.to_s).to eq('nil')
    expect(api_map.clip_at('test.rb', [7, 10]).infer.to_s).to eq('Integer, nil')
  end

  it 'leaves the subject unnarrowed by a value constant pattern' do
    source = Solargraph::Source.load_string(%(
      class Foo
        PATTERN = /abc/

        # @param x [String, Integer]
        def m(x)
          case x
          in PATTERN => f
            x
            f
          end
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    expect(api_map.clip_at('test.rb', [8, 12]).infer.to_s).to eq('String, Integer')
    expect(api_map.clip_at('test.rb', [9, 12]).infer.to_s).to eq('String, Integer, nil')
  end

  it 'types an alternative capture as the union' do
    source = Solargraph::Source.load_string(%(
      # @param x [String, Integer, Symbol]
      def m(x)
        case x
        in String | Integer => v
          v
          x
        else
          x
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    expect(api_map.clip_at('test.rb', [5, 10]).infer.to_s).to eq('String, Integer, nil')
    expect(api_map.clip_at('test.rb', [6, 10]).infer.to_s).to eq('String, Integer')
    expect(api_map.clip_at('test.rb', [8, 10]).infer.to_s).to eq('String, Integer, Symbol')
  end

  it 'types a bare capture as the subject' do
    source = Solargraph::Source.load_string(%(
      # @param x [String]
      def m(x)
        case x
        in y
          y
        end
        x => z
        z
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    expect(api_map.clip_at('test.rb', [5, 10]).infer.to_s).to eq('String, nil')
    expect(api_map.clip_at('test.rb', [8, 8]).infer.to_s).to eq('String')
  end

  it 'types array-index captures in a case clause' do
    pending 'Captures read by index or rest stay non-nil when the match can fail: BaseVariable cannot add nil to a mass assignment'

    source = Solargraph::Source.load_string(%(
      # @param t [Array<String>]
      def m(t)
        case t
        in [a, b]
          a
          b
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    expect(api_map.clip_at('test.rb', [5, 10]).infer.to_s).to eq('String, nil')
    expect(api_map.clip_at('test.rb', [6, 10]).infer.to_s).to eq('String, nil')
  end

  it 'types tuple-index captures by position' do
    pending 'https://github.com/castwide/solargraph/pull/1461'

    source = Solargraph::Source.load_string(%(
      # @param t [Array(String, Integer)]
      def m(t)
        t => [s, n]
        n
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    expect(api_map.clip_at('test.rb', [4, 8]).infer.to_s).to eq('Integer')
  end

  it 'types captures from a one-line in match' do
    pending 'Captures read by index or rest stay non-nil when the match can fail: BaseVariable cannot add nil to a mass assignment'

    source = Solargraph::Source.load_string(%(
      # @param t [Array<String>]
      def m(t)
        if t in [a, Integer => b]
          a
          b
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    expect(api_map.clip_at('test.rb', [4, 10]).infer.to_s).to eq('String, nil')
    expect(api_map.clip_at('test.rb', [5, 10]).infer.to_s).to eq('Integer, nil')
  end

  it 'types a capture read in a guard' do
    source = Solargraph::Source.load_string(%(
      # @param x [String, Integer]
      def m(x)
        case x
        in String => s if s.empty?
          s
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    expect(api_map.clip_at('test.rb', [4, 26]).infer.to_s).to eq('String, nil')
  end

  it 'narrows an instance variable subject with a const_pattern' do
    source = Solargraph::Source.load_string(%(
      class Point; end
      class Example
        # @param value [Point, Integer]
        def initialize(value)
          @value = value
        end

        def check
          case @value
          in Point(x:)
            @value
          in Integer
            @value
          end
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    expect(api_map.clip_at('test.rb', [11, 12]).infer.to_s).to eq('Point')
    expect(api_map.clip_at('test.rb', [13, 12]).infer.to_s).to eq('Integer')
  end

  it 'maps a capture beside a pinned value' do
    source = Solargraph::Source.load_string(%(
      # @param x [Integer]
      def m(x)
        v = 1
        case x
        in ^v => w
          w
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    expect(api_map.clip_at('test.rb', [6, 10]).locals.map(&:name)).to include('w')
  end

  it 'types rest captures in array and find patterns as Array' do
    pending 'Captures read by index or rest stay non-nil when the match can fail: BaseVariable cannot add nil to a mass assignment'

    source = Solargraph::Source.load_string(%(
      # @param x [Object]
      def m(x)
        case x
        in [a, *rest]
          rest
        in [*, 1, *post]
          post
        end
        x in [*tail]
        tail
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    expect(api_map.clip_at('test.rb', [5, 10]).infer.to_s).to eq('Array, nil')
    expect(api_map.clip_at('test.rb', [7, 10]).infer.to_s).to eq('Array, nil')
    expect(api_map.clip_at('test.rb', [10, 8]).infer.to_s).to eq('Array, nil')
  end

  it 'types rest captures as the core Array inside a namespace with its own Array' do
    pending 'Captures read by index or rest stay non-nil when the match can fail: BaseVariable cannot add nil to a mass assignment'

    source = Solargraph::Source.load_string(%(
      module Foo
        class Array; end

        # @param x [Object]
        def self.m(x)
          x in [*rest]
          rest
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    expect(api_map.clip_at('test.rb', [7, 10]).infer.to_s).to eq('Array, nil')
  end

  it 'types rest captures with the element type of an Array subject' do
    pending 'Captures read by index or rest stay non-nil when the match can fail: BaseVariable cannot add nil to a mass assignment'

    source = Solargraph::Source.load_string(%(
      # @param t [Array<String>]
      def m(t)
        case t
        in [*all]
          all
        in [a, *tail]
          tail
        in [a, *middle, b]
          middle
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    expect(api_map.clip_at('test.rb', [5, 10]).infer.to_s).to eq('Array<String>, nil')
    expect(api_map.clip_at('test.rb', [7, 10]).infer.to_s).to eq('Array<String>, nil')
    expect(api_map.clip_at('test.rb', [9, 10]).infer.to_s).to eq('Array<String>, nil')
  end

  it 'types rest captures from a tuple subject as an Array of the remaining element types' do
    pending 'https://github.com/castwide/solargraph/pull/1461'

    source = Solargraph::Source.load_string(%(
      # @param t [Array(String, Integer)]
      def m(t)
        t => [s, *rest]
        rest
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    expect(api_map.clip_at('test.rb', [4, 8]).infer.to_s).to eq('Array<Integer>')
  end

  it 'types index captures from the return type of the subject deconstruct method' do
    source = Solargraph::Source.load_string(%(
      class Pair
        # @return [Array<Symbol>]
        def deconstruct; end
      end

      # @param pair [Pair]
      def m(pair)
        pair => [a, b]
        a
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    expect(api_map.clip_at('test.rb', [9, 8]).infer.to_s).to eq('Symbol')
  end

  it 'does not read #deconstruct for a multiple assignment' do
    source = Solargraph::Source.load_string(%(
      class Pair
        # @return [Array<Symbol>]
        def deconstruct; end
      end

      # @param pair [Pair]
      def m(pair)
        a, b = pair
        a
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    # Multiple assignment destructures with #to_ary, which Pair lacks, not #deconstruct
    expect(api_map.clip_at('test.rb', [9, 8]).infer.to_s).to eq('undefined')
  end

  it 'does not narrow a subject that the pattern rebinds' do
    source = Solargraph::Source.load_string(%(
      class Pt
        # @return [Array<String>]
        def deconstruct; end
      end

      # @param x [Pt, Integer]
      def m(x)
        case x
        in Pt[x]
          x
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    # x is now the capture, not a Pt; the capture itself is not typed yet
    expect(api_map.clip_at('test.rb', [10, 10]).infer.to_s).not_to eq('Pt')
  end

  it 'types index and rest captures from every member of a union subject' do
    source = Solargraph::Source.load_string(%(
      class Box
        # @return [Array<Integer>]
        def deconstruct; end
      end

      class Untyped
        def deconstruct; end
      end

      # @param x [Array<String>, Box]
      # @param y [Array<String>, Untyped]
      def m(x, y)
        x => [a, *rest]
        a
        rest
        y => [b, *more]
        b
        more
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    expect(api_map.clip_at('test.rb', [14, 8]).infer.to_s).to eq('String, Integer')
    expect(api_map.clip_at('test.rb', [15, 8]).infer.to_s).to eq('Array<String, Integer>')
    expect(api_map.clip_at('test.rb', [17, 8]).infer.to_s).to eq('undefined')
    expect(api_map.clip_at('test.rb', [18, 8]).infer.to_s).to eq('Array')
  end

  it 'types a multiple assignment from every member of a union' do
    source = Solargraph::Source.load_string(%(
      # @param x [Array<String>, Array<Integer>]
      def m(x)
        c, d = x
        c
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    expect(api_map.clip_at('test.rb', [4, 8]).infer.to_s).to eq('String, Integer')
  end

  it 'leaves a nested capture of a value constant pattern unknown' do
    source = Solargraph::Source.load_string(%(
      class Base
        PAT = /abc/
      end

      # @param x [Array<String>]
      def m(x)
        x => [Base::PAT => h]
        h
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    expect(api_map.clip_at('test.rb', [8, 8]).infer.to_s).to eq('undefined')
  end

  it 'types rest captures from the return type of the subject deconstruct method' do
    source = Solargraph::Source.load_string(%(
      class Pair
        # @return [Array<Symbol>]
        def deconstruct; end
      end

      # @param pair [Pair]
      def m(pair)
        pair => [:left, *rest]
        rest
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    expect(api_map.clip_at('test.rb', [9, 8]).infer.to_s).to eq('Array<Symbol>')
  end
end
