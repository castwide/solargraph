# frozen_string_literal: true

module Solargraph
  module Pin
    # The base class for map pins.
    #
    class Base
      include Common
      include Conversions
      include Documenting
      include Logging

      # @return [YARD::CodeObjects::Base]
      attr_reader :code_object

      # @return [Solargraph::Location]
      attr_reader :location

      # @return [Solargraph::Location]
      attr_reader :type_location

      # @return [String]
      attr_reader :name

      # @return [String]
      attr_reader :path

      # @return [::Symbol]
      attr_accessor :source

      def presence_certain?
        true
      end

      # @param location [Solargraph::Location, nil]
      # @param type_location [Solargraph::Location, nil]
      # @param closure [Solargraph::Pin::Closure, nil]
      # @param name [String]
      # @param comments [String]
      # @param source [Symbol, nil]
      # @param docstring [YARD::Docstring, nil]
      # @param directives [::Array<YARD::Tags::Directive>, nil]
      def initialize location: nil, type_location: nil, closure: nil, source: nil, name: '', comments: '', docstring: nil, directives: nil
        @location = location
        @type_location = type_location
        @closure = closure
        @name = name
        @comments = comments
        @source = source
        @identity = nil
        @docstring = docstring
        @directives = directives
        assert_source_provided
        assert_location_provided
      end

      # @return [void]
      def assert_location_provided
        return unless best_location.nil? && %i[yardoc source rbs].include?(source)

        Solargraph.assert_or_log(:best_location, "Neither location nor type_location provided - #{path} #{source} #{self.class}")
      end

      # @param other [self]
      # @param attrs [Hash{Symbol => Object}]
      #
      # @return [self]
      def combine_with(other, attrs={})
        raise "tried to combine #{other.class} with #{self.class}" unless other.class == self.class
        type_location = choose(other, :type_location)
        location = choose(other, :location)
        combined_name = combine_name(other)
        new_attrs = {
          location: location,
          type_location: type_location,
          name: combined_name,
          closure: choose_pin_attr_with_same_name(other, :closure),
          comments: choose_longer(other, :comments),
          source: :combined,
          docstring: choose(other, :docstring),
          directives: combine_directives(other),
        }.merge(attrs)
        assert_same_macros(other)
        logger.debug { "Base#combine_with(path=#{path}) - other.comments=#{other.comments.inspect}, self.comments = #{self.comments}" }
        out = self.class.new(**new_attrs)
        out.reset_generated!
        out
      end

      # @param other [self]
      # @param attr [::Symbol]
      # @sg-ignore
      # @return [undefined]
      def choose_longer(other, attr)
        # @type [undefined]
        val1 = send(attr)
        # @type [undefined]
        val2 = other.send(attr)
        return val1 if val1 == val2
        return val2 if val1.nil?
        # @sg-ignore
        val1.length > val2.length ? val1 : val2
      end

      # @param other [self]
      # @return [::Array<YARD::Tags::Directive>, nil]
      def combine_directives(other)
        return self.directives if other.directives.empty?
        return other.directives if directives.empty?
        [directives + other.directives].uniq
      end

      # @param other [self]
      # @return [String]
      def combine_name(other)
        if needs_consistent_name? || other.needs_consistent_name?
          assert_same(other, :name)
        else
          choose(other, :name)
        end
      end

      # @return [void]
      def reset_generated!
        # @return_type doesn't go here as subclasses tend to assign it
        # themselves in constructors, and they will deal with setting
        # it in any methods that call this
        #
        # @docstring also doesn't go here, as there is code which
        # directly manipulates docstring without editing comments
        # (e.g., Api::Map::Store#index processes overrides that way
        #
        # Same with @directives, @macros, @maybe_directives, which
        # regenerate docstring
        @deprecated = nil
        reset_conversions
      end

      def needs_consistent_name?
        true
      end

      # @sg-ignore def should infer as symbol - "Not enough arguments to Module#protected"
      protected def equality_fields
        [name, location, type_location, closure, source]
      end

      # @param other [self]
      # @return [ComplexType]
      def combine_return_type(other)
        if return_type.undefined?
          other.return_type
        elsif other.return_type.undefined?
          return_type
        elsif dodgy_return_type_source? && !other.dodgy_return_type_source?
          other.return_type
        elsif other.dodgy_return_type_source? && !dodgy_return_type_source?
          return_type
        else
          all_items = return_type.items + other.return_type.items
          if all_items.any? { |item| item.selfy? } && all_items.any? { |item| item.rooted_tag == context.rooted_tag }
            # assume this was a declaration that should have said 'self'
            all_items.delete_if { |item| item.rooted_tag == context.rooted_tag }
          end
          ComplexType.new(all_items)
        end
      end

      def dodgy_return_type_source?
        # uses a lot of 'Object' instead of 'self'
        location&.filename&.include?('core_ext/object/')
      end

      # when choices are arbitrary, make sure the choice is consistent
      #
      # @param other [Pin::Base]
      # @param attr [::Symbol]
      #
      # @return [Object, nil]
      def choose(other, attr)
        results = [self, other].map(&attr).compact
        # true and false are different classes and can't be sorted
        return true if results.any? { |r| r == true || r == false }
        results.min
      rescue
        STDERR.puts("Problem handling #{attr} for \n#{self.inspect}\n and \n#{other.inspect}\n\n#{self.send(attr).inspect} vs #{other.send(attr).inspect}")
        raise
      end

      # @param other [self]
      # @param attr [Symbol]
      # @sg-ignore
      # @return [undefined]
      def choose_node(other, attr)
        if other.object_id < attr.object_id
          other.send(attr)
        else
          send(attr)
        end
      end

      # @param other [self]
      # @param attr [::Symbol]
      # @sg-ignore
      # @return [undefined]
      def prefer_rbs_location(other, attr)
        if rbs_location? && !other.rbs_location?
          self.send(attr)
        elsif !rbs_location? && other.rbs_location?
          other.send(attr)
        else
          choose(other, attr)
        end
      end

      def rbs_location?
        type_location&.rbs?
      end

      # @param other [self]
      # @return [void]
      def assert_same_macros(other)
        return unless self.source == :yardoc && other.source == :yardoc
        assert_same_count(other, :macros)
        assert_same_array_content(other, :macros) { |macro| macro.tag.name }
      end

      # @param other [self]
      # @param attr [::Symbol]
      # @return [void]
      # @todo strong typechecking should complain when there are no block-related tags
      def assert_same_array_content(other, attr, &block)
        arr1 = send(attr)
        raise "Expected #{attr} on #{self} to be an Enumerable, got #{arr1.class}" unless arr1.is_a?(::Enumerable)
        # @type arr1 [::Enumerable]
        arr2 = other.send(attr)
        raise "Expected #{attr} on #{other} to be an Enumerable, got #{arr2.class}" unless arr2.is_a?(::Enumerable)
        # @type arr2 [::Enumerable]

        # @sg-ignore
        # @type [undefined]
        values1 = arr1.map(&block)
        # @type [undefined]
        values2 = arr2.map(&block)
        # @sg-ignore
        return arr1 if values1 == values2
        Solargraph.assert_or_log("combine_with_#{attr}".to_sym,
                                 "Inconsistent #{attr.inspect} values between \nself =#{inspect} and \nother=#{other.inspect}:\n\n self values = #{values1}\nother values =#{attr} = #{values2}")
        arr1
      end

      # @param other [self]
      # @param attr [::Symbol]
      #
      # @return [::Enumerable]
      def assert_same_count(other, attr)
        # @type [::Enumerable]
        arr1 = self.send(attr)
        raise "Expected #{attr} on #{self} to be an Enumerable, got #{arr1.class}" unless arr1.is_a?(::Enumerable)
        # @type [::Enumerable]
        arr2 = other.send(attr)
        raise "Expected #{attr} on #{other} to be an Enumerable, got #{arr2.class}" unless arr2.is_a?(::Enumerable)
        return arr1 if arr1.count == arr2.count
        Solargraph.assert_or_log("combine_with_#{attr}".to_sym,
                                 "Inconsistent #{attr.inspect} count value between \nself =#{inspect} and \nother=#{other.inspect}:\n\n self.#{attr} = #{arr1.inspect}\nother.#{attr} = #{arr2.inspect}")
        arr1
      end

      # @param other [self]
      # @param attr [::Symbol]
      #
      # @return [Object, nil]
      def assert_same(other, attr)
        return false if other.nil?
        val1 = send(attr)
        val2 = other.send(attr)
        return val1 if val1 == val2
        Solargraph.assert_or_log("combine_with_#{attr}".to_sym,
                                 "Inconsistent #{attr.inspect} values between \nself =#{inspect} and \nother=#{other.inspect}:\n\n self.#{attr} = #{val1.inspect}\nother.#{attr} = #{val2.inspect}")
        val1
      end

      # @param other [self]
      # @param attr [::Symbol]
      # @sg-ignore
      # @return [undefined]
      def choose_pin_attr_with_same_name(other, attr)
        # @type [Pin::Base, nil]
        val1 = send(attr)
        # @type [Pin::Base, nil]
        val2 = other.send(attr)
        raise "Expected pin for #{attr} on\n#{self.inspect},\ngot #{val1.inspect}" unless val1.nil? || val1.is_a?(Pin::Base)
        raise "Expected pin for #{attr} on\n#{other.inspect},\ngot #{val2.inspect}" unless val2.nil? || val2.is_a?(Pin::Base)
        if val1&.name != val2&.name
          Solargraph.assert_or_log("combine_with_#{attr}_name".to_sym,
                                   "Inconsistent #{attr.inspect} name values between \nself =#{inspect} and \nother=#{other.inspect}:\n\n self.#{attr} = #{val1.inspect}\nother.#{attr} = #{val2.inspect}")
        end
        choose_pin_attr(other, attr)
      end

      # @param other [self]
      # @param attr [::Symbol]
      # @return [undefined]
      def choose_pin_attr(other, attr)
        # @type [Pin::Base, nil]
        val1 = send(attr)
        # @type [Pin::Base, nil]
        val2 = other.send(attr)
        if val1.class != val2.class
          Solargraph.assert_or_log("combine_with_#{attr}_class".to_sym,
                                   "Inconsistent #{attr.inspect} class values between \nself =#{inspect} and \nother=#{other.inspect}:\n\n self.#{attr} = #{val1.inspect}\nother.#{attr} = #{val2.inspect}")
          return val1
        end
        # arbitrary way of choosing a pin
        [val1, val2].compact.min_by { _1.best_location.to_s }
      end

      # @return [void]
      def assert_source_provided
        Solargraph.assert_or_log(:source, "source not provided - #{@path} #{@source} #{self.class}") if source.nil?
      end

      # @return [String]
      def comments
        @comments ||= ''
      end

      # @param generics_to_resolve [Enumerable<String>]
      # @param return_type_context [ComplexType, nil]
      # @param context [ComplexType]
      # @param resolved_generic_values [Hash{String => ComplexType}]
      # @return [self]
      def resolve_generics_from_context(generics_to_resolve, return_type_context = nil, resolved_generic_values: {})
        proxy return_type.resolve_generics_from_context(generics_to_resolve,
                                                        return_type_context,
                                                        resolved_generic_values: resolved_generic_values)
      end

      # @yieldparam [ComplexType]
      # @yieldreturn [ComplexType]
      # @return [self]
      def transform_types(&transform)
        proxy return_type.transform(&transform)
      end

      # Determine the concrete type for each of the generic type
      # parameters used in this method based on the parameters passed
      # into the its class and return a new method pin.
      #
      # @param definitions [Pin::Namespace] The module/class which uses generic types
      # @param context_type [ComplexType] The receiver type
      # @return [self]
      def resolve_generics definitions, context_type
        transform_types { |t| t.resolve_generics(definitions, context_type) if t }
      end

      def all_rooted?
        !return_type || return_type.all_rooted?
      end

      # @param generics_to_erase [::Array<String>]
      # @return [self]
      def erase_generics(generics_to_erase)
        return self if generics_to_erase.empty?
        transform_types { |t| t.erase_generics(generics_to_erase) }
      end

      # @return [String, nil]
      def filename
        return nil if location.nil?
        location.filename
      end

      # @return [Integer]
      def completion_item_kind
        LanguageServer::CompletionItemKinds::KEYWORD
      end

      # @return [Integer, nil]
      def symbol_kind
        nil
      end

      def to_s
        desc
      end

      # @return [Boolean]
      def variable?
        false
      end

      # @return [Location, nil]
      def best_location
        location || type_location
      end

      # True if the specified pin is a near match to this one. A near match
      # indicates that the pins contain mostly the same data. Any differences
      # between them should not have an impact on the API surface.
      #
      # @param other [Solargraph::Pin::Base, Object]
      # @return [Boolean]
      def nearly? other
        self.class == other.class &&
          name == other.name &&
          (closure == other.closure || (closure && closure.nearly?(other.closure))) &&
          (comments == other.comments ||
            (((maybe_directives? == false && other.maybe_directives? == false) || compare_directives(directives, other.directives)) &&
            compare_docstring_tags(docstring, other.docstring))
          )
      end

      # Pin equality is determined using the #nearly? method and also
      # requiring both pins to have the same location.
      #
      # @param other [self]
      def == other
        return false unless nearly? other
        comments == other.comments && location == other.location
      end

      # The pin's return type.
      #
      # @return [ComplexType]
      def return_type
        @return_type ||= ComplexType::UNDEFINED
      end

      # @return [YARD::Docstring]
      def docstring
        parse_comments unless @docstring
        @docstring ||= Solargraph::Source.parse_docstring('').to_docstring
      end

      # @return [::Array<YARD::Tags::Directive>]
      def directives
        parse_comments unless @directives
        @directives
      end

      # @return [::Array<YARD::Tags::MacroDirective>]
      def macros
        @macros ||= collect_macros
      end

      # Perform a quick check to see if this pin possibly includes YARD
      # directives. This method does not require parsing the comments.
      #
      # After the comments have been parsed, this method will return false if
      # no directives were found, regardless of whether it previously appeared
      # possible.
      #
      # @return [Boolean]
      def maybe_directives?
        return !@directives.empty? if defined?(@directives) && @directives
        @maybe_directives ||= comments.include?('@!')
      end

      # @return [Boolean]
      def deprecated?
        @deprecated ||= docstring.has_tag?('deprecated')
      end

      # Get a fully qualified type from the pin's return type.
      #
      # The relative type is determined from YARD documentation (@return,
      # @param, @type, etc.) and its namespaces are fully qualified using the
      # provided ApiMap.
      #
      # @param api_map [ApiMap]
      # @return [ComplexType]
      def typify api_map
        return_type.qualify(api_map, namespace)
      end

      # Infer the pin's return type via static code analysis.
      #
      # @param api_map [ApiMap]
      # @return [ComplexType]
      def probe api_map
        typify api_map
      end

      # @deprecated Use #typify and/or #probe instead
      # @param api_map [ApiMap]
      # @return [ComplexType]
      def infer api_map
        Solargraph::Logging.logger.warn "WARNING: Pin #infer methods are deprecated. Use #typify or #probe instead."
        type = typify(api_map)
        return type unless type.undefined?
        probe api_map
      end

      def proxied?
        @proxied ||= false
      end

      def probed?
        @probed ||= false
      end

      # @param api_map [ApiMap]
      # @return [self]
      def realize api_map
        return self if return_type.defined?
        type = typify(api_map)
        return proxy(type) if type.defined?
        type = probe(api_map)
        return self if type.undefined?
        result = proxy(type)
        result.probed = true
        result
      end

      # Return a proxy for this pin with the specified return type. Other than
      # the return type and the #proxied? setting, the proxy should be a clone
      # of the original.
      #
      # @param return_type [ComplexType]
      # @return [self]
      def proxy return_type
        result = dup
        result.return_type = return_type
        result.proxied = true
        result
      end

      # @deprecated
      # @return [String]
      def identity
        @identity ||= "#{closure&.path}|#{name}|#{location}"
      end

      # @return [String, nil]
      def to_rbs
        return_type.to_rbs
      end

      # @return [String]
      def type_desc
        rbs = to_rbs
        # RBS doesn't have a way to represent a Class<x> type
        rbs = return_type.rooted_tags if return_type.name == 'Class'
        if path
          if rbs
            path + ' ' + rbs
          else
            path
          end
        else
          rbs
        end
      end

      # @return [String]
      def inner_desc
        closure_info = closure&.desc
        binder_info = binder&.desc
        "name=#{name.inspect} return_type=#{type_desc}, context=#{context.rooted_tags}, closure=#{closure_info}, binder=#{binder_info}"
      end

      # @return [String]
      def desc
        "[#{inner_desc}]"
      end

      # @return [String]
      def inspect
        "#<#{self.class} `#{self.inner_desc}`#{all_location_text} via #{source.inspect}>"
      end

      # @return [String]
      def all_location_text
        if location.nil? && type_location.nil?
          ''
        elsif !location.nil? && type_location.nil?
          " at #{location.inspect})"
        elsif !type_location.nil? && location.nil?
          " at #{type_location.inspect})"
        else
          " at (#{location.inspect} and #{type_location.inspect})"
        end
      end

      # @return [void]
      def reset_generated!
      end

      protected

      # @return [Boolean]
      attr_writer :probed

      # @return [Boolean]
      attr_writer :proxied

      # @return [ComplexType]
      attr_writer :return_type

      attr_writer :docstring

      attr_writer :directives

      private

      # @return [void]
      def parse_comments
        # HACK: Avoid a NoMethodError on nil with empty overload tags
        if comments.nil? || comments.empty? || comments.strip.end_with?('@overload')
          @docstring = nil
          @directives = []
        else
          # HACK: Pass a dummy code object to the parser for plugins that
          # expect it not to be nil
          parse = Solargraph::Source.parse_docstring(comments)
          @docstring = parse.to_docstring
          @directives = parse.directives
        end
      end

      # True if two docstrings have the same tags, regardless of any other
      # differences.
      #
      # @param d1 [YARD::Docstring]
      # @param d2 [YARD::Docstring]
      # @return [Boolean]
      def compare_docstring_tags d1, d2
        return false if d1.tags.length != d2.tags.length
        d1.tags.each_index do |i|
          return false unless compare_tags(d1.tags[i], d2.tags[i])
        end
        true
      end

      # @param dir1 [::Array<YARD::Tags::Directive>]
      # @param dir2 [::Array<YARD::Tags::Directive>]
      # @return [Boolean]
      def compare_directives dir1, dir2
        return false if dir1.length != dir2.length
        dir1.each_index do |i|
          return false unless compare_tags(dir1[i].tag, dir2[i].tag)
        end
        true
      end

      # @param tag1 [YARD::Tags::Tag]
      # @param tag2 [YARD::Tags::Tag]
      # @return [Boolean]
      def compare_tags tag1, tag2
        tag1.class == tag2.class &&
          tag1.tag_name == tag2.tag_name &&
          tag1.text == tag2.text &&
          tag1.name == tag2.name &&
          tag1.types == tag2.types
      end

      # @return [::Array<YARD::Tags::Handlers::Directive>]
      def collect_macros
        return [] unless maybe_directives?
        parse = Solargraph::Source.parse_docstring(comments)
        parse.directives.select{ |d| d.tag.tag_name == 'macro' }
      end
    end
  end
end
