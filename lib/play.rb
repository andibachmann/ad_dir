#
AdDir.establish_connection(
  host: 'magma.test.geo.uzh.ch',
  base: 'dc=test,dc=geo,dc=uzh,dc=ch',
  username: 'cn=administrator,cn=users,dc=test,dc=geo,dc=uzh,dc=ch',
  password: 'DXB7xfwP4iFfiFet7b'
  )

def minimal(fn, ln, pw)
  firstname = fn
  lastname  = ln
  username  = fn.downcase[0] + ln.downcase[0..7]
  password  = "\"#{pw}\""
  password_enc =  password.encode(Encoding::UTF_16LE).b

  attrs = {
    objectclass: %w(top person organizationalPerson user),
    cn:             "#{firstname} #{lastname}",
    displayname:    "#{firstname} #{lastname}",
    name:           "#{firstname} #{lastname}",
    givenname:      firstname,
    sn:             lastname,
    samaccountname: username,
    useraccountcontrol: '66048',
    userprincipalname: "#{username}@test.geo.uzh.ch",
    unicodePwd:     password_enc,
    homeDirectory:  "\\\\winhome.geo.uzh.ch\\#{username}",
    homeDrive: 'H:',
    profilePath: "\\\\profile.geo.uzh.ch\\profiles$\\#{username}"
  }
  dn = "cn=#{firstname} #{lastname},ou=people,dc=test,dc=geo,dc=uzh,dc=ch"
  [dn, attrs]
end
