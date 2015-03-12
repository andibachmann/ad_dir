#
module AdDir
  module Utilities

    # DateTime calulations
    # Docu-URL: http://support.microsoft.com/kb/555936 The
    # 
    #   Active Directory stores date/time values as the number of
    #   100-nanosecond intervals that have elapsed since the 0 hour on
    #   January 1, 1601 till the date/time that is being stored. The
    #   time is always stored in Greenwich Mean Time (GMT) in the
    #   Active Directory. Some examples of Active Directory attributes
    #   that store date/time values are LastLogon, LastLogonTimestamp
    #   and LastPwdSet. In order to obtain the date/time value stored
    #   in these attributes into a standard format, some conversion is
    #   required. This article describes how this conversion can be
    #   done.
    # 
    def to_datetime(timestamp)
      Time.at( (timestamp.to_i/10000000) - 11676009600 )
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

  end
end
