# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        # Pattern matching: `case ... in`, `subject => pattern` and
        # `subject in pattern`.  Captures become local variables that
        # stay in scope after the match, as Ruby defines them.
        #
        #   case x                              (case_match (lvar :x)
        #   in Foo => f if f.ok?                  (in_pattern
        #     f                                     (match_as (const nil :Foo) (match_var :f))
        #   end                                     (if_guard ...) (lvar :f)) nil)
        class CaseMatchNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          # @return [void]
          def process
            # @type [Parser::AST::Node]
            subject = node.children.fetch(0)
            NodeProcessor.process(subject, region, pins, locals, ivars)
            return add_captures(node.children.fetch(1), subject) unless node.type == :case_match

            # @type [Array<Parser::AST::Node>]
            clauses = node.children.drop(1).compact
            clauses.each do |clause|
              next process_body(clause) unless clause.type == :in_pattern

              pattern, guard, body = clause.children
              # Captures first, so a guard reading one resolves it
              add_captures(pattern, subject)
              NodeProcessor.process(guard, region, pins, locals, ivars)
              process_body(body)
            end
          end

          private

          # @param body [Parser::AST::Node, nil] an `in` clause body or the `else` body
          # @return [void]
          def process_body body
            return if body.nil?

            pins.push Solargraph::Pin::CompoundStatement.new(
              location: get_node_location(body),
              closure: region.closure,
              node: body,
              source: :parser
            )
            NodeProcessor.process(body, region, pins, locals, ivars)
          end

          # Typed captures: a top-level `in y` or `=> y` is the subject,
          # `Foo => f` is a Foo, and `[a, b, *]` indexes into the subject.
          # Anything deeper is left untyped.
          #
          # @param pattern [Parser::AST::Node]
          # @param subject [Parser::AST::Node, nil] nil below the top level
          # @return [void]
          def add_captures pattern, subject = nil
            case pattern.type
            when :match_var
              add_capture(pattern, assignment: subject)
            when :match_as
              add_as_capture(pattern, subject)
            when :array_pattern
              add_array_captures(pattern, subject)
            else
              pattern.children.each do |child|
                add_captures(child) if Parser.is_ast_node?(child)
              end
            end
          end

          # @param pattern [Parser::AST::Node] e.g. (match_as (const nil :Foo) (match_var :f))
          # @param subject [Parser::AST::Node, nil]
          # @return [void]
          def add_as_capture pattern, subject
            # @type [Parser::AST::Node]
            inner = pattern.children.fetch(0)
            # @type [Parser::AST::Node]
            var = pattern.children.fetch(1)
            type_name = pattern_type_name(inner)
            if type_name
              add_capture(var, comments: "@type [#{type_name}]")
            else
              add_capture(var, assignment: subject)
            end
            add_captures(inner, subject)
          end

          # @param pattern [Parser::AST::Node] e.g. (array_pattern (match_var :a) (match_rest))
          # @param subject [Parser::AST::Node, nil]
          # @return [void]
          def add_array_captures pattern, subject
            # @type [Array<Parser::AST::Node>]
            elements = pattern.children
            # Indexes stop meaning anything after a splat
            indexed = elements.take_while { |element| element.type != :match_rest }
            elements.each_with_index do |element, index|
              if subject && index < indexed.length && element.type == :match_var
                add_capture(element, mass_assignment: [subject, index])
              else
                add_captures(element)
              end
            end
          end

          # @param var [Parser::AST::Node] a match_var node
          # @param assignment [Parser::AST::Node, nil]
          # @param mass_assignment [::Array(Parser::AST::Node, Integer), nil]
          # @param comments [String, nil]
          # @return [void]
          def add_capture var, assignment: nil, mass_assignment: nil, comments: nil
            closure_location = region.closure.location
            # Captures outlive the match, like any local assignment
            presence = Range.new(get_node_start_position(var), closure_location.range.ending) if closure_location
            locals.push Solargraph::Pin::LocalVariable.new(
              location: get_node_location(var),
              closure: region.closure,
              name: var.children.fetch(0).to_s,
              assignment: assignment,
              mass_assignment: mass_assignment,
              comments: comments,
              presence: presence,
              source: :parser
            )
          end
        end
      end
    end
  end
end
