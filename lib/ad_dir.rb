require 'net/ldap'
require 'ad_dir/version'

# AdDir alllows you to talk with an ActiveDirectory in a 'active_record' 
# like way.
#
# Initialize a AdDir connection by providing host, login credentials and
# (optionally) a base dn.
#
#    AdDir.establish_connection(
#                         host:     "my.nice.com",
#                         base:     "dc=my,dc=nice,dc=com",
#                         username: "cn=manager, dc=example, dc=com",
#                         password: "opensesame"
#                       )
#
#  

module AdDir
  class << self
    attr_reader :connection
    
    # #establish_connection establishes a connection to the ActiveDirectory
    # running on `host` using the credentials `username`/`password`.
    #
    # The connection is a ++Net::LDAP.connection++. As any ActiveDirectory is
    # always run with encrypted connections, these options are fixed and set
    # by default. 
    # I.e. :port => 636, :encryption => :simple_tls, :auth_method => :simple.
    # (check out the `net-ldap` API for details).
    # 
    # 
    def establish_connection(host:, username:, password:, base:)
      @connection = Net::LDAP.new( 
        :host => host,
        :port => 636,
        :base => base,
        :encryption => :simple_tls,
        :auth => { 
          method: :simple, 
          :username => username, 
          :password => password
        }
        )
      @connection.bind
    end
    
  end
end

require 'ad_dir/utilities'
require 'ad_dir/entry'
