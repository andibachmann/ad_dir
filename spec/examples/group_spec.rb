require 'spec_helper'

require 'examples/group'

describe "Examples" do
  describe Group do

    group = Group.find('it')
    
    it "#find('it') should find the group it" do
      group.class.should == described_class
    end

    it ".members should return an array of strings of user DNs" do
      group[:member].class.should == Array
      group[:member].first.class.should == String
      group[:member].should include("CN=Thomas Werschlein,OU=People,DC=d,DC=geo,DC=uzh,DC=ch")
    end

    it ".users should return an array of Users" do
      group.users.should be_kind_of(Array)
      group.users.first.should be_kind_of(User)
    end

  end
end
