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
    expect(entry.firstname).to eq('A')
  end

  it '#from_entry(Net::LDAP::Entry)' do
    ldif_example = File.read('spec/support/user_testuser.ldif')
    nete         =  Net::LDAP::Entry.from_single_ldif_string(ldif_example)
    expect(AdDir::Entry.from_ldap_entry(nete)).to be_kind_of(AdDir::Entry)
  end

  context 'when new, unpersisted object' do
    let (:user) { AdDir::Entry.new('cn=John Doe,ou=mgrs,dc=my,dc=nice,dc=com') }
    it '#new_entry?' do
      expect(user.new_entry?).to be_truthy
    end

    it '#changes => {}' do
      user.sn = 'Doe'
      expect(user.changes).to be_empty
    end

    it '#sn = "Doe"' do
      user.sn = 'Doe'
      expect(user.sn).to eq('Doe')
    end

    it '#[:sn] = "Doe"' do
      user.sn = 'Doe'
      expect(user.sn).to eq('Doe')
      expect(user[:sn]).to eq(['Doe'])
    end
  end
end
