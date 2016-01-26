# encoding: utf-8

require 'rspec'
require 'ad_dir'
require 'yaml'

require 'support/load_factories'

def my_ldap_entries
  @my_ldap_entries ||= load_data
end

def get_ad_dir_entry(name)
  AdDir::Entry.from_ldap_entry(@my_ldap_entries[name])
end

def get_my_test(klass, name)
  Object.const_get(klass).from_ldap_entry(my_ldap_entries[name])
end

# puts "env['integration'] = '#{ENV['INTEGRATION']}'"
def integration_setup
  AdDir.establish_connection(YAML.load_file('spec/ad_test.yaml'))
  AdDir::User.tree_base = 'ou=people,'+AdDir.connection.base
  AdDir::Group.tree_base = 'ou=groups,'+AdDir.connection.base
end

RSpec.configure do |c|
  c.filter_run focus: true
  c.run_all_when_everything_filtered = true
  if ENV['INTEGRATION']
    c.filter_run(integration: true)
  end
end
