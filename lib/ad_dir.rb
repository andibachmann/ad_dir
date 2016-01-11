require 'net/ldap'
require 'fix_utf'
require 'ad_dir/version'

# AdDir alllows you to talk with an ActiveDirectory in a 'active_record'
# like way.
#
# Initialize a AdDir connection by providing host, login credentials and
# a base dn.
#
#     AdDir.establish_connection(
#       host:     'my.nice.com',
#       base:     'dc=my,dc=nice,dc=com',
#       username: 'cn=manager,dc=example,dc=com',
#       password: 'opensesame'
#       )
#
# The main class is ''AdDir::Entry''. It supports all CRUD actions.
#
# For full details see {Entry}.
#
module AdDir
  class << self
    # Establishes a connection to the ActiveDirectory
    # running on `host` using the credentials `username`/`password`.
    #
    # The connection is a **`Net::LDAP.connection`**. As any ActiveDirectory is
    # always run with encrypted connections, the following options are preset:
    #
    #     port: 636
    #     encryption: :simple_tls
    #     auth_method: :simple
    #
    # (check out the `net-ldap` API for details).
    # @example Initialize a connection to an ActiveDirectory
    #     AdDir.establish_connection(
    #       host:     'my.nice.com',
    #       base:     'dc=my,dc=nice,dc=com',
    #       username: 'cn=manager,dc=example,dc=com',
    #       password: 'opensesame'
    #       )
    #
    def establish_connection(host:, username:, password:, base:)
      @connection = Net::LDAP.new(
        host: host, base: base,
        encryption: :simple_tls, port: 636,
        auth: {
          username: username, password: password,
          method: :simple }
      )
      @connection.bind
    end

    # Returns a Net::LDAP object (@see Net::LDAP ).
    # If no connection was established it raises a RuntimeError.
    def connection
      return @connection if @connection
      warn 'ERROR: Use \'AdDir#establish_connection\' first to connect \
to your Active Directory.'
      fail 'No connection set up!'
    end

    # Get the status of the last operation.
    # Alias/Shortcut for `AdDir.connection.get_operation_result`
    def last_op
      @connection && @connection.get_operation_result
    end
  end
end

require 'ad_dir/utilities'
require 'ad_dir/entry'
