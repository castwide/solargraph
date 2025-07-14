# frozen_string_literal: true

Encoding.default_external = 'UTF-8'

require 'bundler'
require 'set'
require 'yard-solargraph'
require 'solargraph/yard_tags'
require 'solargraph/version'

# The top-level namespace for the Solargraph code mapping, documentation,
# static analysis, and language server libraries.
#
module Solargraph
  class InvalidOffsetError         < RangeError;    end
  class DiagnosticsError           < RuntimeError;  end
  class FileNotFoundError          < RuntimeError;  end
  class SourceNotAvailableError    < StandardError; end
  class ComplexTypeError           < StandardError; end
  class WorkspaceTooLargeError     < RuntimeError;  end
  class BundleNotFoundError        < StandardError; end
  class InvalidRubocopVersionError < RuntimeError;  end

  autoload :Position,         'solargraph/position'
  autoload :Range,            'solargraph/range'
  autoload :Location,         'solargraph/location'
  autoload :Shell,            'solargraph/shell'
  autoload :Source,           'solargraph/source'
  autoload :SourceMap,        'solargraph/source_map'
  autoload :ApiMap,           'solargraph/api_map'
  autoload :Yardoc,           'solargraph/yardoc'
  autoload :YardMap,          'solargraph/yard_map'
  autoload :Pin,              'solargraph/pin'
  autoload :DocMap,           'solargraph/doc_map'
  autoload :ServerMethods,    'solargraph/server_methods'
  autoload :LanguageServer,   'solargraph/language_server'
  autoload :Workspace,        'solargraph/workspace'
  autoload :Page,             'solargraph/page'
  autoload :Library,          'solargraph/library'
  autoload :Diagnostics,      'solargraph/diagnostics'
  autoload :ComplexType,      'solargraph/complex_type'
  autoload :Bench,            'solargraph/bench'
  autoload :Logging,          'solargraph/logging'
  autoload :TypeChecker,      'solargraph/type_checker'
  autoload :Environ,          'solargraph/environ'
  autoload :Equality,         'solargraph/equality'
  autoload :Convention,       'solargraph/convention'
  autoload :Parser,           'solargraph/parser'
  autoload :RbsMap,           'solargraph/rbs_map'
  autoload :GemPins,          'solargraph/gem_pins'
  autoload :PinCache,         'solargraph/pin_cache'

  dir = File.dirname(__FILE__)
  VIEWS_PATH = File.join(dir, 'solargraph', 'views')

  # @param type [Symbol] Type of assert.
  def self.asserts_on?(type)
    if ENV['SOLARGRAPH_ASSERTS'].nil? || ENV['SOLARGRAPH_ASSERTS'].empty?
      false
    elsif ENV['SOLARGRAPH_ASSERTS'] == 'on'
      true
    else
      logger.warn "Unrecognized SOLARGRAPH_ASSERTS value: #{ENV['SOLARGRAPH_ASSERTS']}"
      false
    end
  end

  # @param type [Symbol] The type of assertion to perform.
  # @param msg [String, nil] An optional message to log
  # @param block [Proc] A block that returns a message to log
  # @return [void]
  def self.assert_or_log(type, msg = nil, &block)
    raise (msg || block.call) if asserts_on?(type) && ![:combine_with_visibility].include?(type)
    logger.info msg, &block
  end

  # A convenience method for Solargraph::Logging.logger.
  #
  # @return [Logger]
  def self.logger
    Solargraph::Logging.logger
  end

  # A helper method that runs Bundler.with_unbundled_env or falls back to
  # Bundler.with_clean_env for earlier versions of Bundler.
  #
  # @generic T
  # @yieldreturn [generic<T>]
  # @sg-ignore dynamic call, but both functions behave the same
  # @return [generic<T>]
  def self.with_clean_env &block
    meth = if Bundler.respond_to?(:with_original_env)
      :with_original_env
    else
      :with_clean_env
    end
    Bundler.send meth, &block
  end
end

# Ensure that ParserGem node processors are properly loaded to avoid conflicts
# with Convention node processors
require 'solargraph/parser/parser_gem/node_processors'
