# encoding: UTF-8

name             'odsee'
maintainer       'Stefano Harding'
maintainer_email 'sharding@trace3.com'
license          'Apache 2.0'
description      'Installs/Configures Oracle Directory Server Enterprise Edition'
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.2.1'

supports 'centos',      '>= 6.0'
supports 'oracle',      '>= 6.0'
supports 'redhat',      '>= 6.0'
supports 'scientific',  '>= 6.0'

# Pessimistic versioning of cookbooks is specifically done to prevent any
# possible variation in cookbook versions.
#
depends 'chef_handler', '~> 1.1.6'
depends 'garcon',       '~> 0.8.5'
