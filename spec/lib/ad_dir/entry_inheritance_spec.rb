require 'spec_helper'

# Test class to check inheritance of
# AdDir::Entry class
class Person < AdDir::Entry
  self.primary_key = :gecos
  self.tree_base   = 'ou=Chiefs of RE,dc=süper,dc=company,dc=com'
end

describe 'Person < AdDir::Entry (Inheritance)' do
  describe Person do
    context 'Class Functions' do
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
  end
end
