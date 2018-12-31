require 'net/http'
require 'uri'
require 'json'
require 'fileutils'

module Solargraph
  class YardMap
    # Tools for managing core documentation.
    #
    module CoreDocs
      SOURCE = 'https://solargraph.org/download'
      DEFAULT = '2.2.2'

      class << self
        # The directory where core documentation is installed.
        #
        # @return [String]
        def cache_dir
          @cache_dir ||= ENV["SOLARGRAPH_CACHE"] || File.join(Dir.home, '.solargraph', 'cache')
        end

        # Ensure installation of minimum documentation.
        #
        # @return [void]
        def require_minimum
          return unless best_match.nil?
          FileUtils.mkdir_p cache_dir
          FileUtils.cp File.join(Solargraph::YARDOC_PATH, "#{DEFAULT}.tar.gz"), cache_dir
          install_archive File.join(cache_dir, "#{DEFAULT}.tar.gz")
        end

        # True if core documentation is installed for the specified version
        # number.
        #
        # @param ver [String] The version number to check
        # @return [Boolean]
        def valid?(ver)
          dir = File.join(cache_dir, ver)
          return false unless File.directory?(dir)
          return false unless File.directory?(File.join(dir, 'yardoc'))
          return false unless File.directory?(File.join(dir, 'yardoc-stdlib'))
          true
        end

        # Get a list of version numbers for currently installed core
        # documentation.
        #
        # @return [Array<String>] The installed version numbers
        def versions
          dirs = Dir[File.join(cache_dir, '*')].map{|d| File.basename(d)}
          dirs.keep_if{|d| valid?(d)}
          dirs.sort!{|a, b| Gem::Version.new(b) <=> Gem::Version.new(a)}
          dirs
        end

        # Get the version number of the installed core documentation that is
        # the closest match for the current Ruby version.
        #
        # @return [String] The closest match
        def best_match
          avail = versions
          cur = Gem::Version.new(RUBY_VERSION)
          avail.each do |v|
            return v if Gem::Version.new(v) <= cur
          end
          avail.last
        end

        # Get a list of core documentation versions that are available for
        # download.
        #
        # @return [Array<String>] The version numbers
        def available
          uri = URI.parse("#{SOURCE}/versions.json")
          response = Net::HTTP.get_response(uri)
          obj = JSON.parse(response.body)
          raise SourceNotAvailableError, "Error connecting to #{SOURCE}" unless obj['status'] == 'ok'
          obj['cores']
        end

        # Get the version number of core documentation available for download
        # that is the closest match for the current Ruby version.
        #
        # @return [String] The version number of the best match
        def best_download
          rv = Gem::Version.new(RUBY_VERSION)
          available.each do |ver|
            return ver if Gem::Version.new(ver) <= rv
          end
          obj['cores'].last
        end

        # Get the path to a yardoc file for Ruby core documentation.
        #
        # @param ver [String] The version number (best match is default)
        # @return [String] The path to the yardoc
        def yardoc_file(ver = best_match)
          raise ArgumentError, "Invalid core yardoc version #{ver}" unless valid?(ver)
          File.join(cache_dir, ver, 'yardoc')
        end

        # Get the path to a yardoc file for Ruby stdlib documentation.
        #
        # @param ver [String] The version number (best match is default)
        # @return [String] The path to the yardoc
        def yard_stdlib_file(ver = best_match)
          raise ArgumentError, "Invalid core yardoc version #{ver}" unless valid?(ver)
          File.join(cache_dir, ver, 'yardoc-stdlib')
        end

        # Download the specified version of core documentation.
        #
        # @param version [String]
        # @return [void]
        def download version
          FileUtils.mkdir_p cache_dir
          uri = URI.parse("#{SOURCE}/#{version}.tar.gz")
          response = Net::HTTP.get_response(uri)
          zipfile = File.join(cache_dir, "#{version}.tar.gz")
          File.binwrite zipfile, response.body
          install_archive zipfile
        end

        # Reset the core documentation cache to the minimum requirement.
        #
        # @return [void]
        def clear
          FileUtils.rm_rf cache_dir, secure: true
          require_minimum
        end

        private

        # Extract the specified archive to the core cache directory.
        #
        # @param filename [String]
        # @return [void]
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
