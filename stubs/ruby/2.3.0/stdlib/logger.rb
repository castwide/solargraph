class Logger < Object
include Logger::Severity
include Kernel
def <<(msg);end
def fatal(*args);end
def reopen(*args);end
def close();end
def log(severity, message = nil, progname = nil, &block);end
def add(severity, message = nil, progname = nil, &block);end
def error(*args);end
def level();end
def level=(severity);end
def progname();end
def datetime_format=(datetime_format);end
def datetime_format();end
def formatter();end
def sev_threshold();end
def sev_threshold=(severity);end
def debug?();end
def info?();end
def warn?();end
def error?();end
def fatal?();end
def debug(*args);end
def info(*args);end
def unknown(*args);end
def progname=(arg0);end
def formatter=(arg0);end
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
def call(severity, time, progname, msg);end
def datetime_format=(arg0);end
def datetime_format();end
end
module Logger::Period
def next_rotate_time(now, shift_age);end
def previous_period_end(now, shift_age);end
def self.next_rotate_time(now, shift_age);end
def self.previous_period_end(now, shift_age);end
end
class Logger::LogDevice < Object
include MonitorMixin
include Logger::Period
include Kernel
def write(message);end
def reopen(*args);end
def close();end
def filename();end
def dev();end
end
class MonitorMixin::ConditionVariable < Object
include Kernel
def wait(*args);end
def signal();end
def broadcast();end
def wait_while();end
def wait_until();end
end
class MonitorMixin::ConditionVariable::Timeout < Exception
include Kernel
def self.exception(*args);end
end
