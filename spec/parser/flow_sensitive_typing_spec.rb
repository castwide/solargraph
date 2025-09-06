# frozen_string_literal: true

# @todo These tests depend on `Clip`, but we're putting the tests here to
#   avoid overloading clip_spec.rb.
describe Solargraph::Parser::FlowSensitiveTyping do
  it 'uses is_a? in a simple if() to refine types on a simple class' do
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

  it 'uses is_a? in a simple unless statement to refine types on a simple class' do
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
end
