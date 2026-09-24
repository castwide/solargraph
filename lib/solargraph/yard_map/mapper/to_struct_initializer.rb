# frozen_string_literal: true

module Solargraph
  class YardMap
    class Mapper
      # Synthesizes the constructor pins YARD never generates for a
      # `Foo = Struct.new(:bar, :baz)` (or `class Foo < Struct.new(...)`)
      # definition it documents.
      #
      # YARD's own Ruby handlers for `Struct.new`
      # (`YARD::Handlers::Ruby::ConstantHandler#process_structclass`,
      # `YARD::Handlers::Ruby::ClassHandler`) register the struct as a real
      # `ClassObject` with a superclass of `Struct` and generate reader/writer
      # methods for each member -- via `StructHandlerMethods#create_attributes`
      # -- but never an `initialize`. Without one, `Foo.new(...)` resolves
      # against `Struct.new`'s own signature (the nearest ancestor method
      # Solargraph can find), reporting a wrong-argument-type error for
      # ordinary positional Struct construction.
      #
      # `Solargraph::Convention::StructDefinition` already covers the
      # equivalent case for workspace source, by building its own initialize
      # pin from the parsed `Struct.new(...)` node. This covers the same shape
      # when it arrives via a gem's yardoc, where there is no such node --
      # only the member names YARD kept.
      module ToStructInitializer
        # Matches Ruby's own magic encoding comment, optionally preceded by a
        # shebang line -- the same two-line rule `Kernel#require` applies.
        # `File.readlines` has no reason to know a file's encoding and
        # defaults to `Encoding.default_external`; it does not honor this
        # comment the way compiling the file would.
        MAGIC_ENCODING_LINE = /\A#.*coding\s*[:=]\s*([\w-]+)/i

        class << self
          # @param code_object [YARD::CodeObjects::Base]
          # @param closure [Pin::Namespace]
          # @param spec [Gem::Specification, nil]
          # @return [Array<Pin::Method>] empty when code_object isn't a
          #   Struct.new definition, or already documents its own initialize
          def make code_object, closure, spec = nil
            return [] unless code_object.is_a?(YARD::CodeObjects::ClassObject)
            return [] unless code_object.superclass.to_s == 'Struct'
            return [] if code_object.child(name: 'initialize', scope: :instance)

            members = code_object.attributes[:instance].keys
            return [] if members.empty?

            initializer = synthetic_initializer(code_object, members, spec)
            [
              ToMethod.make(initializer, 'new', :class, :public, closure, spec),
              ToMethod.make(initializer, 'initialize', :instance, :private, closure, spec)
            ]
          end

          private

          # @param code_object [YARD::CodeObjects::ClassObject]
          # @param members [Array<Symbol>]
          # @param spec [Gem::Specification, nil]
          # @return [YARD::CodeObjects::MethodObject]
          def synthetic_initializer code_object, members, spec
            keyword = keyword_init?(code_object, spec)
            initializer = YARD::CodeObjects::MethodObject.new(code_object, 'initialize', :instance)
            initializer.visibility = :private
            # A truthy second element marks the parameter as having a
            # default, which is what ToMethod's `arg_type` uses to choose
            # `:kwoptarg` over `:kwarg` -- matching how a real keyword_init
            # Struct accepts any member being omitted.
            initializer.parameters = members.map { |m| keyword ? ["#{m}:", ''] : [m.to_s, nil] }
            initializer
          end

          # Best-effort: YARD's Struct handler discards whether the original
          # call passed `keyword_init: true` -- it only keeps the member
          # names -- so this rereads the source line the class was defined on
          # to recover it. Falls back to positional (`false`) when the source
          # can't be read or the line doesn't mention it.
          #
          # @param code_object [YARD::CodeObjects::ClassObject]
          # @param spec [Gem::Specification, nil]
          # @return [Boolean]
          def keyword_init? code_object, spec
            file = code_object.file
            return false if file.nil?

            line = code_object.line
            return false if line.nil?

            path = spec ? File.join(spec.full_gem_path, file) : file
            return false unless File.file?(path)

            # @sg-ignore Fixnum shim (diff-lcs) shadows Integer in RBS union, breaking resolution
            !!File.readlines(path, encoding: detect_encoding(path))[line - 1].to_s.match?(/keyword_init:\s*true/)
          rescue ArgumentError => e
            # The declared encoding doesn't match the file's actual bytes on
            # this line -- e.g. a magic comment claims UTF-8 (or none is
            # present, which defaults to UTF-8) but the byte isn't valid
            # UTF-8, or names an encoding under which it still isn't valid.
            Solargraph.logger.info "Could not check #{path}:#{line} for keyword_init: [#{e.class}] #{e.message}"
            false
          end

          # @param path [String]
          # @return [Encoding]
          # @sg-ignore Only Encoding.find("internal") can return nil, per
          #   https://docs.ruby-lang.org/en/3.2/Encoding.html#method-c-find --
          #   never a name parsed from a magic comment. The `||` below
          #   covers it, but flow-sensitive typing doesn't narrow it out of
          #   this method's inferred return type.
          def detect_encoding path
            first_lines = File.open(path, 'rb') { |f| [f.gets, f.gets] }.compact
            first_lines.shift if first_lines.first&.start_with?('#!')
            match = MAGIC_ENCODING_LINE.match(first_lines.first.to_s)
            return Encoding::UTF_8 if match.nil?

            encoding_name = match[1]
            return Encoding::UTF_8 if encoding_name.nil?

            begin
              Encoding.find(encoding_name) || Encoding::UTF_8
            rescue ArgumentError
              Encoding::UTF_8
            end
          end
        end
      end
    end
  end
end
