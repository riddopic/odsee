# encoding: UTF-8
#
# Cookbook Name:: odsee
# Resources:: dsconf
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

# A Chef Resource and Provider that manages a Directory Server configuration.
#
# The `dsconf` Chef Resource and Provider can be used to manage a Directory
# Server configuration. It enables you to modify the configuration entries in
# `cn=config`. The server must be running in order for `dsconf` to run.
#
class Chef::Resource::Dsconf < Chef::Resource::LWRPBase
  include Odsee

  identity_attr :suffix
  provides :dsconf, os: 'linux'
  self.resource_name = :dsconf

  # Adds actions to the list of valid actions for this resource
  #
  # @return [Chef::Provider::Dsccsetup]
  # @api public
  actions :create_suffix, :delete_suffix, :import, :export

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

  # Creates the namespaced Chef::Provider::Dsconf
  #
  # @return [undefined]
  # @api private
  provider_base Chef::Provider::Dsconf

  # Boolean, returns true if...WHAT?..WHAT?..WHAT?..WHAT?..?.., otherwise false
  #
  # @param [TrueClass, FalseClass]
  #
  # @return [TrueClass, FalseClass]
  #
  # @api private
  attribute :created,
    kind_of: [TrueClass, FalseClass],
    default: nil

  # The DSCC registry host name. By default it is nil, which sets it to
  # localhost.
  #
  # @param [String, NilClass] host
  #
  # @return [String, NilClass]
  #
  # @api public
  attribute :hostname,
    kind_of: [String, NilClass],
    default: nil

  # The port number to use for LDAP communication. Default is 389.
  #
  # @param [Integer] port
  #   The LDAP port to use.
  #
  # @return [Integer]
  #
  # @api public
  attribute :ldap_port,
    kind_of: Integer,
    default: lazy { node[:odsee][:ldap_port] }

  # The name of the backend suffix database
  #
  # @param [String] db_name
  #   Specifies a database name.
  #
  # @return [String] db_name
  #
  # @api public
  attribute :db_name,
    kind_of: String,
    default: nil

  # The path to the backend suffix database
  #
  # @param [String] db_path
  #   Specifies database directory and path.
  #
  # @return [String]
  #
  # @api public
  attribute :db_path,
    kind_of: String,
    default: nil

  # Boolean, used to specify if the `create_suffix` command should not create a
  # top entry for the suffix. By default, a top-level entry is created when a
  # new suffix is created (on the condition that the suffix starts with `dc=,
  # c=, o= or ou=`). The default is false.
  #
  # @param [TrueClass, FalseClass] no_top_entry
  #
  # @return [TrueClass, FalseClass]
  #
  # @api public
  attribute :no_top_entry,
    kind_of: [TrueClass, FalseClass],
    default: lazy { node[:odsee][:no_top_entry] }

  # The Suffix DN (Distinguished Name) for the given resource
  #
  # @param [String] suffix
  #   Suffix DN (Distinguished Name)
  #
  # @return [String]
  #
  # @api public
  attribute :suffix,
    kind_of: String,
    name_attribute: true

  # Launches a task and returns the command line accessible immediately
  #
  # @param [TrueClass, FalseClass] async
  #   Specifies a database name.
  #
  # @return [TrueClass, FalseClass]
  #
  # @api public
  attribute :async,
    kind_of: [TrueClass, FalseClass],
    default: nil

  # Launches a task and returns the command line accessible immediately
  #
  # @param [TrueClass, FalseClass] incremental
  #   Specifies a database name.
  #
  # @return [TrueClass, FalseClass]
  #
  # @api public
  attribute :incremental,
    kind_of: [TrueClass, FalseClass],
    default: nil

  # Launches a task and returns the command line accessible immediately
  #
  # @param [String] exclude_dn
  #   Specifies a database name.
  #
  # @return [String]
  #
  # @api public
  attribute :exclude_dn,
    kind_of: [TrueClass, FalseClass],
    default: nil

  # Path and filename for file in LDIF format to import, can be gzip compressed
  #
  # @param [String] ldif_file
  #
  # @return [String]
  #
  # @api public
  attribute :ldif_file,
    kind_of: String

  # A file containing the Direcctory Service Manager password.
  #
  # @param [String] file
  #   File to use to store the Direcctory Service Manager password.
  #
  # @return [String]
  #
  # @api public
  attribute :admin_pw_file,
    kind_of: Proc,
    default: lazy { __admin_pw__ }

end
