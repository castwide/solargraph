describe Solargraph::LiveMap do
  it "starts and stops" do
    api_map = Solargraph::ApiMap.new
    live_map = Solargraph::LiveMap.new(api_map)
    live_map.start
    live_map.stop
    # @todo Real expectation
    expect(false).to eq(false)
  end
end
