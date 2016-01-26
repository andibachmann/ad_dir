# User Model

module AdDir
  class User < Entry
    extend CommonUserAttributes
    
    # Defines aliases for common attributes.
    # 
    map_common_attrs(
      lastname:  :sn,
      firstname: :givenname,
      username:  :samaccountname,
      email:     :mail
    )
   
    #
    self.tree_base = nil
    
    # This is used for building any filter search for a User.
    # `(objectcategory=#{@objectcategor})`.
    @objectcategory = 'person'

    # Encodes and sets the provided clear text password
    # @see AdDir::Utitlities.unicodepwd
    #
    def password=(val)
      @ldap_entry[:unicodePwd] = AdDir::Utilities.unicodepwd(val)
    end

    # Decodes the binary `:useraccountcontrol` attribute
    # @return [Hash<String>] a hash containing names and hex-values of
    #    the properties set.
    def uac_decoded
      AdDir::Utilities.uac_decode(@ldap_entry[:useraccountcontrol].first)
    end
 
    # Returns the primary_group of the user.
    # The attribute `:primarygroupid` to
    # construct the `primarygroupSID` and retrieve it from the AD.
    def primary_group
      @primary_group ||= Group.find_by_objectsid(primary_group_sid)
    end

    # The SID of the primary group is based on the User's SID
    #
    # The last element of the user's SID is replaced with the value of
    # `:primarygroupid`
    #
    # @example
    #    user = GiuzAd::User.find('jdoe')
    #    user.objectsid_decoded
    #    # => "S-1-5-21-15115519-869956856-4114428504-1105"
    #    user.primarygroupid
    #    # => "3912"
    #    user.primary_group_sid
    #    # => "S-1-5-21-15115519-869956856-4114428504-3912"
    #
    def primary_group_sid
      @primary_group_sid ||= [
        objectsid_decoded.split('-')[0...-1], @ldap_entry[:primarygroupid]
      ].join('-')
    end

    # Return an array of the Group objects the user is member of.
    # @return [Array<Group>] the groups the user is member of.
    def groups
      self[:memberof].map { |dn| Group.select_dn(dn) }
    end

    # Return an array of group names.
    # @return [Array<String>] the group names
    def group_names
      # In order to avoid multiple ldap-connection requests we do not
      # iterate over `.groups` (AKA @attributes[:memberof] but extract
      # the names from the DNs and return the CN part.
      @ldap_entry[:memberof].map do |dn| 
        dn.split(',').first.split('=').last 
      end.sort
    end

    # Explicit method to prevent User to fail
    # when no group is defined. The original `Net::LDAP::Entry#[](name)`
    # method silently adds a new attribute when it is not available.
    # However the calling `some_LDAP_Entry_instance.<non_existing_attr>`
    # fails with a `No Method Error`.
    # A user without groups has no :memberof attributes, but we silently
    # add it.
    def memberof
      return @ldap_entry[:membeof] if attribute_present?(:memberof)
      @ldap_entry[:memberof] = []
    end

    # Add a group
    #
    def add_group(group)
      return if memberof.include?(group.dn)
      if group.add_user(self)
        warn "reloading..."
        warn "changes = > '#{changes}'"
        reload!
        memberof
      else
        false
      end
    end

    # Remove a group
    #
    def remove_group(group)
      if group_names.include?(group.name)
        group.remove_user(self)
        @ldap_entry[:memberof].delete_if { |dn| dn == group.dn }
      end
      # return the new list of groups
      groups
    end
  
  end
end
