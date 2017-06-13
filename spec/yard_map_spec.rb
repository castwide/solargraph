describe Solargraph::YardMap do
  it "gets instance methods from core classes" do
    yard_map = Solargraph::YardMap.new
    result = yard_map.get_instance_methods('String')
    expect(result.map(&:to_s)).to include('upcase')
  end

  it "gets class methods from core classes" do
    yard_map = Solargraph::YardMap.new
    result = yard_map.get_methods('String')
    expect(result.map(&:to_s)).to include('try_convert')
  end
end
