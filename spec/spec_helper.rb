# encoding: utf-8

require 'rspec'
require 'ad_dir'

# include AdDir
# require 'yaml'
# AdDir.connection = Net::LDAP.new(YAML.load_file('spec/ad_test.yaml'))

# examples
# Add the examples directory to the LOAD_PATH
$:.unshift File.join(File.dirname(__FILE__),"..")

require 'support/load_factories'
