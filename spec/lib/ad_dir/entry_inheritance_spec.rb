require 'spec_helper'

# Test class to check inheritance of
# AdDir::Entry class
class Person < AdDir::Entry
  self.primary_key = :gecos
  self.tree_base   = 'ou=Chiefs of RE,dc=süper,dc=company,dc=com'
end

describe 'Person < AdDir::Entry (Inheritance)' do
  describe Person do
    context 'Class Methods' do
      describe 'when using defaults' do
        context '.primary_key' do
          specify { expect(described_class.primary_key).to eq('gecos') }
        end
        context '.tree_base' do
          specify { expect(described_class.tree_base).to eq(
              'ou=Chiefs of RE,dc=süper,dc=company,dc=com')
          }
        end
      end
    end
    context 'Instance Methods' do
      let(:testuser) { get_my_test('AdDir::Entry', :testuser) }
      it '#attributes[:sn] != Array' do
        expect(testuser.attributes[:sn]).to_not be_kind_of(Array)
      end
      it '#raw_attributes[:sn] == Array' do
        expect(testuser.raw_attributes[:sn]).to be_kind_of(Array)
      end
    end
  end
end
