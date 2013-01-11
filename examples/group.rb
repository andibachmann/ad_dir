# encoding: utf-8
#
require 'examples/user'

class Group < AdDir::Entry

  @base_dn = 'ou=groups,dc=d,dc=geo,dc=uzh,dc=ch'

  # Return all users being member of this group.
  # 
  def users
    @attributes[:member].map { |dn|
      User.select_dn(dn)
    }
  end

  # Return the DNs of all user (with all downcase chars)
  # 
  def member_dns
    @member_dns ||= @attributes[:member].map { |dn| dn.downcase }
  end
  
  # Add a <tt>user</tt>
  #
  def add_user(user)
    unless member_dns.include?(user.dn)
      modify_users( member_dns << user.dn )
    end
  end

  # Remove a <tt>user</tt>
  #
  def remove_user(user)
    if member_dns.include?(user.dn)
      modify_users( member_dns - [user.dn])
    end
  end

  def modify_users(new_users)
    @attributes[:member] = new_users if modify({:member => new_users})
  end

end
