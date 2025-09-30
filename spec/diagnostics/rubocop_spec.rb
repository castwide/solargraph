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

  context 'with validation error' do
    let(:fixture_path) do
      File.absolute_path('spec/fixtures/rubocop-validation-error').gsub('\\', '/')
    end

    around do |example|
      config_file = File.join(fixture_path, '.rubocop.yml')
      File.write(config_file, <<~YAML)
        inherit_from:
          - file_not_found.yml
      YAML
      example.run
    ensure
      File.delete(config_file) if File.exist?(config_file)
    end

    it 'handles validation errors' do
      file = File.realpath(File.join(fixture_path, 'app.rb'))
      source = Solargraph::Source.load(file)
      rubocop = Solargraph::Diagnostics::Rubocop.new
      expect do
        rubocop.diagnose(source, nil)
      end.to raise_error(Solargraph::DiagnosticsError)
    end
  end

  it 'calculates ranges' do
    file = File.realpath(File.join('spec', 'fixtures', 'rubocop-unused-variable-error', 'app.rb'))
    source = Solargraph::Source.load(file)
    rubocop = Solargraph::Diagnostics::Rubocop.new
    results = rubocop.diagnose(source, nil)

    expect(results).to be_one
    expect(results.first[:range][:start][:line]).to eq(2)
    expect(results.first[:range][:start][:character]).to eq(0)
    expect(results.first[:range][:end][:line]).to eq(2)
    expect(results.first[:range][:end][:character]).to eq(6)
  end
end
