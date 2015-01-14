# encoding: UTF-8
#
# Cookbook Name:: garcon
# HWRP:: dsccreg
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
    @current_resource.agent_path(@new_resource.agent_path)

    unless ::File.exists?(which(@resource_name.to_s))
      raise Odsee::Exceptions::ResourceNotFound
    end

    @current_resource.servers(check_for(:servers, new_resource.agent_path))
    @current_resource.agents(check_for(:agents, new_resource.agent_path))
    @current_resource
  end

  # Add DSCC agent instance to the DSCC registry.
  #
  # @param [String] text
  #   Used to provide an optional description for the agent instance.
  # @param [String, Integer] hostname
  #   The DSCC registry host name or IP address.
  # @param [String] agent_pw_file
  #   Uses `password` from `agent_pw_file` file to access agent configuration.
  # @param [String] agent_path
  #   Full path to the existing DSCC agent instance. The default path is to use:
  #   `install-path/var/dcc/agent`.
  #
  # @return [Chef::Provider::Dsccreg]
  #
  # @api private
  action :add_agent do
    if @current_resource.agents
      Chef::Log.info "#{new_resource} already created - nothing to do"
    else
      converge_by "Adding #{new_resource} instance to the DSCC registry" do
        begin
          dsccreg :add_agent,
                  new_resource._?(:text,          '-d'),
                  new_resource._?(:hostname,      '-H'),
                  new_resource._?(:agent_pw_file, '-G'),
                  new_resource._?(:admin_pw_file, '-w'),
                  new_resource.agent_path
        ensure
          %w[new_resource.admin_pw_file.split.last
             new_resource.agent_pw_file.split.last
             new_resource.cert_pw_file.split.last].each do |__pfile__|
            ::File.unlink(__pfile__) if ::File.exist?(__pfile__)
          end
        end
        Chef::Log.info 'DSCC agent instance added to the DSCC registry'
      end
    end
    load_new_resource_state
    @new_resource.agents(true)
  end

  # Remove a DSCC agent instance from the DSCC registry.
  #
  # @param [String, Integer] hostname
  #   The DSCC registry host name or IP address.
  # @param [TrueClass, FalseClass] force
  #   Forces removal of the agent instance from the DSCC registry.
  # @param [String] agent_path
  #   Full path to the existing DSCC agent instance. The default path is to use:
  #   install-path/var/dcc/agent.
  #
  # @return [Chef::Provider::Dsccreg]
  #
  # @api private
  action :remove_agent do
    if @current_resource.agents
      converge_by "Remove #{new_resource} instance from the registry" do
        dsccreg :remove_agent,
                new_resource._?(:hostname, '-H'),
                new_resource._?(:force,    '-f'),
                new_resource.agent_path
        Chef::Log.info "#{new_resource} has been removed from the registry."
      end
    else
      Chef::Log.info "#{new_resource} does not exists - nothing to do"
    end
    load_new_resource_state
    @new_resource.agents(false)
  end

  # Add a server instance to the DSCC registry.
  #
  # @param [String] dn
  #   Use the specified bind DN to bind to the instance specified by
  #   instance-path. By default, the dsccreg command uses cn=Directory Manager.
  # @param [String] admin_pw_file
  #   Uses `password` from `admin_pw_file` file to access agent configuration.
  # @param [String] text
  #   Used to provide an optional description for the agent instance.
  # @param [String, Integer] hostname
  #   The DSCC registry host name or IP address.
  # @param [Integer] agent_port
  #   Specifies port as the DSCC agent port to use for communicating with this
  #   server instance.
  # @param [String] INST_PATH
  #   Full path to the server instance.
  #
  # @return [Chef::Provider::Dsccreg]
  #
  # @api private
  action :add_server do
    if @current_resource.servers
      Chef::Log.info "#{new_resource} already created - nothing to do"
    else
      converge_by "Adding server instance #{new_resource} to the registry" do
        begin
          dsccreg :add_agent,
                  new_resource._?(:dn,            '-B'),
                  new_resource._?(:admin_pw_file, '-G'),
                  new_resource._?(:text, '         -d'),
                  new_resource._?(:agent_port,    '-H'),
                  new_resource.INST_PATH
        ensure
          %w[new_resource.admin_pw_file.split.last
             new_resource.agent_pw_file.split.last
             new_resource.cert_pw_file.split.last].each do |__pfile__|
            ::File.unlink(__pfile__) if ::File.exist?(__pfile__)
          end
        end
        Chef::Log.info 'Server instance added to the DSCC registry'
      end
    end
    load_new_resource_state
    @new_resource.servers(true)
  end

  # Remove a server instance from the DSCC registry.
  #
  # @param [String] dn
  #   Use the specified bind DN to bind to the instance specified by
  #   instance-path. By default, the dsccreg command uses cn=Directory Manager.
  # @param [String] admin_pw_file
  #   Uses `password` from `admin_pw_file` file to access agent configuration.
  # @param [String, Integer] hostname
  #   The DSCC registry host name or IP address.
  # @param [String] inst_path
  #   Full path to the server instance.
  #
  # @return [Chef::Provider::Dsccreg]
  #
  # @api private
  action :remove_server do
    if @current_resource.servers
      converge_by "Removing server instance #{new_resource} from registry" do
        begin
          dsccreg :remove_server,
                  new_resource._?(:dn,            '-B'),
                  new_resource._?(:admin_pw_file, '-G'),
                  new_resource._?(:hostname,      '-d'),
                  new_resource.INST_PATH
        ensure
          %w[new_resource.admin_pw_file.split.last
             new_resource.agent_pw_file.split.last
             new_resource.cert_pw_file.split.last].each do |__pfile__|
            ::File.unlink(__pfile__) if ::File.exist?(__pfile__)
          end
        end
        Chef::Log.info "Server instance #{new_resource} has been removed."
      end
    end
    load_new_resource_state
    @new_resource.servers(true)
  end
end
