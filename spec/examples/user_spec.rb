require 'spec_helper'

require 'examples/user'

describe "Examples" do
  describe User do
    describe "accessing" do
      it "#find('bachmann') should find the user 'bachmann'" do
        u = User.find('bachmann')
        u.dn.should =~ /bachmann/
      end

      it "#find_all('*bach*') finds all user with a username =~ '*bach*'" do
        users = User.find_all('*bach*')
        users.size.should >= 1
      end        
      
      it ".group_names should return the group names of a user" do
        u = User.find('bachmann')
        u.group_names.should be_kind_of(Array)
        u.group_names.join(" ").should be_kind_of(String)
      end
    end
    
    describe "Modiyfing a user" do
      let(:user)  { User.find('anditest') }
      let(:group) { Group.find('mfp_test') }
      it ".user[:attribute_name] = <some_string> changes the displayname" do
        old_name = user[:displayname].first
        new_name = "Andis Testuser"
        user[:displayname] = new_name
        user[:displayname].first.should == new_name
        user[:displayname] = old_name
        user[:displayname].first.should == old_name
      end

      it ".add_group(group) makes the user member of the group" do
        group.remove_user(user) if user.group_names.include?(group.name)
        user.add_group(group) 
        group.members.include?(user.dn).should be_true
      end

      it ".remove_group(<group>) removes the user from Group <group>" do
        user.add_group(group) unless user.group_names.include?(group.name)
        user.remove_group(group)
        user.group_names.include?(group.name).should be_true
      end
    end
  end
end
