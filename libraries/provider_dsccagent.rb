# encoding: UTF-8
#
# Cookbook Name:: garcon
# HWRP:: dsccagent
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

# A Chef provider for the Oracle Directory Server dsccagent resource.
#
# The dsccagent command is used to create, delete, start, and stop DSCC agent
# instances on the local system. You can also use the dsccagent command to
# display status and DSCC agent information, and to enable and disable SNMP
# monitoring.
#
class Chef::Provider::Dsccagent < Chef::Provider::LWRPBase
  include Odsee

  use_inline_resources if defined?(:use_inline_resources)

  # Boolean indicating if WhyRun is supported by this provider.
  #
  # @return [TrueClass, FalseClass]
  #
  # @api private
  def whyrun_supported?
    true
  end

  # Load and return the current resource.
  #
  # @return [Chef::Resource::Dsccagent]
  #
  # @api private
  def load_current_resource
    @current_resource ||= Chef::Resource::Dsccagent.new(new_resource.name)
    @current_resource.info = info
    @current_resource.exists = exists?('Instance Path')
    @current_resource.state = state
    @current_resource.snmp = snmp?
    @current_resource
  end

  # Creates a DSCC agent instance.
  #
  # @param [TrueClass, FalseClass] no_inter
  #   Does not prompt for password.
  #
  # @param [Integer] agent_port
  #   Specifies DSCC agent port. The default is 3997.
  #
  # @param [String] agent_pw_file
  #   Use the Direcctory Service Agent password specified in file.
  #
  # @param [String] agent_path
  #   Full path to the existing DSCC agent instance. The default path is to use:
  #   install-path/var/dcc/agent
  #
  # @return [Chef::Resource::Dsccagent]
  #
  # @api private
  def action_create
    if exists?
      Chef::Log.info "#{new_resource} already created - nothing to do"
    else
      converge_by 'Creating the DSCC agent instance' do
        begin
          dsccagent :create, new_resource._?(:no_inter,      '-i'),
                             new_resource._?(:agent_port,    '-p'),
                             new_resource._?(:agent_pw_file, '-w'),
                             new_resource.agent_path

          Chef::Log.info "DSCC agent instance initialized for #{new_resource}"
        ensure
          if ::File.exist?(new_resource.agent_pw_file.split.last)
            Chef::Log.debug "Removing Direcctory Service Agent password file"
            ::File.unlink new_resource.agent_pw_file.split.last
          end
        end
        new_resource.updated_by_last_action(true)
      end
    end
  end

  # Deletes a DSCC agent instance.
  #
  # @param [String] agent_path
  #   Path to the DSCC agent instance. Default is install-path/var/dcc/agent.
  #
  # @return [Chef::Resource::Dsccagent]
  #
  # @api private
  def action_delete
    if exists?
      converge_by "Deleting the DSCC agent instance for #{new_resource}" do
        dsccagent :delete, new_resource.agent_path

        Chef::Log.info "DSCC agent instance deleted for #{new_resource}"
      end
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.info "#{new_resource} does not exists - nothing to do"
    end
  end

  # Registers the DSCC agent instance as a service.
  #
  # @param [String] agent_path
  #   Path to the DSCC agent instance. Default is install-path/var/dcc/agent.
  #
  # @return [Chef::Resource::Dsccagent]
  #
  # @api private
  def action_enable_service
    if snmp?
      converge_by 'Registering the DSCC agent instance as a service' do
        dsccagent :enable_service, new_resource.agent_path

        Chef::Log.info "DSCC agent instance registered for #{new_resource}"
      end
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.info "#{new_resource} already registered - nothing to do"
    end
  end

  # Unregisters the DSCC agent instance as a service.
  #
  # @param [String] agent_path
  #   Path to the DSCC agent instance. Default is install-path/var/dcc/agent.
  #
  # @return [Chef::Resource::Dsccagent]
  #
  def action_disable_service
    if snmp?
      converge_by 'Unregistering the DSCC agent instance service' do
        dsccagent :disable_service, new_resource.agent_path

        Chef::Log.info "DSCC agent instance unregistered for #{new_resource}"
      end
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.info "#{new_resource} not registered - nothing to do"
    end
  end

  # Configures a DSCC agent instance as SNMP agent.
  #
  # @param [TrueClass, FalseClass] v3
  #   Use SNMP version 3.
  #
  # @param [Integer] snmp_port
  #   Use `snmp_port` for SNMP traffic. Default is 3996.
  #
  # @param [String] ds_port
  #   Use ds_port for traffic from Directory Servers to agent. Default is 3995
  #
  # @param [String] agent_path
  #   Path to the DSCC agent instance. Default is install-path/var/dcc/agent.
  #
  # @return [Chef::Resource::Dsccagent]
  #
  # @api private
  def action_enable_snmp
    if snmp?
      Chef::Log.info "#{new_resource} already configured - nothing to do"
    else
      converge_by 'Configure the SNMP agent for DSCC agent instance' do
        dsccagent :enable_snmp, new_resource._?(:snmp_v3,           '-v3'),
                                new_resource._?(:snmp_port, '--snmp-port'),
                                new_resource._?(:ds_port,     '--ds-port'),
                                new_resource.agent_path


        Chef::Log.info "SNMP agent configured for #{new_resource}"
      end
      new_resource.updated_by_last_action(true)
    end
  end

  # Unconfigures the SNMP agent of a DSCC agent instance.
  #
  # @param [String] agent_path
  #   Path to the DSCC agent instance. Default is install-path/var/dcc/agent.
  #
  # @return [Chef::Resource::Dsccagent]
  #
  # @api private
  def action_disable_snmp
    if snmp?
      converge_by "Unconfigure the SNMP agent for #{new_resource}" do
        dsccagent :disable_snmp, new_resource.agent_path

        Chef::Log.info "SNMP agent is unconfigured for #{new_resource}"
      end
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.info "#{new_resource} not configured - nothing to do"
    end
  end

  # Start a DSCC agent instance. The DSCC agent will be able to start if it was
  # registered in the DSCC registry, or if the SNMP agent is enabled.
  #
  # @param [String] agent_path
  #   Path to the DSCC agent instance. Default is install-path/var/dcc/agent.
  #
  # @return [Chef::Resource::Dsccagent]
  #
  # @api private
  def action_start
    if running?
      Chef::Log.info "#{new_resource} is running - nothing to do"
    else
      converge_by "Starting the DSCC agent instance for #{new_resource}" do
        dsccagent :start, new_resource.agent_path

        Chef::Log.info "DSCC agent instance started for #{new_resource}"
      end
      new_resource.updated_by_last_action(true)
    end
  end

  # Stops a DSCC agent instance.
  #
  # @param [String] agent_path
  #   Path to the DSCC agent instance. Default is install-path/var/dcc/agent.
  #
  # @return [Chef::Resource::Dsccagent]
  #
  # @api private
  def action_stop
    if stopped?
      Chef::Log.info "#{new_resource} is stopped - nothing to do"
    else
      converge_by "Stopping the DSCC agent instance for #{new_resource}" do
        dsccagent :stop, new_resource.agent_path

        Chef::Log.info "DSCC agent instance for #{new_resource} is stopped"
      end
      new_resource.updated_by_last_action(true)
    end
  end
end
