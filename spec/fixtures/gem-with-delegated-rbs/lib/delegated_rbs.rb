# frozen_string_literal: true

require 'forwardable'

class DelegatedRbsTarget
  # Label of the target.
  def label
    'label'
  end

  # Title of the target.
  def title
    'title'
  end

  # Size of the target.
  #
  # @return [Integer]
  def size
    1
  end
end

class DelegatedRbs
  extend Forwardable

  def_delegator :helper, :name
  def_delegators :target, :label, :title, :size

  # @return [DelegatedRbsTarget]
  def target
    DelegatedRbsTarget.new
  end

  def helper
    Object.new
  end
end
