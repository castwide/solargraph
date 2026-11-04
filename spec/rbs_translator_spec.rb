# frozen_string_literal: true

require 'rbs'

describe Solargraph::RbsTranslator do
  describe '.to_complex_type' do
    # @param rbs [String]
    # @return [Solargraph::ComplexType]
    def translate rbs
      described_class.to_complex_type(RBS::Parser.parse_type(rbs, variables: [:T]))
    end

    {
      '::String' => '::String',
      '::Array[::String]' => '::Array<::String>',
      '::Array[::String | ::Integer]' => '::Array<::String, ::Integer>',
      '::Hash[::Symbol, ::Integer]' => '::Hash{::Symbol => ::Integer}',
      '::Hash[::Symbol, untyped]' => '::Hash{::Symbol => undefined}',
      '::Array[untyped]' => '::Array',
      '::String?' => '::String, nil',
      '(::String | ::Integer)?' => '::String, ::Integer, nil',
      '::String | ::Integer' => '::String, ::Integer',
      'bool' => '::Boolean',
      'nil' => 'nil',
      'NilClass' => 'nil',
      'void' => 'void',
      'untyped' => 'undefined',
      'bot' => 'undefined',
      'top' => '::BasicObject',
      'self' => 'self',
      'instance' => 'self',
      '[::String, ::Integer]' => '::Array(::String, ::Integer)',
      ':foo' => ':foo',
      '"str"' => '"str"',
      '1' => '1',
      'true' => 'true',
      'true | false' => '::Boolean',
      '{ a: String }' => '::Hash',
      '^() -> void' => '::Proc',
      'singleton(::String)' => '::String',
      '::_ToS' => '::_ToS',
      '::String & ::Comparable' => '::String, ::Comparable',
      'T' => 'generic<T>',
      '::Array[T]' => '::Array<generic<T>>',
      '::Foo::Bar[T, ::String]' => '::Foo::Bar<generic<T>, ::String>',
      '::Enumerator[::String, void]' => '::Enumerator<::String, void>'
    }.each do |rbs, expected|
      it "translates #{rbs} to #{expected}" do
        type = translate(rbs)

        expect([type.rooted_tags, type.all_rooted?]).to eq([expected, true])
      end
    end

    it 'keeps string literals that contain type syntax characters' do
      expect(translate('"=" | "<" | ">="').rooted_tags).to eq('"=", "<", ">="')
    end

    it 'keeps a tuple of string literals that contain type syntax characters' do
      expect(translate('["<", ::Integer]').rooted_tags).to eq('::Array("<", ::Integer)')
    end

    it 'translates an unrecognized type to undefined' do
      unrecognized = Struct.new(:location).new(nil)

      expect(described_class.to_complex_type(unrecognized).rooted_tags).to eq('undefined')
    end

    it 'gives an empty tuple no members' do
      expect(translate('[ ]').first.subtypes).to be_empty
    end
  end
end
