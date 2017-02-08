class OptionParser < Object
include Kernel
def self.reject(*args);end
def self.terminate(*args);end
def self.accept(*args);end
def self.inc(arg, default = nil);end
def self.with(*args);end
def self.top();end
def self.getopts(*args);end
def self.reject(*args);end
def self.terminate(*args);end
def self.accept(*args);end
def self.inc(arg, default = nil);end
def self.with(*args);end
def self.top();end
def self.getopts(*args);end
def to_a();end
def reject(*args);end
def terminate(*args);end
def version();end
def remove();end
def version=(arg0);end
def accept(*args);end
def base();end
def release();end
def parse(*args);end
def candidate(word);end
def inc(*args);end
def summarize(*args);end
def compsys(to, name = nil);end
def help();end
def program_name();end
def ver();end
def banner();end
def add_officious();end
def top();end
def summary_width();end
def summary_indent();end
def default_argv();end
def set_banner(arg0);end
def banner=(arg0);end
def set_program_name(arg0);end
def program_name=(arg0);end
def set_summary_width(arg0);end
def summary_width=(arg0);end
def set_summary_indent(arg0);end
def summary_indent=(arg0);end
def make_switch(opts, block = nil);end
def define(*args);end
def on(*args);end
def def_option(*args);end
def define_head(*args);end
def on_head(*args);end
def def_head_option(*args);end
def define_tail(*args);end
def on_tail(*args);end
def def_tail_option(*args);end
def separator(string);end
def order(*args);end
def order!(*args);end
def permute(*args);end
def permute!(*args);end
def parse!(*args);end
def getopts(*args);end
def environment(*args);end
def default_argv=(arg0);end
def release=(arg0);end
end
module OptionParser::Completion
def regexp(key, icase);end
def candidate(key, icase = nil, pat = nil, &block);end
def self.regexp(key, icase);end
def self.candidate(key, icase = nil, pat = nil, &block);end
def convert(*args);end
def candidate(key, icase = nil, pat = nil);end
def complete(key, icase = nil, pat = nil);end
end
class OptionParser::OptionMap < Hash
include OptionParser::Completion
include Enumerable
include Kernel
def self.[](*args);end
def self.try_convert(arg0);end
end
class OptionParser::Switch < Object
include Kernel
def self.pattern();end
def self.guess(arg);end
def self.incompatible_argument_styles(arg, t);end
def self.pattern();end
def self.guess(arg);end
def self.incompatible_argument_styles(arg, t);end
def arg();end
def block();end
def pattern();end
def conv();end
def short();end
def long();end
def desc();end
def summarize(*args);end
def add_banner(to);end
def match_nonswitch?(str);end
def switch_name();end
def compsys(sdone, ldone);end
end
class OptionParser::Switch::NoArgument < OptionParser::Switch
include Kernel
def self.pattern();end
def self.incompatible_argument_styles(*args);end
def self.guess(arg);end
def self.pattern();end
def self.incompatible_argument_styles(*args);end
def parse(arg, argv);end
end
class OptionParser::Switch::RequiredArgument < OptionParser::Switch
include Kernel
def self.pattern();end
def self.guess(arg);end
def self.incompatible_argument_styles(arg, t);end
def parse(arg, argv);end
end
class OptionParser::Switch::OptionalArgument < OptionParser::Switch
include Kernel
def self.pattern();end
def self.guess(arg);end
def self.incompatible_argument_styles(arg, t);end
def parse(arg, argv, &error);end
end
class OptionParser::Switch::PlacedArgument < OptionParser::Switch
include Kernel
def self.pattern();end
def self.guess(arg);end
def self.incompatible_argument_styles(arg, t);end
def parse(arg, argv, &error);end
end
class OptionParser::List < Object
include Kernel
def list();end
def reject(t);end
def accept(t, pat = nil, &block);end
def complete(id, opt, icase = nil, *pat, &block);end
def short();end
def long();end
def summarize(*args);end
def add_banner(to);end
def compsys(*args);end
def atype();end
def append(*args);end
def search(id, key);end
def each_option(&block);end
end
class OptionParser::CompletingHash < Hash
include OptionParser::Completion
include Enumerable
include Kernel
def self.[](*args);end
def self.try_convert(arg0);end
def match(key);end
end
class OptionParser::ParseError < RuntimeError
include Kernel
def self.filter_backtrace(array);end
def self.exception(*args);end
def self.filter_backtrace(array);end
def message();end
def set_backtrace(array);end
def args();end
def reason();end
def set_option(opt, eq);end
def recover(argv);end
def reason=(arg0);end
end
class OptionParser::AmbiguousOption < OptionParser::ParseError
include Kernel
def self.filter_backtrace(array);end
def self.exception(*args);end
end
class OptionParser::NeedlessArgument < OptionParser::ParseError
include Kernel
def self.filter_backtrace(array);end
def self.exception(*args);end
end
class OptionParser::MissingArgument < OptionParser::ParseError
include Kernel
def self.filter_backtrace(array);end
def self.exception(*args);end
end
class OptionParser::InvalidOption < OptionParser::ParseError
include Kernel
def self.filter_backtrace(array);end
def self.exception(*args);end
end
class OptionParser::InvalidArgument < OptionParser::ParseError
include Kernel
def self.filter_backtrace(array);end
def self.exception(*args);end
end
class OptionParser::AmbiguousArgument < OptionParser::InvalidArgument
include Kernel
def self.filter_backtrace(array);end
def self.exception(*args);end
end
module OptionParser::Arguable
def extend_object(obj);end
def self.extend_object(obj);end
def options();end
def order!(&blk);end
def permute!();end
def parse!();end
def getopts(*args);end
def options=(opt);end
end
module OptionParser::Acceptables
end
class OptionParser < Object
include Kernel
def self.reject(*args);end
def self.terminate(*args);end
def self.accept(*args);end
def self.inc(arg, default = nil);end
def self.with(*args);end
def self.top();end
def self.getopts(*args);end
def self.reject(*args);end
def self.terminate(*args);end
def self.accept(*args);end
def self.inc(arg, default = nil);end
def self.with(*args);end
def self.top();end
def self.getopts(*args);end
def to_a();end
def reject(*args);end
def terminate(*args);end
def version();end
def remove();end
def version=(arg0);end
def accept(*args);end
def base();end
def release();end
def parse(*args);end
def candidate(word);end
def inc(*args);end
def summarize(*args);end
def compsys(to, name = nil);end
def help();end
def program_name();end
def ver();end
def banner();end
def add_officious();end
def top();end
def summary_width();end
def summary_indent();end
def default_argv();end
def set_banner(arg0);end
def banner=(arg0);end
def set_program_name(arg0);end
def program_name=(arg0);end
def set_summary_width(arg0);end
def summary_width=(arg0);end
def set_summary_indent(arg0);end
def summary_indent=(arg0);end
def make_switch(opts, block = nil);end
def define(*args);end
def on(*args);end
def def_option(*args);end
def define_head(*args);end
def on_head(*args);end
def def_head_option(*args);end
def define_tail(*args);end
def on_tail(*args);end
def def_tail_option(*args);end
def separator(string);end
def order(*args);end
def order!(*args);end
def permute(*args);end
def permute!(*args);end
def parse!(*args);end
def getopts(*args);end
def environment(*args);end
def default_argv=(arg0);end
def release=(arg0);end
end
module OptionParser::Completion
def regexp(key, icase);end
def candidate(key, icase = nil, pat = nil, &block);end
def self.regexp(key, icase);end
def self.candidate(key, icase = nil, pat = nil, &block);end
def convert(*args);end
def candidate(key, icase = nil, pat = nil);end
def complete(key, icase = nil, pat = nil);end
end
class OptionParser::OptionMap < Hash
include OptionParser::Completion
include Enumerable
include Kernel
def self.[](*args);end
def self.try_convert(arg0);end
end
class OptionParser::Switch < Object
include Kernel
def self.pattern();end
def self.guess(arg);end
def self.incompatible_argument_styles(arg, t);end
def self.pattern();end
def self.guess(arg);end
def self.incompatible_argument_styles(arg, t);end
def arg();end
def block();end
def pattern();end
def conv();end
def short();end
def long();end
def desc();end
def summarize(*args);end
def add_banner(to);end
def match_nonswitch?(str);end
def switch_name();end
def compsys(sdone, ldone);end
end
class OptionParser::Switch::NoArgument < OptionParser::Switch
include Kernel
def self.pattern();end
def self.incompatible_argument_styles(*args);end
def self.guess(arg);end
def self.pattern();end
def self.incompatible_argument_styles(*args);end
def parse(arg, argv);end
end
class OptionParser::Switch::RequiredArgument < OptionParser::Switch
include Kernel
def self.pattern();end
def self.guess(arg);end
def self.incompatible_argument_styles(arg, t);end
def parse(arg, argv);end
end
class OptionParser::Switch::OptionalArgument < OptionParser::Switch
include Kernel
def self.pattern();end
def self.guess(arg);end
def self.incompatible_argument_styles(arg, t);end
def parse(arg, argv, &error);end
end
class OptionParser::Switch::PlacedArgument < OptionParser::Switch
include Kernel
def self.pattern();end
def self.guess(arg);end
def self.incompatible_argument_styles(arg, t);end
def parse(arg, argv, &error);end
end
class OptionParser::List < Object
include Kernel
def list();end
def reject(t);end
def accept(t, pat = nil, &block);end
def complete(id, opt, icase = nil, *pat, &block);end
def short();end
def long();end
def summarize(*args);end
def add_banner(to);end
def compsys(*args);end
def atype();end
def append(*args);end
def search(id, key);end
def each_option(&block);end
end
class OptionParser::CompletingHash < Hash
include OptionParser::Completion
include Enumerable
include Kernel
def self.[](*args);end
def self.try_convert(arg0);end
def match(key);end
end
class OptionParser::ParseError < RuntimeError
include Kernel
def self.filter_backtrace(array);end
def self.exception(*args);end
def self.filter_backtrace(array);end
def message();end
def set_backtrace(array);end
def args();end
def reason();end
def set_option(opt, eq);end
def recover(argv);end
def reason=(arg0);end
end
class OptionParser::AmbiguousOption < OptionParser::ParseError
include Kernel
def self.filter_backtrace(array);end
def self.exception(*args);end
end
class OptionParser::NeedlessArgument < OptionParser::ParseError
include Kernel
def self.filter_backtrace(array);end
def self.exception(*args);end
end
class OptionParser::MissingArgument < OptionParser::ParseError
include Kernel
def self.filter_backtrace(array);end
def self.exception(*args);end
end
class OptionParser::InvalidOption < OptionParser::ParseError
include Kernel
def self.filter_backtrace(array);end
def self.exception(*args);end
end
class OptionParser::InvalidArgument < OptionParser::ParseError
include Kernel
def self.filter_backtrace(array);end
def self.exception(*args);end
end
class OptionParser::AmbiguousArgument < OptionParser::InvalidArgument
include Kernel
def self.filter_backtrace(array);end
def self.exception(*args);end
end
module OptionParser::Arguable
def extend_object(obj);end
def self.extend_object(obj);end
def options();end
def order!(&blk);end
def permute!();end
def parse!();end
def getopts(*args);end
def options=(opt);end
end
module OptionParser::Acceptables
end
