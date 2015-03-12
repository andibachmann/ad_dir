# encoding: utf-8
#
module AdDir

  class AdError < StandardError; end

  class Entry
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
      
      def base_dn
        @base_dn || connection.base
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
    # 
    attr_reader :attributes

    # Constructs an AdDir::Entry from a +dn+ and an optional Net::LDAP::Entry
    # that has been returned from a search.
    def initialize(dn, entry=nil)
      @dn = dn
      @attributes = {}
      cast(entry) if entry
    end

    def reload
      #
    end

    def dn
      @dn.downcase
    end

    def connection
      self.class.connection
    end
    
    def base_dn
      @base_dn || connection.base
    end

    # SID vs. GUID
    # https://technet.microsoft.com/en-us/library/cc961625.aspx
    # objectguid = 'object's Global Unique ID'
    def objectguid_raw
      @attributes[:objectguid].first
    end

    def objectguid
      @objectguid ||= decode_guid(@attributes[:objectguid].first)
    end

    # SID 
    def objectsid
      @objectsid ||= decode_sid(@attributes[:objectsid].first)
    end

    def objectsid_raw
      @attributes[:objectsid].first
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
    #   entry.modify({ :sn => "John Doe", 
    #                  :mail => "john.doe@foo.bar.com" })
    # 
    def modify(attr_hash)
      ops     = attr_hash.map { |key,new_val|  [:replace, key, new_val] }
      success = connection.modify(:dn => dn, :operations => ops )
      #
      unless success
        raise_ad_error connection.get_operation_result
      end
      
      return success 
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

    # Decode Microsoft Active Directory `objectsid`
    #
    # Official Docu-Link: 
    #    https://msdn.microsoft.com/en-us/library/cc230371.aspx
    # 
    # SID= "S-1-" IdentifierAuthority 1*SubAuthority
    # IdentifierAuthority= IdentifierAuthorityDec / IdentifierAuthorityHex
    #   ; If the identifier authority is < 2^32, the
    #   ; identifier authority is represented as a decimal 
    #   ; number
    #   ; If the identifier authority is >= 2^32,
    #   ; the identifier authority is represented in 
    #   ; hexadecimal
    # IdentifierAuthorityDec =  1*10DIGIT
    #   ; IdentifierAuthorityDec, top level authority of a 
    #   ; security identifier is represented as a decimal number
    # IdentifierAuthorityHex = "0x" 12HEXDIG
    #   ; IdentifierAuthorityHex, the top-level authority of a
    #   ; security identifier is represented as a hexadecimal number
    # SubAuthority= "-" 1*10DIGIT
    #   ; Sub-Authority is always represented as a decimal number 
    #   ; No leading "0" characters are allowed when IdentifierAuthority
    #   ; or SubAuthority is represented as a decimal number
    #   ; All hexadecimal digits must be output in string format,
    #   ; pre-pended by "0x"
    #
    # Short Synopsis
    # http://www.adamretter.org.uk/blog/entries/active-directory-ldap-users-primary-group.xml
    # 
    # byte[0] - Revision Level
    # byte[1] - count of Sub-Authorities
    # byte[2-7] - 48 bit Authority (big-endian)
    # <count> Sub-Authorities, 32 bits (== 4 bytes) each (little-endian)
    #
    def decode_sid(sid_str)
      sid_bin   = sid_str.bytes
      revision  = sid_bin[0]                    # 1st byte
      count     = sid_bin[1]                    # 2nd byte
      authority = sid_bin[2..7].join('').to_i   # 3-8 bytes (length: 48bit) 
      #     authority big-endian
      # sub-authorities
      offset    = 8  # start byte
      size      = 4  # size of chunks, i.e. 4 bytes
      subauths = (0...count.to_i).collect do |c|
        si = c * size + offset
        sid_str[si,size].unpack('V*').first
      end
      ["S",revision,authority,subauths].flatten.join("-")
    end

    # http://support2.microsoft.com/default.aspx?scid=kb%3Ben-us%3B325649
    # and
    # http://serverfault.com/questions/466594/script-to-resolve-guid-to-string-in-active-directory
    
    # Example:
    #    objectguid = "738c16ee-f742-4b01-bbd7-58ac63d0e85c"
    #    oguid_str  = "\xEE\u0016\x8CsB\xF7\u0001K\xBB\xD7X\xACc\xD0\xE8\\"
    # 
    #    Original byte order:
    #             0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15
    #    dec = "238 022 140 115 066 247 001 075 187 215 088 172 099 208 232 092"
    #    hex = " ee  16  8c  73  42  f7  01  4b  bb  d7  58  ac  63  d0  e8  5c"
    #            \------------/  \----/  \----/  \----/  \--------------------/
    #                  |            |       |      |                |
    #               reverse      reverse reverse   |                |
    #                  |            |       |      |                |
    #            [73 8c 16 ee]   [f7 42] [4b 01] [bb d7]   [58 ac 63 d0 e8 5c]
    #
    def decode_guid(guid_str)
      q = []
      bytes = guid_str.bytes
      q << bytes_to_hex( bytes[0..3].reverse )
      q << bytes_to_hex( bytes[4..5].reverse )
      q << bytes_to_hex( bytes[6..7].reverse )
      q << bytes_to_hex( bytes[8..9] )
      q << bytes_to_hex( bytes[10..15])
      return q.join("-")
    end

    # Turns any given byte-arr into a hex string
    # Ensures that any hex-value is represented by 2 digits 
    # (prepending single values with '0').
    def bytes_to_hex(bin_arr)
      bin_arr.collect { |b| b.to_i.to_s(16).rjust(2,'0') }.join
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
    end
  end
end
