# frozen_string_literal: true

describe Solargraph::TypeChecker::Rules do
  it 'exposes the resolved level' do
    expect(described_class.new(:strict, {}).level).to be(:strict)
  end

  it 'falls back to normal for an unrecognized level' do
    allow(Solargraph.logger).to receive(:warn)
    expect(described_class.new(:not_a_real_level, {}).level).to be(:normal)
    expect(Solargraph.logger).to have_received(:warn)
  end

  it 'falls back to the rule default when an override names an unrecognized level' do
    allow(Solargraph.logger).to receive(:warn)
    rules = described_class.new(:strong, { validate_calls: :not_a_real_level })
    expect(rules.validate_calls?).to be(true)
    expect(Solargraph.logger).to have_received(:warn)
  end

  it 'sets normal rules' do
    rules = described_class.new(:normal, {})
    expect(rules.ignore_all_undefined?).to be(true)
    expect(rules.must_tag_or_infer?).to be(false)
    expect(rules.require_type_tags?).to be(false)
    expect(rules.validate_calls?).to be(false)
    expect(rules.validate_tags?).to be(false)
  end

  it 'sets typed rules' do
    rules = described_class.new(:typed, {})
    expect(rules.ignore_all_undefined?).to be(true)
    expect(rules.must_tag_or_infer?).to be(false)
    expect(rules.require_type_tags?).to be(false)
    expect(rules.validate_calls?).to be(false)
    expect(rules.validate_tags?).to be(true)
  end

  it 'sets strict rules' do
    rules = described_class.new(:strict, {})
    expect(rules.ignore_all_undefined?).to be(false)
    expect(rules.must_tag_or_infer?).to be(true)
    expect(rules.require_type_tags?).to be(false)
    expect(rules.validate_calls?).to be(true)
    expect(rules.validate_tags?).to be(true)
  end

  it 'sets strong rules' do
    rules = described_class.new(:strong, {})
    expect(rules.ignore_all_undefined?).to be(false)
    expect(rules.must_tag_or_infer?).to be(true)
    expect(rules.require_type_tags?).to be(true)
    expect(rules.validate_calls?).to be(true)
    expect(rules.validate_tags?).to be(true)
  end
end
