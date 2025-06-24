# frozen_string_literal: true

require 'securerandom'

module Solargraph
  module LanguageServer
    # Progress notification handling for language server hosts.
    #
    class Progress
      WAITING = :waiting
      CREATED = :created
      FINISHED = :finished

      # @return [String]
      attr_reader :uuid

      # @return [String]
      attr_reader :title

      # @return [String, nil]
      attr_reader :kind

      # @return [String, nil]
      attr_reader :message

      # @return [Integer]
      attr_reader :percentage

      # @return [Symbol]
      attr_reader :status

      # @param title [String]
      def initialize title
        @title = title
        @uuid = SecureRandom.uuid
        @percentage = 0
        @status = WAITING
      end

      # @param message [String]
      # @param percentage [Integer]
      def begin message, percentage
        @kind = 'begin'
        @message = message
        @percentage = percentage
      end

      # @param message [String]
      # @param percentage [Integer]
      def report message, percentage
        @kind = 'report'
        @message = message
        @percentage = percentage
      end

      # @param message [String]
      def finish message
        @kind = 'end'
        @message = message
        @percentage = 100
        true
      end

      # @param host [Solargraph::LanguageServer::Host]
      def send host
        return unless host.client_supports_progress? && !finished?

        message = build
        create(host)
        host.send_notification '$/progress', message
        @status = FINISHED if kind == 'end'
        keep_alive host
      end

      def created?
        [CREATED, FINISHED].include?(status)
      end

      def finished?
        status == FINISHED
      end

      private

      # @param host [Solargraph::LanguageServer::Host]
      # @return [void]
      def create host
        return if created?

        host.send_request 'window/workDoneProgress/create', { token: uuid }
        @status = CREATED
      end

      def build
        {
          token: uuid,
          value: {
            kind: kind,
            cancellable: false
          }.merge(build_value)
        }
      end

      def build_value
        case kind
        when 'begin'
          { title: title, message: message, percentage: percentage }
        when 'report'
          { message: message, percentage: percentage }
        when 'end'
          { message: message }
        else
          raise "Invalid progress kind #{kind}"
        end
      end

      # @param host [Host]
      def keep_alive host
        mutex.synchronize { @last = Time.now }
        @keep_alive ||= Thread.new do
          until finished?
            sleep 10
            break if finished?
            next if mutex.synchronize { Time.now - @last < 10 }
            send host
          end
        end
      end

      def mutex
        @mutex ||= Mutex.new
      end
    end
  end
end
