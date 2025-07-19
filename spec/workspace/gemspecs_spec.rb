# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

describe Solargraph::Workspace::Gemspecs do
  let(:workspace) { Solargraph::Workspace.new(dir_path) }
  let(:dir_path)  { File.realpath(Dir.mktmpdir) }
  let(:file_path) { File.join(dir_path, 'file.rb') }

  before   { File.write(file_path, 'exit') }
  after    { FileUtils.remove_entry(dir_path) }

  it 'ignores gemspecs in excluded directories' do
    # vendor/**/* is excluded by default
    workspace = Solargraph::Workspace.new('spec/fixtures/vendored')
    expect(workspace.gemspecs).to be_empty
  end
end
