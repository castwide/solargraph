# frozen_string_literal: true

describe Solargraph::LanguageServer::Message::Extended::DocumentGems do
  let(:host) { Solargraph::LanguageServer::Host.new }
  let(:success) { instance_double(Process::Status, success?: true) }

  def library_in directory, plugins
    workspace = instance_double(Solargraph::Workspace, directory: directory, plugins: plugins)
    instance_double(Solargraph::Library, workspace: workspace)
  end

  it 'caches the gems of each workspace with its plugins' do
    allow(host).to receive(:libraries).and_return([library_in('/work/app', %w[plugin_a plugin_b]),
                                                   library_in('/work/gem', [])])
    allow(Open3).to receive(:capture2).and_return(['', success])

    described_class.new(host, { 'params' => { 'rebuild' => true } }).process

    expect(Open3).to have_received(:capture2)
      .with('solargraph', 'gems', '--rebuild', '--directory', '/work/app', "--plugins=plugin_a#{File::PATH_SEPARATOR}plugin_b")
    expect(Open3).to have_received(:capture2).with('solargraph', 'gems', '--rebuild', '--directory', '/work/gem', '--plugins=')
  end

  it 'caches without a workspace when no library has a directory' do
    allow(host).to receive(:libraries).and_return([library_in('', [])])
    allow(Open3).to receive(:capture2).and_return(['', success])

    message = described_class.new(host, {})
    message.process

    expect(Open3).to have_received(:capture2).with('solargraph', 'gems')
    expect(message.result).to eq({ status: 'ok' })
  end

  it 'reports an error when a workspace fails to cache' do
    allow(host).to receive(:libraries).and_return([library_in('/work/app', [])])
    allow(Open3).to receive(:capture2).and_return(['', instance_double(Process::Status, success?: false)])
    allow(host).to receive(:show_message)

    message = described_class.new(host, {})
    message.process

    expect(message.result).to eq({ status: 'err' })
  end
end
