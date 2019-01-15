require 'fileutils'
require 'tmpdir'
require 'pathname'

module Solargraph
  class YardMap
    # Tools for generating core documentation.
    #
    module CoreGen
      class << self
        # Generate documentation from the specified Ruby source directory.
        #
        # @param ruby_dir [String] The Ruby source directory
        # @param dest_dir [String] The destination directory for the yardocs
        # @return [void]
        def generate_docs ruby_dir, dest_dir
          path_name = Pathname.new(Dir.pwd).join(dest_dir).to_s
          FileUtils.mkdir_p path_name
          Dir.chdir(ruby_dir) do
            `yardoc --plugin coregen -b #{File.join(path_name, 'yardoc')} -n *.c`
            raise 'An error occurred generating the core yardoc.' unless $?.success?
            `yardoc -b #{File.join(path_name, 'yardoc-stdlib')} -n lib ext`
            raise 'An error occurred generating the stdlib yardoc.' unless $?.success?
          end
        end

        # Generate a gzip of documentation from the specified Ruby source
        # directory.
        #
        # This method is designed to generate the directory architecture that
        # YardMap core docs expect.
        #
        # @param ruby_dir [String] The Ruby source directory
        # @param ver_name [String, nil] The version name
        # @param dest_dir [String] The destination directory
        # @return [void]
        def generate_gzip ruby_dir, ver_name = nil, dest_dir = Dir.pwd
          Dir.mktmpdir do |tmp|
            base_name = ver_name || begin
              match = ruby_dir.match(/\d+\.\d+\.\d+$/)
              raise "Unable to determine version name from #{ruby_dir}" if match.nil?
              match[0]
            end
            path_name = Pathname.new(tmp).join(base_name).to_s
            generate_docs ruby_dir, path_name
            `cd #{tmp} && tar -cf #{base_name}.tar *`
            raise 'An error occurred generating the documentation tar.' unless $?.success?
            `gzip #{path_name}.tar`
            raise 'An error occurred generating the documentation gzip.' unless $?.success?
            FileUtils.cp "#{path_name}.tar.gz", Pathname.new(dest_dir).join("#{base_name}.tar.gz").to_s
          end
        end
      end
    end
  end
end
