require 'spec_helper'

require 'examples/user'

describe "Examples" do
  describe User do
    
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
end
