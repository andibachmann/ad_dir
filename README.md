ad_dir ActiveDirectory
======================

## Description

`ad_dir` provides a easy interface to ActiveDirectory based on
the `net-ldap` gem.

## Features

`ad_dir` allows to query and manage entries of the AD directory.
Currently, it provides only a {AdDir::User} and a {AdDir::Group} model
based on the base class {AdDir::Entry}.

{AdDir::Entry} is kind of a proxy that wraps most of the instance methods of
`Net::LDAP::Entry` while most of the class methods deal with connecting
to the ActiveDirectory, as well as searching and retrieving entries.


The library tries to provide the same functionalities as given by `ActiveRecord`.

## Examples

```ruby
  require 'ad_dir'
  AdDir.establish_connection(
    host: 'my.nice.com',
    base: 'dc=my,dc=nice,dc=com',
    username: 'cn=manager,dc=example,dc=com',
    password: 'opensesame'
  )
  
  jdoe = AdDir::User.find('jdoe')
  jdoe.groups
  # => [<#AdDir::Group... ]
  jdoe.add_group(AdDir::Group.find('admin'))
```


## Requirements

 * 'net-ldap' >= '0.16'

## Install

``` bash
$ gem install ad_dir
```

