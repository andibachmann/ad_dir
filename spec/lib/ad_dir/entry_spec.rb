require 'spec_helper'
require 'ad_dir'


describe AdDir::Entry do

  it "#connection should return the connection" do
    AdDir::Entry.connection.should be_true
  end

  it "@base_dn should return" do
    e = AdDir::Entry.new("dn=bachmann")
    puts e.base_dn
    puts e.attributes.keys.join(". ")
  end

  it "#search should work like a charm" do
    filter = Net::LDAP::Filter.eq("sAMAccountName", "bachmann")
    e = AdDir::Entry.search({:filter => filter, 
        :base => "ou=people,dc=d,dc=geo,dc=uzh,dc=ch"})
    puts e.inspect
  end

end
