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
monitor.synchronize do
  node.set_unless[:odsee][:admin_password] = pwd_hash(SecureRandom.hex)[0..12]
  node.set_unless[:odsee][:agent_password] = pwd_hash(SecureRandom.hex)[0..12]
  node.set_unless[:odsee][:cert_password]  = pwd_hash(SecureRandom.hex)[0..12]
  node.save unless Chef::Config[:solo]
end

dsccsetup :ads_create do
  action :ads_create
end

dsccagent :create do
  action :create
end

dsccreg '/opt/dsee7/var/dcc/agent' do
  action :add_agent
end

dsccagent :start do
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
