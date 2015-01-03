# encoding: UTF-8
#
# Cookbook Name:: garcon
# Provider:: dsconf
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

include Odsee

# The dsconf command manages Directory Server configuration. It enables you to
# modify the configuration entries in cn=config. The server must be running in
# order for you to run dsconf.

use_inline_resources if defined?(:use_inline_resources)

# @return [TrueClass, FalseClass] if WhyRun is supported by this provider.
def whyrun_supported?
  true
end

action :create_suffix do
  unless @current_resource.exists?
    converge_by 'Creating an empty suffix' do
      dsconf :create_suffix, user_dn, port, unsecured, admin_pwd,
                             new_resource.suffix
    end
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info "#{new_resource} already exists - nothing to do"
  end
end

action :delete_suffix do
  if @current_resource.exists?
    converge_by 'Deletes suffix configuration and data' do
      dsconf :delete_suffix, user_dn, port, unsecured, admin_pwd,
                             new_resource.suffix
    end
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info "#{new_resource} does not exists - nothing to do"
  end
end

action :import do
  if empty_suffix?
    converge_by 'Populating suffix with LDIF data' do
      if ::File.exist?(new_resource.ldif)
        dsconf :import, user_dn, port, unsecured, no_inter, async, admin_pwd,
                        new_resource.ldif, new_resource.suffix
      else
        fail Odsee::Exceptions::LDIFNotFoundError, new_resource.ldif
      end
    end
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info "#{new_resource} already exists - nothing to do"
  end
end

protected #      A T T E N Z I O N E   A R E A   P R O T E T T A

# @return [Chef::Provider::OdseeDsconf] Load and return the current resource
def load_current_resource
  @current_resource ||= Chef::Resource::OdseeDsconf.new new_resource.name
  @current_resource.exists = exists?
  @current_resource.info = info
  @current_resource
end

# @return [TrueClass, FalseClass] true if the Directory Server instance has
# been created.
def created?
  @info.has_key?('Suffixes') && @info['Suffixes'] == new_resource.suffix
rescue
  false
end
alias_method :exists?, :created?

# @return [TrueClass, FalseClass] true if more than 1 entry exists in the
# directory Server.
def empty_suffix?
  info['Total entries'].to_i < 2
end

# @return [Hash] with Directory Server instance status.
# => {
#      "Instance path" => "/opt/dsInst",
#       "Global State" => "read-write",
#          "Host Name" => "0edf0419bcea",
#               "Port" => "389",
#        "Secure port" => "636",
#      "Total entries" => "1",
#     "Server version" => "11.1.1.7.0",
#           "Suffixes" => "dc=example,dc=com"
# }
def info
  instance = {}
  cmd = "#{dsconf_cmd} info -e #{admin_pwd}"
  shell_out!(cmd).stdout.split("\n").each do |line|
    next unless line.include?(':')
    key,value = line.to_s.split(':')
    instance[key.strip] = value.strip
  end
  instance
end

# @return [String] connects over LDAP with no secure connection.
# @api private
def unsecured
  '-e'
end

# @return [String] launches a task and returns the command line immediately.
# @api private
def async
  '-a'
end

# @param subcmd [String]
#   With the subcommand.
# @param operand [String, Array]
#   With any additional operand.
#
# @return [String]
#   Result of the execution of the command.
#
# @api private
def dsconf(subcmd, *operand)
  cmd = dsconf_cmd
  subcmd = Hoodie::Inflections.dasherize subcmd.to_s
  (run ||= []) << cmd << subcmd.to_s << operand
  Chef::Log.info shell_out!(run.flatten.join(' ')).stdout
end

# @return [String] path to command to run.
# @api private
def dsconf_cmd
  ::File.join(node[:odsee][:install_dir], 'dsee7/bin/dsconf')
end
