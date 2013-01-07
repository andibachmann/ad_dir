# encoding: utf-8

require 'rspec'
require 'ad_dir'

include AdDir

# require 'gibberish'
# cipher = Gibberish::AES.new("This is ä nice & cool thing")
# pproc = proc { cipher.decrypt("U2FsdGVkX18hklQQnNbFzcwenl6Ca9da+vmrqax8lyk=") }

require 'yaml'
AdDir.connection = Net::LDAP.new(YAML.load_file('spec/ad_test.yaml'))

# examples
# Add the examples directory to the LOAD_PATH
$:.unshift File.join(File.dirname(__FILE__),"..")
