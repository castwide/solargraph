require 'solargraph'
require 'eventmachine'
require 'bundler'
require 'json'
#require 'solargraph-rails-ext/event_module'

module Solargraph
  module Plugin
    class Server
      attr_reader :workspace

      def initialize workspace, port, ppid
        @workspace = workspace
        @port = port
        @ppid = ppid
      end

      def run
        EventMachine.run {
          Signal.trap("INT") do
            EventMachine.stop
          end
          Signal.trap("TERM") do
            EventMachine.stop
          end
          EventMachine.start_server 'localhost', @port, Solargraph::Plugin::EventModule
          unless @ppid.nil?
            # HACK: Send a signal to the parent PID to determine whether the
            # server should be stopped.
            EventMachine.add_periodic_timer 1 do
              begin
                Process.kill 0, @ppid
              rescue Errno::ESRCH
                EventMachine.stop
              end
            end
          end
        }
      end

      private

      def load_environment
        begin
          Dir.chdir workspace
          Bundler.with_original_env do
            ENV['BUNDLE_GEMFILE'] = File.join(workspace, 'Gemfile')
            Bundler.reset!
            Bundler.require
            rails_config = File.join(workspace, 'config', 'application.rb')
            if File.file?(rails_config)
              require_relative(rails_config)
            end
          end
        rescue Exception => e
          STDERR.puts "Error loading Rails environment: #{e}"
        end
      end

      def can_posix?
        Signal.list.include?("HUP")
      end
    end
  end
end
