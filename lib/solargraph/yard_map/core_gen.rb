require 'fileutils'
require 'tmpdir'
require 'pathname'

module Solargraph
  class YardMap
    module CoreGen
      class << self
        def generate_core ruby_dir, dest_dir
          FileUtils.mkdir_p dest_dir
          Dir.chdir(ruby_dir) do
            `yardoc -b #{File.join(dest_dir, 'yardoc')} -n *.c`
            raise 'An error occurred generating the core yardoc.' unless $?.success?
            `yardoc -b #{File.join(dest_dir, 'yardoc-stdlib')} -n lib ext`
            raise 'An error occurred generating the stdlib yardoc.' unless $?.success?
          end
        end

        def generate_gzip ruby_dir, zip_name
          Dir.mktmpdir do |tmp|
            zip_name += '.tar.gz' unless zip_name.end_with?('.tar.gz')
            base_name = zip_name[0..-8]
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
