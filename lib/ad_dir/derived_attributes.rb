#
module AdDir
  # DerivedAttributes adds some nice attribute getters for binary
  # attributes used solely by ActiveDirectory.
  #
  #
  module DerivedAttributes
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
      @objectguid_decoded ||= Utilities.decode_guid(
        @ldap_entry[:objectguid].first)
    end

    # Returns the binary ObjectSID attribute as regular [String]
    #
    # The conversion is done by {AdDir::Utilities#decode_did}.
    #
    # @see AdDir::Utilities#decode_sid
    # @return [String] the decoded ObjectSID
    def objectsid_decoded
      @objectsid_decoded ||= Utilities.decode_sid(@ldap_entry[:objectsid].first)
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

    # return all derived attributes
    def derived_attributes
      Module.nesting.first.public_instance_methods
    end
  end
end
