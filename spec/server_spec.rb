require 'rack/test'

ENV['RACK_ENV'] = 'test'

module RSpecMixin
  include Rack::Test::Methods
  def app() Solargraph::Server end
end
RSpec.configure { |c| c.include RSpecMixin }

describe Solargraph::Server do
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
end
