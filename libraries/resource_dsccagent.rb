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

  identity_attr :agent_path
  provides :dsccagent, os: 'linux'
  self.resource_name = :dsccagent

  # The following actions are supported:
  #
  # create         Creates a DSCC agent instance
  # delete         Deletes a DSCC agent instance
  # disable-snmp   Unconfigures SNMP agent of a DSCC agent instance
  # enable-snmp    Configures a DSCC agent instance as SNMP agent
  # start          Starts a DSCC agent instance
  # stop           Stops a DSCC agent instance
  #
  actions :create, :delete, :enable_snmp, :disable_snmp, :start, :stop
  state_attrs :created, :enabled, :running
  default_action :nothing

  provider_base Chef::Provider::Dsccsetup

  # Boolean, true if a DSCC agent instance has been created, otherwise false
  #
  # @param [TrueClass, FalseClass]
  #
  # @return [TrueClass, FalseClass]
  #
  # @api private
  attribute :created,
    kind_of: [TrueClass, FalseClass],
    default: nil

  # Boolean, true if a DSCC agent instance has been configured as a SNMP agent,
  # otherwise false
  #
  # @param [TrueClass, FalseClass]
  #
  # @return [TrueClass, FalseClass]
  #
  # @api private
  attribute :enabled,
    kind_of: [TrueClass, FalseClass],
    default: nil

  # Boolean, true when the DSCC agent instance is running. The DSCC agent will
  # be able to start if it was registered in the DSCC registry, or if the SNMP
  # agent is enabled
  #
  # @param [TrueClass, FalseClass]
  #
  # @return [TrueClass, FalseClass]
  #
  # @api private
  attribute :running,
    kind_of: [TrueClass, FalseClass],
    default: nil

  # When true does not prompt for password and/or does not prompt for
  # confirmation before performing the operation.
  #
  # @note This should always return nil.
  #
  # @param [TrueClass, FalseClass] interupt
  #   If you would like to be prompted to confirm actions.
  #
  # @return [TrueClass, FalseClass]
  #
  # @api private
  attribute :no_inter,
    kind_of: [TrueClass, FalseClass],
    default: lazy { node[:odsee][:no_inter] }

  # Specifies the port for thr DSCC agent. The default is 3997.
  #
  # @param [Integer] port
  #   The DSCC agent port to use.
  #
  # @return [Integer]
  #
  # @api private
  attribute :agent_port,
    kind_of: String,
    default: lazy { node[:odsee][:agent_port] }

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

  # Boolean, true if SNMP version 3 should be used, otherwise false.
  #
  # @param [TrueClass, FalseClass] snmp_v3
  #   True to use SNMP version 3, otherwise false.
  #
  # @return [TrueClass, FalseClass]
  #
  # @api private
  attribute :snmp_v3,
    kind_of: [TrueClass, FalseClass],
    default: lazy { node[:odsee][:snmp_v3] }

  # The port number to use for SNMP traffic. Default is 3996.
  #
  # @param [Integer] port
  #   The SNMP traffic port to use.
  #
  # @return [Integer]
  #
  # @api private
  attribute :snmp_port,
    kind_of: [Integer],
    default: lazy { node[:odsee][:snmp_port] }

  # The port number to use for traffic from Directory Servers to agent. The
  # default is 3995.
  #
  # @param [Integer] port
  #   The Directory Servers agent port to use.
  #
  # @return [Integer]
  #
  # @api private
  attribute :ds_port,
    kind_of: Integer,
    default: lazy { node[:odsee][:ds_port] }

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

end
