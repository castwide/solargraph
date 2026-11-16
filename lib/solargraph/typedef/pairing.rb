# frozen_string_literal: true

module Solargraph
  module Typedef
    # Member pairing behind #combine_via, shared by Typedef::Union and
    # ComplexType: two types are paired up member by member, the block
    # decides each pair, and the caller reassembles the results.
    module Pairing
      module_function

      # Pairs two member lists and yields each pair: a lone member on
      # either side takes on the whole of the other; otherwise members
      # both sides carry pair off first and the rest zip up.
      #
      # @param mine [Array<Type>]
      # @param theirs [Array<Type>]
      # @param gather [Proc] gathers several members into one type
      # @param key [Proc] what two members must share to be the same member
      # @yieldparam mine_member [Type]
      # @yieldparam theirs_member [Type]
      # @yieldreturn [Type]
      # @return [Array<Type>] a result per pair, plus anything left unpaired
      def combine_members mine, theirs, gather, key, &block
        return [block.call(gather.call(mine), gather.call(theirs))] if mine.length == 1 || theirs.length == 1

        mine_rest = mine.dup
        theirs_rest = theirs.dup
        matched = pair_identical_members(mine_rest, theirs_rest, key, &block)
        zipped = pair_remaining_members(mine_rest, theirs_rest, gather, &block)
        matched + zipped + mine_rest + theirs_rest
      end

      # Yields each member both sides carry, matched on +key+ and in any
      # order, removing it from both lists.
      #
      # @param mine [Array<Type>] matched members are removed
      # @param theirs [Array<Type>] matched members are removed
      # @param key [Proc]
      # @yieldparam mine_member [Type]
      # @yieldparam theirs_member [Type]
      # @yieldreturn [Type]
      # @return [Array<Type>]
      def pair_identical_members mine, theirs, key
        results = []
        mine.delete_if do |member|
          index = theirs.index { |other| key.call(other) == key.call(member) }
          next false if index.nil?

          results.push(yield(member, theirs.delete_at(index)))
          true
        end
        results
      end

      # Zips both lists from the front, yielding each pair and removing
      # it. The shorter side runs out first, so its last member takes on
      # everything left of the other.
      #
      # @param mine [Array<Type>] paired members are removed
      # @param theirs [Array<Type>] paired members are removed
      # @param gather [Proc] gathers several members into one type
      # @yieldparam mine_member [Type]
      # @yieldparam theirs_member [Type]
      # @yieldreturn [Type]
      # @return [Array<Type>]
      def pair_remaining_members mine, theirs, gather
        results = []
        until mine.empty? || theirs.empty?
          if mine.length == 1 || theirs.length == 1
            results.push(yield(gather.call(mine.dup), gather.call(theirs.dup)))
            mine.clear
            theirs.clear
          else
            results.push(yield(mine.shift, theirs.shift))
          end
        end
        results
      end
    end
  end
end
