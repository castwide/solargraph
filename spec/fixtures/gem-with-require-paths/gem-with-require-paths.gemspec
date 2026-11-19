Gem::Specification.new do |s|
  s.name          = 'gem-with-require-paths'
  s.version       = '1.0.0'
  s.required_ruby_version = '>= 3.1'
  s.metadata['rubygems_mfa_required'] = 'true'
  s.require_paths = ['other']
end
