module AdDir
  # Defines some common attributes for the user model, that provide aliases
  # for the attribute names given by Microsofts Active Directory Schema.
  #
  #
  module CommonUserAttributes
    # Provide a hash with new and old name for each redefined attribute.
    # @example
    #   class A
    #      extend CommonUserAttributes
    #      map_common_attrs(lastname: :sn, firstname: :givenname)
    #   end
    #   # Then use it like this:
    #   user = AdDir::User.find('jdoe')
    #   user.lastname == user.sn
    #   # => true
    #
    def map_common_attrs(hsh)
      @common_attrs = hsh
      hsh.each do |attr_alias, attr_orig|
        define_method(attr_alias) do
          __send__(attr_orig)
        end
        #
        define_method("#{attr_alias}=") do |val|
          __send__("#{attr_orig}=", val)
        end
      end
    end
  end
end
