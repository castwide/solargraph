# frozen_string_literal: true

describe Solargraph::Diagnostics::Rubocop do
  it 'diagnoses input' do
    source = Solargraph::Source.new(%(
      class Foo
        def bar
        end
      end
      foo = Foo.new
    ), 'file.rb')

    rubocop = Solargraph::Diagnostics::Rubocop.new
    result = rubocop.diagnose(source, nil)
    expect(result).to be_a(Array)
  end

  it 'handles validation errors' do
    file = File.realpath(File.join('spec', 'fixtures', 'rubocop-validation-error', 'app.rb'))
    source = Solargraph::Source.load(file)
    rubocop = Solargraph::Diagnostics::Rubocop.new
    expect {
      rubocop.diagnose(source, nil)
    }.to raise_error(Solargraph::DiagnosticsError)
  end

  it 'calculates ranges' do
    file = File.realpath(File.join('spec', 'fixtures', 'rubocop-unused-variable-error', 'app.rb'))
    source = Solargraph::Source.load(file)
    rubocop = Solargraph::Diagnostics::Rubocop.new
    results = rubocop.diagnose(source, nil)

    puts results.inspect
    expect(results).to be_one
    expect(results.first[:range][:start][:line]).to eq(2)
    expect(results.first[:range][:start][:character]).to eq(0)
    expect(results.first[:range][:end][:line]).to eq(2)
    expect(results.first[:range][:end][:character]).to eq(6)
  end
end
