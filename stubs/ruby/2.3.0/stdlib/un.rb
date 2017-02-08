module FileUtils
include FileUtils::StreamUtils_
def pwd();end
def chdir(dir, options = nil, &block);end
def mkdir(list, options = nil);end
def rmdir(list, options = nil);end
def remove_entry_secure(path, force = nil);end
def remove_entry(path, force = nil);end
def move(src, dest, options = nil);end
def rm_f(list, options = nil);end
def safe_unlink(list, options = nil);end
def rm_r(list, options = nil);end
def rm_rf(list, options = nil);end
def rmtree(list, options = nil);end
def remove_dir(path, force = nil);end
def compare_file(a, b);end
def compare_stream(a, b);end
def cmp(a, b);end
def identical?(a, b);end
def mkdir_p(list, options = nil);end
def chmod(mode, list, options = nil);end
def chown(user, group, list, options = nil);end
def chmod_R(mode, list, options = nil);end
def link(src, dest, options = nil);end
def symlink(src, dest, options = nil);end
def chown_R(user, group, list, options = nil);end
def install(src, dest, options = nil);end
def remove(list, options = nil);end
def cp(src, dest, options = nil);end
def options();end
def copy_stream(src, dest);end
def ln(src, dest, options = nil);end
def mv(src, dest, options = nil);end
def rm(list, options = nil);end
def touch(list, options = nil);end
def commands();end
def have_option?(mid, opt);end
def options_of(mid);end
def private_module_function(name);end
def collect_method(opt);end
def cd(dir, options = nil, &block);end
def uptodate?(new, old_list);end
def mkpath(list, options = nil);end
def makedirs(list, options = nil);end
def remove_file(path, force = nil);end
def ln_s(src, dest, options = nil);end
def ln_sf(src, dest, options = nil);end
def copy_file(src, dest, preserve = nil, dereference = nil);end
def copy(src, dest, options = nil);end
def cp_r(src, dest, options = nil);end
def copy_entry(src, dest, preserve = nil, dereference_root = nil, remove_destination = nil);end
def getwd();end
def self.pwd();end
def self.chdir(dir, options = nil, &block);end
def self.mkdir(list, options = nil);end
def self.rmdir(list, options = nil);end
def self.remove_entry_secure(path, force = nil);end
def self.remove_entry(path, force = nil);end
def self.move(src, dest, options = nil);end
def self.rm_f(list, options = nil);end
def self.safe_unlink(list, options = nil);end
def self.rm_r(list, options = nil);end
def self.rm_rf(list, options = nil);end
def self.rmtree(list, options = nil);end
def self.remove_dir(path, force = nil);end
def self.compare_file(a, b);end
def self.compare_stream(a, b);end
def self.cmp(a, b);end
def self.identical?(a, b);end
def self.mkdir_p(list, options = nil);end
def self.chmod(mode, list, options = nil);end
def self.chown(user, group, list, options = nil);end
def self.chmod_R(mode, list, options = nil);end
def self.link(src, dest, options = nil);end
def self.symlink(src, dest, options = nil);end
def self.chown_R(user, group, list, options = nil);end
def self.install(src, dest, options = nil);end
def self.remove(list, options = nil);end
def self.cp(src, dest, options = nil);end
def self.options();end
def self.copy_stream(src, dest);end
def self.ln(src, dest, options = nil);end
def self.mv(src, dest, options = nil);end
def self.rm(list, options = nil);end
def self.touch(list, options = nil);end
def self.commands();end
def self.have_option?(mid, opt);end
def self.options_of(mid);end
def self.private_module_function(name);end
def self.collect_method(opt);end
def self.cd(dir, options = nil, &block);end
def self.uptodate?(new, old_list);end
def self.mkpath(list, options = nil);end
def self.makedirs(list, options = nil);end
def self.remove_file(path, force = nil);end
def self.ln_s(src, dest, options = nil);end
def self.ln_sf(src, dest, options = nil);end
def self.copy_file(src, dest, preserve = nil, dereference = nil);end
def self.copy(src, dest, options = nil);end
def self.cp_r(src, dest, options = nil);end
def self.copy_entry(src, dest, preserve = nil, dereference_root = nil, remove_destination = nil);end
def self.getwd();end
end
module FileUtils::StreamUtils_
end
class FileUtils::Entry_ < Object
include FileUtils::StreamUtils_
include Kernel
def entries();end
def path();end
def directory?();end
def exist?();end
def file?();end
def pipe?();end
def symlink?();end
def socket?();end
def blockdev?();end
def chardev?();end
def stat();end
def lstat();end
def chmod(mode);end
def chown(uid, gid);end
def prefix();end
def remove();end
def traverse();end
def remove_file();end
def copy_file(dest);end
def copy(dest);end
def wrap_traverse(pre, post);end
def rel();end
def copy_metadata(path);end
def preorder_traverse();end
def postorder_traverse();end
def dereference?();end
def lstat!();end
def door?();end
def stat!();end
def remove_dir1();end
def platform_support();end
end
module FileUtils::LowMethods
end
module FileUtils::Verbose
include FileUtils
include FileUtils::StreamUtils_
def copy_stream(src, dest);end
def identical?(a, b);end
def chmod(*args);end
def chown(*args);end
def link(*args);end
def symlink(*args);end
def chdir(*args);end
def getwd();end
def pwd();end
def mkdir(*args);end
def rmdir(*args);end
def mkdir_p(*args);end
def install(*args);end
def remove(*args);end
def cp(*args);end
def ln(*args);end
def mv(*args);end
def rm(*args);end
def touch(*args);end
def cd(*args);end
def uptodate?(new, old_list);end
def mkpath(*args);end
def makedirs(*args);end
def remove_file(path, force = nil);end
def ln_s(*args);end
def ln_sf(*args);end
def copy_file(src, dest, preserve = nil, dereference = nil);end
def copy(*args);end
def cp_r(*args);end
def copy_entry(src, dest, preserve = nil, dereference_root = nil, remove_destination = nil);end
def remove_entry_secure(path, force = nil);end
def remove_entry(path, force = nil);end
def move(*args);end
def rm_f(*args);end
def safe_unlink(*args);end
def rm_r(*args);end
def rm_rf(*args);end
def rmtree(*args);end
def remove_dir(path, force = nil);end
def compare_file(a, b);end
def compare_stream(a, b);end
def cmp(a, b);end
def chmod_R(*args);end
def chown_R(*args);end
def self.copy_stream(src, dest);end
def self.identical?(a, b);end
def self.chmod(*args);end
def self.chown(*args);end
def self.link(*args);end
def self.symlink(*args);end
def self.chdir(*args);end
def self.getwd();end
def self.pwd();end
def self.mkdir(*args);end
def self.rmdir(*args);end
def self.mkdir_p(*args);end
def self.install(*args);end
def self.remove(*args);end
def self.cp(*args);end
def self.ln(*args);end
def self.mv(*args);end
def self.rm(*args);end
def self.touch(*args);end
def self.cd(*args);end
def self.uptodate?(new, old_list);end
def self.mkpath(*args);end
def self.makedirs(*args);end
def self.remove_file(path, force = nil);end
def self.ln_s(*args);end
def self.ln_sf(*args);end
def self.copy_file(src, dest, preserve = nil, dereference = nil);end
def self.copy(*args);end
def self.cp_r(*args);end
def self.copy_entry(src, dest, preserve = nil, dereference_root = nil, remove_destination = nil);end
def self.remove_entry_secure(path, force = nil);end
def self.remove_entry(path, force = nil);end
def self.move(*args);end
def self.rm_f(*args);end
def self.safe_unlink(*args);end
def self.rm_r(*args);end
def self.rm_rf(*args);end
def self.rmtree(*args);end
def self.remove_dir(path, force = nil);end
def self.compare_file(a, b);end
def self.compare_stream(a, b);end
def self.cmp(a, b);end
def self.chmod_R(*args);end
def self.chown_R(*args);end
end
module FileUtils::NoWrite
include FileUtils::LowMethods
include FileUtils
include FileUtils::StreamUtils_
def copy_stream(*args);end
def identical?(*args);end
def chmod(*args);end
def chown(*args);end
def link(*args);end
def symlink(*args);end
def chdir(*args);end
def getwd(*args);end
def pwd(*args);end
def mkdir(*args);end
def rmdir(*args);end
def mkdir_p(*args);end
def install(*args);end
def remove(*args);end
def cp(*args);end
def ln(*args);end
def mv(*args);end
def rm(*args);end
def touch(*args);end
def cd(*args);end
def uptodate?(*args);end
def mkpath(*args);end
def makedirs(*args);end
def remove_file(*args);end
def ln_s(*args);end
def ln_sf(*args);end
def copy_file(*args);end
def copy(*args);end
def cp_r(*args);end
def copy_entry(*args);end
def remove_entry_secure(*args);end
def remove_entry(*args);end
def move(*args);end
def rm_f(*args);end
def safe_unlink(*args);end
def rm_r(*args);end
def rm_rf(*args);end
def rmtree(*args);end
def remove_dir(*args);end
def compare_file(*args);end
def compare_stream(*args);end
def cmp(*args);end
def chmod_R(*args);end
def chown_R(*args);end
def self.copy_stream(*args);end
def self.identical?(*args);end
def self.chmod(*args);end
def self.chown(*args);end
def self.link(*args);end
def self.symlink(*args);end
def self.chdir(*args);end
def self.getwd(*args);end
def self.pwd(*args);end
def self.mkdir(*args);end
def self.rmdir(*args);end
def self.mkdir_p(*args);end
def self.install(*args);end
def self.remove(*args);end
def self.cp(*args);end
def self.ln(*args);end
def self.mv(*args);end
def self.rm(*args);end
def self.touch(*args);end
def self.cd(*args);end
def self.uptodate?(*args);end
def self.mkpath(*args);end
def self.makedirs(*args);end
def self.remove_file(*args);end
def self.ln_s(*args);end
def self.ln_sf(*args);end
def self.copy_file(*args);end
def self.copy(*args);end
def self.cp_r(*args);end
def self.copy_entry(*args);end
def self.remove_entry_secure(*args);end
def self.remove_entry(*args);end
def self.move(*args);end
def self.rm_f(*args);end
def self.safe_unlink(*args);end
def self.rm_r(*args);end
def self.rm_rf(*args);end
def self.rmtree(*args);end
def self.remove_dir(*args);end
def self.compare_file(*args);end
def self.compare_stream(*args);end
def self.cmp(*args);end
def self.chmod_R(*args);end
def self.chown_R(*args);end
end
module FileUtils::DryRun
include FileUtils::LowMethods
include FileUtils
include FileUtils::StreamUtils_
def copy_stream(*args);end
def identical?(*args);end
def chmod(*args);end
def chown(*args);end
def link(*args);end
def symlink(*args);end
def chdir(*args);end
def getwd(*args);end
def pwd(*args);end
def mkdir(*args);end
def rmdir(*args);end
def mkdir_p(*args);end
def install(*args);end
def remove(*args);end
def cp(*args);end
def ln(*args);end
def mv(*args);end
def rm(*args);end
def touch(*args);end
def cd(*args);end
def uptodate?(*args);end
def mkpath(*args);end
def makedirs(*args);end
def remove_file(*args);end
def ln_s(*args);end
def ln_sf(*args);end
def copy_file(*args);end
def copy(*args);end
def cp_r(*args);end
def copy_entry(*args);end
def remove_entry_secure(*args);end
def remove_entry(*args);end
def move(*args);end
def rm_f(*args);end
def safe_unlink(*args);end
def rm_r(*args);end
def rm_rf(*args);end
def rmtree(*args);end
def remove_dir(*args);end
def compare_file(*args);end
def compare_stream(*args);end
def cmp(*args);end
def chmod_R(*args);end
def chown_R(*args);end
def self.copy_stream(*args);end
def self.identical?(*args);end
def self.chmod(*args);end
def self.chown(*args);end
def self.link(*args);end
def self.symlink(*args);end
def self.chdir(*args);end
def self.getwd(*args);end
def self.pwd(*args);end
def self.mkdir(*args);end
def self.rmdir(*args);end
def self.mkdir_p(*args);end
def self.install(*args);end
def self.remove(*args);end
def self.cp(*args);end
def self.ln(*args);end
def self.mv(*args);end
def self.rm(*args);end
def self.touch(*args);end
def self.cd(*args);end
def self.uptodate?(*args);end
def self.mkpath(*args);end
def self.makedirs(*args);end
def self.remove_file(*args);end
def self.ln_s(*args);end
def self.ln_sf(*args);end
def self.copy_file(*args);end
def self.copy(*args);end
def self.cp_r(*args);end
def self.copy_entry(*args);end
def self.remove_entry_secure(*args);end
def self.remove_entry(*args);end
def self.move(*args);end
def self.rm_f(*args);end
def self.safe_unlink(*args);end
def self.rm_r(*args);end
def self.rm_rf(*args);end
def self.rmtree(*args);end
def self.remove_dir(*args);end
def self.compare_file(*args);end
def self.compare_stream(*args);end
def self.cmp(*args);end
def self.chmod_R(*args);end
def self.chown_R(*args);end
end
module Etc
def group();end
def getpwnam(arg0);end
def getgrnam(arg0);end
def getlogin();end
def getpwuid(*args);end
def setpwent();end
def endpwent();end
def getpwent();end
def passwd();end
def getgrgid(*args);end
def setgrent();end
def endgrent();end
def getgrent();end
def sysconfdir();end
def systmpdir();end
def uname();end
def sysconf(arg0);end
def confstr(arg0);end
def nprocessors();end
def self.group();end
def self.getpwnam(arg0);end
def self.getgrnam(arg0);end
def self.getlogin();end
def self.getpwuid(*args);end
def self.setpwent();end
def self.endpwent();end
def self.getpwent();end
def self.passwd();end
def self.getgrgid(*args);end
def self.setgrent();end
def self.endgrent();end
def self.getgrent();end
def self.sysconfdir();end
def self.systmpdir();end
def self.uname();end
def self.sysconf(arg0);end
def self.confstr(arg0);end
def self.nprocessors();end
end
class Etc::Passwd < Struct
include Enumerable
include Kernel
def self.[](*args);end
def self.each();end
def self.members();end
def self.to_a(*args);end
def self.to_h(*args);end
def self.find(*args);end
def self.entries(*args);end
def self.sort();end
def self.sort_by();end
def self.grep(arg0);end
def self.grep_v(arg0);end
def self.count(*args);end
def self.detect(*args);end
def self.find_index(*args);end
def self.find_all();end
def self.reject();end
def self.collect();end
def self.map();end
def self.flat_map();end
def self.collect_concat();end
def self.inject(*args);end
def self.reduce(*args);end
def self.partition();end
def self.group_by();end
def self.first(*args);end
def self.all?();end
def self.any?();end
def self.one?();end
def self.none?();end
def self.min(*args);end
def self.max(*args);end
def self.minmax();end
def self.min_by(*args);end
def self.max_by(*args);end
def self.minmax_by();end
def self.member?(arg0);end
def self.each_with_index(*args);end
def self.reverse_each(*args);end
def self.each_entry(*args);end
def self.each_slice(arg0);end
def self.each_cons(arg0);end
def self.each_with_object(arg0);end
def self.zip(*args);end
def self.take(arg0);end
def self.take_while();end
def self.drop(arg0);end
def self.drop_while();end
def self.cycle(*args);end
def self.chunk();end
def self.slice_before(*args);end
def self.slice_after(*args);end
def self.slice_when();end
def self.chunk_while();end
def self.lazy();end
def self.[](*args);end
def self.each();end
def self.members();end
def uid();end
def gid();end
def name=(_);end
def uid=(_);end
def gid=(_);end
def dir();end
def passwd();end
def gecos();end
def shell();end
def passwd=(_);end
def gecos=(_);end
def dir=(_);end
def shell=(_);end
end
class Process::Tms < Struct
include Enumerable
include Kernel
def self.[](*args);end
def self.members();end
def self.[](*args);end
def self.members();end
def utime();end
def stime();end
def cutime();end
def cstime();end
def utime=(_);end
def stime=(_);end
def cutime=(_);end
def cstime=(_);end
end
class Etc::Group < Struct
include Enumerable
include Kernel
def self.[](*args);end
def self.each();end
def self.members();end
def self.to_a(*args);end
def self.to_h(*args);end
def self.find(*args);end
def self.entries(*args);end
def self.sort();end
def self.sort_by();end
def self.grep(arg0);end
def self.grep_v(arg0);end
def self.count(*args);end
def self.detect(*args);end
def self.find_index(*args);end
def self.find_all();end
def self.reject();end
def self.collect();end
def self.map();end
def self.flat_map();end
def self.collect_concat();end
def self.inject(*args);end
def self.reduce(*args);end
def self.partition();end
def self.group_by();end
def self.first(*args);end
def self.all?();end
def self.any?();end
def self.one?();end
def self.none?();end
def self.min(*args);end
def self.max(*args);end
def self.minmax();end
def self.min_by(*args);end
def self.max_by(*args);end
def self.minmax_by();end
def self.member?(arg0);end
def self.each_with_index(*args);end
def self.reverse_each(*args);end
def self.each_entry(*args);end
def self.each_slice(arg0);end
def self.each_cons(arg0);end
def self.each_with_object(arg0);end
def self.zip(*args);end
def self.take(arg0);end
def self.take_while();end
def self.drop(arg0);end
def self.drop_while();end
def self.cycle(*args);end
def self.chunk();end
def self.slice_before(*args);end
def self.slice_after(*args);end
def self.slice_when();end
def self.chunk_while();end
def self.lazy();end
def self.[](*args);end
def self.each();end
def self.members();end
def gid();end
def name=(_);end
def gid=(_);end
def passwd();end
def passwd=(_);end
def mem();end
def mem=(_);end
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
def on(*args);end
def help();end
def order!(*args);end
def summarize(*args);end
def compsys(to, name = nil);end
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
def def_option(*args);end
def define_head(*args);end
def on_head(*args);end
def def_head_option(*args);end
def define_tail(*args);end
def on_tail(*args);end
def def_tail_option(*args);end
def separator(string);end
def order(*args);end
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
def on(*args);end
def help();end
def order!(*args);end
def summarize(*args);end
def compsys(to, name = nil);end
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
def def_option(*args);end
def define_head(*args);end
def on_head(*args);end
def def_head_option(*args);end
def define_tail(*args);end
def on_tail(*args);end
def def_tail_option(*args);end
def separator(string);end
def order(*args);end
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
module UN
def help(argv);end
def self.help(argv);end
end
