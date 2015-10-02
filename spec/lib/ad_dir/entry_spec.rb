require 'spec_helper'
require 'ad_dir'


describe AdDir::Entry do

  
  it "#connection should return nil" do
    expect(AdDir::Entry.connection).to be_nil
  end
  
  it "#search is a wrapper for Net::LDAP.search()" do
    filter = Net::LDAP::Filter.eq("sAMAccountName", "*")
    expect( AdDir::Entry.search({:filter => filter, 
        :base => "ou=people,dc=test,dc=geo,dc=uzh,dc=ch"}).size).to be > 0
    
  end

  describe "basic functionality" do

    let(:testuser) { load_data; @testuser }
    
    it "#objectsid returns the SID as string" do
      expect(testuser.objectsid).to be_kind_of(String)
      expect(testuser.objectsid).to eq("S-1-5-21-2991927633-4205666616-3907629239-5295")
    end

    it "#objectsid_raw returns the encoded SID (ASCII_8bit)" do
      res_ascii = "\x01\x05\x00\x00\x00\x00\x00\x05\x15\x00\x00\x00Q1U\xB28a\xAD\xFA\xB7\xB0\xE9\xE8\xAF\x14\x00\x00".force_encoding(Encoding::ASCII_8BIT)

      expect(testuser.objectsid_raw).to eq( res_ascii )
    end

    it "#objectguid returns the GUID as string" do
      expect(testuser.objectguid).to be_kind_of(String)
      expect(testuser.objectguid).to eq("c3644f86-0b6d-44e2-9f57-ae2aea3df22f")
    end

    it "#created_at returns the creation data" do
      expect(testuser.created_at).to be_kind_of(Time)
      expect(testuser.created_at).to eq(Time.new(2011,9,13,16,1,41,"+02:00"))
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
