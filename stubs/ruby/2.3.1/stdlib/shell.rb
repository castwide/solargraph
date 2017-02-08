module Exception2MessageMapper
def extend_object(cl);end
def message(klass, exp);end
def Fail(*args);end
def Raise(*args);end
def def_e2message(k, c, m);end
def def_exception(k, n, m, s = nil);end
def e2mm_message(klass, exp);end
def self.extend_object(cl);end
def self.message(klass, exp);end
def self.Fail(*args);end
def self.Raise(*args);end
def self.def_e2message(k, c, m);end
def self.def_exception(k, n, m, s = nil);end
def self.e2mm_message(klass, exp);end
def fail(*args);end
def bind(cl);end
def Fail(*args);end
def Raise(*args);end
def def_e2message(c, m);end
def def_exception(n, m, s = nil);end
end
class Exception2MessageMapper::ErrNotRegisteredException < StandardError
include Kernel
def self.exception(*args);end
end
module Forwardable
def debug();end
def debug=(arg0);end
def self.debug();end
def self.debug=(arg0);end
def def_delegator(accessor, method, ali = nil);end
def instance_delegate(hash);end
def def_instance_delegator(accessor, method, ali = nil);end
def def_instance_delegators(accessor, *methods);end
def delegate(hash);end
def def_delegators(accessor, *methods);end
end
module SingleForwardable
def def_delegator(accessor, method, ali = nil);end
def delegate(hash);end
def def_delegators(accessor, *methods);end
def single_delegate(hash);end
def def_single_delegator(accessor, method, ali = nil);end
def def_single_delegators(accessor, *methods);end
end
class Solargraph::Shell < Thor
include Thor::Shell
include Thor::Invocation
include Thor::Base
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.map(*args);end
def self.options(*args);end
def self.desc(usage, description, options = nil);end
def self.option(name, options = nil);end
def self.package_name(name, options = nil);end
def self.default_command(*args);end
def self.default_task(*args);end
def self.register(klass, subcommand_name, usage, description, options = nil);end
def self.subcommand(subcommand, subcommand_class);end
def self.long_desc(long_description, options = nil);end
def self.method_options(*args);end
def self.method_option(name, options = nil);end
def self.command_help(shell, command_name);end
def self.task_help(shell, command_name);end
def self.help(shell, subcommand = nil);end
def self.printable_commands(*args);end
def self.printable_tasks(*args);end
def self.subcommands();end
def self.subtasks();end
def self.subcommand_classes();end
def self.subtask(subcommand, subcommand_class);end
def self.check_unknown_options!(*args);end
def self.check_unknown_options?(config);end
def self.stop_on_unknown_option!(*args);end
def self.stop_on_unknown_option?(command);end
def self.prepare_for_invocation(key, name);end
def self.attr_reader(*args);end
def self.attr_writer(*args);end
def self.attr_accessor(*args);end
def self.start(*args);end
def self.arguments();end
def self.group(*args);end
def self.namespace(*args);end
def self.all_commands();end
def self.handle_no_command_error(command, has_namespace = nil);end
def self.commands();end
def self.class_options(*args);end
def self.check_unknown_options();end
def self.strict_args_position?(config);end
def self.no_commands();end
def self.strict_args_position!();end
def self.strict_args_position();end
def self.argument(name, options = nil);end
def self.remove_argument(*args);end
def self.class_option(name, options = nil);end
def self.remove_class_option(*args);end
def self.tasks();end
def self.all_tasks();end
def self.remove_command(*args);end
def self.remove_task(*args);end
def self.no_tasks();end
def self.public_command(*args);end
def self.public_task(*args);end
def self.handle_no_task_error(command, has_namespace = nil);end
def self.handle_argument_error(command, error, args, arity);end
def stub(file);end
def info(file);end
def complete();end
def sexp(file);end
end
class Thor::Command < #<Class:0x007fa0606dc2e0>
include Enumerable
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.[](*args);end
def self.members();end
def run(instance, args = nil);end
def hidden?();end
def formatted_usage(klass, namespace = nil, subcommand = nil);end
end
class Process::Tms < Struct
include Enumerable
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.[](*args);end
def self.members();end
def self.[](*args);end
def self.members();end
def utime();end
def utime=(_);end
def stime();end
def stime=(_);end
def cutime();end
def cutime=(_);end
def cstime();end
def cstime=(_);end
end
class Thor::HiddenCommand < Thor::Command
include Enumerable
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.[](*args);end
def self.members();end
def hidden?();end
end
class Thor::DynamicCommand < Thor::Command
include Enumerable
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.[](*args);end
def self.members();end
def run(instance, args = nil);end
end
module Thor::CoreExt
end
class Thor::CoreExt::HashWithIndifferentAccess < Hash
include JSON::Ext::Generator::GeneratorMethods::Hash
include Enumerable
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.[](*args);end
def self.try_convert(arg0);end
def [](key);end
def []=(key, value);end
def to_hash();end
def delete(key);end
def values_at(*args);end
def merge!(other);end
def merge(other);end
end
class Thor::CoreExt::OrderedHash < Hash
include JSON::Ext::Generator::GeneratorMethods::Hash
include Enumerable
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.[](*args);end
def self.try_convert(arg0);end
end
class Thor::Error < StandardError
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.exception(*args);end
end
class Thor::UndefinedCommandError < Thor::Error
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.exception(*args);end
end
class Thor::AmbiguousCommandError < Thor::Error
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.exception(*args);end
end
class Thor::InvocationError < Thor::Error
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.exception(*args);end
end
class Thor::UnknownArgumentError < Thor::Error
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.exception(*args);end
end
class Thor::RequiredArgumentMissingError < Thor::InvocationError
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.exception(*args);end
end
class Thor::MalformattedArgumentError < Thor::InvocationError
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.exception(*args);end
end
module Thor::Invocation
def included(base);end
def self.included(base);end
def invoke(*args);end
def invoke_command(command, *args);end
def current_command_chain();end
def invoke_all();end
def invoke_task(command, *args);end
def invoke_with_padding(*args);end
end
module Thor::Invocation::ClassMethods
def prepare_for_invocation(key, name);end
end
class Thor::Argument < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def default();end
def description();end
def type();end
def enum();end
def required();end
def usage();end
def banner();end
def required?();end
def human_name();end
def show_default?();end
end
class Thor::Arguments < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.split(args);end
def self.parse(*args);end
def self.split(args);end
def self.parse(*args);end
def parse(args);end
def remaining();end
end
class Thor::Option < Thor::Argument
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.parse(key, value);end
def self.parse(key, value);end
def aliases();end
def group();end
def usage(*args);end
def hide();end
def human_name();end
def switch_name();end
def lazy_default();end
def boolean?();end
def numeric?();end
def hash?();end
def array?();end
def string?();end
end
class Thor::Options < Thor::Arguments
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.to_switches(options);end
def self.split(args);end
def self.parse(*args);end
def self.to_switches(options);end
def peek();end
def parse(args);end
def check_unknown!();end
def remaining();end
end
module Thor::Base
def included(base);end
def shell();end
def subclasses();end
def subclass_files();end
def register_klass_file(klass);end
def shell=(arg0);end
def self.included(base);end
def self.shell();end
def self.subclasses();end
def self.subclass_files();end
def self.register_klass_file(klass);end
def self.shell=(arg0);end
def args();end
def options();end
def parent_options();end
def options=(arg0);end
def parent_options=(arg0);end
def args=(arg0);end
end
module Thor::Base::ClassMethods
def attr_reader(*args);end
def attr_writer(*args);end
def attr_accessor(*args);end
def start(*args);end
def arguments();end
def group(*args);end
def namespace(*args);end
def all_commands();end
def handle_no_command_error(command, has_namespace = nil);end
def commands();end
def class_options(*args);end
def check_unknown_options!();end
def check_unknown_options?(config);end
def check_unknown_options();end
def stop_on_unknown_option?(command_name);end
def strict_args_position?(config);end
def no_commands();end
def strict_args_position!();end
def strict_args_position();end
def argument(name, options = nil);end
def remove_argument(*args);end
def class_option(name, options = nil);end
def remove_class_option(*args);end
def tasks();end
def all_tasks();end
def remove_command(*args);end
def remove_task(*args);end
def no_tasks();end
def public_command(*args);end
def public_task(*args);end
def handle_no_task_error(command, has_namespace = nil);end
def handle_argument_error(command, error, args, arity);end
end
module Thor::Shell
def say(*args);end
def error(*args);end
def shell();end
def print_wrapped(*args);end
def print_table(*args);end
def with_padding();end
def ask(*args);end
def set_color(*args);end
def yes?(*args);end
def no?(*args);end
def say_status(*args);end
def print_in_columns(*args);end
def file_collision(*args);end
def terminal_width(*args);end
def shell=(arg0);end
end
class Thor::Shell::Basic < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def say(*args);end
def error(statement);end
def base();end
def print_wrapped(message, options = nil);end
def print_table(array, options = nil);end
def padding();end
def ask(statement, *args);end
def set_color(string, *args);end
def yes?(statement, color = nil);end
def no?(statement, color = nil);end
def say_status(status, message, log_status = nil);end
def print_in_columns(array);end
def file_collision(destination);end
def terminal_width();end
def base=(arg0);end
def padding=(value);end
def mute();end
def mute?();end
end
class Thor::Shell::Color < Thor::Shell::Basic
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def set_color(string, *colors);end
end
class Thor::Shell::HTML < Thor::Shell::Basic
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def ask(statement, color = nil);end
def set_color(string, *colors);end
end
module Thor::LineEditor
def best_available();end
def self.best_available();end
end
class Thor::LineEditor::Basic < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.available?();end
def self.available?();end
def options();end
def prompt();end
end
class Thor::LineEditor::Readline < Thor::LineEditor::Basic
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.available?();end
def self.available?();end
end
class Thor::LineEditor::Readline::PathCompletion < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def matches();end
end
module Thor::Sandbox
end
module Thor::Util
def user_home();end
def thor_classes_in(klass);end
def namespace_from_thor_class(constant);end
def find_class_and_command_by_namespace(namespace, fallback = nil);end
def find_by_namespace(namespace);end
def snake_case(str);end
def namespaces_in_content(contents, file = nil);end
def load_thorfile(path, content = nil, debug = nil);end
def camel_case(str);end
def find_class_and_task_by_namespace(namespace, fallback = nil);end
def thor_root();end
def thor_root_glob();end
def escape_globs(path);end
def globs_for(path);end
def ruby_command();end
def self.user_home();end
def self.thor_classes_in(klass);end
def self.namespace_from_thor_class(constant);end
def self.find_class_and_command_by_namespace(namespace, fallback = nil);end
def self.find_by_namespace(namespace);end
def self.snake_case(str);end
def self.namespaces_in_content(contents, file = nil);end
def self.load_thorfile(path, content = nil, debug = nil);end
def self.camel_case(str);end
def self.find_class_and_task_by_namespace(namespace, fallback = nil);end
def self.thor_root();end
def self.thor_root_glob();end
def self.escape_globs(path);end
def self.globs_for(path);end
def self.ruby_command();end
end
module Thor::Actions
def included(base);end
def self.included(base);end
def chmod(path, mode, config = nil);end
def run(command, config = nil);end
def directory(source, *args, &block);end
def source_paths();end
def remove_file(path, config = nil);end
def copy_file(source, *args, &block);end
def remove_dir(path, config = nil);end
def action(instance);end
def behavior();end
def behavior=(arg0);end
def destination_root();end
def destination_root=(root);end
def relative_to_original_destination_root(path, remove_dot = nil);end
def find_in_source_paths(file);end
def inside(*args);end
def in_root();end
def apply(path, config = nil);end
def run_ruby_script(command, config = nil);end
def thor(command, *args);end
def create_file(destination, *args, &block);end
def add_file(destination, *args, &block);end
def empty_directory(destination, config = nil);end
def create_link(destination, *args, &block);end
def add_link(destination, *args, &block);end
def template(source, *args, &block);end
def link_file(source, *args, &block);end
def get(source, *args, &block);end
def prepend_to_file(path, *args, &block);end
def insert_into_file(destination, *args, &block);end
def prepend_file(path, *args, &block);end
def append_to_file(path, *args, &block);end
def append_file(path, *args, &block);end
def inject_into_class(path, klass, *args, &block);end
def gsub_file(path, flag, *args, &block);end
def uncomment_lines(path, flag, *args);end
def comment_lines(path, flag, *args);end
def inject_into_file(destination, *args, &block);end
end
class Thor::Actions::EmptyDirectory < Object
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def exists?();end
def config();end
def base();end
def destination();end
def revoke!();end
def invoke!();end
def given_destination();end
def relative_destination();end
end
class Thor::Actions::CreateFile < Thor::Actions::EmptyDirectory
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def identical?();end
def data();end
def invoke!();end
def render();end
end
class Thor::Actions::CreateLink < Thor::Actions::CreateFile
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def exists?();end
def identical?();end
def data();end
def invoke!();end
end
class Thor::Actions::Directory < Thor::Actions::EmptyDirectory
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def source();end
def revoke!();end
def invoke!();end
end
class Thor::Actions::InjectIntoFile < Thor::Actions::EmptyDirectory
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def replacement();end
def behavior();end
def revoke!();end
def invoke!();end
def flag();end
end
module Thor::Actions::ClassMethods
def source_paths();end
def source_root(*args);end
def source_paths_for_search();end
def add_runtime_options!();end
end
module Thor::RakeCompat
include Rake::DSL
include Rake::FileUtilsExt
include FileUtils
include FileUtils::StreamUtils_
def included(base);end
def rake_classes();end
def self.included(base);end
def self.rake_classes();end
end
module FileUtils::StreamUtils_
end
class FileUtils::Entry_ < Object
include FileUtils::StreamUtils_
include JSON::Ext::Generator::GeneratorMethods::Object
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
def cd(*args);end
def rm(*args);end
def remove_entry(path, force = nil);end
def uptodate?(new, old_list);end
def mkpath(*args);end
def makedirs(*args);end
def ln(*args);end
def remove_file(path, force = nil);end
def ln_s(*args);end
def ln_sf(*args);end
def cp(*args);end
def copy_file(src, dest, preserve = nil, dereference = nil);end
def copy(*args);end
def cp_r(*args);end
def copy_entry(src, dest, preserve = nil, dereference_root = nil, remove_destination = nil);end
def mv(*args);end
def remove_entry_secure(path, force = nil);end
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
def touch(*args);end
def safe_ln(*args);end
def split_all(path);end
def sh(*args);end
def ruby(*args);end
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
def self.cd(*args);end
def self.rm(*args);end
def self.remove_entry(path, force = nil);end
def self.uptodate?(new, old_list);end
def self.mkpath(*args);end
def self.makedirs(*args);end
def self.ln(*args);end
def self.remove_file(path, force = nil);end
def self.ln_s(*args);end
def self.ln_sf(*args);end
def self.cp(*args);end
def self.copy_file(src, dest, preserve = nil, dereference = nil);end
def self.copy(*args);end
def self.cp_r(*args);end
def self.copy_entry(src, dest, preserve = nil, dereference_root = nil, remove_destination = nil);end
def self.mv(*args);end
def self.remove_entry_secure(path, force = nil);end
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
def self.touch(*args);end
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
def cd(*args);end
def rm(*args);end
def remove_entry(*args);end
def uptodate?(*args);end
def mkpath(*args);end
def makedirs(*args);end
def ln(*args);end
def remove_file(*args);end
def ln_s(*args);end
def ln_sf(*args);end
def cp(*args);end
def copy_file(*args);end
def copy(*args);end
def cp_r(*args);end
def copy_entry(*args);end
def mv(*args);end
def remove_entry_secure(*args);end
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
def touch(*args);end
def safe_ln(*args);end
def split_all(path);end
def sh(*args);end
def ruby(*args);end
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
def self.cd(*args);end
def self.rm(*args);end
def self.remove_entry(*args);end
def self.uptodate?(*args);end
def self.mkpath(*args);end
def self.makedirs(*args);end
def self.ln(*args);end
def self.remove_file(*args);end
def self.ln_s(*args);end
def self.ln_sf(*args);end
def self.cp(*args);end
def self.copy_file(*args);end
def self.copy(*args);end
def self.cp_r(*args);end
def self.copy_entry(*args);end
def self.mv(*args);end
def self.remove_entry_secure(*args);end
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
def self.touch(*args);end
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
def cd(*args);end
def rm(*args);end
def remove_entry(*args);end
def uptodate?(*args);end
def mkpath(*args);end
def makedirs(*args);end
def ln(*args);end
def remove_file(*args);end
def ln_s(*args);end
def ln_sf(*args);end
def cp(*args);end
def copy_file(*args);end
def copy(*args);end
def cp_r(*args);end
def copy_entry(*args);end
def mv(*args);end
def remove_entry_secure(*args);end
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
def touch(*args);end
def safe_ln(*args);end
def split_all(path);end
def sh(*args);end
def ruby(*args);end
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
def self.cd(*args);end
def self.rm(*args);end
def self.remove_entry(*args);end
def self.uptodate?(*args);end
def self.mkpath(*args);end
def self.makedirs(*args);end
def self.ln(*args);end
def self.remove_file(*args);end
def self.ln_s(*args);end
def self.ln_sf(*args);end
def self.cp(*args);end
def self.copy_file(*args);end
def self.copy(*args);end
def self.cp_r(*args);end
def self.copy_entry(*args);end
def self.mv(*args);end
def self.remove_entry_secure(*args);end
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
def self.touch(*args);end
end
class Thor::Group < Object
include Thor::Shell
include Thor::Invocation
include Thor::Base
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.desc(*args);end
def self.invoke(*args);end
def self.class_options_help(shell, groups = nil);end
def self.help(shell);end
def self.printable_commands(*args);end
def self.printable_tasks(*args);end
def self.handle_argument_error(command, error, args, arity);end
def self.invocations();end
def self.invocation_blocks();end
def self.invoke_from_option(*args);end
def self.remove_invocation(*args);end
def self.get_options_from_invocations(group_options, base_options);end
def self.prepare_for_invocation(key, name);end
def self.attr_reader(*args);end
def self.attr_writer(*args);end
def self.attr_accessor(*args);end
def self.start(*args);end
def self.arguments();end
def self.group(*args);end
def self.namespace(*args);end
def self.all_commands();end
def self.handle_no_command_error(command, has_namespace = nil);end
def self.commands();end
def self.class_options(*args);end
def self.check_unknown_options!();end
def self.check_unknown_options?(config);end
def self.check_unknown_options();end
def self.stop_on_unknown_option?(command_name);end
def self.strict_args_position?(config);end
def self.no_commands();end
def self.strict_args_position!();end
def self.strict_args_position();end
def self.argument(name, options = nil);end
def self.remove_argument(*args);end
def self.class_option(name, options = nil);end
def self.remove_class_option(*args);end
def self.tasks();end
def self.all_tasks();end
def self.remove_command(*args);end
def self.remove_task(*args);end
def self.no_tasks();end
def self.public_command(*args);end
def self.public_task(*args);end
def self.handle_no_task_error(command, has_namespace = nil);end
def self.desc(*args);end
def self.invoke(*args);end
def self.banner();end
def self.class_options_help(shell, groups = nil);end
def self.help(shell);end
def self.printable_commands(*args);end
def self.printable_tasks(*args);end
def self.dispatch(command, given_args, given_opts, config);end
def self.baseclass();end
def self.create_command(meth);end
def self.create_task(meth);end
def self.handle_argument_error(command, error, args, arity);end
def self.invocations();end
def self.invocation_blocks();end
def self.invoke_from_option(*args);end
def self.remove_invocation(*args);end
def self.get_options_from_invocations(group_options, base_options);end
def self.self_command();end
def self.self_task();end
end
module Sync_m
def extend_object(obj);end
def append_features(cl);end
def define_aliases(cl);end
def self.extend_object(obj);end
def self.append_features(cl);end
def self.define_aliases(cl);end
def sync_extend();end
def sync_locked?();end
def sync_mode();end
def sync_shared?();end
def sync_exclusive?();end
def sync_try_lock(*args);end
def sync_lock(*args);end
def sync_sh_locker();end
def sync_upgrade_waiting();end
def sync_waiting();end
def sync_unlock(*args);end
def sync_ex_locker();end
def sync_ex_count();end
def sync_ex_count=(arg0);end
def sync_ex_locker=(arg0);end
def sync_mode=(arg0);end
def sync_waiting=(arg0);end
def sync_synchronize(*args);end
def sync_inspect();end
def sync_upgrade_waiting=(arg0);end
def sync_sh_locker=(arg0);end
end
class Sync_m::Err < StandardError
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.Fail(*args);end
def self.exception(*args);end
def self.Fail(*args);end
end
class Sync_m::Err::UnknownLocker < Sync_m::Err
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.Fail(th);end
def self.exception(*args);end
def self.Fail(th);end
end
class Sync_m::Err::LockModeFailer < Sync_m::Err
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.Fail(mode);end
def self.exception(*args);end
def self.Fail(mode);end
end
module Sync_m
def extend_object(obj);end
def append_features(cl);end
def define_aliases(cl);end
def self.extend_object(obj);end
def self.append_features(cl);end
def self.define_aliases(cl);end
def sync_extend();end
def sync_locked?();end
def sync_mode();end
def sync_shared?();end
def sync_exclusive?();end
def sync_try_lock(*args);end
def sync_lock(*args);end
def sync_sh_locker();end
def sync_upgrade_waiting();end
def sync_waiting();end
def sync_unlock(*args);end
def sync_ex_locker();end
def sync_ex_count();end
def sync_ex_count=(arg0);end
def sync_ex_locker=(arg0);end
def sync_mode=(arg0);end
def sync_waiting=(arg0);end
def sync_synchronize(*args);end
def sync_inspect();end
def sync_upgrade_waiting=(arg0);end
def sync_sh_locker=(arg0);end
end
class Sync_m::Err < StandardError
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.Fail(*args);end
def self.exception(*args);end
def self.Fail(*args);end
end
class Sync_m::Err::UnknownLocker < Sync_m::Err
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.Fail(th);end
def self.exception(*args);end
def self.Fail(th);end
end
class Sync_m::Err::LockModeFailer < Sync_m::Err
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.Fail(mode);end
def self.exception(*args);end
def self.Fail(mode);end
end
class Sync < Object
include Sync_m
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def locked?();end
def try_lock(*args);end
def lock(*args);end
def unlock(*args);end
def synchronize(*args);end
def shared?();end
def exclusive?();end
end
class Sync_m::Err < StandardError
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.Fail(*args);end
def self.exception(*args);end
def self.Fail(*args);end
end
class Sync_m::Err::UnknownLocker < Sync_m::Err
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.Fail(th);end
def self.exception(*args);end
def self.Fail(th);end
end
class Sync_m::Err::LockModeFailer < Sync_m::Err
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.Fail(mode);end
def self.exception(*args);end
def self.Fail(mode);end
end
class Sync < Object
include Sync_m
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def locked?();end
def try_lock(*args);end
def lock(*args);end
def unlock(*args);end
def synchronize(*args);end
def shared?();end
def exclusive?();end
end
class Sync_m::Err < StandardError
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.Fail(*args);end
def self.exception(*args);end
def self.Fail(*args);end
end
class Sync_m::Err::UnknownLocker < Sync_m::Err
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.Fail(th);end
def self.exception(*args);end
def self.Fail(th);end
end
class Sync_m::Err::LockModeFailer < Sync_m::Err
include JSON::Ext::Generator::GeneratorMethods::Object
include Kernel
def self.Fail(mode);end
def self.exception(*args);end
def self.Fail(mode);end
end
