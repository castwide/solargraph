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
            cmd = "rdoc -q -r -o #{rdir}"
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
              namepin = Solargraph::Pin::Namespace.new(
                type: (mod.module? ? :module : :class),
                name: mod.name,
                comments: commentary(mod.comment),
                closure: name_hash[base_name(mod)] || pins.first
              )
              mod.parse(mod.comment_location)
              pins.push namepin
              name_hash[mod.full_name] = namepin
              # @param met [RDoc::AnyMethod]
              mod.each_method do |met|
                pin = Solargraph::SourceMap.load_string("def Object.tmp#{met.param_seq};end").first_pin('Object.tmp') || Solargraph::Pin::BaseMethod.new
                pins.push Solargraph::Pin::Method.new(
                  name: met.name,
                  closure: namepin,
                  comments: commentary(met.comment),
                  scope: (met.singleton ? :class : :method),
                  args: pin.parameters
                )
              end
              # @param const [RDoc::Constant]
              mod.each_constant do |const|
                pins.push Solargraph::Pin::Constant.new(
                  name: const.name,
                  closure: namepin,
                  comments: commentary(const.comment)
                )
              end
            end
            store = Solargraph::ApiMap::Store.new(pins)
            rake_yard(store)
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
    end
  end
end
