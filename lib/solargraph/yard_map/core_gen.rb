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
            generate_docs ruby_dir, tmp
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
