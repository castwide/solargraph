# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

describe Solargraph::ApiMap do
  # A path gem whose Forwardable delegations are also declared in its sig/
  # directory, mapped from a workspace the way the language server maps it.
  before(:all) do # rubocop:disable RSpec/BeforeAfterAll
    @root = File.realpath(Dir.mktmpdir)
    @gem_dir = File.join(@root, 'gem-with-delegated-rbs')
    @workspace_dir = File.join(@root, 'workspace')

    write_file File.join(@gem_dir, 'gem-with-delegated-rbs.gemspec'), <<~RUBY
      Gem::Specification.new do |spec|
        spec.name = 'gem-with-delegated-rbs'
        spec.version = '0.1.0'
        spec.authors = ['Solargraph']
        spec.summary = 'A gem whose RBS types a Forwardable delegation'
        spec.files = Dir['lib/**/*.rb', 'sig/**/*.rbs']
        spec.require_paths = ['lib']
      end
    RUBY

    write_file File.join(@gem_dir, 'lib', 'delegated_rbs.rb'), <<~RUBY
      require 'forwardable'

      class DelegatedRbsTarget
        # Label of the target.
        def label
          'label'
        end

        # Title of the target.
        def title
          'title'
        end

        # Size of the target.
        #
        # @return [Integer]
        def size
          1
        end
      end

      class DelegatedRbs
        extend Forwardable

        def_delegator :helper, :name
        def_delegators :target, :label, :title, :size

        # @return [DelegatedRbsTarget]
        def target
          DelegatedRbsTarget.new
        end

        def helper
          Object.new
        end
      end
    RUBY

    write_file File.join(@gem_dir, 'sig', 'delegated_rbs.rbs'), <<~RBS
      class DelegatedRbs
        def name: () -> String

        def label: () -> String

        # Title of the delegator.
        def title: () -> String

        def size: () -> untyped
      end
    RBS

    write_file File.join(@workspace_dir, 'Gemfile'), <<~RUBY
      source 'https://rubygems.org'

      gem 'gem-with-delegated-rbs', path: '../gem-with-delegated-rbs'
    RUBY

    # Line numbers below are the 0-based lines of these calls.
    write_file File.join(@workspace_dir, 'app.rb'), <<~RUBY
      require 'delegated_rbs'

      holder = DelegatedRbs.new
      holder.label
      holder.title
      holder.size
      holder.name
    RUBY

    Solargraph.with_clean_env do
      `cd #{@workspace_dir} && bundle install --local`
    end
    @api_map = described_class.load(@workspace_dir)
  end

  after(:all) do # rubocop:disable RSpec/BeforeAfterAll
    FileUtils.remove_entry @root
  end

  attr_reader :api_map

  # @param path [String]
  # @param content [String]
  # @return [void]
  def write_file path, content
    FileUtils.mkdir_p File.dirname(path)
    File.write path, content
  end

  # The type a call infers and the documentation hover shows for it.
  #
  # @param line [Integer]
  # @return [Array(String, String)]
  def hover line
    clip = api_map.clip_at(File.join(@workspace_dir, 'app.rb'), [line, 9])
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

  it 'types a delegation from the RBS when mapping the gem alone' do
    metagem = Solargraph::Metagem.new(name: 'gem-with-delegated-rbs', full_path: @gem_dir,
                                      spec_file: File.join(@gem_dir, 'gem-with-delegated-rbs.gemspec'),
                                      source: "source at `#{@gem_dir}`", version: '0.1.0',
                                      require_paths: ['lib'], dependencies: [])
    gem_api_map = described_class.new(pins: Solargraph::Collection::Gem.new(metagem).pins)

    pin = gem_api_map.get_method_stack('DelegatedRbs', 'name').first

    expect(pin.typify(gem_api_map).to_s).to eq('String')
  end
end
