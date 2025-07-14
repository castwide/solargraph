describe Solargraph::Convention::Gemfile do
  describe 'parsing Gemfiles' do
    def type_checker(code)
      Solargraph::TypeChecker.load_string(code, 'Gemfile', :strong)
    end

    it 'typechecks valid files without error' do
      checker = type_checker(%(
        source 'https://rubygems.org'

        gemspec name: 'solargraph'

        # Local gemfile for development tools, etc.
        local_gemfile = File.expand_path(".Gemfile", __dir__)
        instance_eval File.read local_gemfile if File.exist? local_gemfile
      ))

      expect(checker.problems).to be_empty
    end
  end
end
