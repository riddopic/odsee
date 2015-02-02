# encoding: UTF-8
#
# Cookbook Name:: odsee
# Resources:: dsccreg
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

# A Chef provider for the Oracle Directory Server dsccreg command.
#
# The dsccreg command is used to register server instances on the local system
# with the Directory Service Control Center (DSCC) registry.
#
class Chef::Resource::Dsccreg < Chef::Resource::LWRPBase
  include Odsee

  identity_attr :path
  provides :dsccreg, os: 'linux'
  self.resource_name = :dsccreg

  # Adds actions to the list of valid actions for this resource
  #
  # @return [Chef::Provider::Dsccreg]
  # @api public
  actions :add_agent, :remove_agent, :add_server, :remove_server

  # Set or return the list of `state attributes` implemented by the Resource,
  # these are attributes that describe the desired state of the system
  #
  # @return [Chef::Resource::Dsccreg]
  # @api private
  state_attrs :servers, :agents

  # Sets the default action
  #
  # @return [undefined]
  # @api private
  default_action :nothing

  # Creates the namespaced Chef::Provider::Dsccreg
  #
  # @return [undefined]
  # @api private
  provider_base Chef::Provider::Dsccreg

  # Boolean, returns true if the server instance has been added to the DSCC
  # registry, otherwise false
  #
  # @note This is a state attribute or `state_attrs` set by the provider
  # @param [TrueClass, FalseClass]
  # @return [TrueClass, FalseClass]
  # @api private
  attribute :servers,
            kind_of: [TrueClass, FalseClass],
            default: nil

  # Boolean, returns true if the agent instance has been added to the DSCC
  # registry, otherwise false
  #
  # @note This is a state attribute or `state_attrs` set by the provider
  # @param [TrueClass, FalseClass]
  # @return [TrueClass, FalseClass]
  # @api private
  attribute :agents,
            kind_of: [TrueClass, FalseClass],
            default: nil

  # Used to provide an optional description for the agent instance.
  #
  # @param [String] description
  #   Uses text as the description.
  #
  # @return [String]
  #
  # @api public
  attribute :description,
            kind_of: String,
            default: lazy { "'DOB: #{Time.now.strftime('%v')}'" }

  # The DSCC registry host name. By default, the dsccreg command uses the local
  # host name returned by the operating system.
  #
  # @param [String, nil] hostname
  #
  # @return [String, nil]
  #
  # @api public
  attribute :hostname,
            kind_of: String,
            default: nil

  # Full path to the existing DSCC agent or server instance to register
  #
  # @param [String] path
  #   Path to existing DSCC server or agent instance
  #
  # @return [String]
  #
  # @api public
  attribute :path,
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
  # @api public
  attribute :force,
            kind_of: [TrueClass, FalseClass],
            default: lazy { node[:odsee][:force] }

  # Defines the Directory Manager DN. The default is cn=Directory Manager.
  #
  # @param [String] dn
  #
  # @return [String]
  #
  # @api public
  attribute :dn,
            kind_of: String,
            default: lazy { node[:odsee][:dn] }

  # Specifies port as the DSCC agent port to use for communicating with this
  # server instance.
  #
  # @param [Integer] agent_port
  #   The LDAP port to use.
  #
  # @return [Integer]
  #
  # @api public
  attribute :agent_port,
            kind_of: String,
            default: lazy { node[:odsee][:agent_port] }

  # When true does not prompt for password and/or does not prompt for
  # confirmation before performing the operation.
  #
  # @note This should always return nil.
  #
  # @param [TrueClass, FalseClass] no_inter
  #   If you would like to be prompted to confirm actions.
  #
  # @return [TrueClass, FalseClass]
  #
  # @api public
  attribute :no_inter,
            kind_of: [TrueClass, FalseClass],
            default: lazy { node[:odsee][:no_inter] }
end
