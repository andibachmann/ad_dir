require 'spec_helper'
require 'ad_dir'
require 'yaml'

AdDir.establish_connection(YAML.load_file("spec/ad_test.yaml"))


describe AdDir::Entry do
  context 'Finder functionality' do
    let(:testuser) { load_data && @testuser }

    it '#find_by_id(<username>)' do
      expect(AdDir::Entry.find_by_id('jdoe')).to be_kind_of(AdDir::Entry)
    end

    it '#find_by_cn(\'Doe\')' do
      expect(AdDir::Entry.find_by_cn('*Doe*').cn.first).to match(/Doe/)
    end

    it '#find_all_by_cn(\'Doe*\')' do
      results = AdDir::Entry.find_all_by_cn('*Doe*')
      expect(results).to be_kind_of(Array)
      expect(results.first.cn.first).to match(/Doe/)
    end
  end

  context 'Adding entries to AD' do
    it '#new(\'cn=A B,ou=people,dc=test,dc=geo,dc=uzh,dc=ch\')' do
      entry = AdDir::Entry.new('cn=A B,ou=people,dc=test,dc=geo,dc=uzh,dc=ch')
      expect(entry).to be_kind_of(AdDir::Entry)
    end

    context 'Trying to save a not AD-valid Entry' do
      it '#new(\'cn=A B,ou=people,dc=test,dc=geo,dc=uzh,dc=ch\').save' do
        entry = AdDir::Entry.new('cn=A B,ou=people,dc=test,dc=geo,dc=uzh,dc=ch')
        expect(entry.save).to be_falsy
        #warn AdDir.connection.get_operation_result
        warn entry.connection.get_operation_result
      end
    end
  end
end
