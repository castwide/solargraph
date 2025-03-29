describe Solargraph::YardMap::Mapper::ToMethod do
  let(:code_object) {
    namespace = YARD::CodeObjects::ModuleObject.new(nil, 'Example')
    YARD::CodeObjects::MethodObject.new(namespace, 'foo')
  }

  it 'parses args' do
    code_object.parameters = [["bar", nil]]
    pin = Solargraph::YardMap::Mapper::ToMethod.make(code_object)
    param = pin.parameters.first
    expect(param.decl).to be(:arg)
    expect(param.name).to eq("bar")
    expect(param.full).to eq("bar")
  end

  it 'parses optargs' do
    code_object.parameters = [["bar", "'baz'"]]
    pin = Solargraph::YardMap::Mapper::ToMethod.make(code_object)
    param = pin.parameters.first
    expect(param.decl).to be(:optarg)
    expect(param.name).to eq("bar")
    expect(param.full).to eq("bar = 'baz'")
  end

  it 'parses kwargs' do
    code_object.parameters = [["bar:", nil]]
    pin = Solargraph::YardMap::Mapper::ToMethod.make(code_object)
    param = pin.parameters.first
    expect(param.name).to eq('bar')
    expect(param.decl).to be(:kwarg)
    expect(param.full).to eq("bar:")
  end

  it 'parses kwoptargs' do
    code_object.parameters = [["bar:", "'baz'"]]
    pin = Solargraph::YardMap::Mapper::ToMethod.make(code_object)
    param = pin.parameters.first
    expect(param.decl).to be(:kwoptarg)
    expect(param.name).to eq('bar')
    expect(param.full).to eq("bar: 'baz'")
  end

  it 'parses restargs' do
    code_object.parameters = [["*bar", nil]]
    pin = Solargraph::YardMap::Mapper::ToMethod.make(code_object)
    param = pin.parameters.first
    expect(param.decl).to be(:restarg)
    expect(param.name).to eq('bar')
    expect(param.full).to eq("*bar")
  end

  it 'parses kwrestargs' do
    code_object.parameters = [["**bar", nil]]
    pin = Solargraph::YardMap::Mapper::ToMethod.make(code_object)
    param = pin.parameters.first
    expect(param.decl).to be(:kwrestarg)
    expect(param.name).to eq('bar')
    expect(param.full).to eq("**bar")
  end

  it 'parses blockargs' do
    code_object.parameters = [["&bar", nil]]
    pin = Solargraph::YardMap::Mapper::ToMethod.make(code_object)
    param = pin.parameters.first
    expect(param.decl).to be(:blockarg)
    expect(param.name).to eq('bar')
    expect(param.full).to eq("&bar")
  end

  xit 'parses undefined but typed blockargs' do
    code_object.parameters = []
    code_object.docstring = <<EOF
@yieldparam foo [Integer]
EOF
    pin = Solargraph::YardMap::Mapper::ToMethod.make(code_object)
    param = pin.parameters.first
    expect(param.decl).to be(:blockarg)
    expect(param.name).to eq('')
    expect(param.full).to eq("&")
  end
end
