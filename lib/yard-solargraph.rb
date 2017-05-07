require 'yard'
require 'yard/handlers/ruby/base'

class YardHandlerExtension < YARD::Handlers::Ruby::HandlesExtension
  def matches? node
    if node.docstring and node.docstring.include?(name)
      true
    else
      false
    end
  end
end

class MyHandler < YARD::Handlers::Ruby::CommentHandler
  handles YardHandlerExtension.new("@bind")

  process do
    if owner.type == :root
      d = YARD::Docstring.new(statement.docstring)
      owner.add_tag d.tag(:bind)
    end
  end
end

# Define a @type tag to be used for documenting variables
YARD::Tags::Library.define_tag("Type", :type, :with_types_and_name)
YARD::Tags::Library.define_tag("Bind", :bind, :with_types)
