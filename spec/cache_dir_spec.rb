# frozen_string_literal: true

describe Solargraph::CacheDir do
  it 'keeps the gem directory when no plugin is given' do
    expect(described_class.gem_dir).to eq(File.join(described_class.work_dir, 'gems'))
  end

  it 'separates gem caches built with a plugin' do
    expect(described_class.gem_dir('some_plugin' => '1.0.0')).not_to eq(described_class.gem_dir)
  end

  it 'separates gem caches built with different plugin versions' do
    expect(described_class.gem_dir('fake-plugin' => '1.1.0'))
      .not_to eq(described_class.gem_dir('fake-plugin' => '1.0.0'))
  end

  it 'does not depend on the order of plugins' do
    expect(described_class.gem_dir('first' => nil, 'second' => nil))
      .to eq(described_class.gem_dir('second' => nil, 'first' => nil))
  end
end
