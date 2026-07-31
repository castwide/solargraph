# frozen_string_literal: true

require 'rbs'

# RbsTranslator.to_complex_type builds ComplexType::UniqueType::Intersection
# directly from the RBS AST for a *top-level* RBS::Types::Intersection,
# rather than flattening it through a joined tag string - see
# spec/pin/method_spec.rb "with a union nested inside an intersection".
# That fix only covers the entry point used for method return types and
# parameter types. Every other place a type gets recursively translated
# - RBS::Types::Optional, RBS::Types::Union members, RBS::Types::Tuple
# elements, and generic type arguments (Array[...], Hash[...], and any
# other name with type args, via build_type/type_tag) - still goes
# through the same flattening `type_to_tag` string join that caused the
# original bug, whenever the nested type is an intersection with a union
# conjunct. A plain (non-union-conjunct) intersection nested anywhere is
# fine; only the combination of "intersection containing a union" nested
# below the top level is affected.
#
# This spec covers that whole class of position, not just the one
# reported.
describe Solargraph::RbsTranslator do
  # @param rbs_string [String]
  # @return [Solargraph::ComplexType]
  def translate rbs_string
    described_class.to_complex_type(RBS::Parser.parse_type(rbs_string))
  end

  context 'when translating at the top level (already correct)' do
    it 'builds a real intersection from a union conjunct' do
      type = translate('(Integer | String) & Comparable')
      expect(type.length).to eq(1)
      expect(type.to_rbs).to eq('(::Integer | ::String) & ::Comparable')
    end
  end

  context 'with a plain intersection (no union conjunct) nested anywhere' do
    it 'translates correctly inside a generic argument' do
      type = translate('Array[Integer & Comparable]')
      expect(type.to_rbs).to eq('::Array[::Integer & ::Comparable]')
    end
  end

  context 'with a union-in-intersection nested below the top level' do
    it 'preserves grouping inside a generic argument (Array)' do
      type = translate('Array[(Integer | String) & Comparable]')
      expect(type.to_rbs).to eq('::Array[(::Integer | ::String) & ::Comparable]')
    end

    it 'preserves grouping inside a Hash value' do
      type = translate('Hash[Symbol, (Integer | String) & Comparable]')
      expect(type.to_rbs).to eq('::Hash[::Symbol, (::Integer | ::String) & ::Comparable]')
    end

    it 'preserves grouping inside a Hash key' do
      type = translate('Hash[(Integer | String) & Comparable, Symbol]')
      expect(type.to_rbs).to eq('::Hash[(::Integer | ::String) & ::Comparable, ::Symbol]')
    end

    it 'preserves grouping when doubly nested (Array of Hash values)' do
      type = translate('Array[Hash[Symbol, (Integer | String) & Comparable]]')
      expect(type.to_rbs).to eq('::Array[::Hash[::Symbol, (::Integer | ::String) & ::Comparable]]')
    end

    it 'preserves grouping under an optional (nilable) wrapper' do
      type = translate('((Integer | String) & Comparable)?')
      # T? is T | nil - a 2-item union of [the intersection, nil], not a
      # 3-item union that leaks the intersection's own first conjunct
      # out to the top level.
      expect(type.length).to eq(2)
      expect(type.to_rbs).to eq('((::Integer | ::String) & ::Comparable | nil)')
    end

    it 'preserves grouping as one member of an outer union' do
      # NilClass renders as the literal `nil` tag everywhere in this
      # codebase (see RBS_TO_YARD_TYPE), independent of this fix.
      type = translate('((Integer | String) & Comparable) | NilClass')
      expect(type.length).to eq(2)
      expect(type.to_rbs).to eq('((::Integer | ::String) & ::Comparable | nil)')
    end

    it 'preserves grouping as a tuple element' do
      type = translate('[(Integer | String) & Comparable, Integer]')
      # a 2-element tuple - the intersection, then Integer - not a
      # 3-element tuple that leaks the intersection's first conjunct out
      # as its own element.
      expect(type.to_rbs).to eq('[(::Integer | ::String) & ::Comparable, ::Integer]')
    end
  end
end
