# frozen_string_literal: true

describe Solargraph::Convention::Gemfile do
  describe 'parsing Gemfiles' do
    def type_checker code
      Solargraph::TypeChecker.load_string(code, 'Gemfile', :strong)
    end

    it 'typechecks valid files without error' do
      checker = type_checker(%(
        source 'https://rubygems.org'

        ruby "~> 3.3.5"

        gemspec name: 'solargraph'

        # Local gemfile for development tools, etc.
        local_gemfile = File.expand_path(".Gemfile", __dir__)
        instance_eval File.read local_gemfile if File.exist? local_gemfile
      ))

      expect(checker.problems).to be_empty
    end

    it 'finds bad arguments to DSL methods' do
      checker = type_checker(%(
        source File

        gemspec bad_name: 'solargraph'

        # Local gemfile for development tools, etc.
        local_gemfile = File.expand_path(".Gemfile", __dir__)
        instance_eval File.read local_gemfile if File.exist? local_gemfile
      ))

      expect(checker.problems.map(&:message).sort)
        .to eq(['Unrecognized keyword argument bad_name to Bundler::Dsl#gemspec',
                'Wrong argument type for Bundler::Dsl#source: source expected String, received Class<File>'].sort)
    end

    it 'finds bad arguments to DSL ruby method' do
      pending 'missing support for restargs in the typechecker'

      checker = type_checker(%(
        ruby 123
      ))

      expect(checker.problems.map(&:message))
        .to eq(['Wrong argument type for Bundler::Dsl#ruby: ruby_version expected String, received Integer'])
    end
  end
end
