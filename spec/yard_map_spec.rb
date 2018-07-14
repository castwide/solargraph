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

  it "gracefully fails to resolve unknown require paths" do
    expect {
      yard_map = Solargraph::YardMap.new(required: ['invalid_path'])
    }.not_to raise_error
  end

  it "gets locations from required gems" do
    # This spec assumes that the parser gem is installed on the path
    # and has generated yardocs
    Dir.mktmpdir do |dir|
      yard_map = Solargraph::YardMap.new(required: ['parser'], workspace: Solargraph::Workspace.new(dir))
      result = yard_map.objects('Parser')
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
    # This spec assumes that the parser gem is installed on the path
    # and has generated yardocs
    Dir.mktmpdir do |dir|
      Dir.mkdir(File.join(dir, 'lib'))
      filename = File.join(dir, 'lib', 'parser.rb')
      File.write(filename, "puts 'test'")
      yard_map = Solargraph::YardMap.new(required: ['parser'], workspace: Solargraph::Workspace.new(dir))
      incl = yard_map.yardocs.select{|y| y.include?('parser')}
      expect(incl).to be_empty
    end
  end

  it "does not include YARD for requires with a matching gemspec in the workspace's directory" do
    # This spec assumes that the parser gem is installed on the path
    # and has generated yardocs
    Dir.mktmpdir do |dir|
      Dir.mkdir(File.join(dir, 'alt_lib'))
      # This gemspec changes the default require path
      File.write(File.join(dir, 'alt.gemspec'), %(
        Gem::Specification.new do |s|
          s.name          = 'test'
          s.version       = '1.0.0'
          s.summary       = "Test"
          s.files         = Dir['**/*']
          s.require_paths = ['alt_lib']
        end
      ))
      File.write(File.join(dir, 'alt_lib', 'parser.rb'), "puts 'test'")
      yard_map = Solargraph::YardMap.new(required: ['parser'], workspace: Solargraph::Workspace.new(dir))
      incl = yard_map.yardocs.select { |y| y.include?('parser') }
      expect(incl).to be_empty
    end
  end

  it "supports nested gemspecs" do
    # This spec assumes that the parser gem is installed on the path
    # and has generated yardocs
    Dir.mktmpdir do |dir|
      Dir.mkdir(File.join(dir, 'foo'))
      Dir.mkdir(File.join(dir, 'foo', 'bar'))
      Dir.mkdir(File.join(dir, 'foo', 'bar', 'lib'))
      File.write(File.join(dir, 'foo', 'bar', 'lib', 'parser.rb'), "puts 'hello'")
      File.write(File.join(dir, 'foo', 'bar', 'alt.gemspec'), %(
        Gem::Specification.new do |s|
          s.name          = 'test'
          s.version       = '1.0.0'
          s.summary       = "Test"
          s.files         = Dir['**/*']
        end
      ))
      yard_map = Solargraph::YardMap.new(required: ['parser'], workspace: Solargraph::Workspace.new(dir))
      incl = yard_map.yardocs.select { |y| y.include?('parser') }
      expect(incl).to be_empty
    end
  end

  it "tracks unresolved requires" do
    yard_map = Solargraph::YardMap.new(required: ['parser', 'not_a_valid_path'])
    expect(yard_map.unresolved_requires).to include('not_a_valid_path')
    expect(yard_map.unresolved_requires).not_to include('parser')
  end

  # @todo This spec might be outdated, or at least inaccurately worded. YardMap
  #   no longer adapts the environment based on the bundler. Instead, the user
  #   is expected to use the bundler for processes where necessary. Attempts to
  #   change the environment for workspaces that contained a Gemfile were
  #   consistently dodgy.
  it "uses a clean bundler environment in workspaces with unloaded gemfiles" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, 'Gemfile'), %(
        gem 'parser'
      ))
      yard_map = Solargraph::YardMap.new(required: ['parser'], workspace: Solargraph::Workspace.new(dir))
      incl = yard_map.yardocs.select { |y| y.include?('parser') }
      expect(incl).not_to be_empty
    end
  end

  it "adds gem dependencies" do
    yard_map = Solargraph::YardMap.new(required: ['solargraph'])
    incl = yard_map.yardocs.select { |y| y.include?('eventmachine') }
    expect(incl).not_to be_empty
  end

  it "finds method objects" do
    yard_map = Solargraph::YardMap.new
    result = yard_map.objects('String#upcase')
    expect(result).not_to be_empty
  end

  it "finds method objects in nested namespaces" do
    yard_map = Solargraph::YardMap.new
    result = yard_map.objects('Encoding::Converter#convert')
    expect(result).not_to be_empty
  end

  it "finds method objects in nested contexts" do
    yard_map = Solargraph::YardMap.new
    result = yard_map.objects('Converter#convert', 'Encoding')
    expect(result).not_to be_empty
  end

  it "finds method objects in unidentified contexts" do
    yard_map = Solargraph::YardMap.new
    result = yard_map.objects('String#upcase', 'FakeNamespace')
    expect(result).not_to be_empty
  end

  it "finds locations for YardObject pins" do
    yard_map = Solargraph::YardMap.new(required: ['yard'])
    result = yard_map.objects('YARD::CodeObjects::Base#line')
    expect(result).not_to be_empty
    expect(result[0].location).to be_a(Solargraph::Source::Location)
  end

  it "finds appropriate stdlib constants" do
    yard_map = Solargraph::YardMap.new(required: ['net/http'])
    result = yard_map.get_constants('').map(&:path)
    expect(result).to include('Net')
    result = yard_map.get_constants('Net').map(&:path)
    expect(result).to include('Net::HTTP')
    expect(result).not_to include('Net::FTP')
    result = yard_map.objects('Net::HTTP').map(&:path)
    expect(result).to include('Net::HTTP')
    expect(result).not_to include('Net::FTP')
  end

  it "tracks unresolved requires" do
    yard_map = Solargraph::YardMap.new(required: ['net/http', 'unknown_path'])
    expect(yard_map.unresolved_requires).not_to include('net/http')
    expect(yard_map.unresolved_requires).to include('unknown_path')
  end
end
