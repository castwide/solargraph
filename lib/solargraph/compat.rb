unless Hash.method_defined?(:transform_keys)
  class Hash
    def transform_keys &block
      result = {}
      each_pair do |k, v|
        result[block.call(k)] = v
      end
      result
    end
  end
end

unless Hash.method_defined?(:transform_values)
  class Hash
    def transform_values &block
      result = {}
      each_pair do |k, v|
        result[k] = block.call(v)
      end
      result
    end
  end
end

unless Array.method_defined?(:sum)
  class Array
    def sum &block
      inject(0) do |s, x|
        if block
          s + block.call(x)
        else
          s + x
        end
      end
    end
  end
end
