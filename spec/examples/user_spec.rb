require 'spec_helper'
require 'patch'

require 'examples/user'

describe "Examples" do
  describe User do
    describe "accessing" do
      it "#find('bachmann') should find the user 'bachmann'" do
        u = User.find('bachmann')
        expect(u.dn).to match(/bachmann/)
      end

      it "#find_all('*bach*') finds all user with a username =~ '*bach*'" do
        users = User.find_all('*bach*')
        expect(users.size).to be >= 1
      end        
      
      it ".group_names should return the group names of a user" do
        u = User.find('bachmann')
        expect( u.group_names).to be_kind_of(Array)
        expect( u.group_names.join(" ")).to be_kind_of(String)
      end
    end
    
    describe "Modiyfing a user" do
      let(:user)  { User.find('anditest') }
      let(:group) { Group.find('mfp_test') }
      it ".user[:attribute_name] = <some_string> changes the displayname" do
        old_name = user[:displayname].first
        new_name = "Andis Testuser"
        user[:displayname] = new_name
        expect( user[:displayname].first ).to be == new_name
        user[:displayname] = old_name
        expect( user[:displayname].first ).to be == old_name
      end

      it ".add_group(group) makes the user member of the group" do
        group.remove_user(user) if user.group_names.include?(group.name)
        user.add_group(group) 
        expect(group.members.include?(user.dn)).to  be_truthy
      end

      it ".remove_group(<group>) removes the user from Group <group>" do
        user.add_group(group) unless user.group_names.include?(group.name)
        user.remove_group(group)
        expect(user.group_names.include?(group.name)).to be_truthy
      end
    end

    describe "encoding" do
      let(:user)  { User.find('smaechle') }
      it "<Mächle> in user[:sn].encoding = UTF-8" do
        expect( user[:sn].first.encoding ).to be == Encoding::UTF_8
      end
    end
  end
end
