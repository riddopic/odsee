# encoding: UTF-8
#
# Cookbook Name:: odsee
# Resources:: dsccagent
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

# A Chef resource for the Oracle Directory Server dsccagent command.
#
# The dsccagent command is used to create, delete, start, and stop DSCC agent
# instances on the local system. You can also use the dsccagent command to
# display status and DSCC agent information, and to enable and disable SNMP
# monitoring.
#
class Chef::Resource::Dsccagent < Chef::Resource::LWRPBase
  include Odsee

  identity_attr :path
  provides :dsccagent, os: 'linux'
  self.resource_name = :dsccagent

  # Adds actions to the list of valid actions for this resource
  #
  # @return [Chef::Provider::Dsccagent]
  # @api public
  actions :create, :delete, :enable_snmp, :disable_snmp, :start, :stop

  # Set or return the list of `state attributes` implemented by the Resource,
  # these are attributes that describe the desired state of the system
  #
  # @return [Chef::Resource::Dsccagent]
  # @api private
  state_attrs :created, :enabled, :running

  # Sets the default action
  #
  # @return [undefined]
  # @api private
  default_action :nothing

  # Creates the namespaced Chef::Provider::Dsccsetup
  #
  # @return [undefined]
  # @api private
  provider_base Chef::Provider::Dsccsetup

  # Boolean, true if a DSCC agent instance has been created, otherwise false
  #
  # @note This is a state attribute or `state_attrs` set by the provider
  # @param [TrueClass, FalseClass]
  # @return [TrueClass, FalseClass]
  # @api private
  attribute :created,
            kind_of: [TrueClass, FalseClass],
            default: nil

  # Boolean, true if a DSCC agent instance has been configured as a SNMP agent,
  # otherwise false
  #
  # @note This is a state attribute or `state_attrs` set by the provider
  # @param [TrueClass, FalseClass]
  # @return [TrueClass, FalseClass]
  # @api private
  attribute :enabled,
            kind_of: [TrueClass, FalseClass],
            default: nil

  # Boolean, true when the DSCC agent instance is running. The DSCC agent will
  # be able to start if it was registered in the DSCC registry, or if the SNMP
  # agent is enabled
  #
  # @note This is a state attribute or `state_attrs` set by the provider
  # @param [TrueClass, FalseClass]
  # @return [TrueClass, FalseClass]
  # @api private
  attribute :running,
            kind_of: [TrueClass, FalseClass],
            default: nil

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

  # Specifies the port for the DSCC agent. The default is 3997.
  #
  # @param [Integer] agent_port
  #   The DSCC agent port to use.
  #
  # @return [Integer]
  #
  # @api public
  attribute :agent_port,
            kind_of: String,
            default: lazy { node[:odsee][:agent_port] }

  # Full path to the existing DSCC agent instance. The default path is to use:
  # install-path/var/dcc/agent
  #
  # @param [String] path
  #   Path to existing DSCC agent instance.
  #
  # @return [String]
  #
  # @api public
  attribute :path,
            kind_of: String,
            name_attribute: true

  # Boolean, true if SNMP version 3 should be used, otherwise false.
  #
  # @param [TrueClass, FalseClass] snmp_v3
  #   True to use SNMP version 3, otherwise false.
  #
  # @return [TrueClass, FalseClass]
  #
  # @api public
  attribute :snmp_v3,
            kind_of: [TrueClass, FalseClass],
            default: lazy { node[:odsee][:snmp_v3] }

  # The port number to use for SNMP traffic. Default is 3996.
  #
  # @param [Integer] snmp_port
  #   The SNMP traffic port to use.
  #
  # @return [Integer]
  #
  # @api public
  attribute :snmp_port,
            kind_of: [Integer],
            default: lazy { node[:odsee][:snmp_port] }

  # The port number to use for traffic from Directory Servers to agent. The
  # default is 3995.
  #
  # @param [Integer] ds_port
  #   The Directory Servers agent port to use.
  #
  # @return [Integer]
  #
  # @api public
  attribute :ds_port,
            kind_of: Integer,
            default: lazy { node[:odsee][:ds_port] }

end
