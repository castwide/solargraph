module Rake
def each_dir_parent(dir);end
def from_pathname(path);end
def application();end
def application=(app);end
def suggested_thread_count();end
def original_dir();end
def load_rakefile(path);end
def add_rakelib(*args);end
def chdir(*args);end
def cd(*args);end
def mkdir(*args);end
def makedirs(*args);end
def mkpath(*args);end
def mkdir_p(*args);end
def rmdir(*args);end
def link(*args);end
def ln(*args);end
def symlink(*args);end
def ln_s(*args);end
def ln_sf(*args);end
def copy(*args);end
def cp(*args);end
def cp_r(*args);end
def move(*args);end
def mv(*args);end
def remove(*args);end
def rm(*args);end
def safe_unlink(*args);end
def rm_f(*args);end
def rm_r(*args);end
def rmtree(*args);end
def rm_rf(*args);end
def install(*args);end
def chmod(*args);end
def chmod_R(*args);end
def chown(*args);end
def chown_R(*args);end
def touch(*args);end
def verbose(*args);end
def nowrite(*args);end
def when_writing(*args);end
def rake_merge_option(args, defaults);end
def rake_output_message(message);end
def rake_check_options(options, *optdecl);end
def sh(*args);end
def ruby(*args);end
def safe_ln(*args);end
def split_all(path);end
def self.each_dir_parent(dir);end
def self.from_pathname(path);end
def self.application();end
def self.application=(app);end
def self.suggested_thread_count();end
def self.original_dir();end
def self.load_rakefile(path);end
def self.add_rakelib(*args);end
end
module Rake::Version
end
module Rake::Win32
def windows?();end
def win32_system_dir();end
def normalize(path);end
def self.windows?();end
def self.win32_system_dir();end
def self.normalize(path);end
end
class Rake::Win32::Win32HomeError < RuntimeError
include Kernel
def self.exception(*args);end
end
class Rake::LinkedList < Object
include Enumerable
include Kernel
def self.make(*args);end
def self.cons(head, tail);end
def self.empty();end
def self.make(*args);end
def self.cons(head, tail);end
def self.empty();end
def head();end
def tail();end
def conj(item);end
def empty?();end
def each();end
end
class Rake::LinkedList::EmptyLinkedList < Rake::LinkedList
include Enumerable
include Kernel
def self.cons(head, tail);end
def self.make(*args);end
def self.empty();end
def self.cons(head, tail);end
def empty?();end
end
class Rake::CpuCounter < Object
include Kernel
def self.count();end
def self.count();end
def count_with_default(*args);end
def count();end
def count_via_java_runtime();end
def count_via_win32();end
def count_via_cpuinfo();end
def count_via_sysctl();end
def run(command, *args);end
def resolve_command(command);end
def look_for_command(dir, command);end
def in_path_command(command);end
end
class Rake::Scope < Rake::LinkedList
include Enumerable
include Kernel
def self.make(*args);end
def self.cons(head, tail);end
def self.empty();end
def path();end
def path_with_task_name(task_name);end
def trim(n);end
end
class Rake::Scope::EmptyScope < Rake::LinkedList::EmptyLinkedList
include Enumerable
include Kernel
def self.cons(head, tail);end
def self.make(*args);end
def self.empty();end
def path();end
def path_with_task_name(task_name);end
end
class Rake::TaskArgumentError < ArgumentError
include Kernel
def self.exception(*args);end
end
class Rake::RuleRecursionOverflowError < StandardError
include Kernel
def self.exception(*args);end
def add_target(target);end
def message();end
end
module Rake::TaskManager
def record_task_metadata();end
def record_task_metadata=(arg0);end
def self.record_task_metadata();end
def self.record_task_metadata=(arg0);end
def last_description();end
def last_description=(arg0);end
def create_rule(*args);end
def define_task(task_class, *args, &block);end
def intern(task_class, task_name);end
def [](task_name, scopes = nil);end
def synthesize_file_task(task_name);end
def resolve_args(args);end
def enhance_with_matching_rule(task_name, level = nil);end
def tasks();end
def tasks_in_scope(scope);end
def clear();end
def lookup(task_name, initial_scope = nil);end
def current_scope();end
def in_namespace(name);end
end
module Rake::Cloneable
end
module Rake::FileUtilsExt
include FileUtils
include FileUtils::StreamUtils_
def verbose_flag();end
def verbose_flag=(arg0);end
def nowrite_flag();end
def nowrite_flag=(arg0);end
def chdir(*args);end
def cd(*args);end
def mkdir(*args);end
def makedirs(*args);end
def mkpath(*args);end
def mkdir_p(*args);end
def rmdir(*args);end
def link(*args);end
def ln(*args);end
def symlink(*args);end
def ln_s(*args);end
def ln_sf(*args);end
def copy(*args);end
def cp(*args);end
def cp_r(*args);end
def move(*args);end
def mv(*args);end
def remove(*args);end
def rm(*args);end
def safe_unlink(*args);end
def rm_f(*args);end
def rm_r(*args);end
def rmtree(*args);end
def rm_rf(*args);end
def install(*args);end
def chmod(*args);end
def chmod_R(*args);end
def chown(*args);end
def chown_R(*args);end
def touch(*args);end
def verbose(*args);end
def nowrite(*args);end
def when_writing(*args);end
def rake_merge_option(args, defaults);end
def rake_output_message(message);end
def rake_check_options(options, *optdecl);end
def sh(*args);end
def ruby(*args);end
def safe_ln(*args);end
def split_all(path);end
def self.verbose_flag();end
def self.verbose_flag=(arg0);end
def self.nowrite_flag();end
def self.nowrite_flag=(arg0);end
def chdir(*args);end
def cd(*args);end
def mkdir(*args);end
def makedirs(*args);end
def mkpath(*args);end
def mkdir_p(*args);end
def rmdir(*args);end
def link(*args);end
def ln(*args);end
def symlink(*args);end
def ln_s(*args);end
def ln_sf(*args);end
def copy(*args);end
def cp(*args);end
def cp_r(*args);end
def move(*args);end
def mv(*args);end
def remove(*args);end
def rm(*args);end
def safe_unlink(*args);end
def rm_f(*args);end
def rm_r(*args);end
def rmtree(*args);end
def rm_rf(*args);end
def install(*args);end
def chmod(*args);end
def chmod_R(*args);end
def chown(*args);end
def chown_R(*args);end
def touch(*args);end
def verbose(*args);end
def nowrite(*args);end
def when_writing(*args);end
def rake_merge_option(args, defaults);end
def rake_output_message(message);end
def rake_check_options(options, *optdecl);end
end
module FileUtils::StreamUtils_
end
class FileUtils::Entry_ < Object
include FileUtils::StreamUtils_
include Kernel
def path();end
def prefix();end
def rel();end
def dereference?();end
def exist?();end
def file?();end
def directory?();end
def symlink?();end
def chardev?();end
def blockdev?();end
def socket?();end
def pipe?();end
def door?();end
def entries();end
def stat();end
def stat!();end
def lstat();end
def lstat!();end
def chmod(mode);end
def chown(uid, gid);end
def copy(dest);end
def copy_file(dest);end
def copy_metadata(path);end
def remove();end
def remove_dir1();end
def remove_file();end
def platform_support();end
def preorder_traverse();end
def traverse();end
def postorder_traverse();end
def wrap_traverse(pre, post);end
end
module FileUtils::LowMethods
end
module FileUtils::Verbose
include FileUtils
include FileUtils::StreamUtils_
def pwd();end
def getwd();end
def cd(*args);end
def chdir(*args);end
def uptodate?(new, old_list);end
def mkdir(*args);end
def mkdir_p(*args);end
def mkpath(*args);end
def makedirs(*args);end
def rmdir(*args);end
def ln(*args);end
def link(*args);end
def ln_s(*args);end
def symlink(*args);end
def ln_sf(*args);end
def cp(*args);end
def copy(*args);end
def cp_r(*args);end
def copy_entry(src, dest, preserve = nil, dereference_root = nil, remove_destination = nil);end
def copy_file(src, dest, preserve = nil, dereference = nil);end
def copy_stream(src, dest);end
def mv(*args);end
def move(*args);end
def rm(*args);end
def remove(*args);end
def rm_f(*args);end
def safe_unlink(*args);end
def rm_r(*args);end
def rm_rf(*args);end
def rmtree(*args);end
def remove_entry_secure(path, force = nil);end
def remove_entry(path, force = nil);end
def remove_file(path, force = nil);end
def remove_dir(path, force = nil);end
def compare_file(a, b);end
def identical?(a, b);end
def cmp(a, b);end
def compare_stream(a, b);end
def install(*args);end
def chmod(*args);end
def chmod_R(*args);end
def chown(*args);end
def chown_R(*args);end
def touch(*args);end
def sh(*args);end
def ruby(*args);end
def safe_ln(*args);end
def split_all(path);end
def self.pwd();end
def self.getwd();end
def self.cd(*args);end
def self.chdir(*args);end
def self.uptodate?(new, old_list);end
def self.mkdir(*args);end
def self.mkdir_p(*args);end
def self.mkpath(*args);end
def self.makedirs(*args);end
def self.rmdir(*args);end
def self.ln(*args);end
def self.link(*args);end
def self.ln_s(*args);end
def self.symlink(*args);end
def self.ln_sf(*args);end
def self.cp(*args);end
def self.copy(*args);end
def self.cp_r(*args);end
def self.copy_entry(src, dest, preserve = nil, dereference_root = nil, remove_destination = nil);end
def self.copy_file(src, dest, preserve = nil, dereference = nil);end
def self.copy_stream(src, dest);end
def self.mv(*args);end
def self.move(*args);end
def self.rm(*args);end
def self.remove(*args);end
def self.rm_f(*args);end
def self.safe_unlink(*args);end
def self.rm_r(*args);end
def self.rm_rf(*args);end
def self.rmtree(*args);end
def self.remove_entry_secure(path, force = nil);end
def self.remove_entry(path, force = nil);end
def self.remove_file(path, force = nil);end
def self.remove_dir(path, force = nil);end
def self.compare_file(a, b);end
def self.identical?(a, b);end
def self.cmp(a, b);end
def self.compare_stream(a, b);end
def self.install(*args);end
def self.chmod(*args);end
def self.chmod_R(*args);end
def self.chown(*args);end
def self.chown_R(*args);end
def self.touch(*args);end
end
module FileUtils::NoWrite
include FileUtils::LowMethods
include FileUtils
include FileUtils::StreamUtils_
def pwd(*args);end
def getwd(*args);end
def cd(*args);end
def chdir(*args);end
def uptodate?(*args);end
def mkdir(*args);end
def mkdir_p(*args);end
def mkpath(*args);end
def makedirs(*args);end
def rmdir(*args);end
def ln(*args);end
def link(*args);end
def ln_s(*args);end
def symlink(*args);end
def ln_sf(*args);end
def cp(*args);end
def copy(*args);end
def cp_r(*args);end
def copy_entry(*args);end
def copy_file(*args);end
def copy_stream(*args);end
def mv(*args);end
def move(*args);end
def rm(*args);end
def remove(*args);end
def rm_f(*args);end
def safe_unlink(*args);end
def rm_r(*args);end
def rm_rf(*args);end
def rmtree(*args);end
def remove_entry_secure(*args);end
def remove_entry(*args);end
def remove_file(*args);end
def remove_dir(*args);end
def compare_file(*args);end
def identical?(*args);end
def cmp(*args);end
def compare_stream(*args);end
def install(*args);end
def chmod(*args);end
def chmod_R(*args);end
def chown(*args);end
def chown_R(*args);end
def touch(*args);end
def sh(*args);end
def ruby(*args);end
def safe_ln(*args);end
def split_all(path);end
def self.pwd(*args);end
def self.getwd(*args);end
def self.cd(*args);end
def self.chdir(*args);end
def self.uptodate?(*args);end
def self.mkdir(*args);end
def self.mkdir_p(*args);end
def self.mkpath(*args);end
def self.makedirs(*args);end
def self.rmdir(*args);end
def self.ln(*args);end
def self.link(*args);end
def self.ln_s(*args);end
def self.symlink(*args);end
def self.ln_sf(*args);end
def self.cp(*args);end
def self.copy(*args);end
def self.cp_r(*args);end
def self.copy_entry(*args);end
def self.copy_file(*args);end
def self.copy_stream(*args);end
def self.mv(*args);end
def self.move(*args);end
def self.rm(*args);end
def self.remove(*args);end
def self.rm_f(*args);end
def self.safe_unlink(*args);end
def self.rm_r(*args);end
def self.rm_rf(*args);end
def self.rmtree(*args);end
def self.remove_entry_secure(*args);end
def self.remove_entry(*args);end
def self.remove_file(*args);end
def self.remove_dir(*args);end
def self.compare_file(*args);end
def self.identical?(*args);end
def self.cmp(*args);end
def self.compare_stream(*args);end
def self.install(*args);end
def self.chmod(*args);end
def self.chmod_R(*args);end
def self.chown(*args);end
def self.chown_R(*args);end
def self.touch(*args);end
end
module FileUtils::DryRun
include FileUtils::LowMethods
include FileUtils
include FileUtils::StreamUtils_
def pwd(*args);end
def getwd(*args);end
def cd(*args);end
def chdir(*args);end
def uptodate?(*args);end
def mkdir(*args);end
def mkdir_p(*args);end
def mkpath(*args);end
def makedirs(*args);end
def rmdir(*args);end
def ln(*args);end
def link(*args);end
def ln_s(*args);end
def symlink(*args);end
def ln_sf(*args);end
def cp(*args);end
def copy(*args);end
def cp_r(*args);end
def copy_entry(*args);end
def copy_file(*args);end
def copy_stream(*args);end
def mv(*args);end
def move(*args);end
def rm(*args);end
def remove(*args);end
def rm_f(*args);end
def safe_unlink(*args);end
def rm_r(*args);end
def rm_rf(*args);end
def rmtree(*args);end
def remove_entry_secure(*args);end
def remove_entry(*args);end
def remove_file(*args);end
def remove_dir(*args);end
def compare_file(*args);end
def identical?(*args);end
def cmp(*args);end
def compare_stream(*args);end
def install(*args);end
def chmod(*args);end
def chmod_R(*args);end
def chown(*args);end
def chown_R(*args);end
def touch(*args);end
def sh(*args);end
def ruby(*args);end
def safe_ln(*args);end
def split_all(path);end
def self.pwd(*args);end
def self.getwd(*args);end
def self.cd(*args);end
def self.chdir(*args);end
def self.uptodate?(*args);end
def self.mkdir(*args);end
def self.mkdir_p(*args);end
def self.mkpath(*args);end
def self.makedirs(*args);end
def self.rmdir(*args);end
def self.ln(*args);end
def self.link(*args);end
def self.ln_s(*args);end
def self.symlink(*args);end
def self.ln_sf(*args);end
def self.cp(*args);end
def self.copy(*args);end
def self.cp_r(*args);end
def self.copy_entry(*args);end
def self.copy_file(*args);end
def self.copy_stream(*args);end
def self.mv(*args);end
def self.move(*args);end
def self.rm(*args);end
def self.remove(*args);end
def self.rm_f(*args);end
def self.safe_unlink(*args);end
def self.rm_r(*args);end
def self.rm_rf(*args);end
def self.rmtree(*args);end
def self.remove_entry_secure(*args);end
def self.remove_entry(*args);end
def self.remove_file(*args);end
def self.remove_dir(*args);end
def self.compare_file(*args);end
def self.identical?(*args);end
def self.cmp(*args);end
def self.compare_stream(*args);end
def self.install(*args);end
def self.chmod(*args);end
def self.chmod_R(*args);end
def self.chown(*args);end
def self.chown_R(*args);end
def self.touch(*args);end
end
class Rake::FileList < Object
include Rake::Cloneable
include Kernel
def self.[](*args);end
def self.glob(pattern, *args);end
def self.[](*args);end
def self.glob(pattern, *args);end
def &(*args);end
def +(*args);end
def -(*args);end
def [](*args);end
def []=(*args);end
def all?(*args);end
def any?(*args);end
def assoc(*args);end
def at(*args);end
def bsearch(*args);end
def chunk(*args);end
def clear(*args);end
def collect(*args);end
def collect!(*args);end
def collect_concat(*args);end
def combination(*args);end
def compact(*args);end
def compact!(*args);end
def concat(*args);end
def count(*args);end
def cycle(*args);end
def delete(*args);end
def delete_at(*args);end
def delete_if(*args);end
def detect(*args);end
def drop(*args);end
def drop_while(*args);end
def each(*args);end
def each_cons(*args);end
def each_entry(*args);end
def each_index(*args);end
def each_slice(*args);end
def each_with_index(*args);end
def each_with_object(*args);end
def empty?(*args);end
def entries(*args);end
def fetch(*args);end
def fill(*args);end
def find(*args);end
def find_all(*args);end
def find_index(*args);end
def first(*args);end
def flat_map(*args);end
def flatten(*args);end
def flatten!(*args);end
def grep(*args);end
def group_by(*args);end
def index(*args);end
def inject(*args);end
def insert(*args);end
def join(*args);end
def keep_if(*args);end
def last(*args);end
def lazy(*args);end
def length(*args);end
def map(*args);end
def map!(*args);end
def max(*args);end
def max_by(*args);end
def member?(*args);end
def min(*args);end
def min_by(*args);end
def minmax(*args);end
def minmax_by(*args);end
def none?(*args);end
def one?(*args);end
def pack(*args);end
def permutation(*args);end
def pop(*args);end
def product(*args);end
def push(*args);end
def rassoc(*args);end
def reduce(*args);end
def reject(*args);end
def reject!(*args);end
def repeated_combination(*args);end
def repeated_permutation(*args);end
def replace(*args);end
def reverse(*args);end
def reverse!(*args);end
def reverse_each(*args);end
def rindex(*args);end
def rotate(*args);end
def rotate!(*args);end
def sample(*args);end
def select!(*args);end
def shift(*args);end
def shuffle(*args);end
def shuffle!(*args);end
def size(*args);end
def slice(*args);end
def slice!(*args);end
def slice_before(*args);end
def sort(*args);end
def sort!(*args);end
def sort_by(*args);end
def sort_by!(*args);end
def take(*args);end
def take_while(*args);end
def transpose(*args);end
def uniq(*args);end
def uniq!(*args);end
def unshift(*args);end
def values_at(*args);end
def zip(*args);end
def |(*args);end
def include(*args);end
def add(*args);end
def exclude(*args);end
def clear_exclude();end
def to_a();end
def to_ary();end
def *(other);end
def <<(obj);end
def resolve();end
def sub(pat, rep);end
def gsub(pat, rep);end
def sub!(pat, rep);end
def gsub!(pat, rep);end
def pathmap(*args);end
def ext(*args);end
def egrep(pattern, *options);end
def existing();end
def existing!();end
def partition(&block);end
def excluded_from_list?(fn);end
def import(array);end
end
class Rake::Promise < Object
include Kernel
def recorder();end
def recorder=(arg0);end
def value();end
def work();end
end
class Rake::ThreadPool < Object
include Kernel
def future(*args);end
def join();end
def gather_history();end
def history();end
def statistics();end
end
module Rake::PrivateReader
def included(base);end
def self.included(base);end
end
module Rake::PrivateReader::ClassMethods
def private_reader(*args);end
end
class Rake::ThreadHistoryDisplay < Object
include Rake::PrivateReader
include Kernel
def self.private_reader(*args);end
def show();end
end
module Rake::TraceOutput
def trace_on(out, *strings);end
end
class Rake::CommandLineOptionError < StandardError
include Kernel
def self.exception(*args);end
end
class Rake::Application < Object
include Rake::TraceOutput
include Rake::TaskManager
include Kernel
def original_dir();end
def rakefile();end
def terminal_columns();end
def terminal_columns=(arg0);end
def top_level_tasks();end
def tty_output=(arg0);end
def run();end
def init(*args);end
def load_rakefile();end
def top_level();end
def run_with_threads();end
def add_loader(ext, loader);end
def options();end
def thread_pool();end
def invoke_task(task_string);end
def parse_task_string(string);end
def standard_exception_handling();end
def exit_because_of_exception(ex);end
def display_error_message(ex);end
def display_exception_details(ex);end
def has_cause?(ex);end
def display_exception_message_details(ex);end
def display_exception_backtrace(ex);end
def deprecate(old_usage, new_usage, call_site);end
def have_rakefile();end
def tty_output?();end
def truncate_output?();end
def display_tasks_and_comments();end
def terminal_width();end
def dynamic_width();end
def dynamic_width_stty();end
def dynamic_width_tput();end
def unix?();end
def windows?();end
def truncate(string, width);end
def display_prerequisites();end
def trace(*args);end
def standard_rake_options();end
def handle_options();end
def rake_require(file_name, paths = nil, loaded = nil);end
def find_rakefile_location();end
def print_rakefile_directory(location);end
def raw_load_rakefile();end
def system_dir();end
def collect_command_line_tasks(args);end
def default_task_name();end
def add_import(fn);end
def load_imports();end
def rakefile_location(*args);end
end
class Rake::PseudoStatus < Object
include Kernel
def exitstatus();end
def to_i();end
def >>(n);end
def stopped?();end
def exited?();end
end
class Rake::TaskArguments < Object
include Enumerable
include Kernel
def names();end
def to_a();end
def extras();end
def new_scope(names);end
def [](index);end
def with_defaults(defaults);end
def each(&block);end
def values_at(*args);end
def method_missing(sym, *args);end
def to_hash();end
def has_key?(key);end
def key?(key);end
def fetch(*args);end
end
class Rake::InvocationChain < Rake::LinkedList
include Enumerable
include Kernel
def self.append(invocation, chain);end
def self.make(*args);end
def self.cons(head, tail);end
def self.empty();end
def self.append(invocation, chain);end
def member?(invocation);end
def append(invocation);end
end
class Rake::InvocationChain::EmptyInvocationChain < Rake::LinkedList::EmptyLinkedList
include Enumerable
include Kernel
def self.cons(head, tail);end
def self.make(*args);end
def self.empty();end
def member?(obj);end
def append(invocation);end
end
module Rake::InvocationExceptionMixin
def chain();end
def chain=(value);end
end
class Rake::Task < Object
include Kernel
def self.clear();end
def self.tasks();end
def self.[](task_name);end
def self.task_defined?(task_name);end
def self.define_task(*args);end
def self.create_rule(*args);end
def self.scope_name(scope, task_name);end
def self.clear();end
def self.tasks();end
def self.[](task_name);end
def self.task_defined?(task_name);end
def self.define_task(*args);end
def self.create_rule(*args);end
def self.scope_name(scope, task_name);end
def prerequisites();end
def actions();end
def application();end
def application=(arg0);end
def scope();end
def locations();end
def already_invoked();end
def sources=(arg0);end
def sources();end
def prerequisite_tasks();end
def all_prerequisite_tasks();end
def source();end
def enhance(*args);end
def name_with_args();end
def arg_description();end
def arg_names();end
def reenable();end
def clear();end
def clear_prerequisites();end
def clear_actions();end
def clear_comments();end
def clear_args();end
def invoke(*args);end
def invoke_prerequisites(task_args, invocation_chain);end
def invoke_prerequisites_concurrently(task_args, invocation_chain);end
def execute(*args);end
def needed?();end
def timestamp();end
def add_description(description);end
def comment=(comment);end
def full_comment();end
def comment();end
def set_arg_names(args);end
def investigation();end
end
class Rake::EarlyTime < Object
include Singleton
include Comparable
include Kernel
def self.instance();end
def self._load(str);end
def self.instance();end
end
module Singleton::SingletonClassMethods
def clone();end
def _load(str);end
end
class Rake::FileTask < Rake::Task
include Kernel
def self.scope_name(scope, task_name);end
def self.clear();end
def self.tasks();end
def self.[](task_name);end
def self.task_defined?(task_name);end
def self.define_task(*args);end
def self.create_rule(*args);end
def self.scope_name(scope, task_name);end
def needed?();end
def timestamp();end
end
class Rake::FileCreationTask < Rake::FileTask
include Kernel
def self.scope_name(scope, task_name);end
def self.clear();end
def self.tasks();end
def self.[](task_name);end
def self.task_defined?(task_name);end
def self.define_task(*args);end
def self.create_rule(*args);end
def needed?();end
def timestamp();end
end
class Rake::MultiTask < Rake::Task
include Kernel
def self.clear();end
def self.tasks();end
def self.[](task_name);end
def self.task_defined?(task_name);end
def self.define_task(*args);end
def self.create_rule(*args);end
def self.scope_name(scope, task_name);end
def invoke_with_call_chain(task_args, invocation_chain);end
end
module Rake::DSL
include Rake::FileUtilsExt
include FileUtils
include FileUtils::StreamUtils_
end
class Rake::DefaultLoader < Object
include Kernel
end
class Rake::LateTime < Object
include Singleton
include Comparable
include Kernel
def self.instance();end
def self._load(str);end
def self.instance();end
end
class Rake::NameSpace < Object
include Kernel
def [](name);end
def scope();end
def tasks();end
end
module Rake::Backtrace
def collapse(backtrace);end
def self.collapse(backtrace);end
end
module FileUtils
include FileUtils::StreamUtils_
def private_module_function(name);end
def pwd();end
def getwd();end
def cd(dir, options = nil, &block);end
def chdir(dir, options = nil, &block);end
def uptodate?(new, old_list);end
def mkdir(list, options = nil);end
def mkdir_p(list, options = nil);end
def mkpath(list, options = nil);end
def makedirs(list, options = nil);end
def rmdir(list, options = nil);end
def ln(src, dest, options = nil);end
def link(src, dest, options = nil);end
def ln_s(src, dest, options = nil);end
def symlink(src, dest, options = nil);end
def ln_sf(src, dest, options = nil);end
def cp(src, dest, options = nil);end
def copy(src, dest, options = nil);end
def cp_r(src, dest, options = nil);end
def copy_entry(src, dest, preserve = nil, dereference_root = nil, remove_destination = nil);end
def copy_file(src, dest, preserve = nil, dereference = nil);end
def copy_stream(src, dest);end
def mv(src, dest, options = nil);end
def move(src, dest, options = nil);end
def rm(list, options = nil);end
def remove(list, options = nil);end
def rm_f(list, options = nil);end
def safe_unlink(list, options = nil);end
def rm_r(list, options = nil);end
def rm_rf(list, options = nil);end
def rmtree(list, options = nil);end
def remove_entry_secure(path, force = nil);end
def remove_entry(path, force = nil);end
def remove_file(path, force = nil);end
def remove_dir(path, force = nil);end
def compare_file(a, b);end
def identical?(a, b);end
def cmp(a, b);end
def compare_stream(a, b);end
def install(src, dest, options = nil);end
def chmod(mode, list, options = nil);end
def chmod_R(mode, list, options = nil);end
def chown(user, group, list, options = nil);end
def chown_R(user, group, list, options = nil);end
def touch(list, options = nil);end
def commands();end
def options();end
def have_option?(mid, opt);end
def options_of(mid);end
def collect_method(opt);end
def self.private_module_function(name);end
def self.pwd();end
def self.getwd();end
def self.cd(dir, options = nil, &block);end
def self.chdir(dir, options = nil, &block);end
def self.uptodate?(new, old_list);end
def self.mkdir(list, options = nil);end
def self.mkdir_p(list, options = nil);end
def self.mkpath(list, options = nil);end
def self.makedirs(list, options = nil);end
def self.rmdir(list, options = nil);end
def self.ln(src, dest, options = nil);end
def self.link(src, dest, options = nil);end
def self.ln_s(src, dest, options = nil);end
def self.symlink(src, dest, options = nil);end
def self.ln_sf(src, dest, options = nil);end
def self.cp(src, dest, options = nil);end
def self.copy(src, dest, options = nil);end
def self.cp_r(src, dest, options = nil);end
def self.copy_entry(src, dest, preserve = nil, dereference_root = nil, remove_destination = nil);end
def self.copy_file(src, dest, preserve = nil, dereference = nil);end
def self.copy_stream(src, dest);end
def self.mv(src, dest, options = nil);end
def self.move(src, dest, options = nil);end
def self.rm(list, options = nil);end
def self.remove(list, options = nil);end
def self.rm_f(list, options = nil);end
def self.safe_unlink(list, options = nil);end
def self.rm_r(list, options = nil);end
def self.rm_rf(list, options = nil);end
def self.rmtree(list, options = nil);end
def self.remove_entry_secure(path, force = nil);end
def self.remove_entry(path, force = nil);end
def self.remove_file(path, force = nil);end
def self.remove_dir(path, force = nil);end
def self.compare_file(a, b);end
def self.identical?(a, b);end
def self.cmp(a, b);end
def self.compare_stream(a, b);end
def self.install(src, dest, options = nil);end
def self.chmod(mode, list, options = nil);end
def self.chmod_R(mode, list, options = nil);end
def self.chown(user, group, list, options = nil);end
def self.chown_R(user, group, list, options = nil);end
def self.touch(list, options = nil);end
def self.commands();end
def self.options();end
def self.have_option?(mid, opt);end
def self.options_of(mid);end
def self.collect_method(opt);end
def sh(*args);end
def ruby(*args);end
def safe_ln(*args);end
def split_all(path);end
end
module FileUtils::StreamUtils_
end
class FileUtils::Entry_ < Object
include FileUtils::StreamUtils_
include Kernel
def path();end
def prefix();end
def rel();end
def dereference?();end
def exist?();end
def file?();end
def directory?();end
def symlink?();end
def chardev?();end
def blockdev?();end
def socket?();end
def pipe?();end
def door?();end
def entries();end
def stat();end
def stat!();end
def lstat();end
def lstat!();end
def chmod(mode);end
def chown(uid, gid);end
def copy(dest);end
def copy_file(dest);end
def copy_metadata(path);end
def remove();end
def remove_dir1();end
def remove_file();end
def platform_support();end
def preorder_traverse();end
def traverse();end
def postorder_traverse();end
def wrap_traverse(pre, post);end
end
module FileUtils::LowMethods
end
module FileUtils::Verbose
include FileUtils
include FileUtils::StreamUtils_
def pwd();end
def getwd();end
def cd(*args);end
def chdir(*args);end
def uptodate?(new, old_list);end
def mkdir(*args);end
def mkdir_p(*args);end
def mkpath(*args);end
def makedirs(*args);end
def rmdir(*args);end
def ln(*args);end
def link(*args);end
def ln_s(*args);end
def symlink(*args);end
def ln_sf(*args);end
def cp(*args);end
def copy(*args);end
def cp_r(*args);end
def copy_entry(src, dest, preserve = nil, dereference_root = nil, remove_destination = nil);end
def copy_file(src, dest, preserve = nil, dereference = nil);end
def copy_stream(src, dest);end
def mv(*args);end
def move(*args);end
def rm(*args);end
def remove(*args);end
def rm_f(*args);end
def safe_unlink(*args);end
def rm_r(*args);end
def rm_rf(*args);end
def rmtree(*args);end
def remove_entry_secure(path, force = nil);end
def remove_entry(path, force = nil);end
def remove_file(path, force = nil);end
def remove_dir(path, force = nil);end
def compare_file(a, b);end
def identical?(a, b);end
def cmp(a, b);end
def compare_stream(a, b);end
def install(*args);end
def chmod(*args);end
def chmod_R(*args);end
def chown(*args);end
def chown_R(*args);end
def touch(*args);end
def sh(*args);end
def ruby(*args);end
def safe_ln(*args);end
def split_all(path);end
def self.pwd();end
def self.getwd();end
def self.cd(*args);end
def self.chdir(*args);end
def self.uptodate?(new, old_list);end
def self.mkdir(*args);end
def self.mkdir_p(*args);end
def self.mkpath(*args);end
def self.makedirs(*args);end
def self.rmdir(*args);end
def self.ln(*args);end
def self.link(*args);end
def self.ln_s(*args);end
def self.symlink(*args);end
def self.ln_sf(*args);end
def self.cp(*args);end
def self.copy(*args);end
def self.cp_r(*args);end
def self.copy_entry(src, dest, preserve = nil, dereference_root = nil, remove_destination = nil);end
def self.copy_file(src, dest, preserve = nil, dereference = nil);end
def self.copy_stream(src, dest);end
def self.mv(*args);end
def self.move(*args);end
def self.rm(*args);end
def self.remove(*args);end
def self.rm_f(*args);end
def self.safe_unlink(*args);end
def self.rm_r(*args);end
def self.rm_rf(*args);end
def self.rmtree(*args);end
def self.remove_entry_secure(path, force = nil);end
def self.remove_entry(path, force = nil);end
def self.remove_file(path, force = nil);end
def self.remove_dir(path, force = nil);end
def self.compare_file(a, b);end
def self.identical?(a, b);end
def self.cmp(a, b);end
def self.compare_stream(a, b);end
def self.install(*args);end
def self.chmod(*args);end
def self.chmod_R(*args);end
def self.chown(*args);end
def self.chown_R(*args);end
def self.touch(*args);end
end
module FileUtils::NoWrite
include FileUtils::LowMethods
include FileUtils
include FileUtils::StreamUtils_
def pwd(*args);end
def getwd(*args);end
def cd(*args);end
def chdir(*args);end
def uptodate?(*args);end
def mkdir(*args);end
def mkdir_p(*args);end
def mkpath(*args);end
def makedirs(*args);end
def rmdir(*args);end
def ln(*args);end
def link(*args);end
def ln_s(*args);end
def symlink(*args);end
def ln_sf(*args);end
def cp(*args);end
def copy(*args);end
def cp_r(*args);end
def copy_entry(*args);end
def copy_file(*args);end
def copy_stream(*args);end
def mv(*args);end
def move(*args);end
def rm(*args);end
def remove(*args);end
def rm_f(*args);end
def safe_unlink(*args);end
def rm_r(*args);end
def rm_rf(*args);end
def rmtree(*args);end
def remove_entry_secure(*args);end
def remove_entry(*args);end
def remove_file(*args);end
def remove_dir(*args);end
def compare_file(*args);end
def identical?(*args);end
def cmp(*args);end
def compare_stream(*args);end
def install(*args);end
def chmod(*args);end
def chmod_R(*args);end
def chown(*args);end
def chown_R(*args);end
def touch(*args);end
def sh(*args);end
def ruby(*args);end
def safe_ln(*args);end
def split_all(path);end
def self.pwd(*args);end
def self.getwd(*args);end
def self.cd(*args);end
def self.chdir(*args);end
def self.uptodate?(*args);end
def self.mkdir(*args);end
def self.mkdir_p(*args);end
def self.mkpath(*args);end
def self.makedirs(*args);end
def self.rmdir(*args);end
def self.ln(*args);end
def self.link(*args);end
def self.ln_s(*args);end
def self.symlink(*args);end
def self.ln_sf(*args);end
def self.cp(*args);end
def self.copy(*args);end
def self.cp_r(*args);end
def self.copy_entry(*args);end
def self.copy_file(*args);end
def self.copy_stream(*args);end
def self.mv(*args);end
def self.move(*args);end
def self.rm(*args);end
def self.remove(*args);end
def self.rm_f(*args);end
def self.safe_unlink(*args);end
def self.rm_r(*args);end
def self.rm_rf(*args);end
def self.rmtree(*args);end
def self.remove_entry_secure(*args);end
def self.remove_entry(*args);end
def self.remove_file(*args);end
def self.remove_dir(*args);end
def self.compare_file(*args);end
def self.identical?(*args);end
def self.cmp(*args);end
def self.compare_stream(*args);end
def self.install(*args);end
def self.chmod(*args);end
def self.chmod_R(*args);end
def self.chown(*args);end
def self.chown_R(*args);end
def self.touch(*args);end
end
module FileUtils::DryRun
include FileUtils::LowMethods
include FileUtils
include FileUtils::StreamUtils_
def pwd(*args);end
def getwd(*args);end
def cd(*args);end
def chdir(*args);end
def uptodate?(*args);end
def mkdir(*args);end
def mkdir_p(*args);end
def mkpath(*args);end
def makedirs(*args);end
def rmdir(*args);end
def ln(*args);end
def link(*args);end
def ln_s(*args);end
def symlink(*args);end
def ln_sf(*args);end
def cp(*args);end
def copy(*args);end
def cp_r(*args);end
def copy_entry(*args);end
def copy_file(*args);end
def copy_stream(*args);end
def mv(*args);end
def move(*args);end
def rm(*args);end
def remove(*args);end
def rm_f(*args);end
def safe_unlink(*args);end
def rm_r(*args);end
def rm_rf(*args);end
def rmtree(*args);end
def remove_entry_secure(*args);end
def remove_entry(*args);end
def remove_file(*args);end
def remove_dir(*args);end
def compare_file(*args);end
def identical?(*args);end
def cmp(*args);end
def compare_stream(*args);end
def install(*args);end
def chmod(*args);end
def chmod_R(*args);end
def chown(*args);end
def chown_R(*args);end
def touch(*args);end
def sh(*args);end
def ruby(*args);end
def safe_ln(*args);end
def split_all(path);end
def self.pwd(*args);end
def self.getwd(*args);end
def self.cd(*args);end
def self.chdir(*args);end
def self.uptodate?(*args);end
def self.mkdir(*args);end
def self.mkdir_p(*args);end
def self.mkpath(*args);end
def self.makedirs(*args);end
def self.rmdir(*args);end
def self.ln(*args);end
def self.link(*args);end
def self.ln_s(*args);end
def self.symlink(*args);end
def self.ln_sf(*args);end
def self.cp(*args);end
def self.copy(*args);end
def self.cp_r(*args);end
def self.copy_entry(*args);end
def self.copy_file(*args);end
def self.copy_stream(*args);end
def self.mv(*args);end
def self.move(*args);end
def self.rm(*args);end
def self.remove(*args);end
def self.rm_f(*args);end
def self.safe_unlink(*args);end
def self.rm_r(*args);end
def self.rm_rf(*args);end
def self.rmtree(*args);end
def self.remove_entry_secure(*args);end
def self.remove_entry(*args);end
def self.remove_file(*args);end
def self.remove_dir(*args);end
def self.compare_file(*args);end
def self.identical?(*args);end
def self.cmp(*args);end
def self.compare_stream(*args);end
def self.install(*args);end
def self.chmod(*args);end
def self.chmod_R(*args);end
def self.chown(*args);end
def self.chown_R(*args);end
def self.touch(*args);end
end
module Etc
def getlogin();end
def getpwuid(*args);end
def getpwnam(arg0);end
def setpwent();end
def endpwent();end
def getpwent();end
def passwd();end
def getgrgid(*args);end
def getgrnam(arg0);end
def group();end
def setgrent();end
def endgrent();end
def getgrent();end
def sysconfdir();end
def systmpdir();end
def self.getlogin();end
def self.getpwuid(*args);end
def self.getpwnam(arg0);end
def self.setpwent();end
def self.endpwent();end
def self.getpwent();end
def self.passwd();end
def self.getgrgid(*args);end
def self.getgrnam(arg0);end
def self.group();end
def self.setgrent();end
def self.endgrent();end
def self.getgrent();end
def self.sysconfdir();end
def self.systmpdir();end
end
class Struct::Passwd < Struct
include Enumerable
include Kernel
def self.[](*args);end
def self.members();end
def self.each();end
def self.to_a(*args);end
def self.entries(*args);end
def self.sort();end
def self.sort_by();end
def self.grep(arg0);end
def self.count(*args);end
def self.find(*args);end
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
def self.min();end
def self.max();end
def self.minmax();end
def self.min_by();end
def self.max_by();end
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
def self.chunk(*args);end
def self.slice_before(*args);end
def self.lazy();end
def self.to_set(*args);end
def self.[](*args);end
def self.members();end
def self.each();end
def name=(arg0);end
def passwd();end
def passwd=(arg0);end
def uid();end
def uid=(arg0);end
def gid();end
def gid=(arg0);end
def gecos();end
def gecos=(arg0);end
def dir();end
def dir=(arg0);end
def shell();end
def shell=(arg0);end
end
class Struct::Tms < Struct
include Enumerable
include Kernel
def self.[](*args);end
def self.members();end
def self.[](*args);end
def self.members();end
def utime();end
def utime=(arg0);end
def stime();end
def stime=(arg0);end
def cutime();end
def cutime=(arg0);end
def cstime();end
def cstime=(arg0);end
end
class Struct::Group < Struct
include Enumerable
include Kernel
def self.[](*args);end
def self.members();end
def self.each();end
def self.to_a(*args);end
def self.entries(*args);end
def self.sort();end
def self.sort_by();end
def self.grep(arg0);end
def self.count(*args);end
def self.find(*args);end
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
def self.min();end
def self.max();end
def self.minmax();end
def self.min_by();end
def self.max_by();end
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
def self.chunk(*args);end
def self.slice_before(*args);end
def self.lazy();end
def self.to_set(*args);end
def self.[](*args);end
def self.members();end
def self.each();end
def name=(arg0);end
def passwd();end
def passwd=(arg0);end
def gid();end
def gid=(arg0);end
def mem();end
def mem=(arg0);end
end
module Singleton
def __init__(klass);end
def self.__init__(klass);end
def clone();end
def dup();end
def _dump(*args);end
end
module Singleton::SingletonClassMethods
def clone();end
def _load(str);end
end
class OptionParser < Object
include Kernel
def self.with(*args);end
def self.inc(arg, default = nil);end
def self.terminate(*args);end
def self.top();end
def self.accept(*args);end
def self.reject(*args);end
def self.getopts(*args);end
def self.with(*args);end
def self.inc(arg, default = nil);end
def self.terminate(*args);end
def self.top();end
def self.accept(*args);end
def self.reject(*args);end
def self.getopts(*args);end
def compsys(to, name = nil);end
def inc(*args);end
def add_officious();end
def terminate(*args);end
def accept(*args);end
def reject(*args);end
def banner=(arg0);end
def program_name=(arg0);end
def summary_width();end
def summary_width=(arg0);end
def summary_indent();end
def summary_indent=(arg0);end
def default_argv();end
def default_argv=(arg0);end
def banner();end
def program_name();end
def set_banner(arg0);end
def set_program_name(arg0);end
def set_summary_width(arg0);end
def set_summary_indent(arg0);end
def version=(arg0);end
def release=(arg0);end
def version();end
def release();end
def ver();end
def top();end
def base();end
def remove();end
def summarize(*args);end
def help();end
def to_a();end
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
def parse(*args);end
def parse!(*args);end
def getopts(*args);end
def candidate(word);end
def environment(*args);end
end
module OptionParser::Completion
def regexp(key, icase);end
def candidate(key, icase = nil, pat = nil, &block);end
def self.regexp(key, icase);end
def self.candidate(key, icase = nil, pat = nil, &block);end
def candidate(key, icase = nil, pat = nil);end
def complete(key, icase = nil, pat = nil);end
def convert(*args);end
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
def self.guess(arg);end
def self.incompatible_argument_styles(arg, t);end
def self.pattern();end
def self.guess(arg);end
def self.incompatible_argument_styles(arg, t);end
def self.pattern();end
def pattern();end
def conv();end
def short();end
def long();end
def arg();end
def desc();end
def block();end
def summarize(*args);end
def add_banner(to);end
def match_nonswitch?(str);end
def switch_name();end
def compsys(sdone, ldone);end
end
class OptionParser::Switch::NoArgument < OptionParser::Switch
include Kernel
def self.incompatible_argument_styles(*args);end
def self.pattern();end
def self.guess(arg);end
def self.incompatible_argument_styles(*args);end
def self.pattern();end
def parse(arg, argv);end
end
class OptionParser::Switch::RequiredArgument < OptionParser::Switch
include Kernel
def self.guess(arg);end
def self.incompatible_argument_styles(arg, t);end
def self.pattern();end
def parse(arg, argv);end
end
class OptionParser::Switch::OptionalArgument < OptionParser::Switch
include Kernel
def self.guess(arg);end
def self.incompatible_argument_styles(arg, t);end
def self.pattern();end
def parse(arg, argv, &error);end
end
class OptionParser::Switch::PlacedArgument < OptionParser::Switch
include Kernel
def self.guess(arg);end
def self.incompatible_argument_styles(arg, t);end
def self.pattern();end
def parse(arg, argv, &error);end
end
class OptionParser::List < Object
include Kernel
def atype();end
def short();end
def long();end
def list();end
def accept(t, pat = nil, &block);end
def reject(t);end
def prepend(*args);end
def append(*args);end
def search(id, key);end
def complete(id, opt, icase = nil, *pat, &block);end
def each_option(&block);end
def summarize(*args);end
def add_banner(to);end
def compsys(*args);end
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
def args();end
def reason=(arg0);end
def recover(argv);end
def set_backtrace(array);end
def set_option(opt, eq);end
def reason();end
def message();end
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
def options=(opt);end
def options();end
def order!(&blk);end
def permute!();end
def parse!();end
def getopts(*args);end
end
module OptionParser::Acceptables
end
class OpenStruct < Object
include Kernel
def to_h();end
def each_pair();end
def marshal_dump();end
def marshal_load(x);end
def method_missing(mid, *args);end
def [](name);end
def []=(name, value);end
def delete_field(name);end
end
class Set < Object
include Enumerable
include Kernel
def self.[](*args);end
def self.[](*args);end
def size();end
def length();end
def empty?();end
def clear();end
def replace(enum);end
def to_a();end
def flatten();end
def flatten!();end
def member?(o);end
def superset?(set);end
def proper_superset?(set);end
def subset?(set);end
def proper_subset?(set);end
def each(&block);end
def add(o);end
def <<(o);end
def add?(o);end
def delete(o);end
def delete?(o);end
def delete_if();end
def keep_if();end
def collect!();end
def map!();end
def reject!(&block);end
def select!(&block);end
def merge(enum);end
def subtract(enum);end
def |(enum);end
def +(enum);end
def union(enum);end
def -(enum);end
def difference(enum);end
def &(enum);end
def intersection(enum);end
def ^(enum);end
def classify();end
def divide(&func);end
def pretty_print(pp);end
def pretty_print_cycle(pp);end
end
class SortedSet < Set
include Enumerable
include Kernel
def self.[](*args);end
def self.setup();end
def self.[](*args);end
def self.setup();end
end
class Rake::FileList < Object
include Rake::Cloneable
include Kernel
def self.[](*args);end
def self.glob(pattern, *args);end
def self.[](*args);end
def self.glob(pattern, *args);end
def &(*args);end
def +(*args);end
def -(*args);end
def [](*args);end
def []=(*args);end
def all?(*args);end
def any?(*args);end
def assoc(*args);end
def at(*args);end
def bsearch(*args);end
def chunk(*args);end
def clear(*args);end
def collect(*args);end
def collect!(*args);end
def collect_concat(*args);end
def combination(*args);end
def compact(*args);end
def compact!(*args);end
def concat(*args);end
def count(*args);end
def cycle(*args);end
def delete(*args);end
def delete_at(*args);end
def delete_if(*args);end
def detect(*args);end
def drop(*args);end
def drop_while(*args);end
def each(*args);end
def each_cons(*args);end
def each_entry(*args);end
def each_index(*args);end
def each_slice(*args);end
def each_with_index(*args);end
def each_with_object(*args);end
def empty?(*args);end
def entries(*args);end
def fetch(*args);end
def fill(*args);end
def find(*args);end
def find_all(*args);end
def find_index(*args);end
def first(*args);end
def flat_map(*args);end
def flatten(*args);end
def flatten!(*args);end
def grep(*args);end
def group_by(*args);end
def index(*args);end
def inject(*args);end
def insert(*args);end
def join(*args);end
def keep_if(*args);end
def last(*args);end
def lazy(*args);end
def length(*args);end
def map(*args);end
def map!(*args);end
def max(*args);end
def max_by(*args);end
def member?(*args);end
def min(*args);end
def min_by(*args);end
def minmax(*args);end
def minmax_by(*args);end
def none?(*args);end
def one?(*args);end
def pack(*args);end
def permutation(*args);end
def pop(*args);end
def product(*args);end
def push(*args);end
def rassoc(*args);end
def reduce(*args);end
def reject(*args);end
def reject!(*args);end
def repeated_combination(*args);end
def repeated_permutation(*args);end
def replace(*args);end
def reverse(*args);end
def reverse!(*args);end
def reverse_each(*args);end
def rindex(*args);end
def rotate(*args);end
def rotate!(*args);end
def sample(*args);end
def select!(*args);end
def shift(*args);end
def shuffle(*args);end
def shuffle!(*args);end
def size(*args);end
def slice(*args);end
def slice!(*args);end
def slice_before(*args);end
def sort(*args);end
def sort!(*args);end
def sort_by(*args);end
def sort_by!(*args);end
def take(*args);end
def take_while(*args);end
def transpose(*args);end
def uniq(*args);end
def uniq!(*args);end
def unshift(*args);end
def values_at(*args);end
def zip(*args);end
def |(*args);end
def include(*args);end
def add(*args);end
def exclude(*args);end
def clear_exclude();end
def to_a();end
def to_ary();end
def *(other);end
def <<(obj);end
def resolve();end
def sub(pat, rep);end
def gsub(pat, rep);end
def sub!(pat, rep);end
def gsub!(pat, rep);end
def pathmap(*args);end
def ext(*args);end
def egrep(pattern, *options);end
def existing();end
def existing!();end
def partition(&block);end
def excluded_from_list?(fn);end
def import(array);end
end
module Rake::FileUtilsExt
include FileUtils
include FileUtils::StreamUtils_
def verbose_flag();end
def verbose_flag=(arg0);end
def nowrite_flag();end
def nowrite_flag=(arg0);end
def chdir(*args);end
def cd(*args);end
def mkdir(*args);end
def makedirs(*args);end
def mkpath(*args);end
def mkdir_p(*args);end
def rmdir(*args);end
def link(*args);end
def ln(*args);end
def symlink(*args);end
def ln_s(*args);end
def ln_sf(*args);end
def copy(*args);end
def cp(*args);end
def cp_r(*args);end
def move(*args);end
def mv(*args);end
def remove(*args);end
def rm(*args);end
def safe_unlink(*args);end
def rm_f(*args);end
def rm_r(*args);end
def rmtree(*args);end
def rm_rf(*args);end
def install(*args);end
def chmod(*args);end
def chmod_R(*args);end
def chown(*args);end
def chown_R(*args);end
def touch(*args);end
def verbose(*args);end
def nowrite(*args);end
def when_writing(*args);end
def rake_merge_option(args, defaults);end
def rake_output_message(message);end
def rake_check_options(options, *optdecl);end
def sh(*args);end
def ruby(*args);end
def safe_ln(*args);end
def split_all(path);end
def self.verbose_flag();end
def self.verbose_flag=(arg0);end
def self.nowrite_flag();end
def self.nowrite_flag=(arg0);end
def chdir(*args);end
def cd(*args);end
def mkdir(*args);end
def makedirs(*args);end
def mkpath(*args);end
def mkdir_p(*args);end
def rmdir(*args);end
def link(*args);end
def ln(*args);end
def symlink(*args);end
def ln_s(*args);end
def ln_sf(*args);end
def copy(*args);end
def cp(*args);end
def cp_r(*args);end
def move(*args);end
def mv(*args);end
def remove(*args);end
def rm(*args);end
def safe_unlink(*args);end
def rm_f(*args);end
def rm_r(*args);end
def rmtree(*args);end
def rm_rf(*args);end
def install(*args);end
def chmod(*args);end
def chmod_R(*args);end
def chown(*args);end
def chown_R(*args);end
def touch(*args);end
def verbose(*args);end
def nowrite(*args);end
def when_writing(*args);end
def rake_merge_option(args, defaults);end
def rake_output_message(message);end
def rake_check_options(options, *optdecl);end
end
module FileUtils::StreamUtils_
end
class FileUtils::Entry_ < Object
include FileUtils::StreamUtils_
include Kernel
def path();end
def prefix();end
def rel();end
def dereference?();end
def exist?();end
def file?();end
def directory?();end
def symlink?();end
def chardev?();end
def blockdev?();end
def socket?();end
def pipe?();end
def door?();end
def entries();end
def stat();end
def stat!();end
def lstat();end
def lstat!();end
def chmod(mode);end
def chown(uid, gid);end
def copy(dest);end
def copy_file(dest);end
def copy_metadata(path);end
def remove();end
def remove_dir1();end
def remove_file();end
def platform_support();end
def preorder_traverse();end
def traverse();end
def postorder_traverse();end
def wrap_traverse(pre, post);end
end
module FileUtils::LowMethods
end
module FileUtils::Verbose
include FileUtils
include FileUtils::StreamUtils_
def pwd();end
def getwd();end
def cd(*args);end
def chdir(*args);end
def uptodate?(new, old_list);end
def mkdir(*args);end
def mkdir_p(*args);end
def mkpath(*args);end
def makedirs(*args);end
def rmdir(*args);end
def ln(*args);end
def link(*args);end
def ln_s(*args);end
def symlink(*args);end
def ln_sf(*args);end
def cp(*args);end
def copy(*args);end
def cp_r(*args);end
def copy_entry(src, dest, preserve = nil, dereference_root = nil, remove_destination = nil);end
def copy_file(src, dest, preserve = nil, dereference = nil);end
def copy_stream(src, dest);end
def mv(*args);end
def move(*args);end
def rm(*args);end
def remove(*args);end
def rm_f(*args);end
def safe_unlink(*args);end
def rm_r(*args);end
def rm_rf(*args);end
def rmtree(*args);end
def remove_entry_secure(path, force = nil);end
def remove_entry(path, force = nil);end
def remove_file(path, force = nil);end
def remove_dir(path, force = nil);end
def compare_file(a, b);end
def identical?(a, b);end
def cmp(a, b);end
def compare_stream(a, b);end
def install(*args);end
def chmod(*args);end
def chmod_R(*args);end
def chown(*args);end
def chown_R(*args);end
def touch(*args);end
def sh(*args);end
def ruby(*args);end
def safe_ln(*args);end
def split_all(path);end
def self.pwd();end
def self.getwd();end
def self.cd(*args);end
def self.chdir(*args);end
def self.uptodate?(new, old_list);end
def self.mkdir(*args);end
def self.mkdir_p(*args);end
def self.mkpath(*args);end
def self.makedirs(*args);end
def self.rmdir(*args);end
def self.ln(*args);end
def self.link(*args);end
def self.ln_s(*args);end
def self.symlink(*args);end
def self.ln_sf(*args);end
def self.cp(*args);end
def self.copy(*args);end
def self.cp_r(*args);end
def self.copy_entry(src, dest, preserve = nil, dereference_root = nil, remove_destination = nil);end
def self.copy_file(src, dest, preserve = nil, dereference = nil);end
def self.copy_stream(src, dest);end
def self.mv(*args);end
def self.move(*args);end
def self.rm(*args);end
def self.remove(*args);end
def self.rm_f(*args);end
def self.safe_unlink(*args);end
def self.rm_r(*args);end
def self.rm_rf(*args);end
def self.rmtree(*args);end
def self.remove_entry_secure(path, force = nil);end
def self.remove_entry(path, force = nil);end
def self.remove_file(path, force = nil);end
def self.remove_dir(path, force = nil);end
def self.compare_file(a, b);end
def self.identical?(a, b);end
def self.cmp(a, b);end
def self.compare_stream(a, b);end
def self.install(*args);end
def self.chmod(*args);end
def self.chmod_R(*args);end
def self.chown(*args);end
def self.chown_R(*args);end
def self.touch(*args);end
end
module FileUtils::NoWrite
include FileUtils::LowMethods
include FileUtils
include FileUtils::StreamUtils_
def pwd(*args);end
def getwd(*args);end
def cd(*args);end
def chdir(*args);end
def uptodate?(*args);end
def mkdir(*args);end
def mkdir_p(*args);end
def mkpath(*args);end
def makedirs(*args);end
def rmdir(*args);end
def ln(*args);end
def link(*args);end
def ln_s(*args);end
def symlink(*args);end
def ln_sf(*args);end
def cp(*args);end
def copy(*args);end
def cp_r(*args);end
def copy_entry(*args);end
def copy_file(*args);end
def copy_stream(*args);end
def mv(*args);end
def move(*args);end
def rm(*args);end
def remove(*args);end
def rm_f(*args);end
def safe_unlink(*args);end
def rm_r(*args);end
def rm_rf(*args);end
def rmtree(*args);end
def remove_entry_secure(*args);end
def remove_entry(*args);end
def remove_file(*args);end
def remove_dir(*args);end
def compare_file(*args);end
def identical?(*args);end
def cmp(*args);end
def compare_stream(*args);end
def install(*args);end
def chmod(*args);end
def chmod_R(*args);end
def chown(*args);end
def chown_R(*args);end
def touch(*args);end
def sh(*args);end
def ruby(*args);end
def safe_ln(*args);end
def split_all(path);end
def self.pwd(*args);end
def self.getwd(*args);end
def self.cd(*args);end
def self.chdir(*args);end
def self.uptodate?(*args);end
def self.mkdir(*args);end
def self.mkdir_p(*args);end
def self.mkpath(*args);end
def self.makedirs(*args);end
def self.rmdir(*args);end
def self.ln(*args);end
def self.link(*args);end
def self.ln_s(*args);end
def self.symlink(*args);end
def self.ln_sf(*args);end
def self.cp(*args);end
def self.copy(*args);end
def self.cp_r(*args);end
def self.copy_entry(*args);end
def self.copy_file(*args);end
def self.copy_stream(*args);end
def self.mv(*args);end
def self.move(*args);end
def self.rm(*args);end
def self.remove(*args);end
def self.rm_f(*args);end
def self.safe_unlink(*args);end
def self.rm_r(*args);end
def self.rm_rf(*args);end
def self.rmtree(*args);end
def self.remove_entry_secure(*args);end
def self.remove_entry(*args);end
def self.remove_file(*args);end
def self.remove_dir(*args);end
def self.compare_file(*args);end
def self.identical?(*args);end
def self.cmp(*args);end
def self.compare_stream(*args);end
def self.install(*args);end
def self.chmod(*args);end
def self.chmod_R(*args);end
def self.chown(*args);end
def self.chown_R(*args);end
def self.touch(*args);end
end
module FileUtils::DryRun
include FileUtils::LowMethods
include FileUtils
include FileUtils::StreamUtils_
def pwd(*args);end
def getwd(*args);end
def cd(*args);end
def chdir(*args);end
def uptodate?(*args);end
def mkdir(*args);end
def mkdir_p(*args);end
def mkpath(*args);end
def makedirs(*args);end
def rmdir(*args);end
def ln(*args);end
def link(*args);end
def ln_s(*args);end
def symlink(*args);end
def ln_sf(*args);end
def cp(*args);end
def copy(*args);end
def cp_r(*args);end
def copy_entry(*args);end
def copy_file(*args);end
def copy_stream(*args);end
def mv(*args);end
def move(*args);end
def rm(*args);end
def remove(*args);end
def rm_f(*args);end
def safe_unlink(*args);end
def rm_r(*args);end
def rm_rf(*args);end
def rmtree(*args);end
def remove_entry_secure(*args);end
def remove_entry(*args);end
def remove_file(*args);end
def remove_dir(*args);end
def compare_file(*args);end
def identical?(*args);end
def cmp(*args);end
def compare_stream(*args);end
def install(*args);end
def chmod(*args);end
def chmod_R(*args);end
def chown(*args);end
def chown_R(*args);end
def touch(*args);end
def sh(*args);end
def ruby(*args);end
def safe_ln(*args);end
def split_all(path);end
def self.pwd(*args);end
def self.getwd(*args);end
def self.cd(*args);end
def self.chdir(*args);end
def self.uptodate?(*args);end
def self.mkdir(*args);end
def self.mkdir_p(*args);end
def self.mkpath(*args);end
def self.makedirs(*args);end
def self.rmdir(*args);end
def self.ln(*args);end
def self.link(*args);end
def self.ln_s(*args);end
def self.symlink(*args);end
def self.ln_sf(*args);end
def self.cp(*args);end
def self.copy(*args);end
def self.cp_r(*args);end
def self.copy_entry(*args);end
def self.copy_file(*args);end
def self.copy_stream(*args);end
def self.mv(*args);end
def self.move(*args);end
def self.rm(*args);end
def self.remove(*args);end
def self.rm_f(*args);end
def self.safe_unlink(*args);end
def self.rm_r(*args);end
def self.rm_rf(*args);end
def self.rmtree(*args);end
def self.remove_entry_secure(*args);end
def self.remove_entry(*args);end
def self.remove_file(*args);end
def self.remove_dir(*args);end
def self.compare_file(*args);end
def self.identical?(*args);end
def self.cmp(*args);end
def self.compare_stream(*args);end
def self.install(*args);end
def self.chmod(*args);end
def self.chmod_R(*args);end
def self.chown(*args);end
def self.chown_R(*args);end
def self.touch(*args);end
end
