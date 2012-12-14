
module AdDir
  class Entry

    # ----------------------------------------------------------------------
    # CLASS Methods
    #
    class << self
      def connection
        AdDir.connection
      end

      # search(args = {})
      def search(args = {})
        args[:base]    ||= connection.base
        args[:scope]   ||= Net::LDAP::SearchScope_WholeSubtree
        args[:return_result] ||= true
        STDERR.puts args.inspect
        connection.search(args)
      end
      

      # Constructs a DAP::Entry from a Net::LDAP::Entry.
      def from_entry(entry)
        new(entry.dn, entry)
      end
    end
    # 
    # End CLASS Methods
    # ----------------------------------------------------------------------
    
    # Instance methods.
    # 
    attr_reader :attributes

    # Constructs a AdDir::Entry from a +dn+ and an optional Net::LDAP::Entry
    # that has been return from a search.
    def initialize(dn, entry=nil)
      @dn = dn
      @attributes = {}
      if entry
        names = entry.attribte_names.map { |name|
          normalize_name(name) 
        }
        names.delete(:dn)
        @attributes = Hash[
          names.
          map { |name| [
              name, 
              entry[name].
              map { |e| String.new(e) }] }]
      end
    end

    def reload
      
    end

    def [](name)
      val = @attributes[normalize_name(name)]
      val && val.first
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
    
    private
    def normalize_name(name)
      name.to_s.downcase.to_sym
    end
    
  end
end
