# frozen_string_literal: true

module Solargraph
  module Pin
    # The base class for method and attribute pins.
    #
    class Method < Callable
      include Solargraph::Parser::NodeMethods

      # @return [::Symbol] :public, :private, or :protected
      attr_reader :visibility

      # @return [Parser::AST::Node]
      attr_reader :node

      # @param visibility [::Symbol] :public, :protected, or :private
      # @param explicit [Boolean]
      # @param block [Pin::Signature, nil, ::Symbol]
      # @param node [Parser::AST::Node, nil]
      # @param attribute [Boolean]
      # @param signatures [::Array<Signature>, nil]
      # @param anon_splat [Boolean]
      def initialize visibility: :public, explicit: true, block: :undefined, node: nil, attribute: false, signatures: nil, anon_splat: false, **splat
        super(**splat)
        @visibility = visibility
        @explicit = explicit
        @block = block
        @node = node
        @attribute = attribute
        @signatures = signatures
        @anon_splat = anon_splat
      end

      def transform_types(&transform)
        # @todo 'super' alone should work here I think, but doesn't typecheck at level typed
        m = super(&transform)
        m.signatures = m.signatures.map do |sig|
          sig.transform_types(&transform)
        end
        m.block = block&.transform_types(&transform)
        m.signature_help = nil
        m.documentation = nil
        m
      end

      def all_rooted?
        super && parameters.all?(&:all_rooted?) && (!block || block&.all_rooted?) && signatures.all?(&:all_rooted?)
      end

      # @param signature [Pin::Signature]
      # @return [Pin::Method]
      def with_single_signature(signature)
        m = proxy signature.return_type
        m.signature_help = nil
        m.documentation = nil
        # @todo populating the single parameters/return_type/block
        #   arguments here seems to be needed for some specs to pass,
        #   even though we have a signature with the same information.
        #   Is this a problem for RBS-populated methods, which don't
        #   populate these three?
        m.parameters = signature.parameters
        m.return_type = signature.return_type
        m.block = signature.block
        m.signatures = [signature]
        m
      end

      def block?
        !block.nil?
      end

      # @return [Pin::Signature, nil]
      def block
        return @block unless @block == :undefined
        @block = signatures.first&.block
      end

      def completion_item_kind
        attribute? ? Solargraph::LanguageServer::CompletionItemKinds::PROPERTY : Solargraph::LanguageServer::CompletionItemKinds::METHOD
      end

      def symbol_kind
        attribute? ? Solargraph::LanguageServer::SymbolKinds::PROPERTY : LanguageServer::SymbolKinds::METHOD
      end

      def return_type
        @return_type ||= ComplexType.new(signatures.map(&:return_type).flat_map(&:items))
      end

      # @param parameters [::Array<Parameter>]
      # @param return_type [ComplexType]
      # @return [Signature]
      def generate_signature(parameters, return_type)
        block = nil
        yieldparam_tags = docstring.tags(:yieldparam)
        yieldreturn_tags = docstring.tags(:yieldreturn)
        generics = docstring.tags(:generic).map(&:name)
        needs_block_param_signature =
          parameters.last&.block? || !yieldreturn_tags.empty? || !yieldparam_tags.empty?
        if needs_block_param_signature
          yield_parameters = yieldparam_tags.map do |p|
            name = p.name
            decl = :arg
            if name
              decl = select_decl(name, false)
              name = clean_param(name)
            end
            Pin::Parameter.new(
              location: location,
              closure: self,
              comments: p.text,
              name: name,
              decl: decl,
              presence: location ? location.range : nil,
              return_type: ComplexType.try_parse(*p.types)
            )
          end
          yield_return_type = ComplexType.try_parse(*yieldreturn_tags.flat_map(&:types))
          block = Signature.new(generics: generics, parameters: yield_parameters, return_type: yield_return_type)
        end
        Signature.new(generics: generics, parameters: parameters, return_type: return_type, block: block)
      end

      # @return [::Array<Signature>]
      def signatures
        @signatures ||= begin
          top_type = generate_complex_type
          result = []
          result.push generate_signature(parameters, top_type) if top_type.defined?
          result.concat(overloads.map { |meth| generate_signature(meth.parameters, meth.return_type) }) unless overloads.empty?
          result.push generate_signature(parameters, @return_type || ComplexType::UNDEFINED) if result.empty?
          result
        end
      end

      # @return [String, nil]
      def detail
        # This property is not cached in an instance variable because it can
        # change when pins get proxied.
        detail = String.new
        detail += if signatures.length > 1
          "(*) "
        else
          "(#{signatures.first.parameters.map(&:full).join(', ')}) " unless signatures.first.parameters.empty?
        end.to_s
        detail += "=#{probed? ? '~' : (proxied? ? '^' : '>')} #{return_type.to_s}" unless return_type.undefined?
        detail.strip!
        return nil if detail.empty?
        detail
      end

      # @return [::Array<Hash>]
      def signature_help
        @signature_help ||= signatures.map do |sig|
          {
            label: name + '(' + sig.parameters.map(&:full).join(', ') + ')',
            documentation: documentation
          }
        end
      end

      def desc
        # ensure the signatures line up when logged
        if signatures.length > 1
          "\n#{to_rbs}\n"
        else
          to_rbs
        end
      end

      def to_rbs
        return nil if signatures.empty?

        rbs = "def #{name}: #{signatures.first.to_rbs}"
        signatures[1..].each do |sig|
          rbs += "\n"
          rbs += (' ' * (4 + name.length))
          rbs += "| #{name}: #{sig.to_rbs}"
        end
        rbs
      end

      def path
        @path ||= "#{namespace}#{(scope == :instance ? '#' : '.')}#{name}"
      end

      def typify api_map
        logger.debug { "Method#typify(self=#{self}, binder=#{binder}, closure=#{closure}, context=#{context.rooted_tags}, return_type=#{return_type.rooted_tags}) - starting" }
        decl = super
        unless decl.undefined?
          logger.debug { "Method#typify(self=#{self}, binder=#{binder}, closure=#{closure}, context=#{context}) => #{decl.rooted_tags.inspect} - decl found" }
          return decl
        end
        type = see_reference(api_map) || typify_from_super(api_map)
        logger.debug { "Method#typify(self=#{self}) - type=#{type.rooted_tags.inspect}" }
        unless type.nil?
          qualified = type.qualify(api_map, namespace)
          logger.debug { "Method#typify(self=#{self}) => #{qualified.rooted_tags.inspect}" }
          return qualified
        end
        if name.end_with?('?')
          logger.debug { "Method#typify(self=#{self}) => Boolean (? suffix)" }
          ComplexType::BOOLEAN
        else
          logger.debug { "Method#typify(self=#{self}) => undefined" }
          ComplexType::UNDEFINED
        end
      end

      def documentation
        if @documentation.nil?
          @documentation ||= super || ''
          param_tags = docstring.tags(:param)
          unless param_tags.nil? or param_tags.empty?
            @documentation += "\n\n" unless @documentation.empty?
            @documentation += "Params:\n"
            lines = []
            param_tags.each do |p|
              l = "* #{p.name}"
              l += " [#{escape_brackets(p.types.join(', '))}]" unless p.types.nil? or p.types.empty?
              l += " #{p.text}"
              lines.push l
            end
            @documentation += lines.join("\n")
          end
          yieldparam_tags = docstring.tags(:yieldparam)
          unless yieldparam_tags.nil? or yieldparam_tags.empty?
            @documentation += "\n\n" unless @documentation.empty?
            @documentation += "Block Params:\n"
            lines = []
            yieldparam_tags.each do |p|
              l = "* #{p.name}"
              l += " [#{escape_brackets(p.types.join(', '))}]" unless p.types.nil? or p.types.empty?
              l += " #{p.text}"
              lines.push l
            end
            @documentation += lines.join("\n")
          end
          yieldreturn_tags = docstring.tags(:yieldreturn)
          unless yieldreturn_tags.empty?
            @documentation += "\n\n" unless @documentation.empty?
            @documentation += "Block Returns:\n"
            lines = []
            yieldreturn_tags.each do |r|
              l = "*"
              l += " [#{escape_brackets(r.types.join(', '))}]" unless r.types.nil? or r.types.empty?
              l += " #{r.text}"
              lines.push l
            end
            @documentation += lines.join("\n")
          end
          return_tags = docstring.tags(:return)
          unless return_tags.empty?
            @documentation += "\n\n" unless @documentation.empty?
            @documentation += "Returns:\n"
            lines = []
            return_tags.each do |r|
              l = "*"
              l += " [#{escape_brackets(r.types.join(', '))}]" unless r.types.nil? or r.types.empty?
              l += " #{r.text}"
              lines.push l
            end
            @documentation += lines.join("\n")
          end
          @documentation += "\n\n" unless @documentation.empty?
          @documentation += "Visibility: #{visibility}"
          concat_example_tags
        end
        @documentation.to_s
      end

      def explicit?
        @explicit
      end

      def attribute?
        @attribute
      end

      def nearly? other
        super &&
          parameters == other.parameters &&
          scope == other.scope &&
          visibility == other.visibility
      end

      def probe api_map
        attribute? ? infer_from_iv(api_map) : infer_from_return_nodes(api_map)
      end

      def try_merge! pin
        return false unless super
        @node = pin.node
        @resolved_ref_tag = false
        true
      end

      # @return [::Array<Pin::Method>]
      def overloads
        # Ignore overload tags with nil parameters. If it's not an array, the
        # tag's source is likely malformed.
        @overloads ||= docstring.tags(:overload).select(&:parameters).map do |tag|
          Pin::Signature.new(
            generics: generics,
            parameters: tag.parameters.map do |src|
              name, decl = parse_overload_param(src.first)
              Pin::Parameter.new(
                location: location,
                closure: self,
                comments: tag.docstring.all.to_s,
                name: name,
                decl: decl,
                presence: location ? location.range : nil,
                return_type: param_type_from_name(tag, src.first)
              )
            end,
            return_type: ComplexType.try_parse(*tag.docstring.tags(:return).flat_map(&:types))
          )
        end
        @overloads
      end

      def anon_splat?
        @anon_splat
      end

      # @param [ApiMap]
      # @return [self]
      def resolve_ref_tag api_map
        return self if @resolved_ref_tag

        @resolved_ref_tag = true
        return self unless docstring.ref_tags.any?
        docstring.ref_tags.each do |tag|
          ref = if tag.owner.to_s.start_with?(/[#\.]/)
            api_map.get_methods(namespace)
                   .select { |pin| pin.path.end_with?(tag.owner.to_s) }
                   .first
          else
            # @todo Resolve relative namespaces
            api_map.get_path_pins(tag.owner.to_s).first
          end
          next unless ref

          docstring.add_tag(*ref.docstring.tags(:param))
        end
        self
      end

      protected

      attr_writer :block

      attr_writer :signatures

      attr_writer :signature_help

      attr_writer :documentation

      private

      # @param name [String]
      # @param asgn [Boolean]
      #
      # @return [::Symbol]
      def select_decl name, asgn
        if name.start_with?('**')
          :kwrestarg
        elsif name.start_with?('*')
          :restarg
        elsif name.start_with?('&')
          :blockarg
        elsif name.end_with?(':') && asgn
          :kwoptarg
        elsif name.end_with?(':')
          :kwarg
        elsif asgn
          :optarg
        else
          :arg
        end
      end

      # @param name [String]
      # @return [String]
      def clean_param name
        name.gsub(/[*&:]/, '')
      end

      # @param tag [YARD::Tags::OverloadTag]
      # @param name [String]
      #
      # @return [ComplexType]
      def param_type_from_name(tag, name)
        param = tag.tags(:param).select { |t| t.name == name }.first
        return ComplexType::UNDEFINED unless param
        ComplexType.try_parse(*param.types)
      end

      # @return [ComplexType]
      def generate_complex_type
        tags = docstring.tags(:return).map(&:types).flatten.compact
        return ComplexType::UNDEFINED if tags.empty?
        ComplexType.try_parse *tags
      end

      # @param api_map [ApiMap]
      # @return [ComplexType, nil]
      def see_reference api_map
        docstring.ref_tags.each do |ref|
          next unless ref.tag_name == 'return' && ref.owner
          result = resolve_reference(ref.owner.to_s, api_map)
          return result unless result.nil?
        end
        match = comments.match(/^[ \t]*\(see (.*)\)/m)
        return nil if match.nil?
        resolve_reference match[1], api_map
      end

      # @param api_map [ApiMap]
      # @return [ComplexType, nil]
      def typify_from_super api_map
        stack = api_map.get_method_stack(namespace, name, scope: scope).reject { |pin| pin.path == path }
        return nil if stack.empty?
        stack.each do |pin|
          return pin.return_type unless pin.return_type.undefined?
        end
        nil
      end

      # @param ref [String]
      # @param api_map [ApiMap]
      # @return [ComplexType, nil]
      def resolve_reference ref, api_map
        parts = ref.split(/[\.#]/)
        if parts.first.empty? || parts.one?
          path = "#{namespace}#{ref}"
        else
          fqns = api_map.qualify(parts.first, namespace)
          return ComplexType::UNDEFINED if fqns.nil?
          path = fqns + ref[parts.first.length] + parts.last
        end
        pins = api_map.get_path_pins(path)
        pins.each do |pin|
          type = pin.typify(api_map)
          return type unless type.undefined?
        end
        nil
      end

      # @return [Parser::AST::Node, nil]
      def method_body_node
        return nil if node.nil?
        return node.children[1].children.last if node.type == :DEFN
        return node.children[2].children.last if node.type == :DEFS
        return node.children[2] if node.type == :def || node.type == :DEFS
        return node.children[3] if node.type == :defs
        nil
      end

      # @param api_map [ApiMap]
      # @return [ComplexType]
      def infer_from_return_nodes api_map
        return ComplexType::UNDEFINED if node.nil?
        result = []
        has_nil = false
        return ComplexType::NIL if method_body_node.nil?
        returns_from_method_body(method_body_node).each do |n|
          if n.nil? || [:NIL, :nil].include?(n.type)
            has_nil = true
            next
          end
          rng = Range.from_node(n)
          next unless rng
          clip = api_map.clip_at(
            location.filename,
            rng.ending
          )
          chain = Solargraph::Parser.chain(n, location.filename)
          type = chain.infer(api_map, self, clip.locals)
          result.push type unless type.undefined?
        end
        result.push ComplexType::NIL if has_nil
        return ComplexType::UNDEFINED if result.empty?
        ComplexType.new(result.uniq)
      end

      # @param [ApiMap] api_map
      # @return [ComplexType]
      def infer_from_iv api_map
        types = []
        varname = "@#{name.gsub(/=$/, '')}"
        pins = api_map.get_instance_variable_pins(binder.namespace, binder.scope).select { |iv| iv.name == varname }
        pins.each do |pin|
          type = pin.typify(api_map)
          type = pin.probe(api_map) if type.undefined?
          types.push type if type.defined?
        end
        return ComplexType::UNDEFINED if types.empty?
        ComplexType.new(types.uniq)
      end

      # When YARD parses an overload tag, it includes rest modifiers in the parameters names.
      #
      # @param name [String]
      # @return [::Array(String, ::Symbol)]
      def parse_overload_param(name)
        # @todo this needs to handle mandatory vs not args, kwargs, blocks, etc
        if name.start_with?('**')
          [name[2..-1], :kwrestarg]
        elsif name.start_with?('*')
          [name[1..-1], :restarg]
        else
          [name, :arg]
        end
      end

      # @return [void]
      def concat_example_tags
        example_tags = docstring.tags(:example)
        return if example_tags.empty?
        @documentation += "\n\nExamples:\n\n```ruby\n"
        @documentation += example_tags.map do |tag|
          (tag.name && !tag.name.empty? ? "# #{tag.name}\n" : '') +
            "#{tag.text}\n"
        end
        .join("\n")
        .concat("```\n")
      end

      protected

      attr_writer :signatures
    end
  end
end
