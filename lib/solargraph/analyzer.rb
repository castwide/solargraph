require 'parser/current'

class Solargraph::Analyzer
  include NodeMethods
  
  attr_reader :code
  attr_reader :node
  
  def initialize(code = '')
    @code = code
    tries = 0
    code.gsub!(/\.([\s])/, "#$1")
    begin
      @node = Parser::CurrentRuby.parse(code)
    rescue Parser::SyntaxError => e
      if tries < 10
        tries += 1
        spot = e.diagnostic.location.begin_pos
        if spot == code.length
          STDERR.puts "********* END OF FILE"
          code = code[0..-2] + '#'
        else
          STDERR.puts "********* SOMEWHERE IN THERE"
          code = code[0..spot] + '#' + code[spot+2..-1].to_s
        end
        STDERR.puts "Retrying"
        retry
      end
      raise e
    end
  end
  def tree_at(index)
    arr = []
    if index >= @node.loc.expression.begin_pos and index < @node.loc.expression.end_pos
      inner_node_at(index, @node, arr)
    end
    arr
  end
  def namespace_at(index)
    tree = tree_at(index)
    return nil if tree.length == 0
    node = parent_node_from(index, :module, :class)
    slice = tree[tree.index(node)..-1]
    parts = []
    slice.reverse.each { |n|
      if n.type == :class or n.type == :module
        parts.push unpack_name(n.children[0])
      end
    }
    parts.join("::")
  end
  def sexp
    "#{@node}"
  end
  def instance_method_at?(index)
    scope = parent_node_from(index, :module, :class, :def)
    !scope.nil? and scope.type == :def
  end
  def stub
    inner_stub(@node)
  end
  def get_constants namespace
    Object.instance_eval "#{namespace || Module}.constants"
  end
  def get_methods namespace, access = 'public'
    m = []
    m += eval("::#{namespace}.public_methods")
    if access == 'protected' or access == 'private'
      m += eval("::#{namespace}.protected_methods")
    end
    if access == 'private'
      m += eval("::#{namespace}.private_methods")
    end
    m
  end
  def get_instance_methods namespace, access
    m = []
    m += eval("::#{namespace}.public_instance_methods")
    if access == 'protected' or access == 'private'
      m += eval("::#{namespace}.protected_instance_methods")
    end
    if access == 'private'
      m += eval("::#{namespace}.private_instance_methods")
    end
    m
  end
  def get_global_variables
    eval("#{global_variables}")
  end
  def get_instance_variables_at index
    n = namespace_at(index)
    if instance_method_at?(index)
      # TODO Get instance variables from instance methods
      get_ii_variables_at(index)
    else
      # TODO Get instance variables from module and singleton methods
    end
  end
  def get_local_variables_at index
    
  end
  def get_info_at index
    info = {}
    info[:namespace] = namespace_at(index)
    info[:instance_method] = instance_method_at?(index)
    info
  end
  def get_word_at index
    word = ''
    cursor = index - 1
    while cursor > 0
      char = @code[cursor, 1]
      #puts "***#{char}"
      break if char.nil? or char == ''
      break unless char.match(/[\s;=]/).nil?
      word = char + word
      cursor -= 1
    end
    word
  end
  private
  def parent_node_from(index, *types)
    arr = tree_at(index)
    arr.each { |a|
      if types.include?(a.type)
        return a
      end
    }
    nil  
  end
  def get_ii_variables_at index
    arr = []
    node = parent_node_from(index, :class, :module)
    return arr if node.nil?
    find_instance_methods(node).each { |n|
      arr += get_instance_variables_in(n)
    }
    arr
  end
  def find_instance_methods node
    arr = []
    node.children.each { |n|
      if n.kind_of?(AST::Node) and n.type == :begin
        return find_instance_methods n
      end
      if n.kind_of?(AST::Node) and n.type == :def
        arr.push n
      end
    }
    arr
  end
  def get_instance_variables_in node
    arr = []
    node.children.each { |n|
      if n.kind_of?(AST::Node)
        if n.type == :ivasgn
          arr.push n.children[0]
        else
          arr += get_instance_variables_in(n)
        end
      end
    }
    arr
  end
  def inner_node_at(index, node, arr)
    arr.unshift node
    node.children.each { |c|
      if c.kind_of?(AST::Node)
        next if c.loc.expression.nil?
        if index >= c.loc.expression.begin_pos and index < c.loc.expression.end_pos
          f = inner_node_at(index, c, arr)
          return f || c
        end
      end
    }
    return node
  end
  def inner_stub(node)
    code = ''
    scoped = false
    if node.type == :class or node.type == :module
      scoped = true
      code += "#{node.type} "
      code += unpack_name(node.children[0])
      if node.type == :class and !node.children[1].nil?
        code += " < #{unpack_name(node.children[1])}"
      end
      code += "\n"
    elsif node.type == :def
      scoped = true
      code += "def #{node.children[0]}"
      if node.children[1].children.length > 0
        code += " #{unpack_args(node.children[1])}"
      end
      code += "\n"
    elsif node.type == :send and node.children[0] == nil and node.children[1] == :include
      code += "include #{unpack_name(node.children[2])}\n"
    elsif node.type == :send and node.children[0] == nil and node.children[1] == :require and node.children[2].type == :str
      code += "require '#{node.children[2].children[0]}'\n"
    end
    node.children.each { |n|
      if n.kind_of?(AST::Node)
        code += inner_stub(n)
      end
    }
    if scoped
      code += "end\n"
    end
    code
  end
  def unpack_args(node)
    args = []
    node.children.each { |n|
      if n.type == :kwarg
        args.push "#{n.children[0]}:"
      elsif n.type == :kwoptarg
        args.push "#{n.children[0]}:nil"
      elsif n.type == :arg
        args.push "#{n.children[0]}"
      end
    }
    args.join(', ')
  end
end
