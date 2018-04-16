require 'yard'
require 'yard/templates/helpers/markup_helper'
require 'yard/templates/helpers/html_helper'

# Define a @type tag for documenting variables
YARD::Tags::Library.define_tag("Type", :type, :with_types_and_name)
# Define a @yieldself tag for documenting block contexts
YARD::Tags::Library.define_tag("Yieldself", :yieldself, :with_types)
