# encoding: utf-8
#

require 'ad_dir/derived_attributes'

module AdDir
  # Generic Error for AdDir
  class AdError < StandardError; end

  # Entry is basically a wrapper of Net::LDAP::Entry with some additional
  # class methods that provide ActiveRecord-like finders.
  #
  # # Retrieving entries
  # ## Finder
  #
  #     AdDir::Entry.find('jdoe')
  #     # => searches with an LDAP filter '(samaccountname=jdoe)'
  #
  #     AdDir::Entry.find_by_givenname('Doe*')
  #     # => '(givenname=Doe*)'
  #
  # ## Where (Filter)
  #
  # * Using a Hash
  #
  # ```
  #     AdDir::Entry.where(cn: 'Doe', mail: 'john.doe@ibm.com')
  #     # => '(&(cn=Doe)(mail=john.doe@ibm.com))'
  # ```
  #
  # * Using a LDAP-Filter-String
  #
  # ```
  #   AdDir::Entry.where('(|(sn=Foo)(cn=Bar))')
  # ```
  #
  # ## All
  #
  # ``` 
  #   AdDir::Entry.all
  #   # => retrieves all entries for the given 'tree_base'
  # ```
  #
  # # Creating new Entries
  #
  # ```
  # jdoe = AdDir::Entry.new(dn: 'dn=John Doe,ou=people,dc=my,dc=geo,dc=ch',
  #                         attributes: attrs)
  # jdoe.new_entry?
  # # => true
  # jdoe.save
  # ```
  #
  class Entry
    include DerivedAttributes

    # Regexp that matches `find_xxx` methods.
    #
    # Note: Likewise ActiveRecord the difference between `#find` and
    # `#where` is boldly that `#find` is used when you are really
    # looking for a given entry, while the latter is used to filter on
    # some condition.
    FIND_METHOD_REGEXP = /\Afind(_by_(\w+))?\Z/

    # ----------------------------------------------------------------------
    # CLASS Methods
    #
    # class << self
    # Returns the ActiveDirectory's connection
    def self.connection
      AdDir.connection
    end

    # Search
    # @return [Array<Net::LDAP::Entry>, nil] Objects found in the
    #   ActiveDirectory. Can be nil
    def self.search(args = {})
      args[:base] ||= @tree_base
      args[:scope] ||= Net::LDAP::SearchScope_WholeSubtree

      success = connection.search(args)
      if success
        success
      else
        fail AdError, connection.get_operation_result.error_message
      end
    end

    # @return [Array] all objects
    def self.all
      search(base: @tree_base).collect do |e|
        from_ldap_entry(e)
      end
    end

    # Set the search base for a given class, e.g. the DevOps users in
    # the Taka Tuka country.
    #
    #     class DevOpsUser
    #       self.tree_base = 'ou=DevOps,ou=taka tuka,dc=my,dc=company,dc=net'
    #     end
    #
    # This limits the ++:base++ DN when doing search operations on the AD.
    def self.tree_base=(value)
      @tree_base = value
    end

    # Returns the tree_base of this class.
    # @return String
    def self.tree_base
      @tree_base || nil
    end

    # Sets the name of the attribute that acts as `primary_key`.
    #
    #     class User < AdDir::Entry
    #       self.primary_key = :samaccountname
    #     end
    #
    def self.primary_key=(value)
      @primary_key = value && value.to_s
    end

    # Returns the name of the attribute that acts as `primary_key`.
    #
    # The primary_key is used as default when searching.
    #
    #     AdDir::Entry.find('jdoe')
    #
    # searches for an entry with 'samaccountname' = 'jdoe'.
    # @see {#primary_key}.
    def self.primary_key
      @primary_key ||= 'samaccountname'
    end

    ##
    # Instantiates an AdDir::Entry and saves it in the ActiveDirectory.
    #
    # We try to create the entry in the ActiveDirectory and then
    # return it again from there.
    # Depending on your ActiveDirectory the set of mandatory attributes
    # may vary. If you don't provide the correct set of attributes
    # the ActiveDirectory will refuse to add the entry and fail.
    def self.create(dn, attributes)
      #
      success = connection.add(dn: dn, attributes: attributes)
      if success
        select_dn(dn)
      else
        connection.get_operation_result
      end
    end

    # Constructs a AdDir::Entry from a Net::LDAP::Entry.
    def self.from_ldap_entry(entry)
      e = new(entry.dn)
      e.instance_variable_set('@ldap_entry', entry)
      e.instance_variable_set('@new_entry', false)
      e
    end

    # Select an entry by its '''Distinguished Name''' (DN)
    #
    # Example
    #
    #     AdDir::Entry.select_dn('CN=Joe Doe,OU=People,DC=acme,DC=com')
    #
    # @param dn [String] Distinguished Name of an entry
    # @return Entry or nil
    def self.select_dn(dn)
      success = _select_dn(dn)
      success && from_ldap_entry(success.first)
    end

    # This method fetches an ActiveDirectory by its DN.
    # The hope is this is the most efficient way to fetch
    # an entry.
    # :nodoc:
    def self._select_dn(dn)
      args = {
        base:   dn,
        scope:  Net::LDAP::SearchScope_BaseObject,
        filter: Net::LDAP::Filter.present('objectclass')
      }
      connection.search(args)
    end

    # Search and other utilities
    #
    # Note: `find` methods return a single model instance (or nil), whereas
    # `where` always returns a 'collection' of model instances.
    #
    # The find-methods have to follow this pattern:
    #    find_by_<attribute>(<pattern>)
    #
    #
    # @param method_sym [Symbol] the initially called method
    # @param pattern [String] the pattern we are looking for.
    #
    def self.my_find(method_sym, pattern)
      # evaluate the method name
      attr    = evaluate_finder_method(method_sym)
      filter  = Net::LDAP::Filter.eq(attr, pattern)
      records = search(filter: filter).map do |e|
        entry = from_ldap_entry(e)
        entry.instance_variable_set('@new_entry', false)
        entry
      end
      records.first
    end
    private_class_method :my_find

    # analyze and extract the attribute in the dynamic
    # find(_by_xxx) method.
    #
    # If no attribute is given `uid` is returned
    def self.evaluate_finder_method(method_sym)
      method_sym.to_s.match(FIND_METHOD_REGEXP)[2] || primary_key
    end
    private_class_method :evaluate_finder_method

    # Returns an array of entries filtered by the conditions given
    # in the arguments.
    #
    # `#where` accepts conditions in the two following formats.
    #
    # ### String Representation of LDAP Search Filter
    #
    # A single string representing an filter as set out in
    # {http://tools.ietf.org/html/rfc4515 RFC 4515}
    #
    # Examples: [http://tools.ietf.org/html/rfc4515#page-5]
    #
    #     AdDir::Entry.where('(samaccountname=jdoe)')
    #     AdDir::Entry.where('(|(sn=*müller*)(givenname=*müller*))')
    #
    # ### Hash
    #
    # Pass in a hash of conditions. Each hash entry represents an
    # equality condition where the key denotes the name of an
    # attribute and the value its predicate.  All conditions are
    # logically combined by 'AND'.
    #
    # Only equality conditions are allowed.
    #
    # Examples:
    #
    #     AdDir::Entry.where(sn: 'Doe', givenname: 'John')
    #
    # will search for entries having sn == 'Doe' && givenname == 'John'.
    #
    #     AdDir::Entry.where(sn: '*oe', mail: '@geo.uzh.ch')
    #
    # will match all entries with sn ending with 'oe' and having a mail
    # address in the `geo.uzh.ch` domain.
    #
    # @param opts [String|Hash]
    # @return [Array[Entry]] | []
    def self.where(opts)
      if opts.instance_of?(Hash)
        filter = build_filter_from_hash(opts)
      else
        filter = Net::LDAP::Filter.from_rfc4515(opts)
      end
      search(filter: filter).map { |e| from_ldap_entry(e) }
    end

    # Builds a Net::LDAP::Filter based on a given hash.
    # Each key-value pair of the hash is interpreted as an attribute
    # that must match the value.
    #
    # Example:
    #
    #      build_filter_from_hash(sn: 'Doe', givenname: 'John').to_rfc2254
    #      # =>  "(&(sn=Doe)(givenname=John))"
    #
    def self.build_filter_from_hash(opts)
      attr, val = opts.shift
      filter = Net::LDAP::Filter.eq(attr, val)
      opts.each { |attr, val| filter &= Net::LDAP::Filter.eq(attr, val) }
      filter
    end

    # dynamic method handling
    # find out if I have to deal with it
    #    find_<number_scope>_by_<attr>
    #
    def self.my_method?(method_sym)
      method_sym.to_s =~ FIND_METHOD_REGEXP
    end

    def self.respond_to_missing?(method_sym, include_all = false)
      my_method?(method_sym) || super(method_sym, include_all)
    end

    def self.method_missing(method_sym, *args, &block)
      if my_method?(method_sym)
        my_find(method_sym, *args)
      else
        # No need to hand over method's arguments:
        # +super+ will find them in ARGV.
        super
      end
    end

    private_class_method :build_filter_from_hash
    #
    # End CLASS Methods
    # ----------------------------------------------------------------------

    # ----------------------------------------------------------------------
    # Instance Methods

    # We do not provide a constructor, but use the standard one
    # of ++Net::LDAP::Entry++
    #
    #     Net::LDAP::Entry.new(dn=nil)
    def initialize(dn = nil, attrs = {})
      #
      @ldap_entry = Net::LDAP::Entry.new(dn)
      attrs.each { |name, value| @ldap_entry[name] = value }
      @new_entry = true
      self
    end

    # The Net::LDAP::Connection object used by this instance.
    #
    # @return [Net::LDAP]
    def connection
      self.class.connection
    end

    # Returns the base tree node used when establishing the connection
    # to the ActiveDirectory server.
    # def base
    #   connection.base
    # end

    def attributes
      @ldap_entry.attribute_names.each_with_object({}) do |key, hsh|
        hsh[key] = @ldap_entry[key]
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

    # Retrieve the value of the given attribute.
    #
    # Attribute values are always wrapped in an array, although most
    # attributes are singled-valued.
    #
    def [](name)
      val_arr = @ldap_entry[name]
      return val_arr if val_arr.empty?
      #
      val_arr.size == 1 ? val_arr.first : val_arr
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
      ops     = attr_hash.map { |key, new_val| [:replace, key, new_val] }
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
      create_or_update
    end

    # Returns true if the instance is not saved in the AD.
    def new_entry?
      @new_entry
    end

    # compares the given hash with the internal @ldap_entry.attributes
    def changed?
      changed_attributes.size > 0
    end

    # For each changed attribute the old and new value(s) are stored
    # in a hash.
    def changed_attributes
      persisted_attrs = self.class.select_dn(dn).attributes
      @changed_attributes = (@ldap_entry.attribute_names + persisted_attrs.keys)
        .uniq
        .each_with_object({}) do |key, memo|
        unless @ldap_entry[key] == persisted_attrs[key]
          memo[key] = [persisted_attrs[key], @ldap_entry[key]]
        end
      end
    end

    # Destroy the entry
    def destroy
      connection.delete(dn: dn)
    end

    protected

    #
    def create_or_update
      result = new_entry? ? _create_entry : _update_entry
      result != false
    end

    def _update_entry
      if changed?
        modify_params = changed_attributes
          .each_with_object({}) { |(k, v), hsh| hsh[k] = v.last }
        modify(modify_params) && reload
      else
        0
      end
    end

    def _create_entry
      attrs = attributes
      attrs.delete(:dn)
      success = connection.add(dn: dn, attributes: attrs)
      if success
        reload
      else
        success
      end
    end

    # reload
    def reload
      success = self.class._select_dn(dn)
      if success
        @new_entry  = false
        @ldap_entry = success.first
      else
        false
      end
    end

    def raise_ad_error(error)
      exception = AdError.new(
        "LDAP operation on AD failed: #{error.message} (code: #{error.code})")
      exception.set_backtrace(caller[0..-2])
      fail exception
    end
  end
end
