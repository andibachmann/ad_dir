# encoding: utf-8

require 'rspec'
require 'ad_dir'

require 'support/load_factories'

RSpec.configure do |c|
  c.filter_run focus: true
  c.run_all_when_everything_filtered = true
end
