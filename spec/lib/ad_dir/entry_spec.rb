require 'spec_helper'
require 'ad_dir'


describe AdDir::Entry do

  it "#connection should return a Net::LDAP connection" do
    AdDir::Entry.connection.should be_kind_of(Net::LDAP)
  end

  it "#search is a wrapper for Net::LDAP.search()" do
    filter = Net::LDAP::Filter.eq("sAMAccountName", "bachmann")
    AdDir::Entry.search({:filter => filter, 
        :base => "ou=people,dc=d,dc=geo,dc=uzh,dc=ch"}).size.should > 0
    
  end

  describe "#find_by_xxx method" do
    
    it "find_by_id('bachmann') " do
      AdDir::Entry.find_by_id('bachmann').dn.should =~ /bachmann/
    end

    it "find_by_mail('andi.bachmann@geo.uzh.ch')" do 
      AdDir::Entry.find_by_mail('andi.bachmann@geo.uzh.ch').dn.should =~ /bachmann/
    end

    it "find_by_mail('*bachmann@geo.uzh.ch')" do 
      AdDir::Entry.find_by_mail('*bachmann@geo.uzh.ch').dn.should =~ /bachmann/
    end

    it "find_by_noop('crash') should return nil" do
      AdDir::Entry.find_by_noop('crash').should be_nil
    end

    it ".some_strange_method() should return a NoMethodError" do
      expect { described_class.some_strange_method() }.
        to raise_error(NoMethodError)
    end      
  end

  describe "modifying an entry" do
    # 
    let(:testuser) { AdDir::Entry.find('testuser') }

    
    it "entry[:key] = new_val modifies the value of attribute ':key'" do
      old_val      = testuser[:sn].first
      new_val      = "other value"

      testuser[:sn] = new_val
      AdDir::Entry.find('testuser')[:sn].first.should == new_val

      testuser[:sn] = old_val
      AdDir::Entry.find('testuser')[:sn].first.should == old_val
    end
  end

end
