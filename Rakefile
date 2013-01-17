# encoding: utf-8

require 'rubygems'

begin
  require 'bundler'
rescue LoadError => e
  warn e.message
  warn "Run `gem install bundler` to install Bundler."
  exit -1
end

begin
  Bundler.setup(:development)
rescue Bundler::BundlerError => e
  warn e.message
  warn "Run `bundle install` to install missing gems."
  exit e.status_code
end

require 'rake'

require 'rubygems/tasks'
Gem::Tasks.new()

require 'rdoc/task'
RDoc::Task.new do |rdoc|
  rdoc.title = "ad_dir"
end
task :doc => :rdoc

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new

task :test    => :spec
task :default => :spec

desc "Publish gem to the GIUZ gemserver"
task :pushgiuz do
  project = Gem::Tasks::Project.new
  repo_dir = "/web/gems/gems/"
  if File.exist?(repo_dir)
    cp File.join(project.class::PKG_DIR, project.gemspec.file_name), repo_dir
  else
    warn "ERROR: Can't reach #{repo_dir}!"
    warn "  Log in to a machine that mounts #{repo_dir} and do:"
    warn "cp #{File.join(project.class::PKG_DIR, project.gemspec.file_name)} #{repo_dir}"
    exit 1
  end
  # 
  if `uname -s` == "SunOS"
    sh "cd #{repo_dir} && rake"
  else
    warn "ERROR: Could not rebuild the gem repo index!"
    warn "  Try on a SunOS machine:"
    warn "cd #{repo_dir} && rake"
    exit 2
  end
end


desc "rebuild without SCM-checks"
task :rebuild do
  # get the project for this gem
  project = Gem::Tasks::Project.new
  # build the gem with the standard 'gem build' command
  # and move the result to the PKG_DIR
  builder = Gem::Builder.new(project.gemspec)
  mv builder.build, project.class::PKG_DIR
end
