require 'spec_helper'
require 'ad_dir'


describe AdDir::Entry do

  it "#connection should return a Net::LDAP connection" do
    expect(AdDir::Entry.connection).to be_kind_of(Net::LDAP)
  end

  it "#search is a wrapper for Net::LDAP.search()" do
    filter = Net::LDAP::Filter.eq("sAMAccountName", "bachmann")
    expect( AdDir::Entry.search({:filter => filter, 
        :base => "ou=people,dc=d,dc=geo,dc=uzh,dc=ch"}).size).to be > 0
    
  end

  describe "basic functionality" do
    let(:testuser) { AdDir::Entry.find('testuser') }
    
    it "#objectsid returns the SID as string" do
      expect(testuser.objectsid).to be_kind_of(String)
      expect(testuser.objectsid).to eq("S-1-5-21-2991927633-4205666616-3907629239-5295")
    end

    it "#objectsid_raw returns the encoded SID" do
      expect(testuser.objectsid_raw).to eq("\u0001\u0005\u0000\u0000\u0000\u0000\u0000\u0005\u0015\u0000\u0000\u0000Q1U\xB28a\xAD\xFA\xB7\xB0\xE9\xE8\xAF\u0014\u0000\u0000")
    end

  end

  describe "#find_by_xxx method" do
    
    it "find_by_id('bachmann') " do
      expect( AdDir::Entry.find_by_id('bachmann').dn).to be =~ /bachmann/
    end

    it "find_by_mail('andi.bachmann@geo.uzh.ch')" do 
      expect( AdDir::Entry.find_by_mail('andi.bachmann@geo.uzh.ch').dn).to be =~ /bachmann/
    end

    it "find_by_mail('*bachmann@geo.uzh.ch')" do 
      expect( AdDir::Entry.find_by_mail('*bachmann@geo.uzh.ch').dn).to be =~ /bachmann/
    end

    it "find_by_noop('crash') should return nil" do
      expect( AdDir::Entry.find_by_noop('crash')).to be_nil
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
      expect( AdDir::Entry.find('testuser')[:sn].first).to eq(new_val)

      testuser[:sn] = old_val
      expect( AdDir::Entry.find('testuser')[:sn].first).to eq(old_val)
    end
  end

end
