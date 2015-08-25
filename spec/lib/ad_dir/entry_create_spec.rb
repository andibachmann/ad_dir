require 'spec_helper'
require 'ad_dir'


describe AdDir::Entry do
  it "#create" do
    expect( AdDir::Entry.create( dn:'cn=A B,ou=people,dc=test,dc=geo,dc=uzh,dc=ch', attributes: {firstname: 'A', lastname: 'B'} )).to be_kind_of( AdDir::Entry )
  end

end
