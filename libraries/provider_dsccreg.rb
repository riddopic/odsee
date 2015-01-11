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
  # @return [Chef::Provider::Dsccreg]
  #
  # @api private
  def load_current_resource
    @current_resource ||= Chef::Resource::Dsccreg.new(new_resource.name)
    @current_resource.server = registry(:server, admin_pwd)
    @current_resource.agent  = registry(:agent, admin_pwd)
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
    if exists?
      Chef::Log.info "#{new_resource} already created - nothing to do"
    else
      converge_by "Adding #{new_resource} instance to the DSCC registry" do
        begin
          dsccreg :add_agent, new_resource._?(:text,          '-d'),
                              new_resource._?(:hostname,      '-H'),
                              new_resource._?(:agent_pw_file, '-G'),
                              new_resource.agent_path

          Chef::Log.info "DSCC agent instance added to the DSCC registry"
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
    if exists?
      converge_by "Remove #{new_resource} instance from the registry" do
        dsccreg :remove_agent, new_resource._?(:hostname, '-H'),
                               new_resource._?(:force,    '-f'),
                               new_resource.agent_path

        Chef::Log.info "#{new_resource} has been removed from the registry."
      end
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.info "#{new_resource} does not exists - nothing to do"
    end
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
    if exists?
      Chef::Log.info "#{new_resource} already created - nothing to do"
    else
      converge_by "Adding server instance #{new_resource} to the registry" do
        begin
          dsccreg :add_agent, new_resource._?(:dn,            '-B'),
                              new_resource._?(:admin_pw_file, '-G'),
                              new_resource._?(:text, '         -d'),
                              new_resource._?(:agent_port,    '-H'),
                              new_resource.INST_PATH

          Chef::Log.info "Server instance added to the DSCC registry"
        ensure
          if ::File.exist?(new_resource.agent_pw_file.split.last)
            Chef::Log.debug "Removing Direcctory Service Admin password file"
            ::File.unlink new_resource.agent_pw_file.split.last
          end
        end
        new_resource.updated_by_last_action(true)
      end
    end
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
    if exists?
      converge_by "Removing server instance #{new_resource} from registry" do
        begin
          dsccreg :remove_server, new_resource._?(:dn,            '-B'),
                                  new_resource._?(:admin_pw_file, '-G'),
                                  new_resource._?(:hostname,      '-d'),
                                  new_resource.INST_PATH

          Chef::Log.info "Server instance #{new_resource} has been removed."
        ensure
          if ::File.exist?(new_resource.agent_pw_file.split.last)
            Chef::Log.debug "Removing Direcctory Service Admin password file"
          ::File.unlink new_resource.agent_pw_file.split.last
          end
        end
      end
      new_resource.updated_by_last_action(true)
    end
  end
end
