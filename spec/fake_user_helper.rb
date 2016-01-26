#
# As we are heavily using `method_missing` to access attribute values
# the common usage of **verifying instance doubles** of Rspec fails.
# rspec mocks try to verify every single method call and fails with dynamic
# method calls
# @see {http://www.relishapp.com/rspec/rspec-mocks/v/3-4/docs/verifying-doubles/dynamic-classes}
# 
# Providing a method 'define_attr_meths' we can tell rspec to look up and
# verify dynamic calls.
#
# Note: The array `ATTRS` must be maintained! all 'attribute' calls must
#   be present.
class AdDir::Entry
  ATTRS = %w[name dn id lastname]
  def self.define_attr_meths
    ATTRS.each do |attr|
      define_method(attr) { send(:get_value, attr) }
    end
  end
end

RSpec.configuration.mock_with(:rspec) do |config|
  config.before_verifying_doubles do |reference|
    reference.target.define_attr_meths
  end
end
