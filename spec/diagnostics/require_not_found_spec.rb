describe Solargraph::Diagnostics::RequireNotFound do
  before :each do
    @source = Solargraph::Source.new(%(
      require 'rexml/document'
      require 'not_valid'
    ), 'file.rb')

    @api_map = Solargraph::ApiMap.new
    @api_map.map @source
  end

  it "reports unresolved requires" do
    reporter = Solargraph::Diagnostics::RequireNotFound.new
    result = reporter.diagnose(@source, @api_map)
    expect(result.length).to eq(1)
  end
end
