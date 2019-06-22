require 'yard'

module Solargraph
  # A placeholder for the @!domain directive. It doesn't need to do anything
  # for yardocs. It's only used for Solargraph API maps.
  class DomainDirective < YARD::Tags::Directive
    def call; end
  end
end

# Define a @type tag for documenting variables
YARD::Tags::Library.define_tag("Type", :type, :with_types_and_name)
# Define a @yieldself tag for documenting block contexts
YARD::Tags::Library.define_tag("Yieldself", :yieldself, :with_types)
# Define a @yieldpublic tag for documenting block domains
YARD::Tags::Library.define_tag("Yieldpublic", :yieldpublic, :with_types)
# Define a @return_first_parameter tag for returning Array parameters
YARD::Tags::Library.define_tag('ReturnSingleParameter', :return_single_parameter)
# Define a @!domain directive for documenting DSLs
YARD::Tags::Library.define_directive("domain", :with_types, Solargraph::DomainDirective)
# Define an @!override directive for overriding method tags
YARD::Tags::Library.define_directive("override", :with_name, Solargraph::DomainDirective)
