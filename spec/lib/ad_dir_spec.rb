require 'spec_helper'
require 'ad_dir'

describe AdDir do
  it "should have a VERSION constant" do
    expect( subject.const_get('VERSION')).not_to be_empty
  end

  it "#connection should return a connection that binds" do
    expect( subject.connection.bind ).to be_truthy
  end
end
