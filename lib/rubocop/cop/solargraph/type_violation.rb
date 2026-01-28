# frozen_string_literal: true

require 'yard'
require 'rubocop-yard'
require 'solargraph'

module ::RuboCop
  module Cop
    module Solargraph
      # TODO: external_dependency_checksum should probably point to
      #   same things that invalidate Solargraph cache?  Also solargraph
      #   config?
      # TODO: Add one per type of typechecker error - there's a team concept'
      class TypeViolation < ::RuboCop::Cop::Base
        include RuboCop::Cop::YARD::Helper
        include RangeHelp

        # @param config [RuboCop::Config, nil]
        # @param options [Hash, nil]
        def initialize(config = nil, options = nil)
          @@directory = Dir.pwd
          # directory = File.realpath(options[:directory]) TODO allow options
          @@mutex ||= Mutex.new
          @@workspace ||= ::Solargraph::Workspace.new(@@directory)
          # level = options[:level].to_sym TODO
          @@level = :strong
          @@rules ||= @@workspace.rules(@@level)
          @@mutex.synchronize do
            # do this in a mutex as it takes a while and these get called in parallel
            @@api_map ||=
              ::Solargraph::ApiMap.load_with_cache(@@directory, $stdout,
                                                   loose_unions:
                                                     !@@rules.require_all_unique_types_support_call?)
          end
          super
        end

        def self.support_multiple_source?
          true
        end

        # @return [void]
        def on_new_investigation
          file = processed_source.file_path



          checker = ::Solargraph::TypeChecker.new(file,
                                                  api_map: @@api_map,
                                                  rules: @@rules, level: @@level,
                                                  workspace: @@workspace)
          # @return [::Array<::Solargraph::TypeChecker::Problem, nil>]
          problems = nil
          begin
            problems = checker.problems
          rescue ::Solargraph::FileNotFoundError
            # not a file covered by solargraph config
            return
          end

          # @sg-ignore Declared type
          #   Array<Solargraph::TypeChecker::Problem, nil> does not
          #   match inferred type nil for variable problems @type - I
          #   think because it doesn't understand the absolute
          #   ::Solargraph in the context of a class Solargraph
          #
          # @param problem [::Solargraph::TypeChecker::Problem]
          problems.each do |problem|
            # @type [::Parser::Source::Buffer]
            buffer = processed_source.buffer
            contents = buffer.source
            location = problem.location
            start_position = location.range.start
            end_position = location.range.ending
            begin_offset = ::Solargraph::Position.to_offset(contents, start_position)
            end_offset = ::Solargraph::Position.to_offset(contents, end_position)
            range = ::Parser::Source::Range.new(buffer,
                                                begin_offset,
                                                end_offset)


            add_offense(range, message: problem.message)
          end
        end
      end
    end
  end
end
