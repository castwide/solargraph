# frozen_string_literal: true

describe Solargraph::CacheDir do
  around do |example|
    saved = described_class.plugins.dup
    described_class.plugins.clear
    example.run
    described_class.plugins.replace(saved)
  end

  # @param version [String]
  # @return [Hash{String => Gem::Specification}]
  def loaded_plugin_gem version
    spec = Gem::Specification.new do |s|
      s.name = 'fake-plugin'
      s.version = version
    end
    { 'fake-plugin' => spec }
  end

  it 'keeps the gem directory when no plugin is loaded' do
    expect(described_class.gem_dir).to eq(File.join(described_class.work_dir, 'gems'))
  end

  it 'separates gem caches built with a plugin loaded' do
    without = described_class.gem_dir
    described_class.add_plugin 'some_plugin'
    expect(described_class.gem_dir).not_to eq(without)
  end

  it 'separates gem caches built with different plugin versions' do
    allow(Gem).to receive(:loaded_specs).and_return(loaded_plugin_gem('1.0.0'))
    described_class.add_plugin 'fake-plugin'
    first = described_class.gem_dir

    allow(Gem).to receive(:loaded_specs).and_return(loaded_plugin_gem('1.1.0'))
    described_class.add_plugin 'fake-plugin'
    expect(described_class.gem_dir).not_to eq(first)
  end

  it 'does not depend on the order plugins load in' do
    described_class.add_plugin 'first_plugin'
    described_class.add_plugin 'second_plugin'
    forward = described_class.gem_dir

    described_class.plugins.clear
    described_class.add_plugin 'second_plugin'
    described_class.add_plugin 'first_plugin'
    expect(described_class.gem_dir).to eq(forward)
  end
end
