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
            FlowSensitiveTyping.new(locals,
                                    ivars,
                                    enclosing_breakable_pin,
                                    enclosing_compound_statement_pin).process_case_match(node)
            node => [_, ::Parser::AST::Node => subject, *]
            NodeProcessor.process(subject, region, pins, locals, ivars)
            unless node.type == :case_match
              node => [_, _, ::Parser::AST::Node => pattern]
              return add_captures(pattern, subject)
            end

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
            when :array_pattern, :find_pattern
              add_array_captures(pattern, subject)
            else
              pattern.children.each do |child|
                add_captures(child) if child.is_a?(::Parser::AST::Node)
              end
            end
          end

          # @param pattern [Parser::AST::Node] e.g. (match_as (const nil :Foo) (match_var :f))
          # @param subject [Parser::AST::Node, nil]
          # @return [void]
          def add_as_capture pattern, subject
            pattern => [:match_as, ::Parser::AST::Node => inner, ::Parser::AST::Node => var]
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
              elsif element in [:match_rest, ::Parser::AST::Node[:match_var, *] => rest_var]
                add_rest_capture(rest_var, subject, rest_range(pattern, index))
              else
                add_captures(element)
              end
            end
          end

          # A rest in an array or find pattern always binds an Array, of
          # the subject's elements when the subject is known
          #
          # @param rest_var [Parser::AST::Node] a match_var node
          # @param subject [Parser::AST::Node, nil]
          # @param range [::Range<Integer>] subject positions the rest covers
          # @return [void]
          def add_rest_capture rest_var, subject, range
            return add_capture(rest_var, comments: '@type [::Array]') if subject.nil?

            add_capture(rest_var, mass_assignment: [subject, range])
          end

          # Positions a rest covers, e.g. 1..-2 for `[a, *rest, b]`.  A
          # find pattern's rests can cover any position.
          #
          # @param pattern [Parser::AST::Node] an array_pattern or find_pattern
          # @param index [Integer] the rest's position in the pattern
          # @return [::Range<Integer>]
          def rest_range pattern, index
            return (0..) if pattern.type == :find_pattern

            after = pattern.children.length - index - 1
            after.zero? ? (index..) : (index..-(after + 1))
          end

          # @param var [Parser::AST::Node] a match_var node
          # @param assignment [Parser::AST::Node, nil]
          # @param mass_assignment [::Array(Parser::AST::Node, [Integer, ::Range<Integer>]), nil]
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
