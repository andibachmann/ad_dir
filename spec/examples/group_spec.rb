require 'spec_helper'

require 'examples/group'

describe "Group Examples" do
  let(:group) { Group.find('mfp_test') }
  
  describe "Group essentials" do
    
    it "#find('<some_name>') finds and returns a Group object" do
      group.class.should == Group
    end

    it ".name returns the group's names" do
      group.name.should == 'mfp_test'
    end

    it ".members should return an array of strings of user DNs" do
      group.members.class.should == Array
      group.members.first.class.should == String
      # group.members.should include("CN=Ab AndiBachmann,OU=People,DC=d,DC=geo,DC=uzh,DC=ch")
    end

    it ".users should return an array of Users" do
      group.users.should be_kind_of(Array)
      group.users.first.should be_kind_of(User)
    end
  end

  describe "Modifying" do
    let(:user1) { User.find('testuser') } 

    it ".add_user(user) should add the user" do
      group.remove_user(user1) if group.members.include?(user1.dn)
      group.add_user(user1)
      group.members.include?(user1.dn).should be_true
    end

    it ".remove_user(user) removes the user" do
      group.add_user(user1) unless group.members.include?(user1.dn)
      group.members.include?(user1.dn).should be_true
      group.remove_user(user1)
      Group.find('mfp_test').members.include?(user1.dn).should be_false
    end
  end

end
