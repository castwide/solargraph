# frozen_string_literal: true

describe Solargraph::LanguageServer::Message::Initialize do
  it 'prepares workspace folders' do
    host = Solargraph::LanguageServer::Host.new
    dir = File.realpath(File.join('spec', 'fixtures', 'workspace'))
    init = described_class.new(host, {
                                 'params' => {
                                   'capabilities' => {
                                     'workspace' => {
                                       'workspaceFolders' => true
                                     }
                                   },
                                   'workspaceFolders' => [
                                     {
                                       'uri' => Solargraph::LanguageServer::UriHelpers.file_to_uri(dir),
                                       'name' => 'workspace'
                                     }
                                   ]
                                 }
                               })
    init.process
    expect(host.folders.length).to eq(1)
  end

  it 'prepares rootUri as a workspace' do
    host = Solargraph::LanguageServer::Host.new
    dir = File.realpath(File.join('spec', 'fixtures', 'workspace'))
    init = described_class.new(host, {
                                 'params' => {
                                   'capabilities' => {
                                     'workspace' => {
                                       'workspaceFolders' => true
                                     }
                                   },
                                   'rootUri' => Solargraph::LanguageServer::UriHelpers.file_to_uri(dir)
                                 }
                               })
    init.process
    expect(host.folders.length).to eq(1)
  end

  it 'prepares rootPath as a workspace' do
    host = Solargraph::LanguageServer::Host.new
    dir = File.realpath(File.join('spec', 'fixtures', 'workspace'))
    init = described_class.new(host, {
                                 'params' => {
                                   'capabilities' => {
                                     'workspace' => {
                                       'workspaceFolders' => true
                                     }
                                   },
                                   'rootPath' => dir
                                 }
                               })
    init.process
    expect(host.folders.length).to eq(1)
  end

  it 'returns the default capabilities' do
    host = Solargraph::LanguageServer::Host.new
    init = described_class.new(host, {})
    init.process
    result = init.result
    expect(result).to include(:capabilities)
    expect(result[:capabilities]).to eq({
                                          textDocumentSync: 2,
                                          workspace: { workspaceFolders: { supported: true,
                                                                           changeNotifications: true } },
                                          completionProvider: { resolveProvider: true,
                                                                triggerCharacters: ['.', ':', '@'] },
                                          signatureHelpProvider: { triggerCharacters: ['(', ','] },
                                          hoverProvider: true,
                                          documentSymbolProvider: true,
                                          definitionProvider: true,
                                          typeDefinitionProvider: true,
                                          renameProvider: { prepareProvider: true },
                                          referencesProvider: true,
                                          workspaceSymbolProvider: true,
                                          foldingRangeProvider: true,
                                          documentHighlightProvider: true
                                        })
  end

  it 'returns all capabilities when all options are enabled' do
    host = Solargraph::LanguageServer::Host.new
    init = described_class.new(host, {
                                 'params' => {
                                   'initializationOptions' => {
                                     'completion' => true,
                                     'autoformat' => true,
                                     'formatting' => true
                                   }
                                 }
                               })
    init.process
    result = init.result

    expect(result[:capabilities]).to eq(
      completionProvider: { resolveProvider: true, triggerCharacters: ['.', ':', '@'] },
      signatureHelpProvider: { triggerCharacters: ['(', ','] },
      hoverProvider: true,
      documentSymbolProvider: true,
      definitionProvider: true,
      typeDefinitionProvider: true,
      renameProvider: { prepareProvider: true },
      referencesProvider: true,
      workspaceSymbolProvider: true,
      foldingRangeProvider: true,
      documentHighlightProvider: true,
      workspace: { workspaceFolders: { changeNotifications: true, supported: true } },
      documentFormattingProvider: true,
      textDocumentSync: 2
    )
  end
end
