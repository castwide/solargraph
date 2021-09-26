describe Solargraph::Diagnostics::RequireNotFound do
  before :each do
    @source = Solargraph::Source.new(%(
      require 'rexml/document'
      require 'not_valid'
    ), 'file.rb')

    @source_map = Solargraph::SourceMap.map(@source)

    @api_map = Solargraph::ApiMap.new
    @api_map.catalog Solargraph::Bench.new(source_maps: [@source_map], external_requires: ['not_valid'])
  end

  it "reports unresolved requires" do
    reporter = Solargraph::Diagnostics::RequireNotFound.new
    result = reporter.diagnose(@source, @api_map)
    expect(result.length).to eq(1)
  end
end
