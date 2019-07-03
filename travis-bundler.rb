#!/usr/bin/env ruby

# Travis uses this script to select which version of bundler to install for
# each job.

if RUBY_VERSION =~ /^2\.(1|2)\./
  `gem install bundler -v '< 2'`
else
  `gem update --system`
  `gem install bundler`
end
