class GetoptLong < Object
include Kernel
def ordering=(ordering);end
def ordering();end
def set_options(*args);end
def quiet=(arg0);end
def quiet();end
def quiet?();end
def terminate();end
def terminated?();end
def error();end
def error?();end
def error_message();end
def get();end
def get_option();end
def each();end
def each_option();end
end
class GetoptLong::Error < StandardError
include Kernel
def self.exception(*args);end
end
class GetoptLong::AmbiguousOption < GetoptLong::Error
include Kernel
def self.exception(*args);end
end
class GetoptLong::NeedlessArgument < GetoptLong::Error
include Kernel
def self.exception(*args);end
end
class GetoptLong::MissingArgument < GetoptLong::Error
include Kernel
def self.exception(*args);end
end
class GetoptLong::InvalidOption < GetoptLong::Error
include Kernel
def self.exception(*args);end
end
