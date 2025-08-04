require 'rake'
require 'bundler/gem_tasks'
require 'fileutils'
require 'open3'

desc "Open a Pry session preloaded with this library"
task :console do
  sh "pry -I lib -r solargraph.rb"
end

desc "Run the type checker"
task typecheck: [:typecheck_typed]

desc "Run the type checker at typed level - return code issues provable without annotations being correct"
task :typecheck_typed do
  sh "bundle exec solargraph typecheck --level typed"
end

desc "Run the type checker at strict level - report issues using type annotations"
task :typecheck_strict do
  sh "bundle exec solargraph typecheck --level strict"
end

desc "Run the type checker at strong level - enforce that type annotations exist"
task :typecheck_strong do
  sh "bundle exec solargraph typecheck --level strong"
end

desc "Run the type checker at alpha level - run high-false-alarm checks"
task :typecheck_alpha do
  sh "bundle exec solargraph typecheck --level alpha"
end

desc "Run RSpec tests"
task :spec do
  warn 'starting spec'
  sh 'TEST_COVERAGE_COMMAND_NAME=full-new bundle exec rspec' #  --profile'
  warn 'ending spec'
  # move coverage/full-new to coverage/full on success so that we
  # always have the last successful run's 'coverage info
  FileUtils.rm_rf('coverage/full')
  FileUtils.mv('coverage/full-new', 'coverage/full')
end

# @return [Boolean, nil] returns `true` if the command exits with
#  status zero.  `false` if the exit status is a non-zero integer.
#  `nil` if the command could not execute.
def undercover
  simplecov_collate
  cmd = 'bundle exec undercover ' \
        '--simplecov coverage/combined/coverage.json ' \
        '--exclude-files "Rakefile,spec/*,spec/**/*,lib/solargraph/version.rb" ' \
        '--compare origin/master'
  output, status = Bundler.with_unbundled_env do
    Process.spawn(cmd)
  end
  puts output
  $stdout.flush
  status
rescue StandardError => e
  warn "hit error: #{e.message}"
  warn "Backtrace:\n#{e.backtrace.join("\n")}"
  warn "output: #{output}"
  puts "Flushing"
  $stdout.flush
  raise
end

desc "Check PR coverage"
task :undercover do
  raise "Undercover failed" unless undercover
end

desc "Branch-focused fast-feedback quality/spec/coverage checks"
task test: %i[overcommit spec_failed undercover_no_fail] do
  # run these last tasks manually so that rake doesn't optimize
  # undercover away
  Rake::Task['spec'].invoke
  undercover
  Rake::Task['overcommit'].invoke
  Rake::Task['typecheck'].invoke
  Rake::Task['typecheck_strict'].invoke
  Rake::Task['typecheck_strong'].invoke
  Rake::Task['typecheck_alpha'].invoke
end

desc "Re-run failed specs"
task :spec_failed do
  sh 'TEST_COVERAGE_COMMAND_NAME=next-failure bundle exec rspec --next-failure'
end

desc "Run undercover and show output without failing the task if it fails"
task :undercover_no_fail do
  Rake::Task["undercover"].invoke
rescue StandardError
  puts "Undercover failed, but continuing with other tasks."
end

# @return [void]
def simplecov_collate
  require 'simplecov'
  require 'simplecov-lcov'
  require 'undercover/simplecov_formatter'

  SimpleCov.collate(Dir["coverage/{next-failure,full,ad-hoc}/.resultset.json"]) do
    cname = 'combined'
    command_name cname
    new_dir = File.join('coverage', cname)
    coverage_dir new_dir

    formatter \
      SimpleCov::Formatter::MultiFormatter
        .new([
               SimpleCov::Formatter::HTMLFormatter,
               SimpleCov::Formatter::Undercover,
               SimpleCov::Formatter::LcovFormatter
             ])
    SimpleCov::Formatter::LcovFormatter.config.report_with_single_file = true
  end
  puts "Simplecov collated results into coverage/combined/.resultset.json"
rescue StandardError => e
  puts "Simplecov collate failed: #{e.message}"
ensure
  $stdout.flush
end

desc 'Add incremental coverage for rapid iteration with undercover'
task :simplecov_collate do
  simplecov_collate
end

desc "Show quality checks on this development branch so far, including any staged files"
task :overcommit do
  # OVERCOMMIT_DEBUG=1 will show more detail
  sh 'SOLARGRAPH_ASSERTS=on bundle exec overcommit --run --diff origin/master'
end
