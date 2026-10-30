# frozen_string_literal: true

class ProgressTestHost
  attr_reader :messages

  def initialize
    @messages = []
  end

  def client_supports_progress?
    true
  end

  def send_notification method, params
    @messages.push [method, params]
  end

  def send_request method, params, &block
    @messages.push [method, params]
  end

  def stopped?
    false
  end

  # @return [Array<Hash>]
  def progress_values
    @messages.filter_map do |method, params|
      params[:value] if method == '$/progress'
    end
  end
end

describe Solargraph::LanguageServer::Progress do
  it 'sends begin, report, and end notifications' do
    host = ProgressTestHost.new
    progress = described_class.new('Testing')
    progress.begin 'Started', 0
    progress.send host
    progress.report 'Working', 50
    progress.send host
    progress.finish 'done'
    progress.send host
    expect(host.messages.first.first).to eq 'window/workDoneProgress/create'
    expect(host.progress_values.map { |v| v[:kind] }).to eq %w[begin report end]
  end

  it 'does not send notifications after it finishes' do
    host = ProgressTestHost.new
    progress = described_class.new('Testing')
    progress.begin 'Started', 0
    progress.send host
    progress.finish 'done'
    progress.send host
    progress.report 'Too late', 75
    progress.send host
    progress.finish 'done again'
    progress.send host
    kinds = host.progress_values.map { |v| v[:kind] }
    expect(kinds).to eq %w[begin end]
    expect(progress.finished?).to be true
  end

  it 'keeps percentages within bounds' do
    progress = described_class.new('Testing')
    progress.begin 'Started', -10
    expect(progress.percentage).to eq 0
    progress.report 'Working', 120
    expect(progress.percentage).to eq 100
  end

  it 'keeps idle notifications alive until they finish' do
    stub_const 'Solargraph::LanguageServer::Progress::KEEP_ALIVE_INTERVAL', 0.05
    host = ProgressTestHost.new
    progress = described_class.new('Testing')
    progress.begin 'Started', 0
    progress.send host
    sleep 0.2
    alive_count = host.progress_values.length
    progress.finish 'done'
    progress.send host
    sleep 0.2
    expect(alive_count).to be > 1
    expect(host.progress_values.last[:kind]).to eq 'end'
    expect(host.progress_values.count { |v| v[:kind] == 'end' }).to eq 1
  end
end
