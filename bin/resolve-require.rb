def resolve_require(file)
  begin
    require file
    $LOAD_PATH.each { |path|
      ['', '.rb'].each { |ext|
        full = "#{path}/#{file}#{ext}"
        if File.file?(full)
          return full
        end
      }
    }
  rescue Exception => e
    # Ignore all exceptions
  end
  #Gem::Specification.all.each { |spec|
  #  full = "#{spec.gem_dir}/lib/#{file}.rb"
  #  if File.file?(full)
  #    return full
  #  end
  #}
  return nil
end

puts resolve_require(ARGV[0])
