
#
#
def create_user(firstname, lastname, username, password)
  attrs = {
    objectclass: %w(top person organizationalPerson user inetOrgPerson),
    cn:             "#{firstname} #{lastname}",
    mail:           "#{firstname.downcase}.#{lastname.downcase}@geo.uzh.ch",
    givenname:      firstname,
    sn:             lastname,
    samaccountname: username,
    useraccountcontrol: '66048',
    userprincipalname: "#{username}@test.geo.uzh.ch",
    unicodePwd:     AdDir::Utilities.unicodepwd(password)
  }
  dn = "cn=#{attrs[:cn]},#{AdDir::User.tree_base}"
  AdDir::User.create(dn, attrs)
end

def create_group(name)
  attrs = {
    objectclass: %w{top group},
    samaccountname: name,
    cn: name
  }
  dn = "cn=#{attrs[:cn]},#{AdDir::Group.tree_base}"
  AdDir::Group.create(dn, attrs)
end
