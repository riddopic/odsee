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

  actions :create, :delete, :enable_service, :disable_service, :enable_snmp,
          :disable_snmp, :start, :stop
  default_action :nothing
  
  state_attrs :exists, :state, :snmp, :info
  provider_base Chef::Provider::Dsccsetup

  # @!attribute [rw] exists
  #   @return [TrueClass, FalseClass] Boolean, true if the DSCC agent instance
  #     has been created, false otherwise.
  attr_writer :exists

  # @!attribute [rw] state
  #   @return [String] Return the current instance state. The states are;
  #     Running, Stoppend or Unknown
  attr_writer :state

  # @!attribute [rw] info
  #   @return [Hash] Returns a hash containing configuration information about
  #     a server such as port number, suffix name, server mode and task states.
  attr_writer :info

  # @!attribute [rw] info
  #   @return [TrueClass, FalseClass] Boolean to check if the SNMP port is set,
  #     returns true if the SNMP port has been set, otherwise false.
  attr_writer :snmp

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
  attribute :no_inter, kind_of: [TrueClass, FalseClass],
    default: lazy { node[:odsee][:no_inter] }

  # Specifies the port for thr DSCC agent. The default is 3997.
  #
  # @param [Integer] port
  #   The DSCC agent port to use.
  #
  # @return [Integer]
  #
  # @api private
  attribute :agent_port, kind_of: String,
    default: lazy { node[:odsee][:agent_port] },
    callbacks: { 'You must specify a valid port!' =>
      ->(port) { port.to_i > 0 && port.to_i < 65_535 } }

  # A file containing the DSCC agent password.
  #
  # @param [String] file
  #   File to use to store the DSCC agent password.
  #
  # @return [String]
  #
  # @api private
  attribute :agent_pw_file, kind_of: Proc, default: lazy { __agent_pw__ },
    callbacks: { 'You must specify a valid file with the correct password!' =>
      ->(file) { ::File.exists?(file) }}

  # Full path to the existing DSCC agent instance. The default path is to use:
  # install-path/var/dcc/agent
  #
  # @param [String] path
  #   Path to existing DSCC agent instance.
  #
  # @return [String]
  #
  # @api private
  attribute :agent_path, kind_of: String, name_attribute: true,
    default: lazy { node[:odsee][:agent_path].call },
    callbacks: { 'You must specify a valid directory!' =>
      ->(path) { ::File.directory?(path) }}

  # Boolean, true if SNMP version 3 should be used, otherwise false.
  #
  # @param [TrueClass, FalseClass] snmp_v3
  #   True to use SNMP version 3, otherwise false.
  #
  # @return [TrueClass, FalseClass]
  #
  # @api private
  attribute :snmp_v3, kind_of: [TrueClass, FalseClass],
    default: lazy { node[:odsee][:snmp_v3] }

  # The port number to use for SNMP traffic. Default is 3996.
  #
  # @param [Integer] port
  #   The SNMP traffic port to use.
  #
  # @return [Integer]
  #
  # @api private
  attribute :snmp_port, kind_of: [Integer],
    default: lazy { node[:odsee][:snmp_port] },
    callbacks: { 'You must specify a valid port!' =>
      ->(port) { port.to_i > 0 && port.to_i < 65_535 } }

  # The port number to use for traffic from Directory Servers to agent. The
  # default is 3995.
  #
  # @param [Integer] port
  #   The Directory Servers agent port to use.
  #
  # @return [Integer]
  #
  # @api private
  attribute :ds_port, kind_of: Integer,
    default: lazy { node[:odsee][:ds_port] },
    callbacks: { 'You must specify a valid port!' =>
      ->(port) { port.to_i > 0 && port.to_i < 65_535 } }

end
