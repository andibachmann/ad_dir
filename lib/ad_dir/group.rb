module AdDir
  # Group
  #
  class Group < AdDir::Entry
    self.tree_base   = 'ou=groups,dc=d,dc=geo,dc=uzh,dc=ch'
    self.primary_key = :samaccountname

    @objectcategory = 'group'

    # The name of the group (i.e. the samaccountname)
    #
    def name
      samaccountname
    end

    # Return all users being member of this group.
    def users
      members.map { |dn| User.select_dn(dn) }
    end

    # Find the 'primary user' of the group
    # If this is a normal group 'nil' is returned.
    def primary_user
      @primary_user ||= AdDir::User.find_by_primarygroupid(
        objectsid_decoded.split('-').last
      )
    end

    # Returns true if the group is a primary group.
    # @return [Boolean]
    def primary_group?
      !primary_user.nil?
    end

    # Returns the DNs of all user.
    # @note If the group is a **primary group** **`:member`**
    #    is empty (and mutually, the primary group is not present in
    #    the `:memberof` attribute of a {::User} object).
    #
    # @see http://support.microsoft.com/en-us/kb/275523
    def members
      return @ldap_entry[:member] if attribute_present?(:member)
      @ldap_entry[:member] = []
    end

    # Return an array of the members' usernames.
    #
    def members_usernames
      # users.map { |u| u.username }.sort
      users.map(&:username).sort
    end

    alias_method :users_usernames, :members_usernames

    # Add a <tt>user</tt>
    #
    def add_user(user)
      unless members.include?(user.dn)
        self[:member] << user.dn
        save
      end
      users
    end

    # Remove a <tt>user</tt>
    #
    def remove_user(user)
      # modify_users(members - [user.dn]) if members.include?(user.dn)
      if members.include?(user.dn)
        self[:member] -= [user.dn]
        save
      end
      users
    end

    def modify_users(new_users)
      warn "changing 'new_users' '#{new_users}'"
      warn "changing 'new_users' '#{changes[:member]}'"
      modify(member: [changes[:member], new_users])
    end
  end
end
