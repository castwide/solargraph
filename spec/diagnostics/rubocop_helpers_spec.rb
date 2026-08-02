# frozen_string_literal: true

describe Solargraph::Diagnostics::RubocopHelpers, order: :defined do
  context 'with custom version' do
    around do |example|
      old_gem_path = Gem.paths.path
      custom_gem_path = File.absolute_path('spec/fixtures/rubocop-custom-version').gsub('\\', '/')
      # Remove a post_reset hook set by bundler to restore cached specs
      # Source: https://github.com/ruby/ruby/blob/master/lib/bundler/rubygems_integration.rb#L487-L489
      old_post_reset_hooks = Gem.post_reset_hooks.dup
      Gem.post_reset_hooks.clear
      Gem.paths = { 'GEM_PATH' => [custom_gem_path, *old_gem_path].join(Gem.path_separator) }
      # Whether our require_rubocop(custom_version) call below actually
      # swapped in the fixture version, versus being a no-op because
      # something else in this process (e.g. a `require 'rubocop'` at the
      # top of another spec file) already loaded the real gem first -
      # Kernel#require only ever executes a given resolved path once.
      example.run
      swapped_to_custom_version = defined?(RuboCop) && custom_version == RuboCop::Version::STRING
      old_post_reset_hooks.each(&Gem.post_reset_hooks.method(:<<))
      Gem.paths = { 'GEM_PATH' => old_gem_path.join(Gem.path_separator) }
      # Cleanup loaded classes from custom gem path
      $LOAD_PATH.delete_if { |path| path[custom_gem_path] }
      # RuboCop is a process-global constant, not scoped to this example -
      # other specs/code running later in this same process (formatting,
      # Library#diagnose, etc.) expect it to stay defined as the real,
      # bundled version. Only remove/reload it if we actually swapped it
      # out for the fixture version above; otherwise it's already the
      # real version (untouched), and remove_const would just leave it
      # undefined, since re-requiring the same already-loaded path is a
      # no-op and won't redefine it.
      if swapped_to_custom_version
        Object.send(:remove_const, 'RuboCop')
        described_class.require_rubocop
      end
    end

    let(:custom_version) { '0.0.0' }

    it 'requires the specified version of rubocop' do
      input = custom_version
      described_class.require_rubocop(input)
      output = RuboCop::Version::STRING
      expect(output).to eq(custom_version)
    end
  end

  context 'with real version' do
    let(:default_version) { Gem::Specification.find_by_name('rubocop').full_gem_path[/[^-]+$/] }

    it 'requires the default version of rubocop' do
      input = nil
      described_class.require_rubocop(input)
      output = RuboCop::Version::STRING
      expect(output).to eq(default_version)
    end
  end

  it 'converts lower-case drive letters to upper-case' do
    input = 'c:/one/two'
    output = described_class.fix_drive_letter(input)
    expect(output).to eq('C:/one/two')
  end

  it 'ignores paths without drive letters' do
    input = 'one/two'
    output = described_class.fix_drive_letter(input)
    expect(output).to eq('one/two')
  end
end
