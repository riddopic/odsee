# encoding: UTF-8
#
# Cookbook Name:: garcon
# Provider:: dsccreg
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

# The dsccreg command is used to register server instances on the local system
# with the Directory Service Control Center (DSCC) registry, which may be
# remote.

use_inline_resources if defined?(:use_inline_resources)

# @return [TrueClass, FalseClass] if WhyRun is supported by this provider.
def whyrun_supported?
  true
end

action :add_agent do
  unless agent?(new_resource.path)
    converge_by 'Adding a DSCC agent instance to the DSCC registry' do
      dsccreg :add_agent, admin_pwd, agent_pwd, new_resource.path
    end
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info "#{new_resource} already exists - nothing to do"
  end
end

action :remove_agent do
  if agent?(new_resource.path)
    converge_by 'Remove DSCC agent instance to the DSCC registry' do
      dsccreg :remove_agent, admin_pwd, agent_pwd, new_resource.path
    end
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info "#{new_resource} does not exists - nothing to do"
  end
end

action :add_server do
  unless server?(new_resource.path)
    converge_by 'Adding server instance to the DSCC registry' do
      dsccreg :add_server, admin_pwd, agent_pwd, no_inter, new_resource.path
    end
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info "#{new_resource} already exists - nothing to do"
  end
end

action :remove_server do
  if server?(new_resource.path)
    converge_by 'Remove server instance instance to the DSCC registry' do
      dsccreg :remove_server, admin_pwd, agent_pwd, new_resource.path
    end
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info "#{new_resource} does not exists - nothing to do"
  end
end

protected #      A T T E N Z I O N E   A R E A   P R O T E T T A

# @return [TrueClass, FalseClass] if agent instance added to DSCC registry.
def agent?(path)
  !registry('agents').select { |agent| agent[:ipath] == path }.empty?
end

# @return [TrueClass, FalseClass] if server instances added to DSCC registry.
def server?(path)
  !registry('servers').select { |server| server[:ipath] == path }.empty?
end

# @param instance [String] servers or agents to list entries for.
# @return [Array] of registry entries for given instance.
def registry(instance)
  cmd = "#{dsccreg_cmd} list-#{instance} #{admin_pwd}"
  registry = []
  lines = shell_out!(cmd).stdout.split("\n").reverse
  keys = lines.pop.split(' ').map { |line| line.downcase.to_sym }
  lines.delete_if { |line| line =~ /^--/ }
  lines.each { |line| registry << zip_hash(keys, line.split(' ')) }
  registry
end

# Returns a hash using col1 as keys and col2 as values:
# @example zip_hash([:name, :age, :sex], ['Earl', 30, 'male'])
#   => { :age => 30, :name => "Earl", :sex => "male" }
#
# @param col1 [Array] keys for hash.
# @param col2 [Array] values for hash.
# @return [Hash]
def zip_hash(col1, col2)
  col1.zip(col2).inject({}) { |r,i| r[i[0]] = i[1]; r }
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
def dsccreg(subcmd, *operand)
  cmd = dsccreg_cmd
  subcmd = Hoodie::Inflections.dasherize subcmd.to_s
  (run ||= []) << cmd << subcmd.to_s << operand
  Chef::Log.info shell_out!(run.flatten.join(' ')).stdout
end

# @return [String] path to command to run.
# @api private
def dsccreg_cmd
  ::File.join(node[:odsee][:install_dir], 'dsee7/bin/dsccreg')
end
