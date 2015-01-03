# encoding: UTF-8
#
# Cookbook Name:: garcon
# Provider:: dsccsetup
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

# The dsccsetup command is used to deploy Directory Service Control Center
# (DSCC) in an application server, and to register local agents of the
# administration framework.

use_inline_resources if defined?(:use_inline_resources)

# @return [TrueClass, FalseClass] if WhyRun is supported by this provider.
def whyrun_supported?
  true
end

action :ads_create do
  unless @current_resource.exists?
    converge_by 'Initialize the DSCC registry' do
      dsccsetup :ads_create, registry_port, agent_port, admin_pwd
    end
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info "#{new_resource} already exists - nothing to do"
  end
end

action :ads_delete do
  if @current_resource.exists?
    converge_by 'Deleting the DSCC Registry' do
      dsccsetup :ads_delete, admin_pwd
    end
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info "#{new_resource} does not exists - nothing to do"
  end
end

protected #      A T T E N Z I O N E   A R E A   P R O T E T T A

# @return [Chef::Provider::OdseeDsccsetup] Load and return the current resource
def load_current_resource
  @current_resource ||= Chef::Resource::OdseeDsccsetup.new new_resource.name
  @current_resource.exists = ads_created?
  @current_resource
end

# @return [TrueClass, FalseClass] if the DSCC Registry has been created.
def ads_created?
  cmd = "#{dsccsetup_cmd} status"
  shell_out!(cmd).stdout.include?('DSCC Registry has been created')
rescue
  false
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
def dsccsetup(subcmd, *operand)
  cmd = dsccsetup_cmd
  subcmd = Hoodie::Inflections.dasherize subcmd.to_s
  (run ||= []) << cmd << subcmd.to_s << operand
  Chef::Log.info shell_out!(run.flatten.join(' ')).stdout
end

# @return [String] path to command to run.
# @api private
def dsccsetup_cmd
  ::File.join(node[:odsee][:install_dir], 'dsee7/bin/dsccsetup')
end
