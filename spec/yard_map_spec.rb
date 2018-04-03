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

  # @todo May not apply anymore
  # it "does not raise Exception in add_gem_dependencies" do
  #   allow(YARD::Registry).to receive(:yardoc_file_for_gem).with("parser").and_return(false)
  #   allow(YARD::Registry).to receive(:yardoc_file_for_gem).with("ast").and_return(nil)
  #   Solargraph::YardMap.new required: ['parser']
  #   expect(true).to eq true
  # end

  it "gracefully fails to resolve unknown require paths" do
    expect {
      yard_map = Solargraph::YardMap.new(required: ['invalid_path'])
    }.not_to raise_error
  end

  it "gets locations from required gems" do
    yard_map = Solargraph::YardMap.new(required: ['solargraph'])
    result = yard_map.objects('Solargraph::YardMap#objects')
    expect(result.any?).to be(true)
    expect(result[0].location).not_to be(nil)
  end

  it "gets method suggestions by path" do
    yard_map = Solargraph::YardMap.new
    sugg = yard_map.objects('String#upcase')
    expect(sugg[0].path).to eq('String#upcase')
  end
end
