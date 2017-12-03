module Solargraph
  class YardMap
    module CoreDocs
      class << self
        def cache_dir
          @cache_dir ||= File.join(Dir.home, '.solargraph', 'cache')
        end

        # Solargraph installs the Ruby 2.0.0 to ensure minimum functionality.
        def require_2_0_0
          version_dir = File.join(cache_dir, '2.0.0')
          unless File.exist?(version_dir)
            FileUtils.mkdir_p cache_dir
            FileUtils.cp File.join(Solargraph::YARDOC_PATH, '2.0.0.tar.gz'), cache_dir
            tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(File.join(cache_dir, '2.0.0.tar.gz')))
            tar_extract.rewind
            tar_extract.each do |entry|
              if entry.directory?
                FileUtils.mkdir_p File.join(cache_dir, entry.full_name)
              else
                FileUtils.mkdir_p File.join(cache_dir, File.dirname(entry.full_name))
                File.open(File.join(cache_dir, entry.full_name), 'wb') do |f|
                  f << entry.read
                end
              end
            end
            tar_extract.close
            FileUtils.rm File.join(cache_dir, '2.0.0.tar.gz')
          end
        end

        def valid?(ver)
          dir = File.join(cache_dir, ver)
          return false unless File.directory?(dir)
          return false unless File.directory?(File.join(dir, 'yardoc'))
          return false unless File.directory?(File.join(dir, 'yardoc-stdlib'))
          true
        end

        def versions
          dirs = Dir[File.join(cache_dir, '*')].map{|d| File.basename(d)}
          dirs.keep_if{|d| valid?(d)}
          dirs.sort{|a, b| Gem::Version.new(b) <=> Gem::Version.new(a)}
        end

        def best_match
          available = versions
          available.each do |v|
            return v if Gem::Version.new(v) <= Gem::Version.new(RUBY_VERSION)
          end
          return available.last
        end

        def yardoc_file(ver = best_match)
          raise ArgumentError.new("Invalid core yardoc version #{ver}") unless valid?(ver)
          File.join(cache_dir, ver, 'yardoc')
        end

        def yard_stdlib_file(ver = best_match)
          raise ArgumentError.new("Invalid core yardoc version #{ver}") unless valid?(ver)
          File.join(cache_dir, ver, 'yardoc-stdlib')
        end
      end
    end
  end
end
