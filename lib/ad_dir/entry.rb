# encoding: utf-8
#

require 'date'
require 'ad_dir/derived_attributes'

module AdDir
  # Entry is basically a wrapper of Net::LDAP::Entry with some additional
  # class methods that provide ActiveRecord-like finders.
  #
  # ## Design Overview
  # {Entry} stores the original `Net::LDAP::Entry` object in an
  # instance variable `@ldap_entry`. When the entry is fetched
  # from the ActiveDirectory a snapshot of the entry's persisted
  # attributes and its values is stored in a hash
  # `@persisted_attrs` (using `#dup`!).
  #
  # Whenever an attribute is changed the method {#changes} calculates
  # the difference between the currrent values and the values in
  # `@persisted_attrs`.
  #
  # ## Attributes
  # List all attribute names:
  #
  # ```
  # user.attribute_names
  #   => [:dn, :objectclass, :cn, :sn, :givenname, :distinguishedname,
  #   :instancetype, :whencreated, :whenchanged, :displayname, :usncreated,
  #   :usnchanged, :directreports, :name, :objectguid, :useraccountcontrol,
  #   :badpwdcount, :codepage, :countrycode, :badpasswordtime, :lastlogoff,
  #   :lastlogon, :pwdlastset, :primarygroupid, :objectsid, :accountexpires,
  #   :logoncount, :samaccountname, :samaccounttype, :lockouttime,
  #   :objectcategory, :dscorepropagationdata,
  #   :msds-supportedencryptiontypes]
  # ```
  #
  # To get a hash of all attribute names and their values
  #
  # ```
  # user.attributes
  # ```
  #
  # Note: Mainly for debugging purposes there is the method {#raw_attributes}
  #   returning the original attributes as present in the `Net::LDAP::Entry`
  #   object (see also
  #   [Retrieving Attribute Values](#retrieving-attribute-values))
  #
  # ### <a name="retrieving-attribute-values"></a> Retrieving Attribute Values
  #
  # Values of attributes can be accessed in two ways:
  #
  # ```
  # entry.sn
  # # => "Doe"
  #
  # # NOT RECOMMENDED!
  # entry[:sn]
  # # => ["Doe"]
  # ```
  # As a rule of thumbs use
  #
  #  * `#attr_name` to get the values ready-to-use without wrapping array.
  #  * `[:attr_name]` only if you want to retrieve the original
  #    `Net::LDAP::Entry` values.
  #
  # ## Create
  # * Create an entry by specifying a DN and providing an conformant set
  # of valid attributes:
  #
  # ```
  # jdoe = AdDir::Entry.create(dn: 'cn=John Doe,ou=mgrs,dc=my,dc=nice,dc=com',
  #   givenname: 'John',
  #   sn: 'Doe',
  #   objectclass: %w(top person organizationalPerson user),
  #   mail: 'john.doe@my.nice.com')
  # ```
  #
  # * Build a new entry first and then save it.
  #
  # ```
  # jdoe = AdDir::Entry.new('cn=John Doe,ou=mgrs,dc=my,dc=nice,dc=com')
  # jdoe.sn = 'Doe'
  # jdoe.givenname = 'John'
  # jdoe.objectclass = %w(top person organizationalPerson user)
  # jdoe.mail = 'john.doe@my.nice.com'
  # jdoe.new_entry?
  # # => true
  # jdoe.save
  # ```
  #
  # ## Read
  # ### `.find`
  #
  #     AdDir::Entry.find('jdoe')
  #     # => searches with an LDAP filter '(samaccountname=jdoe)'
  #
  #     AdDir::Entry.find_by_givenname('Doe*')
  #     # => '(givenname=Doe*)'
  #
  # ### `.where` (Filter)
  #
  # * Using a Hash
  #
  #  ```
  #   AdDir::Entry.where(cn: 'Doe', mail: 'john.doe@ibm.com')
  #   # => '(&(cn=Doe)(mail=john.doe@ibm.com))'
  #  ```
  #
  # * Using a LDAP-Filter-String
  #
  #  ```
  #   AdDir::Entry.where('(|(sn=Foo)(cn=Bar))')
  #  ```
  #
  # ### `.all`
  #
  # ```
  #   AdDir::Entry.all
  #   # => retrieves all entries for the given 'tree_base'
  # ```
  #
  # ## Update
  #
  # ```
  #  jdoe = AdDir::Entry.find('jdoe')
  #  jdoe[:givenname] = 'Jonny'   # instead of 'John'
  #  jdoe.changed?
  #  # => true
  #  jdoe.changes
  #  # => {givenname: ['John', 'Jonny']}
  #  jdoe.save
  # ```
  #
  # ## Destroy
  #
  # ```
  #  jdoe.destroy
  # ```
  #
  class Entry
    include DerivedAttributes

    # Regexp that matches `find_xxx` methods.
    #
    # Note: Likewise ActiveRecord the difference between `.find` and
    # `.where` is boldly that `.find` is used when you are really
    # looking for a given entry, while the latter is used to filter on
    # some condition.
    FIND_METHOD_REGEXP = /\Afind(_by_(\w+))?\Z/

    # Define which category a record belongs to
    # Active Directory knows: `person`, `computer`, `group`
    #
    OBJECTCATEGORY = ''.freeze

    # ---------------------------------------------------------- CLASS Methods

    # Returns the ActiveDirectory's connection
    def self.connection
      AdDir.connection
    end

    # Search.
    # @return [Array<Net::LDAP::Entry>|nil] Objects found in the
    #   ActiveDirectory. Can be nil
    def self.search(args = {})
      args[:base] ||= @tree_base
      args[:scope] ||= Net::LDAP::SearchScope_WholeSubtree
      connection.search(args)
    end
    private_class_method :search

    # @return [Array] all objects
    def self.all
      search(base: @tree_base, filter: category_filter).collect do |e|
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
    # This limits the `:base` DN when doing search operations on the AD.
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

    # Return the name of the parent module/class.
    #
    # This is important for inflection when inheriting classes.
    # The method is copied from `ActiveSupport::CoreExtensions::Module`
    # @see http://www.rubydoc.info/docs/rails/2.3.8/ActiveSupport/CoreExtensions/Module#parent-instance_method
    def self.parent_name
      return @parent_name if defined? @parent_name
      @parent_name = name =~ /::[^:]+\Z/ ? $`.freeze : nil
    end

    # Return a sibling klass for the given name
    #
    # This is needed to construct some basic relationship between
    # a `User` and `Group` model.
    # @see {User#add_group}
    # @see {User.group_klass}
    # @see {Group#add_user}
    # @see {Group.user_klass}
    # @param klass_name [String]
    def self.sibling_klass(klass_name)
      composed_klass = "#{parent_name}::#{klass_name}"
      Object.const_get(composed_klass)
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
      e.instance_variable_set('@persisted_attrs', e.raw_attributes.dup)
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

    # This method fetches a raw **`Net::LDAP::Entry`** given the DN.
    # The hope is this is the most efficient way to fetch
    # an entry.
    # :nodoc:
    def self._select_dn(dn)
      args = {
        base:   dn,
        scope:  Net::LDAP::SearchScope_BaseObject,
        filter: category_filter
      }
      connection.search(args)
    end

    # Use this to efficiently select entries from the Active Directory.
    # The filter relays on the class instance variable `@objectcategory`
    def self.category_filter
      return @category_filter if @category_filter
      cat = const_get(:OBJECTCATEGORY).empty? ? '*' : const_get(:OBJECTCATEGORY)
      @category_filter = Net::LDAP::Filter.eq('objectcategory', cat)
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
      filter  = category_filter & Net::LDAP::Filter.eq(attr, pattern)
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
    #     AdDir::Entry.where(sn: '*oe', mail: '@my.nice.com')
    #
    # will match all entries with sn ending with 'oe' and having a mail
    # address in the `my.nice.com` domain.
    #
    # @param opts [String|Hash]
    # @return [Array[Entry]] | []
    def self.where(opts)
      if opts.instance_of?(Hash)
        filter = build_filter_from_hash(opts)
      else
        filter = Net::LDAP::Filter.from_rfc4515(opts)
      end
      search(filter: category_filter & filter).map { |e| from_ldap_entry(e) }
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
      opts.each { |k, v| filter &= Net::LDAP::Filter.eq(k, v) }
      filter
    end
    private_class_method :build_filter_from_hash

    # dynamic method handling
    # find out if I have to deal with it
    #    find_<number_scope>_by_<attr>
    #
    def self.my_method?(method_sym)
      method_sym.to_s =~ FIND_METHOD_REGEXP
    end
    private_class_method :my_method?

    def self.respond_to_missing?(method_sym, include_all = false)
      my_method?(method_sym) || super(method_sym, include_all)
    end
    private_class_method :respond_to_missing?

    def self.method_missing(method_sym, *args, &block)
      if my_method?(method_sym)
        my_find(method_sym, *args)
      else
        # No need to hand over method's arguments:
        # +super+ will find them in ARGV.
        super
      end
    end
    private_class_method :method_missing
    #
    # End CLASS Methods
    # ----------------------------------------------------------------------

    # ----------------------------------------------------------------------
    # Instance Methods

    # We do not provide a constructor, but use the standard one
    # of `Net::LDAP::Entry`
    #
    #     Net::LDAP::Entry.new(dn=nil)
    def initialize(dn = nil, attrs = {})
      #
      @ldap_entry = Net::LDAP::Entry.new(dn)
      attrs.each { |name, value| @ldap_entry[name] = value }
      @new_entry = true
      @persisted_attrs = {}
      self
    end

    # The Net::LDAP::Connection object used by this instance.
    #
    # @return [Net::LDAP]
    def connection
      self.class.connection
    end

    # Returns a hash with all attributes and (unwrapped) values.
    # Any singled value array is unwrapped and the value itself is
    # returned.
    #
    # @see #raw_attributes
    # @see #get_value
    # @return [Hash]
    def attributes
      @ldap_entry.attribute_names.each_with_object({}) do |key, hsh|
        hsh[key] = get_value(key)
      end
    end

    # Returns a hash with all attributes and (raw) values
    # as present in the ActiveDirectory entry.
    #
    # @note The values are directly taken from the Net::LDAP::Entry object,
    #   i.e., each value is wrapped in an array.
    #
    # @see #[]
    # @return [Hash]
    def raw_attributes
      @ldap_entry.attribute_names.each_with_object({}) do |key, hsh|
        hsh[key] = @ldap_entry[key]
      end
    end

    def respond_to_missing?(method_sym, include_private = false) # :nodoc
      @ldap_entry.respond_to?(method_sym) || super.respond_to?(method_sym)
    end
    private :respond_to_missing?

    def method_missing(method_sym, *args, &block)
      # Distinguish `method_sym` to speed up attribute setting and getting
      if method_sym.to_s.end_with?('=')
        # Setter, e.g.  `:email=`
        @ldap_entry[method_sym] = args.first
      elsif @ldap_entry.attribute_names.include?(method_sym)
        # Getter, i.e. a valid attribute name ( e.g.  `:email`)
        get_value(method_sym)
      elsif @ldap_entry.respond_to?(method_sym)
        # any other Net::LDAP::Entry instance method
        # (e.g. `:attribute_names`)
        @ldap_entry.__send__(method_sym, *args)
      else
        super
      end
    end
    private :method_missing

    # Retrieve the value of the given attribute.
    #
    # Attribute values are always wrapped in an array, although most
    # attributes are singled-valued.
    #
    def get_value(name)
      val_arr = @ldap_entry[name]
      return val_arr if val_arr.empty?
      #
      val_arr.size == 1 ? val_arr.first : val_arr
    end

    # Get the value of the attribute `attr`
    #
    # @note This is a convenience method to speed up value retrieval, i.e.
    #   bypassing the `method_missing` way.
    #   The value returned is retrieved from the underlying `Net::LDAP:Entry`
    #   object and thus always wrapped in an `Array`.
    #
    # @param attr_name [String,Symbol] The name of the attribute
    # @return [Array<String>] value of attribute `attr`
    def [](attr_name)
      @ldap_entry[attr_name]
    end

    # Set the the attribute ''name'' to the value ''value''.
    # If the attribute ''name'' exists its value is overwritten.
    # If no attribute ''name'' exists a new attribute is created with the
    # provided value.
    # @param name[String,Symbol] attribute name
    # @param value value of attribute
    # @return value of attribute
    def []=(name, value)
      @ldap_entry[name] = value
    end

    # Modify attributes given as hash
    #
    # @example Modify the `:sn` (change) and `:foo` (add) attributes.
    #   entry.modify({:sn=>[["Doe"], ["Doey"]],
    #                 :foo=>[nil, ["hopfen"]]})
    #
    # @return [Boolean]
    def modify(changes_hash)
      ops     = prepare_modify_params(changes_hash)
      success = connection.modify(dn: dn, operations: ops)
      #
      if success
        reload!
      else
        false
      end
    end

    # Save the entry.
    # If saving failed `false` is returned, otherwise `true`.
    # @return [Boolean]
    def save
      create_or_update
    end

    # Returns true if the instance is not saved in the AD.
    def new_entry?
      @new_entry
    end

    # compares the given hash with the internal @ldap_entry.attributes
    def changed?
      changes.size > 0
    end

    # Returns a hash of changed attributes indicating their original and new
    # values like  `attr => [original value, new value]`.
    #
    # @example
    #    user = AdDir::Entry.find('jdoe')
    #    user[:sn]
    #    # => "Doe"
    #    user[:sn] = 'Doey'
    #    user.changes
    #    # => {:sn=>[["Doe"], ["Doey"]]}
    #
    #    # Adding a new attribute
    #    user[:foo] = 'bar'
    #    user.changes
    #    # => {:sn=>[["Doe"], ["Doey"]], :foo=>[nil, ["hopfen"]]}
    #
    def changes
      #
      # Algorithm:
      #  1. Get a list of all relevant attributes
      #   'set' operation union which returns a new array by joining
      #   `@ldap_entry.attribute_names` with `persisted_attrs.keys`,
      #   excluding any duplicates.
      #  2. Loop and record for each key the 'old' (i.e. @persisted_attrs[key])
      #     and the 'new' (i.e. @ldap_entry[<key>]) value but only if they
      #     differ.
      return {} if @persisted_attrs.empty?
      (@ldap_entry.attribute_names | @persisted_attrs.keys)
        .each_with_object({}) do |key, memo|
        unless @ldap_entry[key] == @persisted_attrs[key]
          memo[key] = [@persisted_attrs[key], @ldap_entry[key]]
        end
      end
    end

    # Destroy the entry
    def destroy
      connection.delete(dn: dn)
    end

    # Reload the values from the ActiveDirectory and clear
    # all current changes.
    # @return `true` if successful
    # @return `false` if reloading failed.
    def reload!
      success = self.class._select_dn(dn)
      if success
        @new_entry       = false
        @ldap_entry      = success.first
        @persisted_attrs = raw_attributes.dup
        true
      else
        false
      end
    end

    # find out if attribute is present
    def attribute_present?(name)
      @ldap_entry.attribute_names.include?(name)
    end

    # Returns the cotent of the record as a nicely formatted string.
    # (copied that from ActiveRecord)
    # @see {ActiveRecord::Base#inspect}
    def inspect
      inspection = attribute_names.collect do |k|
        "#{k}: #{attribute_for_inspect(get_value(k))}"
      end.compact.join(', ')
      "#<#{self.class} #{inspection}>"
    end

    # Returns an {#inspect}-like string for the `value` (based on it's class).
    #
    # Copied that from activerecord method
    #
    # @see http://api.rubyonrails.org/classes/ActiveRecord/AttributeMethods.html#method-i-attribute_for_inspect
    def attribute_for_inspect(value)
      # if value.is_a?(String) && value.length > 50
      #   "#{value[0, 50]}...".inspect
      if value.is_a?(String)
        string_inspect(value, 50)
      elsif value.is_a?(Date) || value.is_a?(Time)
        %("#{value.to_s(:db)}")
      elsif value.is_a?(Array) && value.size > 10
        inspected = value.first(10).inspect
        %(#{inspected[0...-1]}, ...])
      else
        value.inspect
      end
    end

    # Shorten long strings for inspection
    def string_inspect(str, len)
      str = "#{str[0, len]}..." if str.length > len
      str.inspect
    end

    private

    # Destinguishes newly created (in memory) instance (e.g. via {#new})
    # from a retrieved instance (e.g. via {#find}) and select the correct
    # action (`_create_entry` vs. `_update_entry`)
    #
    def create_or_update
      result = new_entry? ? _create_entry : _update_entry
      result != false
    end

    def _update_entry
      if changed?
        modify(changes)
      else
        false
      end
    end

    # Prepare an operations array containing all modifications.
    # Each modification consists of three elements:
    # `[ <operation>, <attr>, <value>]`
    #
    # @example Replace the value of `:sn` and add a new attribute `:foo`
    #
    #   operations = [
    #     [ :replace, :sn, ["Doey"],
    #     [ :add, :foo, ["bar"]
    #     [ :delete, :fuz, ["nil"]
    #   ]
    #
    # The operator for an attribute is defined by the presence of its values:
    #
    # ```
    #   :replace  when old_val && new_val
    #   :add      when old_val.nil?
    #   :delete   when new_val.nil?
    # ```
    # @example Transform `changes` hash to ops array
    #   changes_hsh = {
    #     sn: [["Doe"], ["Doey"]],        # :replace
    #     foo: [nil, ["bar"]],            # :add
    #     fuuz: [["bahrr"], nil],         # :delete
    #   }
    #   # =>
    #   [
    #     [:replace, :sn, ["Doey"]],
    #     [:add, :foo, ["bar"]],
    #     [:delete, :fuuz, nil]
    #   ]
    #
    def prepare_modify_params(changes_hsh)
      changes_hsh.each_with_object([]) do |(k, v), arr|
        if v.compact.size > 1
          op = :replace
        else
          op = v[0].nil? ? :add : :delete
        end
        arr << [op, k, v[1]]
      end
    end

    def _create_entry
      attrs = attributes
      attrs.delete(:dn)
      success = connection.add(dn: dn, attributes: attrs)
      if success
        reload!
      else
        success
      end
    end
  end
end
