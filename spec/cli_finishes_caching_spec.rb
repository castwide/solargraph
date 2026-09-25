# frozen_string_literal: true

require 'open3'

# `solargraph gems` offers its cache directory as something to keep between CI
# runs, so what it leaves there has to be everything a later editor session
# needs.
describe Solargraph::Shell do
  let(:shell) do
    described_class.new.tap do |cli|
      cli.options = Thor::CoreExt::HashWithIndifferentAccess.new({})
    end
  end

  let(:directory) { File.expand_path(File.join('spec', 'fixtures', 'bundle-scoped-gems')) }

  # The directory the command names in its own help text.
  #
  # @return [String]
  def cache_dir
    ENV['SOLARGRAPH_CACHE'] || File.join(Dir.home, '.cache', 'solargraph')
  end

  # Scoped to this Solargraph, so another version's run cannot answer for it.
  #
  # @return [Array<String>]
  def cached_backport_files
    Dir.glob(File.join(cache_dir, '**', '*backport*'))
       .select { |path| File.file?(path) && path.include?("solargraph-#{Solargraph::VERSION}") }
       .sort
  end

  # Gem pins are memoized for the life of a process, so a load here would
  # answer from memory and write nothing whatever the cache holds.
  #
  # @return [void]
  def open_the_workspace_elsewhere
    script = "require 'solargraph'; " \
             "Solargraph::ApiMap.load(#{directory.inspect}).get_path_pins('Backport')"
    output, status = Open3.capture2e(RbConfig.ruby, '-e', script)
    raise output unless status.success?
  end

  # @return [Array<String>] cache entries the editor had to write for itself
  def written_by_editor
    already_cached = cached_backport_files
    open_the_workspace_elsewhere
    cached_backport_files - already_cached
  end

  before { capture_both { shell.uncache('backport') } }

  it 'finishes the job when told to cache one gem' do
    pending 'https://github.com/apiology/solargraph/pull/103'
    Dir.chdir(directory) { capture_both { shell.cache('backport') } }

    expect(written_by_editor).to be_empty
  end

  it 'finishes the job when told to cache the workspace' do
    pending 'https://github.com/apiology/solargraph/pull/103'
    Dir.chdir(directory) { capture_both { shell.gems } }

    expect(written_by_editor).to be_empty
  end
end
