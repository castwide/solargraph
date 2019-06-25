# frozen_string_literal: true

require 'rdoc'
require 'rdoc/rdoc'
require 'tmpdir'
require 'fileutils'

module Solargraph
  class YardMap
    module RdocToYard
      extend ApiMap::SourceToYard

      # @param spec [Gem::Specification]
      def self.run spec
        Dir.mktmpdir do |tmpdir|
          rdir = File.join(tmpdir, 'rdoc')
          Dir.chdir spec.full_gem_path do
            pins = []
            pins.push Solargraph::Pin::ROOT_PIN
            name_hash = {}
            cmd = "rdoc -q -N -r -o #{rdir}"
            spec.load_paths.each do |path|
              cmd += " -i #{path}"
            end
            `#{cmd}`
            store = RDoc::Store.new(rdir)
            store.load_all
            store.cache[:modules].each do |mod|
              # store.load_class(mod)
              # @type [RDoc::NormalClass]
              mod = store.find_class_or_module(mod)
              closure = pins.select { |pin| pin.path == mod.full_name.split('::')[0..-2].join('::') }.first || pins.first
              namepin = Solargraph::Pin::Namespace.new(
                type: (mod.module? ? :module : :class),
                name: mod.name,
                comments: commentary(mod.comment),
                closure: closure,
                location: locate(mod)
              )
              mod.parse(mod.comment_location)
              # @param inc [RDoc::Include]
              mod.includes.each do |inc|
                pins.push Solargraph::Pin::Reference::Include.new(
                  location: locate(inc),
                  name: inc.name,
                  closure: namepin
                )
              end
              # @param inc [RDoc::Extend]
              mod.extends.each do |ext|
                pins.push Solargraph::Pin::Reference::Extend.new(
                  location: locate(ext),
                  name: ext.name,
                  closure: namepin
                )
              end
              pins.push namepin
              name_hash[mod.full_name] = namepin
              # @param met [RDoc::AnyMethod]
              mod.each_method do |met|
                pin = Solargraph::SourceMap.load_string("def Object.tmp#{met.param_seq};end").first_pin('Object.tmp') || Solargraph::Pin::BaseMethod.new
                pins.push Solargraph::Pin::Method.new(
                  name: met.name,
                  closure: namepin,
                  comments: commentary(met.comment),
                  scope: met.type.to_sym,
                  args: pin.parameters,
                  visibility: met.visibility,
                  location: locate(met)
                )
              end
              # @param const [RDoc::Constant]
              mod.each_constant do |const|
                pins.push Solargraph::Pin::Constant.new(
                  name: const.name,
                  closure: namepin,
                  comments: commentary(const.comment),
                  location: locate(const)
                )
              end
            end
            mapstore = Solargraph::ApiMap::Store.new(pins)
            rake_yard(mapstore)
            YARD::Registry.clear
            code_object_map.values.each do |co|
              YARD::Registry.register(co)
            end
            cache_dir = File.join(Solargraph::YardMap::CoreDocs.cache_dir, 'gems', "#{spec.name}-#{spec.version}", "yardoc")
            FileUtils.remove_entry_secure cache_dir if File.exist?(cache_dir)
            FileUtils.mkdir_p cache_dir
            # @todo Should merge be true?
            YARD::Registry.save true, cache_dir
          end
        end
      end

      def self.base_name mod
        mod.full_name.split('::')[0..-2].join('::')
      end

      def self.commentary cmnt
        result = []
        cmnt.parts.each do |part|
          result.push RDoc::Markup::ToHtml.new({}).to_html(part.text) if part.respond_to?(:text)
        end
        result.join("\n\n")
      end

      # @param obj [RDoc::Context]
      def self.locate obj
        # @todo line is always nil for some reason
        file, line = find_file(obj)
        return nil if file.nil?
        Location.new(
          file,
          Range.from_to(line || 1, 0, line || 1, 0)
        )
      end

      def self.find_file obj
        if obj.respond_to?(:in_files) && !obj.in_files.empty?
          [obj.in_files.first.to_s.sub(/^file /, ''), obj.in_files.first.line]
        else
          [obj.file_name, obj.line]
        end
      end
    end
  end
end
