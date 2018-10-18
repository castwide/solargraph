require 'fileutils'
require 'tmpdir'

describe Solargraph::Workspace::ReporterConfigs do
  it "each calls block with reporter name and config" do
    config = Solargraph::Workspace::ReporterConfigs.new([
      'one',
      'two',
      { 'three' => { 'hello' => 'world' } },
      'four'
    ])

    config.each do |reporter, reporter_config|
      expect(reporter_config).to eq({}) if reporter == 'one'
      expect(reporter_config).to eq({}) if reporter == 'two'
      expect(reporter_config).to eq('hello' => 'world') if reporter == 'three'
      expect(reporter_config).to eq({}) if reporter == 'four'
    end
  end

  it "to_a returns array of two element arrays for reporters" do
    config = Solargraph::Workspace::ReporterConfigs.new([
      'one',
      'two',
      { 'three' => { 'hello' => 'world' } },
      'four'
    ])
    expected = [
      ['one', {}],
      ['two', {}],
      ['three', { 'hello' => 'world' }],
      ['four', {}]
    ]

    expect(config.to_a).to eq(expected)
  end
end
