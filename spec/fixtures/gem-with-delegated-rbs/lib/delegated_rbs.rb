# frozen_string_literal: true

require 'forwardable'

class DelegatedRbs
  extend Forwardable

  def_delegator :helper, :name

  def helper
    Object.new
  end
end
