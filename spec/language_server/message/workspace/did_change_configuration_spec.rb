# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Solargraph::LanguageServer::Message::Workspace::DidChangeConfiguration do
  let(:host) { Solargraph::LanguageServer::Host.new }

  describe '#process' do
    context 'when no custom settings are provided' do
      it 'uses default settings' do
        message = { 'params' => { 'settings' => { 'solargraph' => {} } } }
        described_class.new(host, message).process

        expect(host.options).to eq(
          'completion' => true,
          'hover' => true,
          'symbols' => true,
          'definitions' => true,
          'typeDefinitions' => true,
          'rename' => true,
          'references' => true,
          'autoformat' => false,
          'diagnostics' => true,
          'formatting' => false,
          'folding' => true,
          'highlights' => true,
          'logLevel' => 'warn'
        )
      end
    end

    context 'when custom settings are provided' do
      it 'updates the provided settings' do
        message = { 'params' => { 'settings' => { 'solargraph' => { 'logLevel' => 'debug' } } } }
        described_class.new(host, message).process

        expect(host.options['logLevel']).to eq('debug')
      end

      it 'retains the other default settings' do
        message = { 'params' => { 'settings' => { 'solargraph' => { 'typeDefinitions' => false } } } }
        described_class.new(host, message).process

        expect(host.options).to eq(
          'completion' => true,
          'hover' => true,
          'symbols' => true,
          'definitions' => true,
          'typeDefinitions' => false,
          'rename' => true,
          'references' => true,
          'autoformat' => false,
          'diagnostics' => true,
          'formatting' => false,
          'folding' => true,
          'highlights' => true,
          'logLevel' => 'warn'
        )
      end
    end

    context 'when a capability can be dynamically registered' do
      before do
        # This is defined in [Solargraph::LanguageServer::Message::Initialize] phase.
        host.allow_registration('textDocument/completion')
      end

      it 'changes capabilities from options' do
        message = { 'params' => { 'settings' => { 'solargraph' => { 'completion' => true } } } }

        described_class.new(host, message).process

        expect(
          host.registered?('textDocument/completion')
        ).to be_truthy, 'Expected textDocument/completion to be registered'
      end
    end

    context 'when a capability can not be dynamically registered' do
      it 'does not change capabilities from options' do
        message = { 'params' => { 'settings' => { 'solargraph' => { 'completion' => true } } } }

        described_class.new(host, message).process

        expect(
          host.registered?('textDocument/completion')
        ).to be_falsy, 'Expected textDocument/completion to not be registered'
      end
    end
  end
end
