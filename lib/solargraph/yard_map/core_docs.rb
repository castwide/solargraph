require 'net/http'
require 'uri'
require 'json'
require 'fileutils'

module Solargraph
  class YardMap
    module CoreDocs
      class SourceNotAvailableError < StandardError;end
      
      SOURCE = 'http://solargraph.org/download'

      class << self
        def cache_dir
          @cache_dir ||= File.join(Dir.home, '.solargraph', 'cache')
        end

        # Solargraph installs Ruby 2.2.2 documentation to ensure minimum functionality.
        def require_minimum
          FileUtils.mkdir_p cache_dir
          version_dir = File.join(cache_dir, '2.2.2')
          unless File.exist?(version_dir)
            FileUtils.cp File.join(Solargraph::YARDOC_PATH, '2.2.2.tar.gz'), cache_dir
            install_archive File.join(cache_dir, '2.2.2.tar.gz')
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
          dirs.sort!{|a, b| Gem::Version.new(b) <=> Gem::Version.new(a)}
          dirs
        end

        def best_match
          available = versions
          available.each do |v|
            return v if Gem::Version.new(v) <= Gem::Version.new(RUBY_VERSION)
          end
          return available.last
        end

        def available
          uri = URI.parse("#{SOURCE}/versions.json")
          response = Net::HTTP.get_response(uri)
          obj = JSON.parse(response.body)
          raise SourceNotAvailableError.new("Error connecting to #{SOURCE}") unless obj['status'] == 'ok'
          obj['cores']
        end

        def best_download
          rv = Gem::Version.new(RUBY_VERSION)
          available.each do |ver|
            return ver if Gem::Version.new(ver) <= rv
          end
          obj['cores'].last
        end

        def yardoc_file(ver = best_match)
          raise ArgumentError.new("Invalid core yardoc version #{ver}") unless valid?(ver)
          File.join(cache_dir, ver, 'yardoc')
        end

        def yard_stdlib_file(ver = best_match)
          raise ArgumentError.new("Invalid core yardoc version #{ver}") unless valid?(ver)
          File.join(cache_dir, ver, 'yardoc-stdlib')
        end

        def download version
          FileUtils.mkdir_p cache_dir
          uri = URI.parse("http://solargraph.org/download/#{version}.tar.gz")
          response = Net::HTTP.get_response(uri)
          zipfile = File.join(cache_dir, "#{version}.tar.gz")
          File.binwrite zipfile, response.body
          install_archive zipfile
        end

        def clear
          FileUtils.rm_rf cache_dir, secure: true
          require_minimum
        end

        private

        def install_archive filename
          tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(filename))
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
        end
      end
    end
  end
end
