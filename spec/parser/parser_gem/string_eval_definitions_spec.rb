# frozen_string_literal: true

describe Solargraph::Parser::ParserGem::NodeProcessors::StringEvalDefinitions do
  # @param code [String]
  # @return [Solargraph::ApiMap]
  def map_code code
    map = Solargraph::ApiMap.new
    map.map Solargraph::Source.load_string(code, 'test.rb')
    map
  end

  it 'maps a literal string evaluated in a class body' do
    map = map_code(%(
      class Foo
        class_eval "def bar(baz); end"
      end
    ))
    pin = map.get_path_pins('Foo#bar').first
    expect(pin).to be_a(Solargraph::Pin::Method)
    expect(pin.parameters.map(&:name)).to eq(['baz'])
  end

  it 'maps methods named by the variable of a loop over a literal array' do
    map = map_code(%(
      module PolymorphicRoutes
        %w(edit new).each do |action|
          module_eval <<-EOT, __FILE__, __LINE__ + 1
            def \#{action}_polymorphic_url(record_or_hash, options = {})
              polymorphic_url_for_action("\#{action}", record_or_hash, options)
            end
          EOT
        end
      end
    ))
    %w[edit new].each do |action|
      pin = map.get_path_pins("PolymorphicRoutes##{action}_polymorphic_url").first
      expect(pin).to be_a(Solargraph::Pin::Method)
      expect(pin.parameters.map(&:name)).to eq(%w[record_or_hash options])
      expect(pin.location.filename).to eq('test.rb')
      expect(pin.location.range.start.line).to eq(4)
    end
  end

  it 'maps every method in a squiggly heredoc with nested heredocs' do
    map = map_code(%(
      module ClassMethods
        %w(reading_role writing_role).each do |attr|
          module_eval(<<~RUBY, __FILE__, __LINE__ + 1)
            def \#{attr}
              warn(<<~MSG)
                \#{attr} is deprecated
              MSG
              Other.\#{attr}
            end

            def \#{attr}=(value)
              Other.\#{attr} = value
            end
          RUBY
        end
      end
    ))
    %w[reading_role reading_role= writing_role writing_role=].each do |name|
      expect(map.get_path_pins("ClassMethods##{name}")).not_to be_empty
    end
  end

  it 'maps instance_eval strings as singleton methods' do
    map = map_code(%(
      class Foo
        instance_eval "def bar; end"
      end
    ))
    expect(map.get_path_pins('Foo.bar')).not_to be_empty
    expect(map.get_path_pins('Foo#bar')).to be_empty
  end

  it 'maps strings evaluated on a constant onto that namespace' do
    map = map_code(%(
      module Outer
        module Helpers; end
        class Target
          Helpers.class_eval "def helped; end"
        end
      end
    ))
    expect(map.get_path_pins('Outer::Helpers#helped')).not_to be_empty
    expect(map.get_path_pins('Outer::Target#helped')).to be_empty
  end

  it 'ignores constants scoped under a non-constant expression' do
    map = map_code(%(
      class Baz; end
      class Foo
        obj.klass::Baz.class_eval "def scoped; end"
        ::Baz.class_eval "def rooted; end"
      end
    ))
    expect(map.get_path_pins('Baz#scoped')).to be_empty
    expect(map.get_path_pins('Baz#rooted')).not_to be_empty
  end

  it 'ignores interpolations that are not loop variables or parameters' do
    map = map_code(%(
      class Foo
        NAME = 'bar'
        class_eval "def \#{NAME}; end"
        %w(a).each do |x|
          class_eval "def \#{x.upcase}; end"
        end
      end
    ))
    expect(map.get_method_stack('Foo', 'bar')).to be_empty
    expect(map.get_method_stack('Foo', 'A')).to be_empty
    expect(map.get_method_stack('Foo', 'a')).to be_empty
  end

  it 'ignores strings evaluated in blocks that may change self' do
    map = map_code(%(
      class Foo
        included do
          class_eval "def bar; end"
        end
      end
    ))
    expect(map.get_path_pins('Foo#bar')).to be_empty
  end

  # @param block [Proc]
  # @return [Float] seconds the block took
  def elapsed &block
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    block.call
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
  end

  it 'skips loops with too many combinations to expand' do
    words = (0...20).map { |i| "w#{i}" }.join(' ')
    map = nil
    seconds = elapsed do
      map = map_code(%(
        class Foo
          %w(#{words}).each do |x|
            %w(#{words}).each do |y|
              %w(#{words}).each do |z|
                class_eval "def \#{x}_\#{y}_\#{z}; end"
              end
            end
          end
        end
      ))
    end
    expect(map.get_path_pins('Foo#w0_w0_w0')).to be_empty
    expect(seconds).to be < 5
  end

  it 'skips templates that would generate too much source' do
    body = "  x = 1\n" * 300
    words = (0...200).map { |i| "w#{i}" }.join(' ')
    map = map_code(%(
      class Foo
        %w(#{words}).each do |x|
          class_eval "def \#{x}\n#{body}end"
        end
      end
    ))
    expect(map.get_path_pins('Foo#w0')).to be_empty
  end

  it 'skips call sites with too many combinations to expand' do
    args = (0...20).map { |i| ":s#{i}" }.join(', ')
    map = nil
    seconds = elapsed do
      map = map_code(%(
        class Base
          def self.flags(*names)
            names.each do |a|
              names.each do |b|
                names.each do |c|
                  class_eval "def \#{a}_\#{b}_\#{c}; end"
                end
              end
            end
          end
          flags #{args}
        end
      ))
    end
    expect(map.get_path_pins('Base#s0_s0_s0')).to be_empty
    expect(seconds).to be < 5
  end

  it 'ignores strings that do not parse' do
    expect do
      map_code(%(
        class Foo
          class_eval "def bar baz qux"
        end
      ))
    end.not_to raise_error
  end

  it 'maps methods named by parameters at literal call sites in the class body' do
    map = map_code(%(
      class Base
        def self.flag(name)
          class_eval <<-RUBY
            def \#{name}?
              true
            end
          RUBY
        end
        flag :admin
      end
    ))
    pin = map.get_path_pins('Base#admin?').first
    expect(pin).to be_a(Solargraph::Pin::Method)
    expect(pin.location.range.start.line).to eq(9)
  end

  it 'maps methods onto the subclass that calls an inherited macro' do
    map = map_code(%(
      class Base
        def self.flag(name)
          class_eval "def \#{name}?; true; end"
        end
      end
      class Sub < Base
        flag :admin
      end
    ))
    expect(map.get_path_pins('Sub#admin?')).not_to be_empty
    expect(map.get_path_pins('Base#admin?')).to be_empty
  end

  it 'maps parameters iterated with each' do
    map = map_code(%(
      class Base
        def self.flags(*names)
          names.each do |name|
            class_eval "def \#{name}?; true; end"
          end
        end
        flags :admin, 'staff'
      end
    ))
    expect(map.get_path_pins('Base#admin?')).not_to be_empty
    expect(map.get_path_pins('Base#staff?')).not_to be_empty
  end

  it 'maps onto the evaluated constant when the call has a typed receiver' do
    map = map_code(%(
      module Routing
        class RouteSet
          module MountedHelpers; end

          def define_mounted_helper(name, script_namer = nil)
            MountedHelpers.class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
              def \#{name}
                @_\#{name} ||= _\#{name}
              end
            RUBY
          end
        end
      end
      class App
        # @return [Routing::RouteSet]
        def routes; end
        def setup
          routes.define_mounted_helper(:main_app)
        end
      end
    ))
    expect(map.get_path_pins('Routing::RouteSet::MountedHelpers#main_app')).not_to be_empty
    expect(map.get_path_pins('Routing::RouteSet#main_app')).to be_empty
    expect(map.get_path_pins('App#main_app')).to be_empty
  end

  it 'ignores calls whose receiver type is unknown' do
    map = map_code(%(
      module Routing
        class RouteSet
          module MountedHelpers; end

          def define_mounted_helper(name)
            MountedHelpers.class_eval "def \#{name}; end"
          end
        end
      end
      class App
        def setup(app)
          app.routes.define_mounted_helper(:main_app)
        end
      end
    ))
    expect(map.get_path_pins('Routing::RouteSet::MountedHelpers#main_app')).to be_empty
  end

  it 'ignores call sites with arguments that are not literals' do
    map = map_code(%(
      class Base
        def self.flag(name)
          class_eval "def \#{name}?; true; end"
        end
        NAME = :admin
        flag NAME
        flag "dyn\#{1}"
      end
    ))
    expect(map.get_method_stack('Base', 'admin?')).to be_empty
    expect(map.get_method_stack('Base', 'NAME?')).to be_empty
  end

  it 'ignores calls to an unrelated method with the same name' do
    map = map_code(%(
      class Base
        def self.flag(name)
          class_eval "def \#{name}?; true; end"
        end
      end
      class Other
        def self.flag(name); end
        flag :unrelated
      end
    ))
    expect(map.get_method_stack('Other', 'unrelated?')).to be_empty
    expect(map.get_method_stack('Base', 'unrelated?')).to be_empty
  end

  it 'maps call sites in a different source' do
    template = Solargraph::SourceMap.load_string(%(
      class Base
        def self.flag(name)
          class_eval "def \#{name}?; true; end"
        end
      end
    ), 'template.rb')
    call = Solargraph::SourceMap.load_string(%(
      class Sub < Base
        flag :admin
      end
    ), 'call.rb')
    map = Solargraph::ApiMap.new
    map.catalog Solargraph::Bench.new(source_maps: [template, call])
    pin = map.get_path_pins('Sub#admin?').first
    expect(pin).to be_a(Solargraph::Pin::Method)
    expect(pin.location.filename).to eq('call.rb')
  end

  it 'keeps templates through serialization' do
    source = Solargraph::SourceMap.load_string(%(
      class Base
        def self.flag(name)
          class_eval "def \#{name}?; true; end"
        end
      end
    ), 'test.rb')
    pin = source.pins.find { |p| p.path == 'Base.flag' }
    copy = Marshal.load(Marshal.dump(pin))
    expect(copy.call_site_templates).not_to be_empty
    expect(copy.call_site_templates).to eq(pin.call_site_templates)
  end
end
