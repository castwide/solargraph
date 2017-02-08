class Logger < Object
include Logger::Severity
include Kernel
def level();end
def level=(arg0);end
def progname();end
def progname=(arg0);end
def datetime_format=(datetime_format);end
def datetime_format();end
def formatter();end
def formatter=(arg0);end
def sev_threshold();end
def sev_threshold=(arg0);end
def debug?();end
def info?();end
def warn?();end
def error?();end
def fatal?();end
def add(severity, message = nil, progname = nil, &block);end
def log(severity, message = nil, progname = nil, &block);end
def <<(msg);end
def debug(*args);end
def info(*args);end
def error(*args);end
def fatal(*args);end
def unknown(*args);end
def close();end
end
class Logger::Error < RuntimeError
include Kernel
def self.exception(*args);end
end
class Logger::ShiftingError < Logger::Error
include Kernel
def self.exception(*args);end
end
module Logger::Severity
end
class Logger::Formatter < Object
include Kernel
def datetime_format();end
def datetime_format=(arg0);end
def call(severity, time, progname, msg);end
end
class Logger::LogDevice < Object
include Kernel
def dev();end
def filename();end
def write(message);end
def close();end
end
class Logger::LogDevice::LogDeviceMutex < Object
include MonitorMixin
include Kernel
end
class MonitorMixin::ConditionVariable < Object
include Kernel
def wait(*args);end
def wait_while();end
def wait_until();end
def signal();end
def broadcast();end
end
class MonitorMixin::ConditionVariable::Timeout < Exception
include Kernel
def self.exception(*args);end
end
class Logger::Application < Object
include Logger::Severity
include Kernel
def appname();end
def start();end
def logger();end
def logger=(logger);end
def set_log(logdev, shift_age = nil, shift_size = nil);end
def log=(logdev);end
def level=(level);end
def log(severity, message = nil, &block);end
end
