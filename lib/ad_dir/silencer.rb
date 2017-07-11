# Used to instrument the net-ldap connection.
# It silences any annoying messages
#   not verifying SSL hostname of LDAPS server '#{host}:#{port}'"
# https://github.com/ruby-ldap/ruby-net-ldap/blob/release-0.16.0/lib/net/ldap/connection.rb, line 58
# This was introduced in net-ldap 0.16
class Silencer
  def instrument(_event, payload)
    begin
      original_stderr = $stderr.clone
      $stderr.reopen(File.new('/dev/null', 'w'))
      result = yield(payload)
    rescue StandardError => e
      $stderr.reopen(original_stderr)
      raise e
    ensure
      $stderr.reopen(original_stderr)
    end
    result
  end  
end
