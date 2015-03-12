require 'net/ldap'
require 'ad_dir/version'

# AdDir alllows you to deal with an ActiveDirectory in a 'active_record' 
# like way.
#
# Initialize a AdDir connection by providing a Net::LDAP connection
#    AdDir.connection = Net::LDAP.new( 
#                         :host => "my.nice.com",
#                         :port => 636,
#                         :encryption => :simple_tls,
#                         :base => 'dc=geo,dc=uzh,dc=ch'
#                         :auth => {
#                           :method => "simple,
#                           :username => "cn=manager, dc=example, dc=com",
#                           :password => "opensesame"
#                       )
#
#  

module AdDir
  class << self
    attr_accessor :connection
  end
end

require 'ad_dir/utilities'
require 'ad_dir/entry'
