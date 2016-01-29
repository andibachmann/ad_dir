require 'spec_helper'

describe AdDir::CommonUserAttributes do
  let(:testuser) { get_my_test('AdDir::User', :testuser) }

  context 'when retrieving value' do
    it '.lastname == .sn' do
      expect(testuser.lastname).to eq(testuser.sn)
    end

    it '.email == :mail' do
      expect(testuser.email).to eq(testuser.mail)
    end

    it '.firstname == .givenname' do
      expect(testuser.firstname).to eq(testuser.givenname)
    end

    it '.username == .samaccountname' do
      expect(testuser.username).to eq(testuser.samaccountname)
    end
  end

  context 'when setting value' do
    it '.lastname = "Doey"' do
      testuser.lastname = 'Doey'
      expect(testuser.sn).to eq('Doey')
    end

    it '.firstname = "Jonny"', value: 'jonny' do |ex|
      testuser.firstname = ex.metadata[:value]
      expect(testuser.givenname).to eq(ex.metadata[:value])
    end

    it '.email = "chef@apple.com"', value: 'chef@apple.com' do |ex|
      testuser.email = ex.metadata[:value]
      expect(testuser.mail).to eq(ex.metadata[:value])
    end

    it '.username = "supermario"', value: 'supermario' do |ex|
      testuser.username = ex.metadata[:value]
      expect(testuser.samaccountname).to eq(ex.metadata[:value])
    end
  end
end
