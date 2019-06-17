require 'rdoc'

module Solargraph
  class YardMap
    module RdocToYard
      def self.run
        pins = []
        pins.push Solargraph::Pin::ROOT_PIN
        name_hash = {}
        store = RDoc::Store.new('../rails/.rdoc')
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
          puts namepin.inspect
          name_hash[mod.full_name] = namepin
          puts mod.full_name
          # @param met [RDoc::AnyMethod]
          mod.each_method do |met|
            puts met.full_name
            puts met.params
            pins.push Solargraph::Pin::Method.new(
              name: met.name,
              closure: namepin,
              comments: commentary(met.comment),
              scope: (met.singleton ? :class : :method)
            )
          end
        end
        puts "#{pins.length} pins."
        api_map = Solargraph::ApiMap.new(pins: pins)
        pin = api_map.get_path_pins('AbstractController::Callbacks::ClassMethods.before_action').first
        puts pin.docstring.all
        res = api_map.search('_insert_callbacks')
        puts res.inspect
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
