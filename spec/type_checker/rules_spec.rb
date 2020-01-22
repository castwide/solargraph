describe Solargraph::TypeChecker::Rules do
  it 'sets normal rules' do
    rules = Solargraph::TypeChecker::Rules.new(:normal)
    expect(rules.ignore_all_undefined?).to be(true)
    expect(rules.must_tag_or_infer?).to be(false)
    expect(rules.require_type_tags?).to be(false)
    expect(rules.validate_calls?).to be(false)
    expect(rules.validate_tags?).to be(false)
  end

  it 'sets typed rules' do
    rules = Solargraph::TypeChecker::Rules.new(:typed)
    expect(rules.ignore_all_undefined?).to be(true)
    expect(rules.must_tag_or_infer?).to be(false)
    expect(rules.require_type_tags?).to be(false)
    expect(rules.validate_calls?).to be(false)
    expect(rules.validate_tags?).to be(true)
  end

  it 'sets strict rules' do
    rules = Solargraph::TypeChecker::Rules.new(:strict)
    expect(rules.ignore_all_undefined?).to be(false)
    expect(rules.must_tag_or_infer?).to be(true)
    expect(rules.require_type_tags?).to be(false)
    expect(rules.validate_calls?).to be(true)
    expect(rules.validate_tags?).to be(true)
  end

  it 'sets strong rules' do
    rules = Solargraph::TypeChecker::Rules.new(:strong)
    expect(rules.ignore_all_undefined?).to be(false)
    expect(rules.must_tag_or_infer?).to be(true)
    expect(rules.require_type_tags?).to be(true)
    expect(rules.validate_calls?).to be(true)
    expect(rules.validate_tags?).to be(true)
  end
end
