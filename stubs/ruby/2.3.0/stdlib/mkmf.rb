module FileUtils
include FileUtils::StreamUtils_
def pwd();end
def mkdir(list, options = nil);end
def rmdir(list, options = nil);end
def private_module_function(name);end
def commands();end
def cd(dir, options = nil, &block);end
def uptodate?(new, old_list);end
def options_of(mid);end
def have_option?(mid, opt);end
def collect_method(opt);end
def mkpath(list, options = nil);end
def makedirs(list, options = nil);end
def ln(src, dest, options = nil);end
def identical?(a, b);end
def mkdir_p(list, options = nil);end
def remove_file(path, force = nil);end
def ln_sf(src, dest, options = nil);end
def ln_s(src, dest, options = nil);end
def copy_file(src, dest, preserve = nil, dereference = nil);end
def copy(src, dest, options = nil);end
def chmod(mode, list, options = nil);end
def chown(user, group, list, options = nil);end
def cp_r(src, dest, options = nil);end
def link(src, dest, options = nil);end
def symlink(src, dest, options = nil);end
def copy_entry(src, dest, preserve = nil, dereference_root = nil, remove_destination = nil);end
def cp(src, dest, options = nil);end
def mv(src, dest, options = nil);end
def install(src, dest, options = nil);end
def remove_entry_secure(path, force = nil);end
def remove_entry(path, force = nil);end
def move(src, dest, options = nil);end
def rm(list, options = nil);end
def remove(list, options = nil);end
def safe_unlink(list, options = nil);end
def rm_r(list, options = nil);end
def copy_stream(src, dest);end
def rmtree(list, options = nil);end
def options();end
def remove_dir(path, force = nil);end
def compare_file(a, b);end
def compare_stream(a, b);end
def cmp(a, b);end
def chmod_R(mode, list, options = nil);end
def chown_R(user, group, list, options = nil);end
def touch(list, options = nil);end
def rm_f(list, options = nil);end
def rm_rf(list, options = nil);end
def chdir(dir, options = nil, &block);end
def getwd();end
def self.pwd();end
def self.mkdir(list, options = nil);end
def self.rmdir(list, options = nil);end
def self.private_module_function(name);end
def self.commands();end
def self.cd(dir, options = nil, &block);end
def self.uptodate?(new, old_list);end
def self.options_of(mid);end
def self.have_option?(mid, opt);end
def self.collect_method(opt);end
def self.mkpath(list, options = nil);end
def self.makedirs(list, options = nil);end
def self.ln(src, dest, options = nil);end
def self.identical?(a, b);end
def self.mkdir_p(list, options = nil);end
def self.remove_file(path, force = nil);end
def self.ln_sf(src, dest, options = nil);end
def self.ln_s(src, dest, options = nil);end
def self.copy_file(src, dest, preserve = nil, dereference = nil);end
def self.copy(src, dest, options = nil);end
def self.chmod(mode, list, options = nil);end
def self.chown(user, group, list, options = nil);end
def self.cp_r(src, dest, options = nil);end
def self.link(src, dest, options = nil);end
def self.symlink(src, dest, options = nil);end
def self.copy_entry(src, dest, preserve = nil, dereference_root = nil, remove_destination = nil);end
def self.cp(src, dest, options = nil);end
def self.mv(src, dest, options = nil);end
def self.install(src, dest, options = nil);end
def self.remove_entry_secure(path, force = nil);end
def self.remove_entry(path, force = nil);end
def self.move(src, dest, options = nil);end
def self.rm(list, options = nil);end
def self.remove(list, options = nil);end
def self.safe_unlink(list, options = nil);end
def self.rm_r(list, options = nil);end
def self.copy_stream(src, dest);end
def self.rmtree(list, options = nil);end
def self.options();end
def self.remove_dir(path, force = nil);end
def self.compare_file(a, b);end
def self.compare_stream(a, b);end
def self.cmp(a, b);end
def self.chmod_R(mode, list, options = nil);end
def self.chown_R(user, group, list, options = nil);end
def self.touch(list, options = nil);end
def self.rm_f(list, options = nil);end
def self.rm_rf(list, options = nil);end
def self.chdir(dir, options = nil, &block);end
def self.getwd();end
end
module FileUtils::StreamUtils_
end
class FileUtils::Entry_ < Object
include FileUtils::StreamUtils_
include MakeMakefile
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
def rm_f(*args);end
def rm_rf(*args);end
def cd(*args);end
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
def remove_entry(path, force = nil);end
def move(*args);end
def rm(*args);end
def safe_unlink(*args);end
def rm_r(*args);end
def rmtree(*args);end
def remove_dir(path, force = nil);end
def compare_file(a, b);end
def compare_stream(a, b);end
def cmp(a, b);end
def chmod_R(*args);end
def chown_R(*args);end
def touch(*args);end
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
def self.rm_f(*args);end
def self.rm_rf(*args);end
def self.cd(*args);end
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
def self.remove_entry(path, force = nil);end
def self.move(*args);end
def self.rm(*args);end
def self.safe_unlink(*args);end
def self.rm_r(*args);end
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
def rm_f(*args);end
def rm_rf(*args);end
def cd(*args);end
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
def remove_entry(*args);end
def move(*args);end
def rm(*args);end
def safe_unlink(*args);end
def rm_r(*args);end
def rmtree(*args);end
def remove_dir(*args);end
def compare_file(*args);end
def compare_stream(*args);end
def cmp(*args);end
def chmod_R(*args);end
def chown_R(*args);end
def touch(*args);end
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
def self.rm_f(*args);end
def self.rm_rf(*args);end
def self.cd(*args);end
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
def self.remove_entry(*args);end
def self.move(*args);end
def self.rm(*args);end
def self.safe_unlink(*args);end
def self.rm_r(*args);end
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
def rm_f(*args);end
def rm_rf(*args);end
def cd(*args);end
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
def remove_entry(*args);end
def move(*args);end
def rm(*args);end
def safe_unlink(*args);end
def rm_r(*args);end
def rmtree(*args);end
def remove_dir(*args);end
def compare_file(*args);end
def compare_stream(*args);end
def cmp(*args);end
def chmod_R(*args);end
def chown_R(*args);end
def touch(*args);end
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
def self.rm_f(*args);end
def self.rm_rf(*args);end
def self.cd(*args);end
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
def self.remove_entry(*args);end
def self.move(*args);end
def self.rm(*args);end
def self.safe_unlink(*args);end
def self.rm_r(*args);end
def self.rmtree(*args);end
def self.remove_dir(*args);end
def self.compare_file(*args);end
def self.compare_stream(*args);end
def self.cmp(*args);end
def self.chmod_R(*args);end
def self.chown_R(*args);end
def self.touch(*args);end
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
include MakeMakefile
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
include MakeMakefile
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
include MakeMakefile
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
module Shellwords
def split(line);end
def join(array);end
def escape(str);end
def shellwords(line);end
def shellsplit(line);end
def shellescape(str);end
def shelljoin(array);end
def self.split(line);end
def self.join(array);end
def self.escape(str);end
def self.shellwords(line);end
def self.shellsplit(line);end
def self.shellescape(str);end
def self.shelljoin(array);end
end
module MakeMakefile
def config_string(key, config = nil);end
def dir_re(dir);end
def rm_f(*args);end
def rm_rf(*args);end
def self.config_string(key, config = nil);end
def self.dir_re(dir);end
def self.rm_f(*args);end
def self.rm_rf(*args);end
def find_header(header, *paths);end
def have_struct_member(type, member, headers = nil, opt = nil, &b);end
def try_type(type, headers = nil, opt = nil, &b);end
def have_type(type, headers = nil, opt = nil, &b);end
def find_type(type, opt, *headers, &b);end
def try_const(const, headers = nil, opt = nil, &b);end
def have_const(const, headers = nil, opt = nil, &b);end
def typedef_expr(type, headers);end
def try_signedness(type, member, headers = nil, opts = nil);end
def check_sizeof(type, headers = nil, opts = nil, &b);end
def check_signedness(type, headers = nil, opts = nil, &b);end
def convertible_int(type, headers = nil, opts = nil, &b);end
def scalar_ptr_type?(type, member = nil, headers = nil, &b);end
def scalar_type?(type, member = nil, headers = nil, &b);end
def have_typeof?();end
def what_type?(type, member = nil, headers = nil, &b);end
def find_executable0(bin, path = nil);end
def find_executable(bin, path = nil);end
def arg_config(config, default = nil, &block);end
def enable_config(config, default = nil);end
def create_header(*args);end
def dir_config(target, idefault = nil, ldefault = nil);end
def pkg_config(pkg, option = nil);end
def with_destdir(dir);end
def winsep(s);end
def mkintpath(path);end
def timestamp_file(name, target_prefix = nil);end
def dummy_makefile(srcdir);end
def each_compile_rules();end
def relative_from(path, base);end
def depend_rules(depend);end
def install_dirs(*args);end
def map_dir(dir, map = nil);end
def create_makefile(target, srcprefix = nil);end
def modified?(target, times);end
def split_libs(*args);end
def merge_libs(*args);end
def libpath_env();end
def init_mkmf(*args);end
def xsystem(command, opts = nil);end
def mkmf_failed(path);end
def configuration(srcdir);end
def xpopen(command, *mode, &block);end
def log_src(src, heading = nil);end
def create_tmpsrc(src);end
def have_devel?();end
def try_link(src, opt = nil, *opts, &b);end
def try_do(src, command, *opts, &b);end
def link_command(ldflags, opt = nil, libpath = nil);end
def libpathflag(*args);end
def cc_command(*args);end
def cpp_command(outfile, opt = nil);end
def with_werror(opt, opts = nil);end
def try_link0(src, opt = nil, *opts, &b);end
def try_compile(src, opt = nil, *opts, &b);end
def try_cpp(src, opt = nil, *opts, &b);end
def try_header(src, opt = nil, *opts, &b);end
def cpp_include(header);end
def with_cppflags(flags);end
def try_cppflags(flags, opts = nil);end
def append_cppflags(flags, *opts);end
def checking_for(m, fmt = nil);end
def with_cflags(flags);end
def try_cflags(flags, opts = nil);end
def message(*args);end
def append_cflags(flags, *opts);end
def with_ldflags(flags);end
def try_ldflags(flags, opts = nil);end
def append_ldflags(flags, *opts);end
def try_static_assert(expr, headers = nil, opt = nil, &b);end
def try_constant(const, headers = nil, opt = nil, &b);end
def try_func(func, libs, headers = nil, opt = nil, &b);end
def try_var(var, headers = nil, opt = nil, &b);end
def egrep_cpp(pat, src, opt = nil, &b);end
def macro_defined?(macro, src, opt = nil, &b);end
def try_run(src, opt = nil, &b);end
def install_files(mfile, ifiles, map = nil, srcprefix = nil);end
def install_rb(mfile, dest, srcdir = nil);end
def append_library(libs, lib);end
def checking_message(target, place = nil, opt = nil);end
def have_macro(macro, headers = nil, opt = nil, &b);end
def have_library(lib, func = nil, headers = nil, opt = nil, &b);end
def with_config(config, default = nil);end
def find_library(lib, func, *paths, &b);end
def have_func(func, headers = nil, opt = nil, &b);end
def have_var(var, headers = nil, opt = nil, &b);end
def have_header(header, preheaders = nil, opt = nil, &b);end
def have_framework(fw, &b);end
end
module MakeMakefile::Logging
def log_open();end
def log_opened?();end
def logfile(file);end
def log_close();end
def postpone();end
def quiet();end
def quiet=(arg0);end
def self.log_open();end
def self.log_opened?();end
def self.logfile(file);end
def self.log_close();end
def self.postpone();end
def self.quiet();end
def self.quiet=(arg0);end
end
CONFIG = nil
C_EXT = nil
CXX_EXT = nil
SRC_EXT = nil
HDR_EXT = nil
INSTALL_DIRS = nil
CONFTEST = nil
CONFTEST_C = nil
OUTFLAG = nil
COUTFLAG = nil
CPPOUTFILE = nil
module MakeMakefile::Logging
def log_open();end
def log_opened?();end
def logfile(file);end
def log_close();end
def postpone();end
def quiet();end
def quiet=(arg0);end
def self.log_open();end
def self.log_opened?();end
def self.logfile(file);end
def self.log_close();end
def self.postpone();end
def self.quiet();end
def self.quiet=(arg0);end
end
STRING_OR_FAILED_FORMAT = nil
FailedMessage = nil
EXPORT_PREFIX = nil
COMMON_HEADERS = nil
COMMON_LIBS = nil
COMPILE_RULES = nil
COMPILE_C = nil
COMPILE_CXX = nil
ASSEMBLE_C = nil
ASSEMBLE_CXX = nil
TRY_LINK = nil
LINK_SO = nil
LIBPATHFLAG = nil
RPATHFLAG = nil
LIBARG = nil
MAIN_DOES_NOTHING = nil
UNIVERSAL_INTS = nil
CLEANINGS = nil
