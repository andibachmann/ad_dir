# encoding: utf-8

require 'examples/group'

class User < AdDir::Entry

  @base_dn = 'ou=people,dc=d,dc=geo,dc=uzh,dc=ch'

  def user_name
    @attributes[:samaccountname].first
  end

  # Return an array of the Group objects the user is member of.
  #
  def groups
    @attributes[:memberof].map { |dn|
      Group.select_dn(dn)
    }
  end

  # Return an array of group names.
  # 
  def group_names
    # In order to avoid multiple ldap-connection requests we do not iterate
    # over `.groups` (AKA @attributes[:memberof] but extract the names from
    # the DNs and return the CN part.
    @attributes[:memberof].
      delete_if { |dn| dn =~ /Domain\ Users/ }.
      map { |dn|  dn.split(",").first.split("=").last.downcase }
  end

  # Add a group
  # 
  def add_group(group)
    group.add_user(self) if group.users.include?(self)
  end

  # Delete a group
  #
  def delete_group(group)
    
  end
end
