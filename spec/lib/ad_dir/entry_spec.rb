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
    puts e.first[:memberof].class
    puts e.first.samaccountname.inspect
    # puts e.inspect
  end

  describe "#find_by_xxx method" do
    
    it "find_by_id('bachmann') " do
      AdDir::Entry.find_by_id('bachmann').dn.should =~ /bachmann/
    end

    it "find_by_email('andi.bachmann@geo.uzh.ch')" do 
      AdDir::Entry.find_by_mail('andi.bachmann@geo.uzh.ch').dn.should =~ /bachmann/
    end

    it "find_by_email('*bachmann@geo.uzh.ch')" do 
      AdDir::Entry.find_by_mail('*bachmann@geo.uzh.ch').dn.should =~ /bachmann/
    end

    it "find_by_noop('crash') should return nil" do
      AdDir::Entry.find_by_noop('crash').should be_nil
    end

    it ".some_really_strange_method() should return a NoMethodError" do
      lambda { AdDir::Entry.some_really_strange_method() }.
        should raise_error(NoMethodError)
    end      

  end

end
