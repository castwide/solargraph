# frozen_string_literal: true

require 'jaro_winkler'

module Solargraph
  module Pin
    class Search
      class Result
        # @return [Float]
        attr_reader :match

        # @return [Pin::Base]
        attr_reader :pin

        def initialize match, pin
          @match = match
          @pin = pin
        end
      end

      # @param pins [Array<Pin::Base>]
      # @param query [String]
      def initialize pins, query
        @pins = pins
        @query = query
      end

      # @return [Array<Pin::Base>]
      def results
        @results ||= do_query
      end

      private

      # @return [Array<Pin::Base>]
      def do_query
        return @pins if @query.nil? || @query.empty?
        @pins.map do |pin|
          match = [fuzzy_string_match(pin.path, @query), fuzzy_string_match(pin.name, @query)].max
          Result.new(match, pin) if match > 0.6
        end
          .compact
          .sort do |a, b|
            if a.match == b.match
              a.pin.path <=> b.pin.path
            else
              b.match <=> a.match
            end
          end
          .map(&:pin)
      end

      # @param str1 [String]
      # @param str2 [String]
      # @return [Float]
      def fuzzy_string_match str1, str2
        JaroWinkler.distance(str1, str2)
      end
    end
  end
end
