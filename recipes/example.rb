# encoding: UTF-8
#
# Author: Stefano Harding <sharding@trace3.com>
# Cookbook Name:: odsee
# Recipe:: example
#

single_include 'odsee::default'

require 'tempfile'
require 'securerandom' unless defined?(SecureRandom)

node.set_unless[:odsee][:admin_password] = pwd_hash(SecureRandom.hex)[0..12]
node.set_unless[:odsee][:agent_password] = pwd_hash(SecureRandom.hex)[0..12]
node.save unless Chef::Config[:solo]

# tmp_file = Tempfile.new(SecureRandom.hex(3))
# password_file = tmp_file.path
#
# template password_file do
#   source 'password.erb'
#   sensitive true
#   owner 'root'
#   group 'root'
#   mode 00400
#   action :create
#   notifies :create, 'ruby_block[unlink]'
# end

# ruby_block :unlink do
#   block { tmp_file.unlink }
#   action :nothing
# end

odsee_dsccsetup :ads_create do
  action :ads_create
end

odsee_dsccagent :create do
  action :create
end

odsee_dsccreg '/opt/dsee7/var/dcc/agent' do
  action :add_agent
end

odsee_dsccagent :start do
  action :start
end

odsee_dsadm '/opt/dsInst' do
  action [:create, :start]
end

odsee_dsconf 'dc=example,dc=com' do
  ldif ::File.join(node[:odsee][:install_dir], 'dsee7/resources/ldif/Example.ldif')
  action [:create_suffix, :import]
end

odsee_dsccreg '/opt/dsInst' do
  action :add_server
end
