# encoding: UTF-8
#
# Cookbook Name:: odsee
# Cookbook:: example
#
# Author: Stefano Harding <riddopic@gmail.com>
#
# Copyright (C) 2014-2015 Stefano Harding
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

single_include 'odsee::default'

require 'securerandom' unless defined?(SecureRandom)

# Generate passwords if none are provided, passwords are saved in the node
# attributes, at the moment unencrypted although encrypting them does not
# provide any level of protection becasue the machine must always be able to
# decrypt the keys when required.
#
# There are different passwords for various components, they could all be set
# the same for simplicity or each can be different.
#
monitor.synchronize do
  node.set_unless[:odsee][:admin_password] = pwd_hash(SecureRandom.hex)[0..12]
  node.set_unless[:odsee][:agent_password] = pwd_hash(SecureRandom.hex)[0..12]
  node.set_unless[:odsee][:cert_password]  = pwd_hash(SecureRandom.hex)[0..12]
  node.save unless Chef::Config[:solo]
end

# This is an example of how you can use the providers in this cookbook to create
# a LDAP directory tree. There are many advantages to using Chef providers over
# scripts ensuring that you have a reproducable envirment ....but if you are not compertable with Ruby I don't not suggest you make
# any modifications

dsccsetup :ads_create do
  action :ads_create
end

dsccagent node[:odsee][:agent_path].call do
  action :create
end

dsccreg '/opt/dsee7/var/dcc/agent' do
  action :add_agent
end

dsccagent node[:odsee][:agent_path].call do
  action :start
end

dsadm '/opt/dsInst' do
  action [:create, :start]
end

dsconf 'dc=example,dc=com' do
  ldif_file ::File.join(node[:odsee][:install_dir],
    'dsee7/resources/ldif/Example.ldif')
  action [:create_suffix, :import]
end

dsccreg '/opt/dsInst' do
  action :add_server
end
