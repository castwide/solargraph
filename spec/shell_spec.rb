require 'tmpdir'
require 'open3'

describe Solargraph::Shell do
  before do
    @temp_dir = Dir.mktmpdir
    File.open(File.join(@temp_dir, 'Gemfile'), 'w') do |file|
        file.puts "source 'https://rubygems.org'"
        file.puts "gem 'solargraph', path: #{File.expand_path('../..', __FILE__)}"
    end
    output, status = Open3.capture2e("bundle install", chdir: @temp_dir)
    expect(status.success?).to eq(true), ->{ "Bundle install failed: output=#{output}" }
  end

  def bundle_exec(*cmd)
    # run the command in the temporary directory with bundle exec
    output, status = Open3.capture2e("bundle exec #{cmd.join(' ')}", chdir: @temp_dir)
    expect(status.success?).to eq(true), "Command failed: #{output}"
    output
  end

  after do
    # remove the temporary directory after the tests
    FileUtils.remove_entry(@temp_dir) if Dir.exist?(@temp_dir)
  end

  describe "--version" do
    it "returns a version when run" do
      output = bundle_exec("solargraph", "--version")

      expect(output).to_not be_empty
      expect(output).to eq (Solargraph::VERSION + "\n")
    end
  end

  describe "uncache" do
    it "uncaches without erroring out" do
      output = bundle_exec("solargraph", "uncache", "solargraph")

      expect(output).to include('Clearing pin cache in')
    end
  end
end
