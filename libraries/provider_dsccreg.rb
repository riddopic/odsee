# encoding: UTF-8
#
# Cookbook Name:: odsee
# HWRP:: dsccreg
#
# Author:    Stefano Harding <riddopic@gmail.com>
# License:   Apache License, Version 2.0
# Copyright: (C) 2014-2015 Stefano Harding
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

# A Chef provider for the Oracle Directory Server dsccreg resource.
#
# The dsccreg command is used to register server instances on the local system
# with the Directory Service Control Center (DSCC) registry.
#
class Chef::Provider::Dsccreg < Chef::Provider::LWRPBase
  include Odsee

  # Boolean indicating if WhyRun is supported by this provider.
  #
  # @return [TrueClass, FalseClass]
  #
  # @api private
  def whyrun_supported?
    true
  end

  # Reload the resource state when something changes
  #
  # @return [undefined]
  #
  # @api private
  def load_new_resource_state
    if @new_resource.servers.nil?
      @new_resource.servers(@current_resource.servers)
    end
    if @new_resource.agents.nil?
      @new_resource.agents(@current_resource.agents)
    end
  end

  # Load and return the current resource
  #
  # @return [Chef::Resource::Dsccreg]
  #
  # @raise [Odsee::Exceptions::ResourceNotFound]
  #
  # @api private
  def load_current_resource
    @current_resource = Chef::Resource::Dsccreg.new(@new_resource.name)
    @current_resource.path(@new_resource.path)

    unless ::File.exist?(which(@resource_name.to_s))
      fail Odsee::Exceptions::ResourceNotFound
    end

    @current_resource.servers(check_for(:servers, @new_resource.path))
    @current_resource.agents(check_for(:agents, @new_resource.path))
    @current_resource
  end

  # Add DSCC agent instance to the DSCC registry.
  #
  # @param [String] description
  #   Used to provide an optional description for the agent instance.
  # @param [String, Integer] hostname
  #   The DSCC registry host name or IP address.
  # @param [String] agent_passwd
  #   Uses `password` from `agent_passwd` file to access agent configuration.
  # @param [String] path
  #   Full path to the existing DSCC agent instance. The default path is to use:
  #   `install-path/var/dcc/agent`.
  #
  # @return [Chef::Provider::Dsccreg]
  #
  # @api public
  def action_add_agent
    if @current_resource.agents
      Chef::Log.debug "#{new_resource} already created - nothing to do"
    else
      converge_by "Add instance #{new_resource.path} to DSCC registry" do
        new_resource.admin_passwd.tmp do |__p__|
          new_resource.agent_passwd.tmp do |__p__|
            dsccreg :add_agent,
                    new_resource._?(:description,  '-d'),
                    new_resource._?(:hostname,     '-H'),
                    new_resource._?(:agent_passwd, '-G'),
                    new_resource._?(:admin_passwd, '-w'),
                    new_resource.path
          end
        end
        new_resource.updated_by_last_action(true)
      end
    end
    load_new_resource_state
    @current_resource.agents(check_for(:agents, @new_resource.path))
  end

  # Remove a DSCC agent instance from the DSCC registry.
  #
  # @param [String, Integer] hostname
  #   The DSCC registry host name or IP address.
  # @param [TrueClass, FalseClass] force
  #   Forces removal of the agent instance from the DSCC registry.
  # @param [String] path
  #   Full path to the existing DSCC agent instance. The default path is to use:
  #   install-path/var/dcc/agent.
  #
  # @return [Chef::Provider::Dsccreg]
  #
  # @api public
  def action_remove_agent
    if @current_resource.agents
      converge_by "Remove instance #{new_resource.path} from DSCC registry" do
        dsccreg :remove_agent,
                new_resource._?(:hostname, '-H'),
                new_resource._?(:force,    '-f'),
                new_resource.path
      end
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.debug "#{new_resource} does not exists - nothing to do"
    end
    load_new_resource_state
    @current_resource.agents(check_for(:agents, @new_resource.path))
  end

  # Add a server instance to the DSCC registry.
  #
  # @param [String] dn
  #   Use the specified bind DN to bind to the instance specified by
  #   instance-path. By default, the dsccreg command uses cn=Directory Manager.
  # @param [String] admin_passwd
  #   Uses `password` from `admin_passwd` file to access agent configuration.
  # @param [String] description
  #   Used to provide an optional description for the agent instance.
  # @param [String, Integer] hostname
  #   The DSCC registry host name or IP address.
  # @param [Integer] agent_port
  #   Specifies port as the DSCC agent port to use for communicating with this
  #   server instance.
  # @param [String] path
  #   Full path to the server instance.
  #
  # @return [Chef::Provider::Dsccreg]
  #
  # @api public
  def action_add_server
    if @current_resource.servers
      Chef::Log.debug "#{new_resource} already created - nothing to do"
    else
      converge_by "Add server instance #{new_resource.path} to DSCC registry" do
        new_resource.admin_passwd.tmp do |__p__|
          new_resource.agent_passwd.tmp do |__p__|
            dsccreg :add_server,
                    new_resource._?(:admin_passwd, '-w'),
                    new_resource._?(:agent_passwd, '-G'),
                    new_resource._?(:no_inter,     '-i'),
                    new_resource.path
          end
        end
        new_resource.updated_by_last_action(true)
      end
    end
    load_new_resource_state
    @current_resource.servers(check_for(:servers, @new_resource.path))
  end

  # Remove a server instance from the DSCC registry.
  #
  # @param [String] dn
  #   Use the specified bind DN to bind to the instance specified by
  #   instance-path. By default, the dsccreg command uses cn=Directory Manager.
  # @param [String] admin_passwd
  #   Uses `password` from `admin_passwd` file to access agent configuration.
  # @param [String, Integer] hostname
  #   The DSCC registry host name or IP address.
  # @param [String] path
  #   Full path to the server instance.
  #
  # @return [Chef::Provider::Dsccreg]
  #
  # @api public
  def action_remove_server
    if @current_resource.servers
      converge_by "Remove server instance #{new_resource.path} to DSCC registry" do
        new_resource.admin_passwd.tmp do |__p__|
          dsccreg :remove_server,
                  new_resource._?(:dn,           '-B'),
                  new_resource._?(:admin_passwd, '-G'),
                  new_resource._?(:hostname,     '-H'),
                  new_resource.path
        end
        new_resource.updated_by_last_action(true)
      end
    else
      Chef::Log.debug "#{new_resource} does not exists - nothing to do"
    end
    load_new_resource_state
    @current_resource.servers(check_for(:servers, @new_resource.path))
  end
end
