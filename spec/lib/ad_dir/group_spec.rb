require 'spec_helper'

describe AdDir::Group do
  let(:testuser) { get_my_test('AdDir::User', :testuser) }
  let(:group) { get_my_test('AdDir::Group', :group) }
  let(:primarygroup) { get_my_test('AdDir::Group', :primarygroup) }

  context 'Querying attributes' do
      it '#name displays the name' do
      expect(group.name ).to eq('geo000_s')
    end

    it '#users_usernames  => [<String>]' do
      # mocking '#users'
      expect(group).to receive(:users).and_return([testuser])
      expect(group.users_usernames).to include('testuser')
    end

    it '#users => [<GiuzAd::User>]' do
      expect(group).to receive(:users).and_return([testuser])
      users = group.users
      expect(users).to be_kind_of(Array)
      expect(users.first).to be_kind_of(AdDir::User)
    end

    it '#members => [dn, dn2, ...]' do
      expect(group).to receive(:members).and_return([testuser.dn])
      members = group.members
      expect(members).to be_kind_of(Array)
      expect(members).to include(testuser.dn)
    end

    it '#updated_at' do
      expect(group.updated_at).to be_kind_of(Time)
    end

    it '#created_at' do
      expect( group.created_at ).to be_kind_of(Time)
    end
  end

  context 'when not Primary Group' do
    it '#primary_group? to be false' do
      expect(group).to receive(:primary_user).and_return(nil)
      expect(group.primary_group?).to be_falsy
    end

    it '#primary_user to be nil' do
      expect(group).to receive(:primary_user).and_return(nil)
      expect(group.primary_user).to be_nil
    end
  end

  context 'when Primary Group' do
    it '#primary_group? => true' do
      expect(primarygroup).to receive(:primary_user).and_return(testuser)
      expect(primarygroup.primary_group?).to be_truthy
    end

    it '#primary_user not empty' do
      expect(primarygroup).to receive(:primary_user).and_return(testuser)
      expect(primarygroup.primary_user).to be_kind_of(AdDir::User)
    end
  end

  context 'modifying members' do
    it '#add_user' do
      nu_dn = 'cn=hansi hintersehr,ou=people,dc=d,dc=geo,dc=geo,dc=uzh,dc=ch'
      nu    = instance_double('AdDir::User', dn: nu_dn)
      allow(group).to receive(:modify).and_return(group.members << nu_dn)
      allow(group).to receive(:users).and_return([nu])
      #
      group.add_user(nu)
      expect(group.members).to include(nu_dn)
    end

    it '#remove_user' do
      allow(group).to receive(:modify).and_return([])
      allow(group).to receive(:users).and_return([])
      #
      group.remove_user(testuser)
      expect(group.members).to_not include(testuser.dn)
    end
  end
end
