module Net::BER::Extensions::String
	##
	# Converts a string to a BER string but does *not* encode to UTF-8 first.
	# This is required for proper representation of binary data for Microsoft
	# Active Directory
	def to_ber_bin(code = 0x04)
		[code].pack('C') + length.to_ber_length_encoding + self
	end

  def raw_utf8_encoded
    if self.respond_to?(:encode)
      # Strings should be UTF-8 encoded according to LDAP.
      # However, the BER code is not necessarily valid UTF-8
      begin
        #self.encode('UTF-8').force_encoding('ASCII-8BIT')
        self.encode('UTF-8', invalid: :replace, undef: :replace, replace: '' ).force_encoding('ASCII-8BIT')
      rescue Encoding::UndefinedConversionError
        self
      rescue Encoding::ConverterNotFoundError
        return self
      end
    else
      self
    end
  end

end
