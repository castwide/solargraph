# frozen_string_literal: true

require 'digest'

module Solargraph
  module Collection
    # Cacheable pins from an RBS collection directory.
    #
    class Rbs < Base
      # @return [String]
      attr_reader :path

      # @param path [String]
      # @return [Array<Pin::Base>]
      def self.load path
        new(path).load
      end

      # @param path [String]
      def initialize path
        super()
        @path = path
      end

      # @return [Array<Pin::Base>]
      def pins
        @pins ||= RbsMap::Path.pins(path)
      end

      # @return [String]
      def cache_file
        File.join CacheDir.rbs_dir, "#{key}.ser"
      end

      private

      # A collection is rewritten in place by `rbs collection install`, so the
      # newest signature mtime distinguishes one installation from the next.
      #
      # @return [String]
      def key
        @key ||= begin
          stamp = Dir.glob(File.join(path, '**', '*.rbs')).map { |file| File.mtime(file).to_i }.max
          format('%.32s', Digest::SHA256.hexdigest("#{File.expand_path(path)}:#{stamp}"))
        end
      end
    end
  end
end
