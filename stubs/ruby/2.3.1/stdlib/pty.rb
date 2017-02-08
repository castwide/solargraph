module PTY
def getpty(*args);end
def check(*args);end
def self.getpty(*args);end
def self.check(*args);end
end
class PTY::ChildExited < RuntimeError
include Kernel
def self.exception(*args);end
def status();end
end
