spec = Gem::Specification.find_by_name(ARGV[0].split('/')[0])
gem_root = spec.gem_dir
gem_lib = gem_root + "/lib"
puts gem_lib
