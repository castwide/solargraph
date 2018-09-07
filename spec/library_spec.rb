require 'tmpdir'
require 'yard'

describe Solargraph::Library do
  it "raises an exception for unknown filenames" do
    library = Solargraph::Library.new
    expect {
      library.checkout 'invalid_filename.rb'
    }.to raise_error(Solargraph::FileNotFoundError)
  end

  it "ignores created files that are not in the workspace" do
    library = Solargraph::Library.new
    result = library.create('file.rb', 'a = b')
    expect(result).to be(false)
    expect {
      library.checkout 'file.rb'
    }.to raise_error(Solargraph::FileNotFoundError)
  end

  it "does not open created files in the workspace" do
    Dir.mktmpdir do |temp_dir_path|
      # Ensure we resolve any symlinks to their real path
      workspace_path = File.realpath(temp_dir_path)
      file_path = File.join(workspace_path, 'file.rb')
      File.write(file_path, 'a = b')
      library = Solargraph::Library.load(workspace_path)
      result = library.create(file_path, File.read(file_path))
      expect(result).to be(true)
      expect(library.open?(file_path)).to be(false)
    end
  end

  it "raises an exception for files that do not exist" do
    Dir.mktmpdir do |temp_dir_path|
      # Ensure we resolve any symlinks to their real path
      workspace_path = File.realpath(temp_dir_path)
      file_path = File.join(workspace_path, 'not_real.rb')
      library = Solargraph::Library.load(workspace_path)
      expect {
        library.checkout file_path
      }.to raise_error(Solargraph::FileNotFoundError)
    end
  end

  it "opens a file" do
    library = Solargraph::Library.new
    library.open('file.rb', 'a = b', 0)
    source = nil
    expect {
      source = library.checkout('file.rb')
    }.not_to raise_error
    expect(source.filename).to eq('file.rb')
  end

  it "deletes an open file" do
    library = Solargraph::Library.new
    library.open('file.rb', 'a = b', 0)
    library.delete 'file.rb'
    expect {
      library.checkout 'file.rb'
    }.to raise_error(Solargraph::FileNotFoundError)
  end

  it "deletes a file from the workspace" do
    Dir.mktmpdir do |dir|
      file = File.join(dir, 'file.rb')
      File.write(file, 'a = b')
      library = Solargraph::Library.load(dir)
      library.open file, File.read(file), 0
      expect {
        library.checkout file
      }.not_to raise_error
      File.unlink file
      library.delete file
      expect {
        library.checkout file
      }.to raise_error(Solargraph::FileNotFoundError)
    end
  end

  it "makes a closed file unavailable if it doesn't exist on disk" do
    library = Solargraph::Library.new
    library.open 'file.rb', 'a = b', 0
    expect {
      library.checkout 'file.rb'
    }.not_to raise_error
    library.close 'file.rb'
    expect {
      library.checkout 'file.rb'
    }.to raise_error(Solargraph::FileNotFoundError)
  end

  it "keeps a closed file available if it exists in the workspace" do
    library = Solargraph::Library.load('spec/fixtures/workspace')
    file = 'spec/fixtures/workspace/app.rb'
    library.open file, File.read(file), 0
    expect {
      library.checkout file
    }.not_to raise_error
    library.close file
    expect {
      library.checkout file
    }.not_to raise_error(Solargraph::FileNotFoundError)
  end

  it "keeps a closed file in the workspace" do
    Dir.mktmpdir do |dir|
      file = File.join(dir, 'file.rb')
      File.write file, 'a = b'
      library = Solargraph::Library.load(dir)
      library.open file, File.read(file), 0
      expect {
        library.checkout file
      }.not_to raise_error
      library.close file
      expect(library.open?(file)).to be(false)
      expect(library.contain?(file)).to be(true)
    end
  end

  it "returns a Completion" do
    library = Solargraph::Library.new
    library.open 'file.rb', %(
      x = 1
      x
    ), 0
    completion = library.completions_at('file.rb', 2, 7)
    expect(completion).to be_a(Solargraph::SourceMap::Completion)
    expect(completion.pins.map(&:name)).to include('x')
  end

  it "gets definitions from a file" do
    library = Solargraph::Library.new
    library.open 'file.rb', %(
      class Foo
        def bar
        end
      end
    ), 0
    paths = library.definitions_at('file.rb', 2, 13).map(&:path)
    expect(paths).to include('Foo#bar')
  end

  it "signifies method arguments" do
    library = Solargraph::Library.new
    library.open 'file.rb', %(
      class Foo
        def bar baz, key: ''
        end
      end
      Foo.new.bar()
    ), 0
    pins = library.signatures_at('file.rb', 5, 18)
    expect(pins.length).to eq(1)
    expect(pins.first.path).to eq('Foo#bar')
  end

  it "ignores invalid filenames in create_from_disk" do
    library = Solargraph::Library.new
    filename = 'not_a_real_file.rb'
    expect(library.create_from_disk(filename)).to be(false)
    expect(library.contain?(filename)).to be(false)
  end

  it "adds mergeable files to the workspace in create_from_disk" do
    Dir.mktmpdir do |temp_dir_path|
      # Ensure we resolve any symlinks to their real path
      workspace_path = File.realpath(temp_dir_path)
      library = Solargraph::Library.load(workspace_path)
      file_path = File.join(workspace_path, 'created.rb')
      File.write(file_path, "puts 'hello'")
      expect(library.create_from_disk(file_path)).to be(true)
      expect(library.contain?(file_path)).to be(true)
    end
  end

  it "ignores non-mergeable files in create_from_disk" do
    Dir.mktmpdir do |dir|
      library = Solargraph::Library.load(dir)
      filename = File.join(dir, 'created.txt')
      File.write(filename, "puts 'hello'")
      expect(library.create_from_disk(filename)).to be(false)
      expect(library.contain?(filename)).to be(false)
    end
  end

  it "diagnoses files" do
    library = Solargraph::Library.new
    library.open('file.rb', %(
      puts 'hello'
    ), 0)
    result = library.diagnose 'file.rb'
    expect(result).to be_a(Array)
    # @todo More tests
  end

  it "documents symbols" do
    library = Solargraph::Library.new
    library.open('file.rb', %(
      class Foo
        def bar
        end
      end
    ), 0)
    pins = library.document_symbols 'file.rb'
    expect(pins.length).to eq(2)
    expect(pins.map(&:path)).to include('Foo')
    expect(pins.map(&:path)).to include('Foo#bar')
  end

  it "collects references to a method symbol" do
    library = Solargraph::Library.new
    library.open('file1.rb', %(
      class Foo
        def bar
        end
      end

      Foo.new.bar
    ), 0)
    library.open('file2.rb', %(
      foo = Foo.new
      foo.bar
    ), 0)
    pins = library.references_from('file2.rb', 2, 11)
    expect(pins.length).to eq(3)
  end

  it "searches the core for queries" do
    library = Solargraph::Library.new
    result = library.search('String')
    expect(result).not_to be_empty
  end

  it "returns YARD documentation from the core" do
    library = Solargraph::Library.new
    result = library.document('String')
    expect(result).not_to be_empty
    expect(result.first).to be_a(YARD::CodeObjects::Base)
  end

  it "returns YARD documentation from sources" do
    library = Solargraph::Library.new
    library.open('test.rb', %(
      class Foo
        # My bar method
        def bar; end
      end
    ), 0)
    result = library.document('Foo#bar')
    expect(result).not_to be_empty
    expect(result.first).to be_a(YARD::CodeObjects::Base)
  end

  it "synchronizes sources from updaters" do
    library = Solargraph::Library.new
    library.open('test.rb', %(
      class Foo
      end
    ), 1)
    repl = %(
      class Foo
        def bar; end
      end
    )
    updater = Solargraph::Source::Updater.new(
      'test.rb',
      2,
      [Solargraph::Source::Change.new(nil, repl)]
    )
    library.update updater
    expect(library.checkout('test.rb').code).to eq(repl)
  end

  it "synchronizes workspaces from updaters" do
    library = Solargraph::Library.load('spec/fixtures/workspace')
    updater = Solargraph::Source::Updater.new('spec/fixtures/workspace/app.rb', 1, [
      Solargraph::Source::Change.new(nil, 'updated_from_updater')
    ])
    library.update updater
    source = library.checkout('spec/fixtures/workspace/app.rb')
    expect(source.code).to eq('updated_from_updater')
  end
end
