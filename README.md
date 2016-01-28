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


# Requirements

 * `net-ldap` >= 0.13

#Install

    $ gem install ad_dir

# Synopsis

    AdDir::User.find('uid_string')

