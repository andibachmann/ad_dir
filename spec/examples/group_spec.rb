require 'spec_helper'

require 'examples/group'

describe "Group Examples" do
  let(:group) { Group.find('mfp_test') }
  let(:testuser) { User.find('testuser') } 
  
  describe "Group essentials" do
    
    it "#find('<some_name>') finds and returns a Group object" do
      expect(group).to be_kind_of(Group)
    end

    it ".name returns the group's names" do
      expect( group.name).to eq('mfp_test')
    end

    it ".members should return an array of strings of user DNs" do
      if group.members.empty?
        group.add_user( testuser )
        group = Group.find('mfp_test')
      end
      expect( group.members ).to be_kind_of(Array)
      expect( group.members.first).to be_kind_of(String)
      expect( group.members).to include(testuser.dn)
    end

    it ".users should return an array of Users" do
      expect(group.users).to be_kind_of(Array)
      expect(group.users.first).to be_kind_of(User)
    end
  end

  describe "Modifying" do
    let(:user1) { User.find('testuser') } 

    it ".add_user(user) should add the user" do
      group.remove_user(user1) if group.members.include?(user1.dn)
      group.add_user(user1)
      expect(group.members.include?(user1.dn)).to be_truthy
    end

    it ".remove_user(user) removes the user" do
      group.add_user(user1) unless group.members.include?(user1.dn)
      expect( group.members.include?(user1.dn)).to be_truthy
      group.remove_user(user1)
      expect( Group.find('mfp_test').members.include?(user1.dn) ).to be_falsy
    end
  end

end
