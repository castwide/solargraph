# frozen_string_literal: true

module Solargraph
  module RbsMap
    class Path < Base
      # @param path [String]
      def initialize path
        super()
        loader.add path: Pathname.new(path)
      end
    end
  end
end
