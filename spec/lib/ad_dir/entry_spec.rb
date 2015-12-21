require 'spec_helper'
require 'ad_dir'

describe AdDir::Entry do
  context 'Class Functions' do
    describe 'when using defaults' do
      context '.primary_key' do
        specify { expect(described_class.primary_key).to eq('samaccountname') }
      end
    end

    context 'when `self.primary_key = :dn`' do
      # Make sure to reset the :unique_attribute
      after(:example) do
        described_class.primary_key = :samaccountname
      end

      it '.primary_key = :dn' do
        described_class.primary_key = :dn
        expect(described_class.primary_key).to eq('dn')
      end

      it '.find() will search with the :dn attribute' do
        described_class.primary_key = 'dn'
        expect(described_class.send(:evaluate_finder_method, :find)).to eq('dn')
      end
    end
  end

  # define a testuser
  let(:testuser) { load_data && @testuser }
  let(:entry_klass) { class_double('AdDir::Entry') }

  describe 'basic functionalities' do
    it '#cn returns the value of the \'cn\'-Attribute' do
      expect(testuser.cn.first).to be_kind_of(String)
    end
  end

  context 'finder functionality' do
    it '#evaluate_finder_method(:find_by_some_attribute) \
       returns \'some_attribute\'' do
      expect(
        # Note: by using :send() we can bypass the `protected` mode
        # for this method
        described_class.send(:evaluate_finder_method, :find_by_some_attributes)
        ).to eq('some_attributes')
    end

    context '.find()' do
      it 'without attribute searches \'samaccountname\'' do
        expect(
          described_class.send(:evaluate_finder_method, :find)
          ).to eq('samaccountname')
      end
    end

    context '.find_by_xx()' do
      it '.find_by_id()' do
        allow(entry_klass).to receive(:find_by_id).with('testuser')
          .and_return(testuser)
        allow(entry_klass).to receive(:my_find)
          .with('id', 'testuser') { testuser }
        expect(entry_klass.find_by_id('testuser')).to eq(testuser)
      end

      it '.find_by_lastname()' do
        allow(entry_klass).to receive(:find_by_lastname).with('Testuser')
          .and_return(testuser)
        allow(entry_klass).to receive(:my_find).with('lastname', 'Testuser')
          .and_return(testuser)
      end
      it '.find_by_nonexistent_attr() will fail' do
        allow(entry_klass).to receive(:find_by_nonexistent_attr)
          .with('Testuser')
          .and_return(nil)
        allow(entry_klass).to receive(:my_find)
          .with('nonexistent_attr', 'Testuser')
          .and_return(nil)
        expect(entry_klass.find_by_nonexistent_attr('Testuser')).to eq(nil)
      end
    end
  end

  describe 'modifying an entry' do
    # Makes sure we have clean object to start with.
    let (:user) { testuser.dup }

    it '#[:key] = val' do
      new_val   = 'other value'
      user[:sn] = new_val
      expect(user[:sn]).to eq(new_val)
    end

    it 'should fail' do
      expect(user[:sn]).to eq('Test-Lastname')
    end

    it '#[:sn]=(value)' do
      user[:sn] = 'bling'
      expect(user[:sn]).to eq('bling')
    end
  end
end
