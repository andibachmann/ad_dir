#
module AdDir
  # Provides useful functions to de- and encode MS-specific binary fields
  # and timestamps.
  # @see https://msdn.microsoft.com/en-us/library/windows/desktop/ms674984.aspx
  #    Active Directory Schema General Overview 
  #    (https://msdn.microsoft.com/en-us/library/windows/desktop/ms674984.aspx)
  # @see https://msdn.microsoft.com/en-us/library/windows/desktop/ms675085.aspx
  #    Active Directory Schema Definitions
  #    (https://msdn.microsoft.com/en-us/library/windows/desktop/ms675085.aspx)
  module Utilities
    module_function

    # UserAccountControl Properties
    # URL: https://support.microsoft.com/en-us/kb/305144
    # (for further details see {.uac_decode}) and {.compose_uac_code}).
    UAC_PROPERTIES = {
      SCRIPT:                             0x0001,
      ACCOUNTDISABLE:                     0x0002,
      HOMEDIR_REQUIRED:                   0x0008,
      LOCKOUT:                            0x0010,
      PASSWD_NOTREQD:                     0x0020,
      PASSWD_CANT_CHANGE:                 0x0040,
      ENCRYPTED_TEXT_PWD_ALLOWED:         0x0080,
      TEMP_DUPLICATE_ACCOUNT:             0x0100,
      NORMAL_ACCOUNT:                     0x0200,
      INTERDOMAIN_TRUST_ACCOUNT:          0x0800,
      WORKSTATION_TRUST_ACCOUNT:          0x1000,
      SERVER_TRUST_ACCOUNT:               0x2000,
      DONT_EXPIRE_PASSWORD:              0x10000,
      MNS_LOGON_ACCOUNT:                 0x20000,
      SMARTCARD_REQUIRED:                0x40000,
      TRUSTED_FOR_DELEGATION:            0x80000,
      NOT_DELEGATED:                    0x100000,
      USE_DES_KEY_ONLY:                 0x200000,
      DONT_REQ_PREAUTH:                 0x400000,
      PASSWORD_EXPIRED:                 0x800000,
      TRUSTED_TO_AUTH_FOR_DELEGATION:  0x1000000,
      PARTIAL_SECRETS_ACCOUNT:        0x04000000
    }

    # DateTime calulations
    # Docu-URL: http://support.microsoft.com/kb/555936
    #
    #   The Active Directory stores date/time values as the number of
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
    # After the conversion of the MS time format into epoc seconds `Time.at()`
    # is used to return the time in 'localtime'. The local timezone is
    # 'guessed' from the underlying operating system (e.g. `locale`).
    #
    def to_datetime(secs)
      Time.at((secs.to_i / 10_000_000) - 11_676_096_000.0)
    end

    # The MS time string has the format "YYYYMMDDHHmmss.0Z" (e.g.
    # "20140912231209.0Z"). '0Z' denotes the UTC timezone.
    def utc_to_localtime(timestr)
      t = timestr.scan(/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/).first
      Time.utc(t[0], t[1], t[2], t[3], t[4], t[5]).localtime
    end

    # rubocop:disable Metrics/LineLength

    # Decode Microsoft Active Directory Attributes +*objectsid*+
    #
    # Official Docu-Link:
    # https://msdn.microsoft.com/en-us/library/cc230371.aspx
    #
    #     SID= "S-1-" IdentifierAuthority 1*SubAuthority
    #     IdentifierAuthority= IdentifierAuthorityDec / IdentifierAuthorityHex
    #       ; If the identifier authority is < 2^32, the
    #       ; identifier authority is represented as a decimal
    #       ; number
    #       ; If the identifier authority is >= 2^32,
    #       ; the identifier authority is represented in
    #       ; hexadecimal
    #     IdentifierAuthorityDec =  1*10DIGIT
    #       ; IdentifierAuthorityDec, top level authority of a
    #       ; security identifier is represented as a decimal number
    #     IdentifierAuthorityHex = "0x" 12HEXDIG
    #       ; IdentifierAuthorityHex, the top-level authority of a
    #       ; security identifier is represented as a hexadecimal number
    #     SubAuthority= "-" 1*10DIGIT
    #       ; Sub-Authority is always represented as a decimal number
    #       ; No leading "0" characters are allowed when IdentifierAuthority
    #       ; or SubAuthority is represented as a decimal number
    #       ; All hexadecimal digits must be output in string format,
    #       ; pre-pended by "0x"
    #
    # Short Synopsis:
    # http://www.adamretter.org.uk/blog/entries/active-directory-ldap-users-primary-group.xml
    #
    # __Example:__
    #
    #     (raw) objectsid: "\x01\x05\x00\x00\x00\x00\x00\x05\x15\x00\x00\x00\xFF\xA4\xE6\x00\xF8|\xDA3X2=\xF5Q\x04\x00\x00"
    #     decoded        : "S-1-5-21-15115519-869956856-4114428504-1105"
    def decode_sid(sid_str)
      sid_bin   = sid_str.bytes
      # 1st byte - Revision Level
      revision  = sid_bin[0]
      # 2nd byte - count of Sub-Authorities
      count     = sid_bin[1]
      # 3-8 bytes (length: 48bit) -  Authority big-endian
      authority = sid_bin[2..7].join('').to_i
      # sub-authorities
      offset    = 8  # start byte
      size      = 4  # size of chunks, i.e. 4 bytes
      subauths = (0...count.to_i).collect do |i|
        sid_str[(offset + size * i), size].unpack('V*').first
      end
      ['S', revision, authority, subauths].flatten.join('-')
    end
    # rubocop:enable Metrics/LineLength

    # rubocop:disable Metrics/LineLength

    # Documentation URLs:
    #
    #  * http://support2.microsoft.com/default.aspx?scid=kb%3Ben-us%3B325649
    #  * http://serverfault.com/questions/466594/script-to-resolve-guid-to-string-in-active-directory
    #
    # Example:
    #
    #     objectguid = "738c16ee-f742-4b01-bbd7-58ac63d0e85c"
    #     oguid_str  = "\xEE\u0016\x8CsB\xF7\u0001K\xBB\xD7X\xACc\xD0\xE8\\"
    #
    #     Original byte order:
    #
    #               0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15
    #      dec = "238 022 140 115 066 247 001 075 187 215 088 172 099 208 232 092"
    #      hex = " ee  16  8c  73  42  f7  01  4b  bb  d7  58  ac  63  d0  e8  5c"
    #              \------------/  \----/  \----/  \----/  \--------------------/
    #                    |            |       |      |                |
    #                 reverse      reverse reverse   |                |
    #                    |            |       |      |                |
    #              [73 8c 16 ee]   [f7 42] [4b 01] [bb d7]   [58 ac 63 d0 e8 5c]
    #
    def decode_guid(guid_str)
      q = guid_str.unpack('h8h4h4H4H12')
      [q[0..2].map(&:reverse), q[3..4]].flatten.join('-')
    end
    # rubocop:enable Metrics/LineLength

    # Decode the attribute 'useraccountcontrol'
    #
    # @see http://support.microsoft.com/en-us/kb/305144 Microsoft How to 
    #   use the UserAccountControl flags to manipulate user account properties
    # 
    # @example
    #   uac_decode(66048)
    #   # => {:NORMAL_ACCOUNT=>512, :DONT_EXPIRE_PASSWORD=>65536}
    #
    def uac_decode(code)
      # make sure the code is an Integer
      ci = code.to_i

      # Bitwise ANDing of ci and value returns for each bit a 1
      # if (and only if) it is present in both values.
      UAC_PROPERTIES.select { |_, val| val & ci == val }
    end

    # Calculate the binary code for an array of ''user account control''
    # properties.
    #
    # Example:
    #
    #       uac_code = compose_uac_code(
    #         [:DONT_EXPIRE_PASSWORD, :DONT_EXPIRE_PASSWORD, :NORMAL_ACCOUNT])
    #       # => 66048
    def compose_uac_code(*props)
      props.uniq.inject(0) do |sum, prop|
        sum + UAC_PROPERTIES[prop] if UAC_PROPERTIES.key?(prop)
      end.to_s
    end

    # rubocop:disable Metrics/LineLength

    # Converts a plain text password into the ActiveDirectory **`:unicodePwd`**
    # format.
    #
    # **`:unicodePwd`** must be a double quoted password that in UNICODE format
    # (i.e. 16bit unicode lower ending, AKA '`UTF_16LE`').
    #
    # Attribute description:
    #   https://msdn.microsoft.com/en-us/library/cc220961.aspx
    #
    # LDAP specific description:
    #   https://msdn.microsoft.com/en-us/library/cc223248.aspx
    #
    # Windows Example:
    #
    # ```
    # ASCII   'new' :           0x6E      0x65      0x77
    # UTF-16  'new' :           0x6E 0x00 0x65 0x00 0x77 0x00
    # UTF-16 '"new"': 0x22 0x00 0x6E 0x00 0x65 0x00 0x77 0x00 0x22 0x00
    # ```
    #
    # Examples:
    #
    #      unicodepwd("new")
    #      => ""\x00n\x00e\x00w\x00"\x00"
    #
    #      unicodepwd("Hämmerli-dk23#")
    #      => ""\x00H\x00\xE4\x00m\x00m\x00e\x00r\x00l\x00i\x00-\x00d\x00k\x002\x003\x00#\x00"\x00"
    #
    def unicodepwd(plain_pw)
      "\"#{plain_pw}\"".encode(Encoding::UTF_16LE).b
    end
    # rubocop:enable Metrics/LineLength
  end
end
