# frozen_string_literal: true

module Solargraph
  class ApiMap
    class ReqDiff
      def initialize
        require 'trie'
        @native = true
      rescue LoadError
        @native = false
      end

      # Determine requires that still need processing
      #
      # @param bundle [Bundle]
      # @param reqs [Array<String>]
      # @param new_map_hash [Hash<String, String>]
      # @return [Array<String>]
      def unresolved_requires bundle, reqs, new_map_hash
        if @native
          diff_native(bundle, reqs, new_map_hash)
        else
          diff_pure(bundle, reqs, new_map_hash)
        end
      end

      private

      # Determine requires that still need processing using trie_fast
      #
      # @param bundle [Bundle]
      # @param reqs [Array<String>]
      # @param new_map_hash [Hash<String, String>]
      # @return [Array<String>]
      def diff_native bundle, reqs, new_map_hash
        local_path_hash = {}

        # convert new map hash to a trie
        source_trie = Trie.new
        new_map_hash.keys.each do |key|
          source_trie.add(key) unless key.nil?
        end

        # add eagerly add trailing separator to directories
        ws_path = Pathname.new(bundle.workspace.directory)
        req_paths = bundle.workspace.require_paths.map do |req_path|
          req_path + File::SEPARATOR
        end
        all_paths = req_paths.concat([ws_path.to_s])

        # determine the longest shared prefix, likely the repo root directory
        longest_prefix = longest_prefix(all_paths)

        # navigate down trie to longest shared prefix
        prefix_node = source_trie.root
        longest_prefix.each_char do |c|
          prefix_node = prefix_node.walk(c)
          break if prefix_node.nil?
        end
        return local_path_hash if prefix_node.nil?

        all_paths.each do |req_path|
          break if reqs.empty?
          remaining_path = req_path[longest_prefix.size..-1]

          # navigate down require path
          node = prefix_node
          remaining_path.each_char do |c|
            node = node.walk(c)
            break if node.nil?
          end
          next unless node

          # remove all requires that are found in new_map_hash
          reqs = reqs.delete_if do |req|
            req_node = node

            (req + '.rb').each_char do |c|
              req_node = req_node.walk(c)
              break if req_node.nil?
            end

            if req_node.nil?
              false
            else
              local_path_hash[req] = req_node.full_state
              true
            end
          end
        end

        local_path_hash
      end

      # Determine requires that still need processing using trie_fast
      #
      # @param bundle [Bundle]
      # @param reqs [Array<String>]
      # @param new_map_hash [Hash<String, String>]
      # @return [Array<String>]
      def diff_pure bundle, reqs, new_map_hash
        local_path_hash = {}
        file_keys = new_map_hash.keys
        workspace_path = Pathname.new(bundle.workspace.directory)
        reqs.delete_if do |r|
          bundle.workspace.require_paths.any? do |base|
            pn = workspace_path.join(base, "#{r}.rb").to_s
            if file_keys.include? pn
              local_path_hash[r] = pn
              true
            else
              false
            end
          end
        end

        local_path_hash
      end

      # Find the longest prefix in an array of strings
      #
      # @params paths: [Array<String>]
      # @returns String
      def longest_prefix paths
        return '' if paths.nil? || paths.empty?
        sorted_paths = paths

        first = sorted_paths[0]
        last = sorted_paths[sorted_paths.size - 1]
        min_length = [first.size, last.size].min

        i = 0
        i += 1 while i < min_length && first[i] == last[i]

        first[0...i]
      end
    end
  end
end
