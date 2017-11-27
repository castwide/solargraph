$LOAD_PATH.unshift File.realpath(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'solargraph'
require 'simplecov'

SimpleCov.start

RSpec.configure do |config|
  config.before :all do
    Solargraph::LiveMap.install Solargraph::Plugin::Canceler
  end

  config.after :all do
    Solargraph::LiveMap.uninstall Solargraph::Plugin::Canceler
  end
end
