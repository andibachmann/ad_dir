# encoding: utf-8

require 'examples/group'

class User < AdDir::Entry

  @base_dn = 'ou=people,dc=d,dc=geo,dc=uzh,dc=ch'

  def user_name
    @attributes[:samaccountname].first
  end

  def primary_group
    @primary_group ||= Group.find_by_objectsid(primarygroupsid)
  end

  def primary_group_name
    primary_group.name
  end

  # 
  # The SID of the primary group is based on the User's SID
  #  The last element of the user's SID is replaced with the value of
  #  :primarygroupid
  def primarygroupsid
    @primarygroupsid ||= [
      objectsid.split("-")[0...-1],
      @attributes[:primarygroupid].first
        ].flatten.join("-")
  end

  # Return an array of the Group objects the user is member of.
  #
  def groups
    @attributes[:memberof].map { |dn|
      Group.select_dn(dn)
    }
  end

  def last_logon
    to_datetime(@attributes[:lastlogon].first)
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
    group.add_user(self) unless group_names.include?(group.name)
  end

  # Remove a group
  #
  def remove_group(group)
    group.remove_user(self) if group_names.include?(group.name)
  end
end
