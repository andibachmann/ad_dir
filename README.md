# ad_dir - ActiveDirectory #

# Description

`ad_dir` provides an easy interface to ActiveDirectory based on
`net-ldap` gem.

# Features

`ad_dir` allows to query and manage entries of the AD directory

The most important class is `AdDir::Entry`. It is kind of a proxy
the wraps most of the instance methods to Net::LDAP::Entry while
most of the class methods deal with connecting to the ActiveDirectory,
and search and retrieve an entry.


# Examples

  require 'ad_dir'

#  Howto add Entries to ActiveDirectory

## User
Minimal set of attributes:

    require 'yaml'
    AdDir.establish_connection(YAML.load_file('spec/ad_test.yaml'))
    
    firstname = 'Ulrich'
    lastname  = 'Binder'
    username  = 'ubinder'
    password  = "\"eiW4%shaeP12\""
    password_enc =  password.encode(Encoding::UTF_16LE).b
    dn = "cn=#{firstname} #{lastname},ou=people,dc=test,dc=geo,dc=uzh,dc=ch"
    
    attributes = {
        objectclass: ["top","person","organizationalPerson", "user" ],
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
        homeDrive: "H:",
        profilePath: "\\\\profile.geo.uzh.ch\\profiles$\\#{username}"}
    AdDir::Entry.create(dn, attributes)


In the old lib we did:

    "dn: #{aduser.dn}",
    "changetype: add",
    "objectClass: top",
    "objectClass: person",
    "objectClass: organizationalPerson",
    "objectClass: user",
    "cn: #{aduser.firstname} #{aduser.lastname}",
    "sn: #{aduser.lastname}",
    "givenName: #{aduser.firstname}",
    "displayName: #{aduser.firstname} #{aduser.lastname}",
    "name: #{aduser.firstname} #{aduser.lastname}",
    "userAccountControl: 66048",
    "homeDirectory: \\\\winhome.geo.uzh.ch\\#{aduser.username}",
    "homeDrive: H:",
    "profilePath: \\\\profile.geo.uzh.ch\\profiles$\\#{aduser.username}",
    "sAMAccountName: #{aduser.username}",
    "userPrincipalName: #{aduser.username}@#{DOMAIN}",
    "unicodePwd: #{Password.encode(aduser.password, :binary => true)}",


# Requirements

 * `net-ldap` >= 0.11

#Install

    $ gem install ad_dir

# Synopsis

    irb>> AdDir::Entry.find('uid_string')

