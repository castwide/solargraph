# frozen_string_literal: true

describe Solargraph::ApiMap do
  # A path gem whose Forwardable delegations are also declared in its sig/
  # directory, mapped from a workspace the way the language server maps it.
  let(:directory) { File.join('spec', 'fixtures', 'workspace-with-delegated-rbs-gem') }
  let(:filename) { File.expand_path(File.join(directory, 'app.rb')) }

  before(:all) do # rubocop:disable RSpec/BeforeAfterAll
    Solargraph.with_clean_env do
      `cd #{File.join('spec', 'fixtures', 'workspace-with-delegated-rbs-gem')} && bundle install --local`
    end
    @api_map = described_class.load(File.join('spec', 'fixtures', 'workspace-with-delegated-rbs-gem'))
  end

  after(:all) do # rubocop:disable RSpec/BeforeAfterAll
    FileUtils.rm_f File.join('spec', 'fixtures', 'workspace-with-delegated-rbs-gem', 'Gemfile.lock')
  end

  attr_reader :api_map

  # The type a call infers and the documentation hover shows for it.
  #
  # @param line [Integer]
  # @return [Array(String, String)]
  def hover line
    clip = api_map.clip_at(filename, [line, 9])
    [clip.infer.to_s, clip.define.map(&:documentation).join("\n")]
  end

  it 'types a delegation from its RBS signature' do
    expect(hover(3).first).to eq('String')
  end

  it 'documents a delegation from its RBS comment' do
    type, docs = hover(4)

    expect(type).to eq('String')
    expect(docs).to include('Title of the delegator.')
  end

  it 'types a delegation from the target method when the RBS is untyped' do
    expect(hover(5).first).to eq('Integer')
  end

  it 'types an unresolvable delegation from its RBS signature' do
    expect(hover(6).first).to eq('String')
  end
end
