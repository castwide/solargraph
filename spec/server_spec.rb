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

  it "returns search results for a String query" do
    get '/search', query: 'String'
    expect(last_response).to be_ok
    expect(last_response.body).to include('String')
  end

  it "returns a document for a class" do
    get '/document', query: 'String'
    expect(last_response).to be_ok
    expect(last_response.body).to include('String')
  end

  it "returns a document for a method" do
    get '/document', query: 'String#split'
    expect(last_response).to be_ok
    expect(last_response.body).to include('split')
  end

  it "returns a suggestion on hover" do
    post '/hover', text: 'String', line: 0, column: 1
    expect(last_response).to be_ok
    response = JSON.parse(last_response.body)
    expect(response['suggestions'].length > 0).to be(true)
  end

  it "returns a suggestion for a signature" do
    post '/signify', text: 'x="foo";x.split()', line: 0, column: 16
    expect(last_response).to be_ok
    response = JSON.parse(last_response.body)
    expect(response['suggestions'].length > 0).to be(true)
  end

  it "prepares a workspace" do
    post '/prepare', workspace: @workspace
    expect(last_response).to be_ok
    expect(Dir.exist?("#{@workspace}/.yardoc")).to be(true)
  end

  it "returns suggestions from the workspace" do
    post '/suggest', text: 'Foo.', line: 0, column: 4, workspace: @workspace
    expect(last_response).to be_ok
    response = JSON.parse(last_response.body)
    expect(response['suggestions'].map{|s| s['label']}).to include('new')
  end
end
