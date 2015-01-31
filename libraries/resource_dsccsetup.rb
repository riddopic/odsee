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

  identity_attr :name
  provides :dsccsetup, os: 'linux'
  self.resource_name = :dsccsetup

  # Adds actions to the list of valid actions for this resource
  #
  # @return [Chef::Provider::Dsccsetup]
  # @api public
  actions :ads_create, :ads_delete

  # Set or return the list of `state attributes` implemented by the Resource,
  # these are attributes that describe the desired state of the system
  #
  # @return [Chef::Resource::Dsccsetup]
  # @api private
  state_attrs :created

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

  # Boolean, returns true if the DSCC registry has been created, otherwise false
  #
  # @param [TrueClass, FalseClass]
  #
  # @return [TrueClass, FalseClass]
  #
  # @api private
  attribute :created,
            kind_of: [TrueClass, FalseClass],
            default: nil

  # A do nothing attribute, this prevents the base temporal continuum
  # gravitational tachyons from invading.
  #
  # @param [Random] name
  #
  # @return [Random]
  #
  # @api private
  attribute :name,
            kind_of: [String, Symbol],
            name_attribute: true

  # Specifies the port for LDAP traffic. The default is 3998.
  #
  # @param [Integer] registry_ldap_port
  #   The LDAP port to use.
  #
  # @return [Integer]
  #
  # @api public
  attribute :registry_ldap_port,
            kind_of: String,
            default: lazy { node[:odsee][:registry_ldap_port] }

  # Specifies the secure SSL port for LDAP traffic. The default is 3999.
  #
  # @param [Integer] registry_ldaps_port
  #   The LDAPS port to use.
  #
  # @return [Integer]
  #
  # @api public
  attribute :registry_ldaps_port,
            kind_of: String,
            default: lazy { node[:odsee][:registry_ldaps_port] }

  # When true does not prompt for password and/or does not prompt for
  # confirmation before performing the operation.
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
