module Solargraph
  module Parser
    module Legacy
      module ClassMethods
        # @param code [String]
        # @param filename [String]
        # @return [Array(Parser::AST::Node, Array<Parser::Source::Comment>)]
        def parse_with_comments code, filename = nil
          buffer = ::Parser::Source::Buffer.new(filename, 0)
          buffer.source = code
          parser.parse_with_comments(buffer)
        end

        # @param code [String]
        # @param filename [String, nil]
        # @param line [Integer]
        # @return [Parser::AST::Node]
        def parse code, filename = nil, line = 0
          buffer = ::Parser::Source::Buffer.new(filename, line)
          buffer.source = code
          parser.parse(buffer)
        end

        # @return [Parser::Base]
        def parser
          # @todo Consider setting an instance variable. We might not need to
          #   recreate the parser every time we use it.
          parser = ::Parser::CurrentRuby.new(FlawedBuilder.new)
          parser.diagnostics.all_errors_are_fatal = true
          parser.diagnostics.ignore_warnings      = true
          parser
        end

        def map source
          NodeProcessor.process(source.node, Region.new(source: source))
        end

        def returns_from node
          NodeMethods.returns_from(node)
        end
      end
    end
  end
end
