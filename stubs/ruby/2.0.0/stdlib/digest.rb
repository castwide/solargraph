module Digest
def hexencode(arg0);end
def self.hexencode(arg0);end
end
module Digest::Instance
def update(arg0);end
def <<(arg0);end
def reset();end
def digest_length();end
def block_length();end
def ==(arg0);end
def inspect();end
def new();end
def digest(*args);end
def digest!();end
def hexdigest(*args);end
def hexdigest!();end
def to_s();end
def length();end
def size();end
def file(name);end
def base64digest(*args);end
def base64digest!();end
end
class Digest::Class < Object
include Digest::Instance
include Kernel
def self.digest(*args);end
def self.hexdigest(*args);end
def self.file(name);end
def self.base64digest(str, *args);end
def self.digest(*args);end
def self.hexdigest(*args);end
def self.file(name);end
def self.base64digest(str, *args);end
end
class Digest::Base < Digest::Class
include Digest::Instance
include Kernel
def self.digest(*args);end
def self.hexdigest(*args);end
def self.file(name);end
def self.base64digest(str, *args);end
def reset();end
def update(arg0);end
def <<(arg0);end
def digest_length();end
def block_length();end
end
