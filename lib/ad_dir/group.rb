module AdDir
  # **`AdDir::Group`** models a 'Group' entry in an Active Directory.
  #
  # For basic CRUD operations see {AdDir::Entry}. In additon to these
  # {AdDir::Group} offers methods to list and managed {AdDir::User}
  # relationships.
  #
  # ## List users belonging to a group
  #
  # * **`members`** list of members' DNs
  #
  # ```
  #    mygrp = AdDir::Group.find('lpadmin')
  #    mygrp.members
  #    # => ["CN=John Doe",OU=people,ou....", "CN=Betty...", ...]
  # ```
  #
  # * **`users`** => Array of {User} objects
  #
  # ```
  #    mygrp.users
  #    # => [#<AdDir::User dn: "CN=John Doe",..." ...>, <#AdDir::User dn: ..]
  # ```
  #
  # * **`users_usernames`** lists the username of each member
  #
  # ```
  #    mygrp.users_usernames
  #    # => ["jdoe", "bblue", "shhinter"]
  # ```
  #
  # ## Modify User Relationship
  #
  # **Note**: Contrary to modifications of 'normal' attributes
  # modifications of user relationships are instantly saved!
  #
  # ### Add User
  #
  # ```
  #   jdoe = AdDir::User.find('jdoe')
  #   mygrp.add_user(jdoe)
  # ```
  #
  # ### Removing a user
  #
  # ```
  #   jdoe = AdDir::User.find('jdoe')
  #   mygrp.remove_user(jdoe)
  # ```
  #
  class Group < AdDir::Entry
    self.tree_base   = 'ou=groups,dc=d,dc=geo,dc=uzh,dc=ch'
    self.primary_key = :samaccountname

    # Used to efficiently filter Group entries in ActiveDirectory.
    OBJECTCATEGORY = 'group'

    # Get the correct `User` class.
    # When querying and managing users subclasses of this class
    # have to get the correct User model.
    # @example
    #
    # ```
    #   module B
    #     class User < AdDir::User
    #     end
    #
    #     class Group < AdDir::Group
    #     end
    #   end
    #
    #   g = B::Group.user_klass
    #   => B::User
    # ```
    # If there is no class `B::User` any group related methods will fail.
    #
    # If you want to override this method simply set the class instance
    # variable `@user_klass` to your custom group class:
    #
    # ```
    #   module B
    #     class Group < AdDir::Group
    #       @user_klass = C::User
    #     end
    #   end
    #   #
    #   B::Group.user_klass
    #   # => C::User
    # ```
    def self.user_klass
      return @user_klass if defined? @user_klass
      @user_klass = sibling_klass('User')
    end

    # The name of the group (i.e. the samaccountname)
    #
    def name
      samaccountname
    end

    # Return all users being member of this group.
    def users
      # members.map { |dn| User.select_dn(dn) }
      members.map { |dn| self.class.user_klass.select_dn(dn) }
    end

    # Find the 'primary user' of the group
    # If this is a normal group 'nil' is returned.
    def primary_user
      # @primary_user ||= AdDir::User.find_by_primarygroupid(
      @primary_user ||= self.class.user_klass.find_by_primarygroupid(
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

    # Adds a user to the group
    #
    def add_user(user)
      unless members.include?(user.dn)
        self[:member] << user.dn
        save
      end
      users
    end

    # Remove a user from the group
    #
    def remove_user(user)
      if members.include?(user.dn)
        self[:member] -= [user.dn]
        save
      end
      users
    end
  end
end
