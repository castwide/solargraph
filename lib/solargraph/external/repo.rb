# frozen_string_literal: true

require 'open3'

module Solargraph
  class External
    class Repo
      def initialize directory
        @directory = directory
        @metagems = build_from_directory
      end

      def find_by_path path
        return system_find_by_path(path) unless @metagems

        @metagems.find { |mg| mg.require?(path) }
      end

      def find_by_name name
        return system_find_by_name(name) unless @metagems

        @metagems.find { |mg| mg.name == name }
      end

      def bundle?
        !!@metagems
      end

      private

      def build_from_directory
        return unless File.file?(File.join(@directory, 'Gemfile'))

        Solargraph.with_clean_env do
          cmd = [
            'ruby', '-e',
            "require 'bundler/setup'; require 'json'; Dir.chdir('#{@directory}') { puts Gem::Specification.all.map { |spec| { name: spec.name, full_path: spec.full_gem_path, spec_file: spec.spec_file, source: spec.source.to_s, version: spec.version, require_paths: spec.require_paths, dependencies: spec.dependencies.map(&:name) } }.to_json }"
          ]
          o, e, s = Open3.capture3(*cmd)
          if s.success?
            Solargraph.logger.debug "External bundle: #{o}"
            list = o && !o.empty? ? JSON.parse(o.split("\n").last, symbolize_names: true) : {}
            list.map { |hash| Metagem.new(**hash) }
          else
            Solargraph.logger.warn "Failed to load gems from bundle at #{@directory}: #{e}"
            nil
          end
        end
      end

      def system_find_by_path path
        gem = Gem::Specification.find_by_path(path)
        gem && Metagem.from_specification(gem)
      end

      def system_find_by_name name
        gem = Gem::Specification.find_by_name(name)
        gem && Metagem.from_specification(gem)
      rescue Gem::MissingSpecError => _e
        nil
      end
    end
  end
end
