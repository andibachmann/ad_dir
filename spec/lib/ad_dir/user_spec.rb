require 'spec_helper'
require 'fake_user_helper'

describe AdDir::User do
  let(:tuser) { get_my_test('AdDir::User', :testuser) }
  let(:group) { get_my_test('AdDir::Group', :group) }
  let(:primarygroup) { get_my_test('AdDir::Group', :primarygroup) }

  context '#where' do
    it ':filter includes objectfilter' do
      tfilter = Net::LDAP::Filter.eq("objectcategory", "person") &
        Net::LDAP::Filter.eq(:samaccountname, 'testuser')
      allow(AdDir::User).to receive(:connection)
      expect(AdDir::User).to receive(:search).with(hash_including(filter: tfilter)).and_return([tuser])
      AdDir::User.where(samaccountname: 'testuser')
    end
  end
  
  context 'Querying attributes' do
    it '#dn returns the \'Distinct Name\'' do
      expect(tuser.dn).to eq('CN=testuser testuser,OU=People,DC=d,DC=geo,DC=uzh,DC=ch')
    end

    it '#username returns the username' do
      expect(tuser.username).to eq('testuser')
    end

    it '#firstname returns the firstname' do
      expect(tuser.firstname).to eq('Test-Firstname')
    end

    it '#lastname returns the lastname' do
      expect(tuser.lastname).to eq('Test-Lastname')
    end

    it '#mail returns the mail address' do
      expect(tuser.mail).to eq('testuser.testuser@geo.uzh.ch')
    end

    it '#email returns the mail address' do
      expect( tuser.email ).to eq('testuser.testuser@geo.uzh.ch')
    end
  end

  describe 'Querying group relations' do
    it '#primary_group_sid returns the SID of primary group' do
      expect(tuser.primary_group_sid).
        to eq(primarygroup.objectsid_decoded)
    end

    it '#groups returns array of group objects (w/o primary group)' do
      allow(AdDir::Group).to receive(:select_dn).and_return(group)
      expect(tuser.groups).to be_kind_of(Array)
      expect(tuser.groups.first).to be_kind_of(AdDir::Group)
    end

    it '#group_names returns array of group names (w/o primary group)' do
      group_names = tuser.group_names
      expect(group_names).to be_kind_of(Array)
      expect(group_names.first).to be_kind_of(String)
    end
  end

  describe 'Manipulating group memberships' do
    it '#add_group(AdDir::Group)' do
      ngrp_dn = 'cn=ngrp,ou=groups,dc=d,dc=geo,dc=geo,dc=uzh,dc=ch'
      ngrp    = instance_double('AdDir::Group', dn: ngrp_dn)
      allow(ngrp).to receive(:add_user).and_return(ngrp)
      allow(ngrp).to receive(:dn).and_return(ngrp_dn)
      allow(tuser).to receive(:memberof).and_return([ngrp_dn])
      #
      tuser.add_group(ngrp)
      expect(tuser.memberof).to include(ngrp_dn)
    end

    it '#remove_group(AdDir::Group)' do
      allow(group).to receive(:remove_user).with(tuser).and_return(true)
      allow(tuser).to receive(:groups).and_return([])
      tuser.remove_group(group)
      expect(tuser.memberof).to_not include(group.dn)
    end
  end
end
