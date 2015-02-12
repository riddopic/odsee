# encoding: UTF-8
#
# Cookbook Name:: odsee
# Cookbook:: example
#
# Author:    Stefano Harding <riddopic@gmail.com>
# License:   Apache License, Version 2.0
# Copyright: (C) 2014-2015 Stefano Harding
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#       T H I S   I S   A   E X A M P L E   R E C I P E   F O R
#       D E M O N S T R A T I O N   P U R P O S E S   O N L Y !

single_include 'odsee::install'

# Generate passwords if none are provided, passwords are saved in the node
# attributes, at the moment unencrypted although encrypting them does not
# provide any level of protection because the machine must always be able to
# decrypt the keys when required.
#
# There are different passwords for various components, they could all be set
# the same for simplicity or each can be different.
#
require 'securerandom' unless defined?(SecureRandom)
monitor.synchronize do
  node.set_unless[:odsee][:admin_passwd] = pwd_hash(SecureRandom.hex)[0..12]
  node.set_unless[:odsee][:agent_passwd] = pwd_hash(SecureRandom.hex)[0..12]
  node.set_unless[:odsee][:cert_passwd]  = pwd_hash(SecureRandom.hex)[0..12]
  node.save unless Chef::Config[:solo]
end

# This is an example of how you can use the providers in this cookbook to create
# a LDAP directory tree. We create the dc=example,dc=com suffix and use the
# supplied Example.ldif file to populate the directory.

base_ldif = ::File.join(
  node[:odsee][:install_dir], 'dsee7/resources/ldif/Example.ldif'
)

dsccsetup :create do
  action :ads_create
end

dsccagent node[:odsee][:agent_path].call do
  action :create
end

dsccreg node[:odsee][:agent_path].call do
  action :add_agent
end

dsccagent node[:odsee][:agent_path].call do
  action :start
end

dsadm node[:odsee][:instance_path] do
  action [:create, :start]
end

dsconf node[:odsee][:suffix] do
  path node[:odsee][:instance_path]
  ldif_file base_ldif
  action [:create_suffix, :import]
end

dsccreg node[:odsee][:instance_path] do
  action :add_server
end
