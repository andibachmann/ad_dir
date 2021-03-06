# -*- encoding: utf-8 -*-

require File.expand_path('../lib/ad_dir/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = 'ad_dir'
  gem.version       = AdDir::VERSION
  gem.summary       = %(net-ldap wrapper for ActiveDirectory)
  gem.description   = %(Based on net-ldap this gem is a simple wrapper that \
behaves like ActiveRecord.)
  gem.license       = 'MIT'
  gem.authors       = ['Andi Bachmann']
  gem.email         = 'andi.bachmann@geo.uzh.ch'
  gem.homepage      = 'https://rubygems.org/gems/ad_dir'

  gem.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_development_dependency 'bundler'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'yard'
  gem.add_development_dependency 'wirble'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'rubygems-tasks'
  gem.add_development_dependency('rubocop', '> 0.28')

  gem.add_dependency 'net-ldap', '~> 0.16'
end
