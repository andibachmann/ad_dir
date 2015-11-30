# encoding: utf-8
#
require 'examples/user'

class Group < AdDir::Entry

  @base_dn = 'ou=groups,dc=d,dc=geo,dc=uzh,dc=ch'

  # The name of the group (i.e. the samaccountname)
  #
  def name
    @attributes[:samaccountname].first
  end


  # Return all users being member of this group.
  #
  def users
    members.map { |dn|
      User.select_dn(dn)
    }
  end

  # Return the DNs of all user (with all downcase chars)
  #
  def members
    @attributes[:member] ||= []
    @attributes[:member].map { |dn| dn.downcase }
  end

  # Add a <tt>user</tt>
  #
  def add_user(user)
    unless members.include?(user.dn)
      modify_users( members << user.dn )
    end
  end

  # Remove a <tt>user</tt>
  #
  def remove_user(user)
    if members.include?(user.dn)
      modify_users( members - [user.dn])
    end
  end

  def modify_users(new_users)
    @attributes[:member] = new_users if modify({:member => new_users})
  end

end
