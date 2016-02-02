require 'spec_helper'

#require 'fake_user_helper'

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
  let(:entry_klass) { class_double('AdDir::Entry') }
  let(:testuser) { get_my_test('AdDir::User', :testuser) }

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
      expect(user[:sn]).to eq([new_val])
    end

    it '#objectclass = %w{user inetOrgPerson} (assign [])' do
      new_val = %w{top person organizationalPerson user}
      user.objectclass = new_val
      expect(user[:objectclass]).to eq(new_val)
    end

    it '#[:objectclass] = %w{user inetOrgPerson} (assign [])' do
      new_val = %w{organizationalPerson user}
      user[:objectclass] = new_val
      expect(user[:objectclass]).to eq(new_val)
    end

    it '#sn = val' do
      user.sn = 'bling'
      expect(user.sn).to eq('bling')
    end

    context 'when nothing was changed' do
      let (:user) { testuser.dup }

      it '#changes  => {}' do
        warn user
        expect(user.changes).to be_empty
      end

      it '#changed? => false' do
        expect(user.changed?).to be_falsy
      end
    end

    context 'when object was changed' do
      it '#changes  => {:sn=>[["Test-Lastname"], ["Ha, changed!"]]}' do
        new_val = 'Ha, changed!'
        res_hsh = {sn: [[testuser.sn], [new_val]]}
        user.sn = new_val
        expect(user.changes).not_to be_empty
        expect(user.changes).to eq(res_hsh)
      end

      it '#changed?  => true' do
        user.sn = 'Ha, changed!'
        expect(user.changed?).to be_truthy
      end
    end
  end
end
