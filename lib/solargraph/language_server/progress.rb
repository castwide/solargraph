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

      # The number of seconds an idle notification can go without an update
      # before it's refreshed. Some hosts dismiss progress notifications that
      # haven't been updated recently.
      #
      KEEP_ALIVE_INTERVAL = 10

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
      # @return [void]
      def begin message, percentage
        @kind = 'begin'
        @message = message
        @percentage = clamp_percentage percentage
      end

      # @param message [String]
      # @param percentage [Integer]
      # @return [void]
      def report message, percentage
        return if finished?
        @kind = 'report'
        @message = message
        @percentage = clamp_percentage percentage
      end

      # @param message [String]
      # @return [void]
      def finish message
        return false if finished?
        @kind = 'end'
        @message = message
        @percentage = 100
        true
      end

      # @param host [Solargraph::LanguageServer::Host]
      # @return [void]
      def send host
        return unless host.client_supports_progress?
        mutex.synchronize do
          return if finished?
          message = build
          create host
          host.send_notification '$/progress', message
          @last = Time.now
          @status = FINISHED if kind == 'end'
          start_keep_alive host unless finished?
        end
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

      # @return [Hash]
      def build
        {
          token: uuid,
          value: {
            kind: kind,
            cancellable: false
          }.merge(build_value)
        }
      end

      # @return [Hash]
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

      # Keep idle notifications alive. Some hosts, including VS Code, stop
      # responding to progress notifications that haven't been updated for a
      # while, so a long-running job has to refresh its notification until it
      # either reports again or finishes.
      #
      # The thread is only created once and exits as soon as the progress is
      # finished or the host shuts down, so a completed notification can never
      # be resurrected.
      #
      # @param host [Host]
      # @return [void]
      def start_keep_alive host
        return if @keep_alive
        @keep_alive = Thread.new do
          loop do
            sleep KEEP_ALIVE_INTERVAL
            break if finished? || host.stopped?
            next if mutex.synchronize { elapsed < KEEP_ALIVE_INTERVAL }
            begin
              send host
            rescue StandardError
              break
            end
          end
        end
      end

      # The number of seconds since the last notification was sent.
      #
      # @return [Float]
      def elapsed
        (Time.now - (@last ||= Time.now)).to_f
      end

      # @param percentage [Integer, nil]
      # @return [Integer]
      def clamp_percentage percentage
        return 0 if percentage.nil?
        percentage.to_i.clamp 0, 100
      end

      # @return [Thread::Mutex]
      def mutex
        @mutex ||= Mutex.new
      end
    end
  end
end
