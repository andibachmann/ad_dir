#
# ATTENTION: This is a monkey patch for
#            Net::BER::BerIdentifiedString
#
module Net
  module BER
    class BerIdentifiedString
      def initialize(args)
        super
        #
        # Check the encoding of the newly created String and set the encoding
        # to 'UTF-8' (NOTE: we do NOT change the bytes, but only set the
        # encoding to 'UTF-8').
        current_encoding = encoding
        if current_encoding == Encoding::BINARY
          force_encoding(Encoding::UTF_8)
          force_encoding(current_encoding) unless valid_encoding?
        end
      end
    end
  end
end
