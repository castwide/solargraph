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
        def generate_core ruby_dir, dest_dir
          FileUtils.mkdir_p dest_dir
          Dir.chdir(ruby_dir) do
            `yardoc --plugin coregen -b #{File.join(dest_dir, 'yardoc')} -n *.c`
            raise 'An error occurred generating the core yardoc.' unless $?.success?
            `yardoc -b #{File.join(dest_dir, 'yardoc-stdlib')} -n lib ext`
            raise 'An error occurred generating the stdlib yardoc.' unless $?.success?
          end
        end

        # Generate a gzip of documentation from the specified Ruby source directory.
        #
        # @param ruby_dir [String] The Ruby source directory
        # @param gzip_name [String] The gzip file name
        # @return [void]
        def generate_gzip ruby_dir, gzip_name
          Dir.mktmpdir do |tmp|
            gzip_name += '.tar.gz' unless gzip_name.end_with?('.tar.gz')
            base_name = gzip_name[0..-8]
            path_name = Pathname.new(Dir.pwd).join(base_name).to_s
            generate_core ruby_dir, tmp
            `cd #{tmp} && tar -cf #{path_name}.tar *`
            raise 'An error occurred generating the documentation tar.' unless $?.success?
            `gzip #{path_name}.tar`
            raise 'An error occurred generating the documentation gzip.' unless $?.success?
          end
        end
      end
    end
  end
end
