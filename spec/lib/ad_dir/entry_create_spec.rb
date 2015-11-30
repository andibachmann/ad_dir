require 'spec_helper'
require 'ad_dir'

describe AdDir::Entry do
  it '#new(\'cn=A B,ou=people,dc=test,dc=geo,dc=uzh,dc=ch\'' do
    entry = AdDir::Entry.new('cn=A B,ou=people,dc=test,dc=geo,dc=uzh,dc=ch')
    expect(entry).to be_kind_of(AdDir::Entry)
  end

  it '#new(\'cn=A B,ou=people,dc=test,dc=geo,dc=uzh,dc=ch\',\
     name: \'Bingo\')' do
    entry = AdDir::Entry.new(
      'cn=A B,ou=people,dc=test,dc=geo,dc=uzh,dc=ch',
      firstname: 'A', lastname: 'B')
    expect(entry).to be_kind_of(AdDir::Entry)
    expect(entry.firstname.first).to eq('A')
  end

  it '#from_entry(Net::LDAP::Entry)' do
    ldif_example = File.read('spec/support/user_testuser.ldif')
    nete         =  Net::LDAP::Entry.from_single_ldif_string(ldif_example)
    expect(AdDir::Entry.from_ldap_entry(nete)).to be_kind_of(AdDir::Entry)
  end
end
