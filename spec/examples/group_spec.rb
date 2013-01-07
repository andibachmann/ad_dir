require 'spec_helper'

require 'examples/group'

describe "Examples" do
  describe Group do
    
    it "#find('it') should find the group it" do
      g = Group.find('it')
      puts g.inspect
    end

    it ".members should return an array of user DNs" do
      g = Group.find('it')
      puts g.member.join(", ")
    end

  end
end
