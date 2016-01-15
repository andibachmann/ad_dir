require 'spec_helper'
require 'ad_dir'

describe AdDir::DerivedAttributes do
  # define a testuser
  let(:testuser) { load_data && @testuser }

  # Keep this hash manually in sync with {#derived_attribute_names}!
  all_methods = {
    # method:           Result
    updated_at:         Time.new(2015,3,10,16,54,9,'+01:00'),
    created_at:         Time.new(2011,9,13,16,01,41,'+02:00'),
    objectguid_decoded: 'c3644f86-0b6d-44e2-9f57-ae2aea3df22f',
    objectsid_decoded:  'S-1-5-21-2991927633-4205666616-3907629239-5295',
  }

  all_methods.each do |meth, val|
    it "##{meth} => [#{val.class}]" do
      expect(testuser.send(meth)).to eq(val)
    end
  end

  it '#derived_attribute_names' do
    expect(testuser.derived_attribute_names).to be_kind_of(Array)
    expect(all_methods.keys).to include(*testuser.derived_attribute_names)
  end
end
