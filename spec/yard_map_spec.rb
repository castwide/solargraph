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

  it "is not raise Exception in add_gem_dependencies" do
    allow(YARD::Registry).to receive(:yardoc_file_for_gem).with("parser").and_return(false)
    allow(YARD::Registry).to receive(:yardoc_file_for_gem).with("ast").and_return(nil)
    Solargraph::YardMap.new required: ['parser']
    expect(true).to eq true
  end
end
