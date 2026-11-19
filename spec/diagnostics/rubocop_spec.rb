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

    rubocop = described_class.new
    result = rubocop.diagnose(source, nil)
    expect(result).to be_a(Array)
  end

  context 'with a source transformed by a convention' do
    let(:fake_convention) do
      Class.new(Solargraph::Convention::Base) do
        def transform_source filename, code
          code.gsub(/^> ?/, '') if filename.end_with?('.fake')
        end
      end
    end

    let(:code) { "> # frozen_string_literal: true\n>\n> foo = 1  \n> puts foo\n" }

    before { Solargraph::Convention.register fake_convention }

    after { Solargraph::Convention.unregister fake_convention }

    it 'does not lint the transformed source' do
      source = Solargraph::Source.load_string(code, 'file.fake')
      expect(described_class.new.diagnose(source, nil)).to eq([])
    end

    it 'still lints Ruby files with the same code' do
      source = Solargraph::Source.load_string(code.gsub(/^> ?/, ''), 'file.rb')
      codes = described_class.new.diagnose(source, nil).map { |diag| diag[:code] }
      expect(codes).to include('Layout/TrailingWhitespace')
    end
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
      FileUtils.rm_rf(config_file)
    end

    it 'handles validation errors' do
      file = File.realpath(File.join(fixture_path, 'app.rb'))
      source = Solargraph::Source.load(file)
      rubocop = described_class.new
      expect do
        rubocop.diagnose(source, nil)
      end.to raise_error(Solargraph::DiagnosticsError)
    end
  end

  it 'calculates ranges' do
    file = File.realpath(File.join('spec', 'fixtures', 'rubocop-unused-variable-error', 'app.rb'))
    source = Solargraph::Source.load(file)
    rubocop = described_class.new
    results = rubocop.diagnose(source, nil)

    expect(results).to be_one
    expect(results.first[:range][:start][:line]).to eq(2)
    expect(results.first[:range][:start][:character]).to eq(0)
    expect(results.first[:range][:end][:line]).to eq(2)
    expect(results.first[:range][:end][:character]).to eq(6)
  end
end
