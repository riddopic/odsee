# encoding: UTF-8
#
# Cookbook Name:: odsee
# Resources:: dsccreg
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

# A Chef provider for the Oracle Directory Server dsccreg command.
#
# The dsccreg command is used to register server instances on the local system
# with the Directory Service Control Center (DSCC) registry.
#
class Chef::Resource::Dsccreg < Chef::Resource::LWRPBase
  include Odsee

  identity_attr :agent_path
  provides :dsccreg, os: 'linux'
  self.resource_name = :dsccreg

  # The following actions are supported:
  #
  # add-agent      Add a DSCC agent instance to the DSCC registry
  # add-server     Add a server instance to the DSCC registry
  # remove-agent   Remove an agent instance from the DSCC registry
  # remove-server  Remove a server instance from the DSCC registry
  #
  actions :add_agent, :remove_agent, :add_server, :remove_server
  state_attrs :servers, :agents
  default_action :nothing

  provider_base Chef::Provider::Dsccreg

  # Boolean, returns true if the server instance has been added to the DSCC
  # registry, otherwise false
  #
  # @param [TrueClass, FalseClass]
  #
  # @return [TrueClass, FalseClass]
  #
  # @api private
  attribute :servers,
    kind_of: [TrueClass, FalseClass],
    default: nil

  # Boolean, returns true if the agent instance has been added to the DSCC
  # registry, otherwise false
  #
  # @param [TrueClass, FalseClass]
  #
  # @return [TrueClass, FalseClass]
  #
  # @api private
  attribute :agents,
    kind_of: [TrueClass, FalseClass],
    default: nil

  # Path to the DSCC server instance. Default is: `install-path/var/dcc/agent`.
  #
  # @param [String] path
  #   Directory where you would like the Directory Server instance to run.
  #
  # @return [String]
  #
  # @api private
  attribute :below,
    kind_of: String,
    default: lazy { node[:odsee][:instance_path].call }

  # Path to the DSCC agent instance. Default is: `install-path/var/dcc/agent`.
  #
  # @param [String] path
  #   Path to existing DSCC agent instance.
  #
  # @return [String]
  #
  # @api private
  attribute :agent_path,
    kind_of: String,
    default: lazy { node[:odsee][:agent_path].call }

  # Used to provide an optional description for the agent instance.
  #
  # @param [String] text
  #   Uses text as the description.
  #
  # @return [String]
  #
  # @api private
  attribute :text,
    kind_of: String,
    default: lazy { "'DOB: #{Time.now.strftime('%v')}'" }

  # The DSCC registry host name or IP address. By default, the dsccreg command
  # uses the local host name returned by the operating system.
  #
  # @param [String, Integer, nil] host
  #
  # @return [String, Integer, nil]
  #
  # @api private
  attribute :hostname,
    kind_of: [String, Integer],
    default: nil

  # A file containing the DSCC agent password.
  #
  # @param [String] file
  #   File to use to store the DSCC agent password.
  #
  # @return [String]
  #
  # @api private
  attribute :agent_pw_file,
    kind_of: Proc,
    default: lazy { __agent_pw__ }

  # Full path to the existing DSCC agent instance. The default path is to use:
  # install-path/var/dcc/agent
  #
  # @param [String] path
  #   Path to existing DSCC agent instance.
  #
  # @return [String]
  #
  # @api private
  attribute :agent_path,
    kind_of: String,
    name_attribute: true

  # If the instance should be forcibly shut down. When used with
  # `stop-running-instances`, the command forcibly shuts down all the running
  # server instances that are created using the same dsadm installation. When
  # used with stop, the command forcibly shuts down the instance even if the
  # instance is not initiated by the current installation.
  #
  # @param [TrueClass, FalseClass]
  #
  # @return [TrueClass, FalseClass]
  #
  # @api private
  attribute :force,
    kind_of: [TrueClass, FalseClass],
    default: lazy { node[:odsee][:force] }

  # Defines the Directory Manager DN. The default is cn=Directory Manager.
  #
  # @param [String] dn
  #
  # @return [String]
  #
  # @api private
  attribute :dn,
    kind_of: String,
    default: lazy { node[:odsee][:dn] }

  # A file containing the Direcctory Service Manager password.
  #
  # @param [String] file
  #   File to use to store the Direcctory Service Manager password.
  #
  # @return [String]
  #
  # @api private
  attribute :admin_pw_file,
    kind_of: Proc,
    default: lazy { __admin_pw__ }

  # Specifies port as the DSCC agent port to use for communicating with this
  # server instance.
  #
  # @param [Integer] port
  #   The LDAP port to use.
  #
  # @return [Integer]
  #
  # @api private
  attribute :agent_port,
    kind_of: String,
    default: lazy { node[:odsee][:registry_ldap_port] }

end
