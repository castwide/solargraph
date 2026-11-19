# frozen_string_literal: true

describe Solargraph::Pin::Callable do
  it 'infers a method-level generic block parameter from the argument bound to it' do
    # Enumerable#each_with_object is declared in RBS as
    #   [U] (obj U) { [U] (arg_0 Elem, obj U) -> untyped } -> U
    # `U` is a method-level generic bound by the `obj` argument passed
    # to each_with_object, not by the receiver's own `Elem` generic.
    source = Solargraph::Source.load_string(%(
      # @type [Array<Integer>]
      a = [1, 2, 3]
      a.each_with_object({}) do |e, memo|
        memo
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [4, 8])
    type = clip.infer
    expect(type.to_s).to eq('Hash')
  end

  it 'infers a method-level generic block parameter from the argument bound to it (Enumerable#inject)' do
    # Enumerable#inject has the same method-level-generic shape as
    # each_with_object: [U] (U init) { (U, Elem) -> U } -> U
    source = Solargraph::Source.load_string(%(
      # @type [Array<Integer>]
      a = [1, 2, 3]
      a.inject(0) do |acc, e|
        acc
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [4, 8])
    type = clip.infer
    expect(type.to_s).to eq('Integer')
  end

  it 'still infers the receiver-level generic block parameter for each_with_index' do
    # Negative control: Array#each_with_index has no method-level
    # generic in its block signature, only the receiver's own Elem.
    source = Solargraph::Source.load_string(%(
      # @type [Array<Integer>]
      a = [1, 2, 3]
      a.each_with_index do |e, i|
        e
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [4, 8])
    type = clip.infer
    expect(type.to_s).to eq('Integer')
  end
end
