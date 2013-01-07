require 'examples/group'

class User < AdDir::Entry

  @base_dn = 'ou=people,dc=d,dc=geo,dc=uzh,dc=ch'

  def groups
    @attributes[:memberof].map { |dn|
      Group.select_dn(dn)
    }
  end

  # 
  # Do not iterate over `.groups` but extract the name from the dn and
  # return the CN part.
  def group_names
    @attributes[:memberof].
      delete_if { |dn| dn =~ /Domain\ Users/ }.
      map { |dn|  dn.split(",").first.split("=").last }
  end

end
