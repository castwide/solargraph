# frozen_string_literal: true

require 'tmpdir'

describe Solargraph::Collection::Gem do
  describe '#pins' do
    around do |example|
      Dir.mktmpdir do |dir|
        @gem_dir = dir
        example.run
      end
    end

    # @param dependencies [Array<String>]
    # @return [Array<Solargraph::Pin::Base>]
    def gem_pins dependencies
      FileUtils.mkdir_p File.join(@gem_dir, 'lib', 'foo')
      File.write File.join(@gem_dir, 'lib', 'foo', 'logging.rb'), %(
        module Foo
          module Logging
            extend ActiveSupport::Concern

            included do
              cattr_accessor :logger, default: Logger.new($stdout)
              class_attribute :log_arguments, instance_accessor: false, default: true
            end
          end
        end
      )
      metagem = Solargraph::Metagem.new(name: 'foo', full_path: @gem_dir, spec_file: nil,
                                        source: "source at #{@gem_dir}", version: '1.0.0',
                                        require_paths: ['lib'], dependencies: dependencies)
      described_class.new(metagem).pins
    end

    it 'creates accessor pins for ActiveSupport macros in a gem depending on activesupport' do
      paths = gem_pins(['activesupport']).map(&:path)
      expect(paths).to include('Foo::Logging#logger', 'Foo::Logging#logger=',
                               'Foo::Logging.logger', 'Foo::Logging.logger=',
                               'Foo::Logging.log_arguments', 'Foo::Logging.log_arguments=')
    end

    it 'skips ActiveSupport macros in a gem without activesupport' do
      paths = gem_pins([]).map(&:path)
      expect(paths).not_to include('Foo::Logging#logger', 'Foo::Logging.log_arguments')
    end
  end
end
