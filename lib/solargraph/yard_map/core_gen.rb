require 'fileutils'
require 'tmpdir'

module Solargraph
  class YardMap
    module CoreGen
      class << self
        def generate_core ruby_dir, dest_dir
          FileUtils.mkdir_p dest_dir
          Dir.chdir(ruby_dir) do
            `yardoc -b #{File.join(dest_dir, 'yardoc')} -n *.c`
            raise 'An error occurred generating the core yardoc.' unless $?.zero?
            `yardoc -b #{File.join(dest_dir, 'yardoc-stdlib')} -n lib ext`
            raise 'An error occurred generating the stdlib yardoc.' unless $?.zero?
          end
        end

        def generate_gzip ruby_dir, zip_name
          Dir.mktmpdir do |tmp|
            zip_name += '.tar.gz' unless zip_name.end_with?('.tar.gz')
            base_name = zip_name[0..-8]
            generate_core ruby_dir, tmp
            `tar -cf #{base_name}.tar #{tmp}/*`
            raise 'An error occurred generating the documentation tar.' unless $?.zero?
            `gzip #{base_name}.tar`
            raise 'An error occurred generating the documentation gzip.' unless $?.zero?
          end
        end
      end
    end
  end
end
