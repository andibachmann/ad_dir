require 'spec_helper'
require 'ad_dir'

describe AdDir::Entry do
  # define a testuser
  let(:testuser) { load_data && @testuser }
  let(:entry_klass) { class_double('AdDir::Entry') }

  describe 'basic functionality' do
    it '#cn returns the value of the \'cn\'-Attribute' do
      expect(testuser.cn.first).to be_kind_of(String)
    end
  end

  context 'finder functionality' do
    #entry = class_double('AdDir::Entry')

    it '#find_by_id(<username>)' do
      allow(entry_klass).to receive(:find_by_id).with('testuser')
        .and_return(testuser)
      allow(entry_klass).to receive(:my_find)
        .with('id', 'testuser') { testuser }
      expect(entry_klass.find_by_id('testuser')).to eq(testuser)
    end
    
    it '#find_by_lastname' do
      allow(entry_klass).to receive(:find_by_lastname).with('Testuser')
        .and_return(testuser)
      allow(entry_klass).to receive(:my_find).with('lastname', 'Testuser')
        .and_return(testuser)
    end

    it '#find_all_by_id("*") returns all users' do
      allow(entry_klass).to receive(:find_all_by_id).with('*')
        .and_return([testuser])
      allow(entry_klass).to receive(:my_find).with('id', '*', :all)
        .and_return([testuser])
      expect(entry_klass.find_all_by_id('*')).to include(testuser)
    end

    it '#find_all_by_id(\'non_existent\') returns an empty array ' do
      allow(entry_klass).to receive(:find_all_by_id).with('non_existent')
        .and_return([])
      allow(entry_klass).to receive(:my_find).with('id', 'non_existent', :all)
        .and_return([])
      expect(entry_klass.find_all_by_id('non_existent')).to be_empty
    end
  end

  xdescribe 'modifying an entry' do
    #
    let(:testuser) { AdDir::Entry.find('testuser') }

    it "entry[:key] = new_val modifies the value of attribute ':key'" do
      old_val      = testuser[:sn].first
      new_val      = 'other value'

      testuser[:sn] = new_val
      expect(AdDir::Entry.find('testuser')[:sn].first).to eq(new_val)

      testuser[:sn] = old_val
      expect(AdDir::Entry.find('testuser')[:sn].first).to eq(old_val)
    end
  end
end
