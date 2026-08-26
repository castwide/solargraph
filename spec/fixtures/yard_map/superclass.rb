# frozen_string_literal: true

class SuperclassBase; end

class SuperclassDeclared < SuperclassBase; end

# A reopening with no superclass clause. YARD records `Object` here, the same
# as it would for a first definition with no superclass.
class SuperclassReopened
  def reopened; end
end
