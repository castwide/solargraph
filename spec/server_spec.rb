require 'rack/test'
require 'tmpdir'

ENV['RACK_ENV'] = 'test'

module RSpecMixin
  include Rack::Test::Methods
  def app() Solargraph::Server end
end
RSpec.configure { |c| c.include RSpecMixin }

describe Solargraph::Server do
  before :all do
    @workspace = Dir.mktmpdir
    Dir.mkdir("#{@workspace}/lib")
    File.open("#{@workspace}/lib/test.rb", 'w') do |file|
      file.puts "class Foo",
      "  def bar",
      "  end",
      "end"
    end
  end

  after :all do
    FileUtils.remove_entry @workspace
  end

  it "returns suggestions for String instances" do
    post '/suggest', text: 'String.new.', line: 0, column: 11
    expect(last_response).to be_ok
    expect(last_response.body).to include('upcase')
  end

  it "returns a document for a String query" do
    get '/search', query: 'String'
    expect(last_response).to be_ok
    expect(last_response.body).to include('String')
  end

  it "prepares a workspace" do
    post '/prepare', workspace: @workspace
    expect(last_response).to be_ok
    # HACK Wait for the thread in ApiMap#update_yardoc to finish
    sleep(5)
    expect(Dir.exist?("#{@workspace}/.yardoc")).to be(true)
  end
end
