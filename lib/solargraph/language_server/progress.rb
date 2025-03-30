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

        if created?
          host.send_notification '$/progress', message
        else
          create(host) { host.send_notification '$/progress', message }
        end
        @status = FINISHED if kind == 'end'
      end

      def created?
        [CREATED, FINISHED].include?(status)
      end

      def finished?
        status == FINISHED
      end

      private

      # @param host [Solargraph::LanguageServer::Host]
      def create host, &block
        return false if created?

        host.send_request 'window/workDoneProgress/create', { token: uuid }, &block
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
    end
  end
end
