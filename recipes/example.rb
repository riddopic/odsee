# encoding: UTF-8
#
# Author: Stefano Harding <sharding@trace3.com>
# Cookbook Name:: odsee
# Recipe:: example
#

single_include 'odsee::default'

require 'securerandom' unless defined?(SecureRandom)

node.set_unless[:odsee][:dsm_password] = create_hash(SecureRandom.hex)[0..12]
node.set_unless[:odsee][:agent_password] = node[:odsee][:dsm_password]
node.save unless Chef::Config[:solo]

template node[:odsee][:pwd_file] do
  source 'password.erb'
  sensitive true
  owner 'root'
  group 'root'
  mode 00400
  notifies :delete, "template[#{node[:odsee][:pwd_file]}]"
  action :create
end

dsccsetup :ads_create do
  pwd_file node[:odsee][:pwd_file]
  action :ads_create
end

dsccagent :create do
  pwd_file node[:odsee][:pwd_file]
  action :create
end

dsccreg '/opt/dsee7/var/dcc/agent' do
  pwd_file node[:odsee][:pwd_file]
  agent_pwd_file node[:odsee][:agent_pwd_file]
  action :add_agent
end

dsccagent :start do
  pwd_file node[:odsee][:pwd_file]
  action :start
end

dsadm '/opt/dsInst' do
  pwd_file node[:odsee][:pwd_file]
  action [:create, :start]
end

dsconf 'dc=example,dc=com' do
  pwd_file node[:odsee][:pwd_file]
  ldif ::File.join(node[:odsee][:install_dir], 'dsee7/resources/ldif/Example.ldif')
  action [:create_suffix, :import]
end

dsccreg '/opt/dsInst' do
  pwd_file node[:odsee][:pwd_file]
  agent_pwd_file node[:odsee][:agent_pwd_file]
  notifies :delete, "template[#{node[:odsee][:pwd_file]}]", :immediately
  action :add_server
end
