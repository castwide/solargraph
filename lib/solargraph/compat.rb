unless Hash.method_defined?(:transform_keys)
  class Hash
    def transform_keys &block
      each_pair do |k, v|
        self[block.call(k)] = v
      end
    end
  end
end

unless Hash.method_defined?(:transform_values)
  class Hash
    def transform_values &block
      each_pair do |k, v|
        self[k] = block.call(v)
      end
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
