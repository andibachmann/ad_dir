# encoding: utf-8
#
require 'examples/user'

class Group < AdDir::Entry

  @base_dn = 'ou=groups,dc=d,dc=geo,dc=uzh,dc=ch'

  def users
    @attributes[:member].map { |dn|
      User.select_dn(dn)
    }
  end

  def user_names
    @attributes[:member].map { |dn|
      dn.split(",").first.split("=").last
    }
  end

end
