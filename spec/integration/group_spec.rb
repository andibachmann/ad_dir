require 'spec_helper'
require 'real_dir_helper'

describe AdDir::Group, integration: true do
  integration_setup
  
  context 'user modifications' do
    before(:context) do
      @tu.destroy if @tu = AdDir::User.find('usertt')
      @tu = create_user('First', 'Last', 'usertt', '1235qwer')
      #
      @gu.destroy if @gu = AdDir::Group.find('grouptt')
      @gu = create_group('grouptt')
    end
    
    it '#add_user(<some_user>)' do
      @gu.add_user(@tu)
      expect(@gu.members).to include(@tu.dn)
    end
    
    it '#remove_user(<some_user>)' do
      fu = @gu.users.first
      @gu.remove_user(fu)
      expect(@gu.members).to_not include(fu.dn)
    end
  end
end
