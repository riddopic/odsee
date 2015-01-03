# encoding: UTF-8
#
# Cookbook Name:: garcon
# Provider:: dsccagent
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

use_inline_resources if defined?(:use_inline_resources)

# @return [TrueClass, FalseClass] if WhyRun is supported by this provider.
def whyrun_supported?
  true
end

# The dsccagent command is used to create, delete, start, and stop DSCC agent
# instances on the local system. You can also use the dsccagent command to
# display status and DSCC agent information, and to enable and disable SNMP
# monitoring.

action :create do
  unless exists?
    converge_by 'Creating the DSCC agent instance' do
      run(dsccagent, :create, no_inter, registry_port, admin_pwd)
    end
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info "#{new_resource} already exists - nothing to do"
  end
end

action :delete do
  if exists?
    converge_by 'Deleting the DSCC agent instance' do
      run(dsccagent, :delete, admin_pwd)
    end
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info "#{new_resource} does not exists - nothing to do"
  end
end

action :disable_snmp do
  if snmp?
    converge_by 'Unconfigure the SNMP agent for DSCC agent instance' do
      run(dsccagent, :disable_snmp)
    end
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info "#{new_resource} not configured - nothing to do"
  end
end

action :enable_snmp do
  unless snmp?
    converge_by 'Configure the SNMP agent for DSCC agent instance' do
      run(dsccagent, :enable_snmp)
    end
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info "#{new_resource} already configured - nothing to do"
  end
end

action :start do
  unless running?
    converge_by 'Starting the DSCC agent instance' do
      run(dsccagent, :start)
    end
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info "#{new_resource} is running - nothing to do"
  end
end

action :stop do
  unless stopped?
    converge_by 'Stopping the DSCC agent instance' do
      run(dsccagent, :stop)
    end
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info "#{new_resource} not running - nothing to do"
  end
end

protected #      A T T E N Z I O N E   A R E A   P R O T E T T A

# @return [Chef::Provider::OdseeDsccagent] Load and return the current resource.
def load_current_resource
  @current_resource      ||= new(new_resource.name)
  @current_resource.info   = run(dsccagent, :info, code: [0,125,154]).to_hash
  @current_resource.exists = exists?
  @current_resource.state  = state
  @current_resource.snmp   = snmp?
  @current_resource
end

# @return [TrueClass, FalseClass] if the DSCC Agent instance has been created.
def created?
  @info.has_key?('Instance Path')
rescue
  false
end
alias_method :exists?, :created?

# @return [TrueClass, FalseClass] if the DSCC Agent instance is running.
def running?
  @info['State'] =~ /^Running$/i
rescue
  false
end

# @return [TrueClass, FalseClass] if the DSCC Agent instance is stopped.
def stopped?
  @info['State'] =~ /^Stopped$/i
rescue
  false
end

# @return [String] `Running`, `Stoppend` or `Unknown` for the DSCC Agent.
def state
  @info['State']
rescue
  'Unknown'
end

# @return [TrueClass, FalseClass] true if the SNMP port is set.
def snmp?
  @info['SNMP port'] =~ /^Disabled$/i ? false : true
rescue
  'Unknown'
end

# @return [String] path to command to run.
# @api private
def dsccagent
  ::File.join(node[:odsee][:install_dir], 'dsee7/bin/dsccagent')
end
