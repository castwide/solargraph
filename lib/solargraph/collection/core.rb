# frozen_string_literal: true

module Solargraph
  module Collection
    class Core < Base
      def cache_file
        File.join CacheDir.work_dir, 'core.ser'
      end

      def pins
        RbsMap::Core.pins
      end
    end
  end
end
