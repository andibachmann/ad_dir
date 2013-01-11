require 'spec_helper'

require 'examples/group'

describe "Examples" do
  let(:group) { Group.find('mfp_test') }
  
  describe Group do
    it "#find('it') should find the group it" do
      group.class.should == described_class
    end

    it ".members should return an array of strings of user DNs" do
      group[:member].class.should == Array
      group[:member].first.class.should == String
      group[:member].should include("CN=Ab AndiBachmann,OU=People,DC=d,DC=geo,DC=uzh,DC=ch")
    end

    it ".users should return an array of Users" do
      group.users.should be_kind_of(Array)
      group.users.first.should be_kind_of(User)
    end
  end

  describe "Modifying" do
    let(:user1) { User.find('testuser') } 

    it ".add_user(user) should add the user" do
      group.member_dns.include?(user1.dn).should be_false
      group.add_user(user1)
      group.member_dns.include?(user1.dn).should be_true
    end

    it ".remove_user(user) removes the user" do
      group.remove_user(user1)
      Group.find('mfp_test').member_dns.include?(user1.dn).should be_false
    end

  end
end
