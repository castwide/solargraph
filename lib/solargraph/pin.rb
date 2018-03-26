module Solargraph
  module Pin
    autoload :Helper,           'solargraph/pin/helper'
    autoload :Conversions,      'solargraph/pin/conversions'
    autoload :Base,             'solargraph/pin/base'
    autoload :Method,           'solargraph/pin/method'
    autoload :Attribute,        'solargraph/pin/attribute'
    autoload :BaseVariable,     'solargraph/pin/base_variable'
    autoload :InstanceVariable, 'solargraph/pin/instance_variable'
    autoload :ClassVariable,    'solargraph/pin/class_variable'
    autoload :LocalVariable,    'solargraph/pin/local_variable'
    autoload :GlobalVariable,   'solargraph/pin/global_variable'
    autoload :Constant,         'solargraph/pin/constant'
    autoload :Symbol,           'solargraph/pin/symbol'
    autoload :Directed,         'solargraph/pin/directed'
    autoload :Namespace,        'solargraph/pin/namespace'
    autoload :YardObject,       'solargraph/pin/yard_object'
    autoload :Keyword,          'solargraph/pin/keyword'
    autoload :Parameter,        'solargraph/pin/parameter'
    autoload :MethodParameter,  'solargraph/pin/method_parameter'
    autoload :BlockParameter,   'solargraph/pin/block_parameter'
  end
end
