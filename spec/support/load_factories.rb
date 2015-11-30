# load_factories
#
# Load factory examples based on fixtures in LDIF format.
# The format of the filename defines the class to test.
#
# E.g.:
#
#    user_<somename>.ldif
#    group_<somename>.ldif
#
# The instance is then named ++@<somename>++ and of class
# GiuzAd::Group or GiuzAd::User.
#
def load_data
  examples = Dir.glob('spec/support/*.ldif')
  examples.each do |ex|
    _klass, name = File.basename(ex, '.ldif').split('_')
    nete =  Net::LDAP::Entry.from_single_ldif_string(File.read(ex))
    entry = AdDir::Entry.from_ldap_entry(nete)
    instance_variable_set("@#{name}", entry)
  end
end
