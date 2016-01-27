require 'spec_helper'
require 'real_dir_helper'

describe AdDir::User, integration: true do
  integration_setup

  context 'group modifications' do
    before(:context) do
      @tu.destroy if @tu = AdDir::User.find('usertt')
      @tu = create_user('First', 'Last', 'usertt', '1235qwer')
      #
      @gu.destroy if @gu = AdDir::Group.find('grouptt')
      @gu = create_group('grouptt')
    end

    it '#add_group(<some_grp>)' do
      @tu.add_group(@gu)
      expect(@tu.memberof).to include(@gu.dn)
    end

    it '#remove_group(<some_grp>)' do
      fg = @tu.groups.first
      @tu.remove_group(fg)
      expect(@tu.memberof).to_not include(fg.dn)
    end
  end
end
