require 'spec_helper'

require 'examples/user'

describe "Examples" do
  describe User do
    describe "accessing" do
      it "#find('bachmann') should find the user 'bachmann'" do
        us1 = User.find_all('*bach*')
        puts us1.size
        u = User.find('bachmann')
        # puts u.inspect
        # puts u.groups.join(", ")
        us1.first.dn.should =~ /bachmann/
        #puts u.groups[4].inspect
      end
      
      it ".group_names should return the group names of a user" do
        u = User.find('bachmann')
        u.group_names.should be_kind_of(Array)
        u.group_names.join(" ").should be_kind_of(String)
      end
    end
    
    describe "Modiyfing a user" do
      let(:user) { User.find('anditest') }

      it ".user[:attribute_name] = <some_string> changes the displayname" do
        old_name = user[:displayname].first
        new_name = "Andis Testuser"
        user[:displayname] = new_name
        user[:displayname].first.should == new_name
        user[:displayname] = old_name
        user[:displayname].first.should == old_name
      end

      it ".add_group(group) makes the user member of the group" do
        #
      end
    end
  end
end
