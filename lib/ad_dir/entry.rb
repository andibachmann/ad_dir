# encoding: utf-8
#

module AdDir
  class AdError < StandardError; end

  # Entry
  # Entry is basically a wrapper of Net::LDAP::Entry with some additional
  # class methods that provide ActiveRecord-like finders.
  class Entry
    #
    #
    FIND_METHOD_REGEXP = /find(_(all|first|last))?(_by_(\w*))?/

    # ----------------------------------------------------------------------
    # CLASS Methods
    #
    class << self
      def connection
        AdDir.connection
      end

      #
      def search(args = {})
        args[:base]          ||= base_dn
        args[:scope]         ||= Net::LDAP::SearchScope_WholeSubtree

        success = connection.search(args)
        if success
          success
        else
          fail AdError, connection.get_operation_result.error_message
        end
      end

      # Set the tree base for a given class, e.g. the DevOps users in
      # the Taka Tuka country.
      #
      #     class DevOpsUser
      #        tree_base 'ou=DevOps users,ou=taka tuka,dc=my,dc=company,dc=net'
      #     end
      #
      # This limits the ++:base++ DN when doing search operations on the AD.
      #
      def tree_base(tree_base_dn)
        @base_dn ||= tree_base_dn || connection.base
      end

      def base_dn
        @base_dn ||= connection.base
      end

      ##
      # Creates an AdDir::Entry and stores it
      #
      # We try to create the entry in the ActiveDirectory and then
      # return it again from there.
      # Depending on your ActiveDirectory the set of mandatory attributes
      # may vary. If you don't provide the correct set of attributes
      # the ActiveDirectory will refuse to add the entry and fail.
      def create(dn, attributes)
        #
        success = connection.add(dn: dn, attributes: attributes)
        if success
          select_dn(dn)
        else
          connection.get_operation_result
        end
      end

      # Constructs a AdDir::Entry from a Net::LDAP::Entry.
      def from_ldap_entry(entry)
        e = new(entry.dn)
        e.instance_variable_set('@ldap_entry', entry)
        e
      end

      # TODO: Do not call `find_by_dn` but directly got to 'search'.
      def select_dn(dn)
        args = {}
        args[:base]   = dn
        args[:scope]  = Net::LDAP::SearchScope_BaseObject
        args[:filter] = Net::LDAP::Filter.present('objectclass')
        find_by_dn(dn, args)
      end

      # Search and other utilities
      #
      #
      # The find-methods have to follow this pattern:
      #    find_<:all_flag_>?by_<attribute>(<pattern> [,
      #           {optional_hash_of_ldap_search_options}])
      #
      # The behaviour of the <:all_flag> follows pretty much the activerecord
      # philosophy. +find_by_id+ will either find exactly one record or
      # it returns nil. +find_all_by_id+ will always return an array
      # being either empty or comprising all records matching the pattern).
      #
      # @param method_sym [Symbol] the initially called method
      # (e.g. `#find_all_by_cn('Doe')`).
      # @param pattern [String] the pattern we are looking for.
      # @param options [Array|Hash] of additional ldap_options
      #
      # TODO: remove the 'options' hash.
      def my_find(method_sym, pattern, options = {})
        # evaluate the method name
        number_scope, attr = evaluate_finder_method(method_sym)
        search_args   = {}
        unless options[:filter]
          search_args[:filter] =
            case attr
            when nil, 'id'
              Net::LDAP::Filter.eq('sAMAccountName', pattern)
            else Net::LDAP::Filter.eq(attr, pattern)
            end
        end
        search_args   = options.merge(search_args) unless options.nil?
        # puts search_args.inspect
        records       = search(search_args).map { |e| from_ldap_entry(e) }
        if number_scope == 'all'
          return records
        else
          # i.e. records.send("first") or records.send("last")
          return records.send(number_scope)
        end
      end

      # analyze and extract number_scope and attribute in
      # dynamic finder
      def evaluate_finder_method(method_sym)
        _, num_scope, _by, attr = method_sym.to_s.scan(FIND_METHOD_REGEXP).first
        num_scope ||= 'first'
        [num_scope, attr]
      end

      # dynamic method handling
      # find out if I have to deal with it
      #    find_<number_scope>_by_<attr>
      #
      def my_method?(method_sym)
        method_sym.to_s =~ FIND_METHOD_REGEXP
      end

      def respond_to_missing?(method_sym, include_all = false)
        my_method?(method_sym) || super(method_sym, include_all)
      end

      def method_missing(method_sym, *args, &block)
        if my_method?(method_sym)
          my_find(method_sym, *args)
        else
          # No need to hand over method's arguments:
          # +super+ will find them in ARGV.
          super
        end
      end
    end
    #
    # End CLASS Methods
    # ----------------------------------------------------------------------

    # ----------------------------------------------------------------------
    # Instance Methods

    # We do not provide a constructor, but use the standard one
    # of ++Net::LDAP::Entry++
    #
    #     Net::LDAP::Entry.new(dn=nil)
    def initialize(dn = nil, attributes = {})
      #
      @ldap_entry = Net::LDAP::Entry.new(dn)
      unless attributes.empty?
        attributes.each do |name, value|
          @ldap_entry[name] = value
        end
      end
      self
    end

    # The Net::LDAP::Connection object used by this instance.
    #
    # @return [Net::LDAP::Connection]
    def connection
      self.class.connection
    end

    # Returns the base tree node used when establishing the connection
    # to the ActiveDirectory server.
    def base_dn
      connection.base_dn
    end

    def attributes
      @ldap_entry.attribute_names.inject({}) do |hsh, key|
        hsh[key] = @ldap_entry[key]
        hsh
      end
    end

    def respond_to_missing?(method_sym, include_private = false)
      @ldap_entry.respond_to?(method_sym) || super.respond_to?(method_sym)
    end

    def method_missing(method_sym, *args, &block)
      if @ldap_entry.respond_to?(method_sym)
        @ldap_entry.__send__(method_sym, *args)
      else
        super(method_sym, *args, &block)
      end
    end

    # Returns the binary ObjectGUID attribute as regular [String].
    #
    # To understand the difference between the GUID (globally unique identifier)
    # and the SID (security identififer) read this:
    # {https://technet.microsoft.com/en-us/library/cc961625.aspx}
    #
    # The conversion is done by {AdDir::Utilities#decode_guid}.
    #
    # @see AdDir::Utilities#decode_guid
    # @return [String] the decoded ObjectGUID
    def objectguid_decoded
      @objectguid_decoded ||= Utilities.decode_guid(@ldap_entry[:objectguid].first)
    end

    # Returns the binary ObjectSID attribute as regular [String]
    #
    # The conversion is done by {AdDir::Utilities#decode_guid}.
    #
    # @see AdDir::Utilities#decode_guid
    # @return [String] the decoded ObjectGUID
    def objectsid_decoded
      @objectsid_decoded ||= Utilities.decode_sid(@ldap_entry[:objectsid])
    end

    # time stamps
    def created_at
      @created_at ||=
        Utilities.utc_to_localtime(@ldap_entry[:whencreated].first)
    end

    def updated_at
      @udpated_at ||=
        Utilities.utc_to_localtime(@ldap_entry[:whenchanged].first)
    end

    #
    def [](name)
      @ldap_entry[name]
    end

    #
    def []=(name, value)
      @ldap_entry[name] = value
    end

    # Modify attributes given as hash
    #
    # Example: Modify the ++:sn++ and ++:mail++ attributes.
    #
    #   entry.modify({ sn:   "John Doe",
    #                  mail: "john.doe@foo.bar.com" })
    #
    def modify(attr_hash)
      ops     = attr_hash.map { |key, new_val|  [:replace, key, new_val] }
      success = connection.modify(dn: dn, operations: ops)
      #
      if success
        success
      else
        raise_ad_error connection.get_operation_result
      end
    end

    # Save the entry
    def save
      connection.add(dn: dn, attributes: attributes)
    end

    private

    def normalize_name(name)
      # Turn all characters of an attribute name into lower case characters.
      name.to_s.downcase.to_sym
    end

    def raise_ad_error(error)
      exception = AdError.new(
        "LDAP operation on AD failed: #{error.message} (code: #{error.code})")
      exception.set_backtrace(caller[0..-2])
      fail exception
    end
  end
end
