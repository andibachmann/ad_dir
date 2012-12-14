# encoding: utf-8

require 'rspec'
require 'ad_dir'

include AdDir

require 'gibberish'
cipher = Gibberish::AES.new("This is ä nice & cool thing")
pproc = proc { cipher.decrypt("U2FsdGVkX18hklQQnNbFzcwenl6Ca9da+vmrqax8lyk=") }

require 'yaml'
ad_test = YAML.file_load('ad_test.yaml')

AdDir.connection = Net::LDAP.new(
  :host => "tin",
  :port => 636,
  :encryption => :simple_tls,
  :base => 'dc=d,dc=geo,dc=uzh,dc=ch',
  :auth => {
    :method =>   :simple,
    :username => "cn=administrator,cn=users,dc=d,dc=geo,dc=uzh,dc=ch",
    :password => pproc
  }
  )

