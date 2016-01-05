require 'spec_helper'
require 'ad_dir'
require 'yaml'

AdDir.establish_connection(YAML.load_file('spec/ad_test.yaml'))

describe AdDir::Entry do
  context 'Finder functionality' do
    let(:testuser) { load_data && @testuser }

    context '.find()' do
      it '#find(<username>)' do
        expect(AdDir::Entry.find('jdoe')).to be_kind_of(AdDir::Entry)
      end

      it '#find_by_cn(\'Doe\')' do
        expect(AdDir::Entry.find_by_cn('*Doe*').cn.first).to match(/Doe/)
      end
    end

    context '.where()' do
      it '{ samaccountname: \'jdoe\'} returns an Array of Entry objects' do
        result = described_class.where(samaccountname: 'jdoe')
        expect(result).to be_kind_of(Array)
        expect(result.first).to be_kind_of(AdDir::Entry)
      end

      context 'with Hash condition (only equality, joined by &&)' do
        it '{ sn: \'Doe\' }' do
          expect(AdDir::Entry.where(sn: 'Doe').first.sn.first).to eq('Doe')
        end

        it '{ sn: \'doe\' }' do
          expect(described_class.where(sn: 'doe').first.sn.first).to eq('Doe')
        end

        it '{ sn: \'doe\', objectclass: \'user\'}' do
          opts = { sn: 'doe', objectclass: 'user' }
          expect(described_class.where(opts).first.sn.first).to eq('Doe')
        end
      end

      context 'with String LDAP Filter (full range of filters!)' do
        let(:ldap_filter) do |example|
          example.description
        end

        it '(sn=doe)' do
          #result = described_class.where(ldap_filter)
          result = described_class.where(ldap_filter)
          expect(result.first.sn.first).to eq('Doe')
        end

        it '(&(sn=doe)(objectclass=user))' do
          result = described_class.where(ldap_filter)
          expect(result.first.sn.first).to eq('Doe')
        end

        it '(|(sn=doe)(mail=*doe*))' do
          result = described_class.where(ldap_filter)
          expect(result.first.sn.first).to eq('Doe')
        end

        it '(&(|(sn=doe)(mail=*doe*))(objectclass=user))' do
          result = described_class.where(ldap_filter)
          expect(result.first.sn.first).to eq('Doe')
        end
      end
    end
  end

  context 'Adding entries to AD' do
    after(:example) do
      # Delete the entry 'hmeier', if it exists
      testentry = AdDir::Entry.find('hmeier')
      testentry.destroy if testentry
    end

    let (:minimal_attrs) {
      { givenname: 'Hans',
        sn: 'Meier',
        objectclass: %w(top person organizationalPerson user),
        userprincipalname: 'hmeier@test.geo.uzh.ch',
        samaccountname: 'hmeier' }
    }

    it '#new(), then #save()' do
      #
      base = 'ou=people,dc=test,dc=geo,dc=uzh,dc=ch'
      dn   = "cn=#{minimal_attrs[:givenname]} #{minimal_attrs[:sn]},#{base}"
      entry = AdDir::Entry.new(dn, minimal_attrs)
      expect(entry.save).to be true
    end

    context 'Trying to create an invalid ActiveDirectory entry' do
      it '#new() with dn, but no attributes' do
        entry = AdDir::Entry.new('cn=A B,ou=people,dc=test,dc=geo,dc=uzh,dc=ch')
        expect(entry.save).to be false
        expect(AdDir.last_op.message).to match(/Violation/)
      end

      it 'create an already existing entry' do
        base   = 'ou=people,dc=test,dc=geo,dc=uzh,dc=ch'
        dn     = "cn=#{minimal_attrs[:givenname]} #{minimal_attrs[:sn]},#{base}"
        entry1 = AdDir::Entry.new(dn, minimal_attrs)
        expect(entry1.save).to be true
        entry2 = AdDir::Entry.new(dn, minimal_attrs)
        expect(entry2.save).to be false
        expect(AdDir.connection.get_operation_result.message
          ).to match(/Entry Already Exists/)
      end
    end
  end

  def prepare_test_entry
    testentry = AdDir::Entry.find('hmeier')
    testentry.destroy if testentry
    #
    hmeier_attrs = {
      givenname: 'Hans',
      sn:        'Meier',
      useraccountcontrol: '66048',
      objectclass: %w(top person organizationalPerson user),
      userprincipalname: 'hmeier@test.geo.uzh.ch',
      unicodepwd: '"ads0-e$f123"'.encode(Encoding::UTF_16LE).b,
      samaccountname: 'hmeier'
    }
    base   = 'ou=people,dc=test,dc=geo,dc=uzh,dc=ch'
    dn     = "cn=#{hmeier_attrs[:givenname]} #{hmeier_attrs[:sn]},#{base}"
    testentry = AdDir::Entry.new(dn, hmeier_attrs)
    testentry.save
  end

  context 'when modifying entries' do
    after(:context) do
      # Delete the entry 'hmeier', if it exists
      testentry = AdDir::Entry.find('hmeier')
      testentry.destroy if testentry
    end

    before(:context) do
      prepare_test_entry
    end

    it '#[:sn] = Müller' do
      entry = AdDir::Entry.find('hmeier')
      entry[:sn] = 'Müller'
      entry.save
      expect(AdDir::Entry.find('hmeier')[:sn]).to eq('Müller')
    end
  end
end
