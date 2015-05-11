require 'spec_helper'
require 'ad_dir'

describe AdDir::Utilities do
  let(:extended_class) { Class.new { extend AdDir::Utilities } }

  it "#to_datetime(0).getutc == '1600-01-01 00:00:00 UTC' " do
    expect( extended_class.to_datetime("0").getutc ).to eq(
      Time.utc(1600,1,1,0,0,0))
  end

  it "#utc_to_localtime('20140912231209.0Z') => '2014-09-12 10:12:09 +0200'" do
    time_str = '20140912081209.0Z'
    expect( extended_class.utc_to_localtime(time_str) ).to eq(
        Time.new(2014, 9, 12, 10, 12, 9,"+02:00") )
  end
  
  it "#decode_sid(objectsid_str) => \"S-1-5-21-2991927633-4205666616-3907629239-3790\"" do
    objectsid = "\u0001\u0005\u0000\u0000\u0000\u0000\u0000\u0005\u0015\u0000\u0000\u0000Q1U\xB28a\xAD\xFA\xB7\xB0\xE9\xE8\xCE\u000E\u0000\u0000"
    expect( extended_class.decode_sid(objectsid) ).to eq("S-1-5-21-2991927633-4205666616-3907629239-3790")
  end
  
  it "#decode_guid(objectguid) => \"738c16ee-f742-4b01-bbd7-58ac63d0e85c\"" do
    objectguid_str = "738c16ee-f742-4b01-bbd7-58ac63d0e85c"
    objectguid     = "\xEE\u0016\x8CsB\xF7\u0001K\xBB\xD7X\xACc\xD0\xE8\\"
    expect( extended_class.decode_guid(objectguid) ).to eq(objectguid_str)
  end

  it "#bytes_to_hex([....]) => to hex" do
    byte_arr = "\xEE\u0016\x8CsB\xF7\u0001K\xBB\xD7X\xACc\xD0\xE8\\".bytes
    hex_string = "ee168c7342f7014bbbd758ac63d0e85c"
    expect( extended_class.bytes_to_hex(byte_arr) ).to eq(hex_string)
  end

  
  it "#uac_decode('66050') returns the properties" do
    code = "66050"
    result = extended_class.uac_decode(code) 
    expect( result ).to be_kind_of(Hash)
    expect( result.keys ).to include(:ACCOUNTDISABLE, :NORMAL_ACCOUNT, :DONT_EXPIRE_PASSWORD)
  end

  it "#compose_uac_code returns the uac_code" do
    props = [:ACCOUNTDISABLE, :NORMAL_ACCOUNT, :DONT_EXPIRE_PASSWORD]
    result = extended_class.compose_uac_code(*props)
    expect( result ).to eq("66050")

  end

end
