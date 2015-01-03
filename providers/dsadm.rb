# encoding: UTF-8
#
# Cookbook Name:: garcon
# Provider:: dsadm
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

# Manages a Directory Server instance. The dsadm command is the local
# administration command for Directory Server instances. The dsadm command must
# be run from the local machine where the server instance is located. This
# command must be run by the username that is the operating system owner of the
# server instance, or by root.

use_inline_resources if defined?(:use_inline_resources)

# @return [TrueClass, FalseClass] if WhyRun is supported by this provider.
def whyrun_supported?
  true
end

action :create do
  unless exists?
    converge_by 'Creating a Directory Server instance' do
      dsadm :create, port, secure_port, admin_pwd, new_resource.path
    end
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info "#{new_resource} already exists - nothing to do"
  end
end

action :delete do
  if exists?
    converge_by 'Deleting a Directory Server instance' do
      dsadm :delete, admin_pwd, new_resource.path
    end
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info "#{new_resource} does not exists - nothing to do"
  end
end

action :start do
  unless running?
    converge_by 'Starting the Directory Server instance' do
      dsadm :start, new_resource.path
    end
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info "#{new_resource} is running - nothing to do"
  end
end

action :stop do
  unless stopped?
    converge_by 'Stopping the Directory Server instance' do
      dsadm :stop, new_resource.path
    end
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info "#{new_resource} not running - nothing to do"
  end
end

protected #      A T T E N Z I O N E   A R E A   P R O T E T T A

# @return [Chef::Provider::OdseeDsadm]
def load_current_resource
  @current_resource ||= Chef::Resource::OdseeDsadm.new new_resource.name
  @current_resource.exists = exists?
  @current_resource.state = state
  @current_resource.info = info
  @current_resource
end

# @return [TrueClass, FalseClass] true if the Directory Server instance has
# been created.
# @api private
def created?
  @info.has_key?('Instance Path')
rescue
  false
end
alias_method :exists?, :created?

# @return [TrueClass, FalseClass] if the Directory Server instance is running.
# @api private
def running?
  @info.state =~ /^Running$/i
rescue
  false
end

# @return [TrueClass, FalseClass] if the Directory Server instance is stopped.
# @api private
def stopped?
  @info.state =~ /^Stopped$/i
rescue
  false
end

# @return [String] `Running`, `Stoppend` or `Unknown` for the state of the
# Directory Server instance.
# @api private
def state
  @info['State']
rescue
  'Unknown'
end

# @return [Hash] with Directory Server instance status.
# @api private
def info
  instance = {}
  cmd = "#{dsadm_cmd} info #{new_resource.path}"
  shell_out!(cmd, returns: [0, 154]).stdout.split("\n").each do |line|
    key, value = line.to_s.split(':')
    instance[key.strip] = value.strip
  end
  instance
end

# @return [String] the server instance owner user ID.
# @api private
def user
  "-u #{new_resource.username}" if new_resource.username
end

# @return [String] the server instance owner's group ID.
# @api private
def group
  "-g #{new_resource.groupname}" if new_resource.groupname
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
def dsadm(subcmd, *operand)
  cmd = dsadm_cmd
  subcmd = Hoodie::Inflections.dasherize subcmd.to_s
  (run ||= []) << cmd << subcmd.to_s << operand
  Chef::Log.info shell_out!(run.flatten.join(' ')).stdout
end

# @return [String] path to command to run.
# @api private
def dsadm_cmd
  ::File.join(node[:odsee][:install_dir], 'dsee7/bin/dsadm')
end
