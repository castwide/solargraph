require 'tmpdir'

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
    # This spec assumes that the bundler gem is installed on the path
    # and has generated yardocs
    Dir.mktmpdir do |dir|
      yard_map = Solargraph::YardMap.new(required: ['bundler'], workspace: Solargraph::Workspace.new(dir))
      result = yard_map.objects('Bundler')
      expect(result.any?).to be(true)
      expect(result[0].location).not_to be(nil)
    end
  end

  it "gets method suggestions by path" do
    yard_map = Solargraph::YardMap.new
    sugg = yard_map.objects('String#upcase')
    expect(sugg[0].path).to eq('String#upcase')
  end

  it "does not include YARD for requires with matching files in the workspace's lib directory" do
    # This spec assumes that the bundler gem is installed on the path
    # and has generated yardocs
    Dir.mktmpdir do |dir|
      Dir.mkdir(File.join(dir, 'lib'))
      filename = File.join(dir, 'lib', 'bundler.rb')
      File.write(filename, "puts 'test'")
      yard_map = Solargraph::YardMap.new(required: ['bundler'], workspace: Solargraph::Workspace.new(dir))
      incl = yard_map.yardocs.select{|y| y.include?('bundler')}
      expect(incl).to be_empty
    end
  end

  it "does not include YARD for requires with a matching gemspec in the workspace's directory" do
    # This spec assumes that the bundler gem is installed on the path
    # and has generated yardocs
    Dir.mktmpdir do |dir|
      Dir.mkdir(File.join(dir, 'lib'))
      filename = File.join(dir, 'bundler.gemspec')
      File.write(filename, "puts 'test'")
      yard_map = Solargraph::YardMap.new(required: ['bundler'], workspace: Solargraph::Workspace.new(dir))
      incl = yard_map.yardocs.select{|y| y.include?('bundler')}
      expect(incl).to be_empty
    end
  end
end
