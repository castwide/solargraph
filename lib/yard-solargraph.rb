require 'yard'

# Define a @type tag for documenting variables
YARD::Tags::Library.define_tag("Type", :type, :with_types_and_name)
# Define a @yieldself tag for documenting block contexts
YARD::Tags::Library.define_tag("Yieldself", :yieldself, :with_types)
YARD::Tags::Library.define_directive("domain", YARD::Tags::MacroDirective)
