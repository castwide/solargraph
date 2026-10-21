# frozen_string_literal: true

describe Solargraph::ComplexType::UniqueType::Intersection do
  # @param tags [Array<String>]
  # @return [Solargraph::ComplexType::UniqueType::Intersection]
  def intersection *tags
    described_class.new(tags.map { |tag| Solargraph::ComplexType.parse(tag) })
  end

  let(:type) { intersection('Comparable', 'String') }

  describe 'readers with no single answer for a compound type' do
    %i[
      tag rooted_tag generic? rooted? duck_type? interface? literal?
      implicit_union? unioned_items items rooted_namespace rooted_name name
      can_root_name? key_types subtypes all_params parameters_type
      namespace_type recreate value_types parameters? list_parameters?
      fixed_parameters? hash_parameters? substring rooted_substring
      generate_substring_from parameters_as_rbs
      resolve_param_generics_from_context rbs_name non_literal_name
      determine_non_literal_name expand without_nil narrow_with
      erase_generics simplify_literals force_rooted self_to_type exclude
      desc parameter_variance simplifyable_literal? tuple?
      downcast_to_literal_if_possible rbs_union namespace scope
      mixin_pairing? namespace_kind
    ].each do |reader|
      it "raises from ##{reader} rather than answering for one conjunct" do
        expect { type.send(reader) }.to raise_error(NotImplementedError)
      end
    end
  end

  describe '#to_s' do
    it 'renders every conjunct' do
      expect(type.to_s).to eq('Comparable & String')
    end
  end

  describe '#nil_type?' do
    it 'is the nil type when any conjunct is nil' do
      expect(intersection('String', 'nil')).to be_nil_type
    end

    it 'is not the nil type when no conjunct is nil' do
      expect(type).not_to be_nil_type
    end
  end

  describe '#candidate_methods_from' do
    it 'offers the methods of every conjunct' do
      api_map = Solargraph::ApiMap.new
      names = type.candidate_methods_from(api_map, '', false).map(&:name)
      expect(names).to include('between?', 'upcase')
    end
  end
end
