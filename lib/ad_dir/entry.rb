# encoding: utf-8
#
module AdDir

  class AdError < StandardError; end

  class Entry < Net::LDAP::Entry
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
      def search(args={})
        args[:base]          ||= base_dn
        args[:scope]         ||= Net::LDAP::SearchScope_WholeSubtree

        success = connection.search(args)
        unless success
          raise AdError, connection.get_operation_result.error_message
        else
          success
        end
      end
      
      # Set the tree base for a given class, e.g. the DevOps users in
      # the Taka Tuka country.
      # 
      #     class DevOpsUser
      #        tree_base 'ou=devops users,ou=taka tuka,dc=my,dc=company,dc=net'
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
      def create(dn, attributes)
        #
        success = connection.add(dn:dn, attributes: attributes)
        if success
          select_dn(dn)
        else
          connection.get_operation_result
        end
      end


      # Constructs a AdDir::Entry from a Net::LDAP::Entry.
      def from_entry(entry)
        new(entry.dn, entry)
      end

      def select_dn(dn)
        args = {}
        args[:base]   = dn
        args[:scope]  = Net::LDAP::SearchScope_BaseObject
        args[:filter] = Net::LDAP::Filter.present("objectclass")
        find_by_dn(dn,args)
      end
      # search and other utilities
      # 
      # The find-methods have to follow this pattern:
      #    find_<:all_flag_>?by_<attribute>(<pattern> [,
      #           {optional_hash_of_ldap_search_options}])
      #
      # The behaviour of the <:all_flag> follows pretty much the activerecord
      # philosophy. +find_user_by_id+ will either find exactly one record or
      # it returns nil. +find_all_user_by_id+ will always return an array
      # being either empty or comprising all records matching the pattern).
      #
      def my_find(method_sym, *args)
        # evaluate the method name
        a,number_scope,by,attr = method_sym.to_s.scan(FIND_METHOD_REGEXP).first
        number_scope ||= "first"
        # pattern
        pattern       = args.shift
        # ldap_options
        ldap_options  = args.shift
        search_args   = {}
        unless ldap_options.kind_of?(Hash) && ldap_options[:filter]
          search_args[:filter] =
            case attr
            when nil,"id"
              Net::LDAP::Filter.eq("sAMAccountName", pattern)
            else Net::LDAP::Filter.eq(attr, pattern)
            end
        end
        search_args   = ldap_options.merge(search_args) unless ldap_options.nil?
        # puts search_args.inspect
        records       = search(search_args).map { |e| self.from_entry(e) }
        if number_scope == "all"
          return records
        else
          # i.e. records.send("first") or records.send("last")
          return records.send(number_scope)
        end
      end
      
      #
      # dynamic method handling
      # find out if I have to deal with it
      #    find_<object>_by_<attr>
      #    
      def my_method?(method_sym)
        method_sym.to_s =~ FIND_METHOD_REGEXP
      end
      
      def respond_to?(method_sym)
        my_method?(method_sym) || super(method_sym)
      end

      def method_missing(method_sym, *args, &block)
        if my_method?(method_sym)
          my_find(method_sym, *args)
        else
          super    # No need to hand over method's arguments:
                   # +super+ will find them in ARGV.
        end
      end
      #
    end
    # 
    # End CLASS Methods
    # ----------------------------------------------------------------------
    
    # ----------------------------------------------------------------------
    # Instance Methods

    # Returns a hash of all attributes
    attr_reader :attributes

    # 
    # 
    # We do not provide a constructor, but use the standard one
    # of ++Net::LDAP::Entry++
    #
    #     Net::LDAP::Entry.new(dn=nil)
    def initialize(dn=nil, attributes = {})
      super(dn)
      unless attributes.empty?
        attributes.each do |name,value|
          @myhash[self.class.attribute_name(name)] = Kernel::Array(value)
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
    
    # Returns the DN (Distinguisded Name) of self.
    #
    # @return [String] the DN of self.
    def dn
      @dn.downcase
    end

    # Returns the binary ObjectGUID attribute as regular [String].
    # 
    # To understand the difference between the GUID (globally unique identifier)
    # and the SID (security identififer) read this: {https://technet.microsoft.com/en-us/library/cc961625.aspx}
    #
    # The conversion is done by {AdDir::Utilities#decode_guid}.
    #
    # @see AdDir::Utilities#decode_guid
    # @return [String] the decoded ObjectGUID
    def objectguid_decoded
      @objectguid_decoded ||= Utilities.decode_guid(@attributes[:objectguid])
    end

    # Returns the binary ObjectSID attribute as regular [String]
    # 
    # The conversion is done by {AdDir::Utilities#decode_guid}.
    #
    # @see AdDir::Utilities#decode_guid
    # @return [String] the decoded ObjectGUID
    def objectsid_decoded
      @objectsid_decoded ||= Utilities.decode_sid(@myhash[:objectsid])
    end
    
    
    def objectsid
      @myhash[:objectsid]
    end

    # time stamps
    def created_at
      @created_at ||= Entry.utc_to_localtime(@attributes[:whencreated].first)
    end

    def updated_at
      @udpated_at ||= Entry.utc_to_localtime(@attributes[:whenchanged].first)
    end

    # 
    def [](name)
      @attributes[normalize_name(name)]
    end
    #
    def []=(name,value)
      key              = normalize_name(name)

      # update the attributes hash
      if modify( { key => value } )
        value = [value] unless value.kind_of?(Array)
        @attributes[key] = value
      end
    end
    
    # Returns the attributes keys
    def attribute_names
      @attributes.keys
    end

    # Modify attributes given as hash
    #
    # Example: Modify the ++:sn++ and ++:mail++ attributes.
    #
    #   entry.modify({ sn:   "John Doe", 
    #                  mail: "john.doe@foo.bar.com" })
    # 
    def modify(attr_hash)
      ops     = attr_hash.map { |key,new_val|  [:replace, key, new_val] }
      success = connection.modify(dn: dn, operations: ops )
      #
      unless success
        raise_ad_error connection.get_operation_result
      end
      
      return success 
    end
    

    # Save 
    # 
    def save
      success = connection.add(dn: dn, attributes: @attributes)
    end
      
    private
    def normalize_name(name)
      # Turn all characters of an attribute name into lower case characters.
      # 
      name.to_s.downcase.to_sym
    end

    def raise_ad_error(error)
      exception = AdError.new(
        "LDAP operation on AD failed: #{error.message} (code: #{error.code})")
      exception.set_backtrace(
        caller[0..-2])
      
      raise exception
    end

    # ----------------------------------------------------------------------
    # Cast an LDAP::Entry object into an Entry object
    # 
    # 
    def cast(ldap_entry)
      # 
      # Get all attribute names and normalize (i.e. downcase) them.
      names = ldap_entry.attribute_names.map { |name|
        normalize_name(name)
      }
      # Remove the :dn attribute. The :dn attribute is a top level attribute
      # by itself, while all other attributes are stored in the hash 
      # 'attributes'.
      names.delete(:dn)
      names.delete(:objectguid)
      names.delete(:objectsid)

      # LDAP::Entry returns any value as BER (Basic Encoding Rules) String
      # (http://en.wikipedia.org/wiki/Basic_Encoding_Rules). We don't need
      # this, but prefer dealing directly with Strings, thus any values
      # are explicitly stored as String.
      # 
      @attributes = Hash[
        names.
        map { |name| [
            name, 
            ldap_entry[name].
            map { |e| String.new(e).force_encoding('UTF-8') }] }]
      @attributes[:objectguid] =ldap_entry[:objectguid].first
      @attributes[:objectsid] =ldap_entry[:objectsid].first
    end
  end
end
