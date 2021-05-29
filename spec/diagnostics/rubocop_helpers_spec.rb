describe Solargraph::Diagnostics::RubocopHelpers do
  context do
    around do |example|
      old_gem_path = Gem.paths.path
      custom_gem_path = File.absolute_path('spec/fixtures/rubocop-custom-version').gsub(/\\/, '/')
      # Remove a post_reset hook set by bundler to restore cached specs
      # Source: https://github.com/ruby/ruby/blob/master/lib/bundler/rubygems_integration.rb#L487-L489
      old_post_reset_hooks = Gem.post_reset_hooks.dup
      Gem.post_reset_hooks.clear
      Gem.paths = { 'GEM_PATH' => [custom_gem_path, *old_gem_path].join(Gem.path_separator) }
      example.run
      old_post_reset_hooks.each(&Gem.post_reset_hooks.method(:<<))
      Gem.paths = { 'GEM_PATH' => old_gem_path.join(Gem.path_separator) }
      # Cleanup loaded classes from custom gem path
      $LOAD_PATH.delete_if { |path| path[custom_gem_path] }
      Object.send(:remove_const, 'RuboCop')
    end

    let(:custom_version) { '0.0.0' }

    it "requires the specified version of rubocop" do
      input = custom_version
      Solargraph::Diagnostics::RubocopHelpers.require_rubocop(input)
      output = RuboCop::Version::STRING
      expect(output).to eq(custom_version)
    end
  end

  context do
    let(:default_version) { Gem::Specification.find_by_name('rubocop').full_gem_path[/[^-]+$/] }

    it "requires the default version of rubocop" do
      input = nil
      Solargraph::Diagnostics::RubocopHelpers.require_rubocop(input)
      output = RuboCop::Version::STRING
      expect(output).to eq(default_version)
    end
  end

  it "converts lower-case drive letters to upper-case" do
    input = 'c:/one/two'
    output = Solargraph::Diagnostics::RubocopHelpers.fix_drive_letter(input)
    expect(output).to eq('C:/one/two')
  end

  it "ignores paths without drive letters" do
    input = 'one/two'
    output = Solargraph::Diagnostics::RubocopHelpers.fix_drive_letter(input)
    expect(output).to eq('one/two')
  end
end
