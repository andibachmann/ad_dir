require 'bundler/gem_tasks'

require 'rubocop/rake_task'
RuboCop::RakeTask.new

namespace 'rubocop' do
  desc 'fix double quotes [Style/StringLiterals]'
  task :fix_quotes do
    sh 'bundle exec rubocop --only Style/StringLiterals -a'
  end

  desc 'Fix trailing whitespaces [Style/TrailingWhitespace]'
  task :fix_whitespace do
    sh 'bundle exec rubocop --auto-correct -c .rubocop-spaces.yml'
  end
end

require 'yard'
desc 'Run yarddoc for the source'
YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb', '-', 'README.md']
  t.options = ['--markup=markdown', '--exclude=play.rb', '--exclude=fix_utf.rb']
  t.stats_options = ['--list-undoc']
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task default: :spec

namespace :spec do
  desc 'Run only base specs withouth INTEGRATION'
  task base: :spec

  desc 'integration'
  task :integration do
    ENV['INTEGRATION'] = '1'
    # Rake::Task[:spec].execute
    sh "rspec --pattern 'integration/**/*_spec.rb'"
  end
end

desc 'rebuild without SCM-checks'
task :rebuild do
  # get the project for this gem
  project = Gem::Tasks::Project.new
  # build the gem with the standard 'gem build' command
  # and move the result to the PKG_DIR
  builder = Gem::Builder.new(project.gemspec)
  mv builder.build, project.class::PKG_DIR
end

desc 'console_integr'
task :console_integr do
  $LOAD_PATH.unshift('spec/')
  $LOAD_PATH.unshift('lib/')
  ENV['INTEGRATION'] = '1'
  require 'irb'
  require 'irb/completion'
  require 'ad_dir'
  require 'spec_helper'      #
  require 'real_dir_helper'  # create_user, create_group helpers
  ARGV.clear
  IRB.start
end
