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
    autoload :Namespace,        'solargraph/pin/namespace'
    autoload :Keyword,          'solargraph/pin/keyword'
    autoload :MethodParameter,  'solargraph/pin/method_parameter'
    autoload :BlockParameter,   'solargraph/pin/block_parameter'
    autoload :Reference,        'solargraph/pin/reference'
    autoload :Documenting,      'solargraph/pin/documenting'
    autoload :Block,            'solargraph/pin/block'
    autoload :Localized,        'solargraph/pin/localized'
    autoload :ProxyType,        'solargraph/pin/proxy_type'
    autoload :DuckMethod,       'solargraph/pin/duck_method'
    autoload :YardPin,          'solargraph/pin/yard_pin'

    ATTRIBUTE = 1
    CLASS_VARIABLE = 2
    CONSTANT = 3
    GLOBAL_VARIABLE = 4
    INSTANCE_VARIABLE = 5
    KEYWORD = 6
    LOCAL_VARIABLE = 7
    METHOD = 8
    NAMESPACE = 9
    SYMBOL = 10
    BLOCK = 11
    BLOCK_PARAMETER = 12

    ROOT_PIN = Pin::Namespace.new(nil, '', '', '', :class, :public, nil)
  end
end
