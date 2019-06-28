# frozen_string_literal: true

require 'bundler'
require 'json'
require 'open3'
require 'shellwords'
require 'yard'

module Solargraph
  class Documentor
    RDOC_GEMS = %w[
      actioncable actionmailbox actionmailer actionpack actiontext actionview
      activejob activemodel activerecord activestorage activesupport railties
    ]

    def initialize directory, rebuild: false
      @directory = directory
      @rebuild = rebuild
    end

    # @return [Boolean] True if all specs were found and documented.
    def document
      failures = 0
      Documentor.specs_from_bundle(@directory).each_pair do |name, version|
        yd = YARD::Registry.yardoc_file_for_gem(name, "= #{version}")
        if !yd || @rebuild
          puts "Documenting #{name} #{version}"
          `yard gems #{name} #{version} #{@rebuild ? '--rebuild' : ''}`
          yd = YARD::Registry.yardoc_file_for_gem(name, "= #{version}")
          if !yd
            puts "#{name} #{version} YARD documentation failed"
            failed += 1
          end
        end
        if yd && RDOC_GEMS.include?(name)
          cache = File.join(Solargraph::YardMap::CoreDocs.cache_dir, 'gems', "#{name}-#{version}", 'yardoc')
          if !File.exist?(cache) || @rebuild
            puts "Caching custom documentation for #{name} #{version}"
            spec = Gem::Specification.find_by_name(name, "= #{version}")
            Solargraph::YardMap::RdocToYard.run(spec)
          end
        end
      end
      if failures > 0
        puts "#{failures} gem#{failures == 1 ? '' : 's'} could not be documented. You might need to run `bundle install` first."
      end
      failures == 0
    end

    def self.specs_from_bundle directory
      Bundler.with_clean_env do
        cmd = "cd #{Shellwords.escape(directory)} && bundle exec ruby -e \"require 'bundler'; require 'json'; puts Bundler.definition.specs_for([:default]).map { |spec| [spec.name, spec.version] }.to_h.to_json\""
        o, e, s = Open3.capture3(cmd)
        if s.success?
          o && !o.empty? ? JSON.parse(o) : {}
        else
          Solargraph.logger.warn e
          raise BundleNotFoundError, "Failed to load gems from bundle at #{directory}"
        end
      end
    end
  end
end
