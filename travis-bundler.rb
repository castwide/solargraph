#!/usr/bin/env ruby

# Travis uses this script to select which version of bundler to install for
# each job.

if RUBY_VERSION =~ /^2\.(1|2)\./
  exec "gem install bundler -v '< 2'"
else
  exec "gem install bundler"
end
