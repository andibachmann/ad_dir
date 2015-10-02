# -*- encoding: utf-8 -*-

require File.expand_path('../lib/ad_dir/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "ad_dir"
  gem.version       = AdDir::VERSION
  gem.summary       = %q{net-ldap wrapper for GIUZ ActiveDirectory}
  gem.description   = %q{Base on net-ldap this gem allows you to build a simple User/Group abstraction of our ActiveDirectory}
  gem.license       = "MIT"
  gem.authors       = ["Andi Bachmann"]
  gem.email         = "andi.bachmann@geo.uzh.ch"
  gem.homepage      = "https://rubygems.org/gems/ad_dir"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_development_dependency 'bundler', '~> 1.6'
  gem.add_development_dependency 'rake', '~> 10.4'
  gem.add_development_dependency 'yard', '~> 0.8'
  gem.add_development_dependency 'wirble', '> 0.1'
  gem.add_development_dependency 'rspec', '~> 3.2'
  gem.add_development_dependency 'rubygems-tasks', "~> 0.2"

  gem.add_dependency 'net-ldap', '~> 0.11'
end
