# encoding: UTF-8
#
# Cookbook Name:: odsee
# Resources:: dsccsetup
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

# A Chef resource for the Oracle Directory Server dsccsetup command.
#
# The dsccsetup command is used to deploy Directory Service Control Center
# (DSCC) in an application server, and to register local agents of the
# administration framework.
#
class Chef::Resource::Dsccsetup < Chef::Resource::LWRPBase
  include Odsee

  identity_attr :path
  provides :dsccsetup, os: 'linux'
  self.resource_name = :dsccsetup

  actions :ads_create, :ads_delete
  default_action :nothing

  state_attrs :exists
  provider_base Chef::Provider::Dsccsetup

  # @!attribute [rw] exists
  #   @return [TrueClass, FalseClass] Boolean, true if the Directory Server
  #     DSCC registry instance has been created, false otherwise.
  attr_writer :exists

  # A do nothing attribute, this prevents the base temporal continuum
  # gravitational tachyons from invading.
  #
  # @return [undefined]
  #
  # @api private
  attribute :name, kind_of: [String, Symbol], name_attribute: true

  # A file containing the Direcctory Service Manager password.
  #
  # @param [String] admin_pw_file
  #   File to use to store the Direcctory Service Manager password.
  #
  # @return [String]
  #
  # @api private
  attribute :admin_pw_file, kind_of: Proc, default: lazy { __admin_pw__ },
    callbacks: { 'You must specify a valid file with the correct password!' =>
      ->(file) { ::File.exists?(file) }}

  # Specifies the port for LDAP traffic. The default is 3998.
  #
  # @param [Integer] port
  #   The LDAP port to use.
  #
  # @return [Integer]
  #
  # @api private
  attribute :registry_ldap_port, kind_of: String,
    default: lazy { node[:odsee][:registry_ldap_port] },
    callbacks: { 'You must specify a valid port!' =>
      ->(port) { port.to_i > 0 && port.to_i < 65_535 } }

  # Specifies the secure SSL port for LDAP traffic. The default is 3999.
  #
  # @param [Integer] port
  #   The LDAPS port to use.
  #
  # @return [Integer]
  #
  # @api private
  attribute :registry_ldaps_port, kind_of: String,
    default: lazy { node[:odsee][:registry_ldaps_port] },
    callbacks: { 'You must specify a valid port!' =>
      ->(port) { port.to_i > 0 && port.to_i < 65_535 } }

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

end
