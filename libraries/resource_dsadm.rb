# encoding: UTF-8
#
# Cookbook Name:: odsee
# Resources:: dsadm
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

# A Chef Resource and Provider that manages a Directory Server instance.
#
# The dsadm Chef Resource and Provider can be used to manage a local Directory
# Server instance as a native Chef resource. With it you can create, delete,
# start, stop and backup local DSCC instances.
#
class Chef::Resource::Dsadm < Chef::Resource::LWRPBase
  include Odsee

  identity_attr :name
  provides :dsadm, os: 'linux'
  self.resource_name = :dsadm

  actions :create, :delete, :start, :stop, :restart, :backup,
          :enable_service, :disable_service
  state_attrs :exists, :state, :info
  default_action :nothing

  provider_base Chef::Provider::Dsccsetup

  # Boolean, returns true if the Directory Server instance has been created,
  # otherwise false
  # @note state attribute
  #
  # @param [TrueClass, FalseClass]
  #
  # @return [TrueClass, FalseClass]
  #
  # @api private
  attribute :created,
    kind_of: [TrueClass, FalseClass],
    default: nil

  # Creates the Directory Server instance in an existing directory,
  # specified by the `instance_path`. The existing directory must be empty.
  # On UNIX machines, the user who runs this command must be root, or must
  # be the owner of the existing directory. If the user is root, the
  # instance will be owned by the owner of the existing directory.
  #
  # @param [String] instance_path
  #   Directory where you would like the Directory Server instance to run.
  #
  # @return [String]
  #
  # @api private
  attribute :below,
    kind_of: String, name_attribute: true,
    default: lazy { node[:odsee][:instance_path] }

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

  # The server instance owner user ID. The default is root.
  #
  # @param [String] user
  #
  # @return [String]
  #
  # @api private
  attribute :user_name,
    kind_of: String,
    default: lazy { node[:odsee][:dsadm][:user_name] },
    regex: Chef::Config[:user_valid_regex]

  # The server instance owner user ID. The default is root.
  #
  # @param [String] user
  #
  # @return [String]
  #
  # @api private
  attribute :group_name,
    kind_of: String,
    default: lazy { node[:odsee][:dsadm][:group_name] },
    regex: Chef::Config[:user_valid_regex]

  # The DSCC registry host name. By default it is nil, which sets it to
  # localhost.
  #
  # @param [String, NilClass] host
  #
  # @return [String, NilClass]
  #
  # @api private
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
  # @api private
  attribute :ldap_port,
    kind_of: Integer,
    default: lazy { node[:odsee][:ldap_port] }

  # The port number to use for LDAPS communication. Default is 636.
  #
  # @param [Integer] port
  #   The LDAPS port to use.
  #
  # @return [Integer]
  #
  # @api private
  attribute :ldaps_port,
    kind_of: Integer,
    default: lazy { node[:odsee][:ldaps_port] }

  # Defines the Directory Manager DN. The default is `cn=Directory Manager`.
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

  # Starts Directory Server with the configuration used at the last
  # successful startup.
  #
  # @param [TrueClass, FalseClass]
  #
  # @return [TrueClass, FalseClass]
  #
  # @api private
  attribute :safe_mode,
    kind_of: [TrueClass, FalseClass],
    default: lazy { node[:odsee][:safe_mode] }

  # Ensures manually modified schema is replicated to consumers.
  #
  # @param [TrueClass, FalseClass] schema_push
  #
  # @return [TrueClass, FalseClass]
  #
  # @api private
  attribute :schema_push,
    kind_of: [TrueClass, FalseClass],
    default: lazy { node[:odsee][:schema_push] }

  # A file containing the certificate database password.
  #
  # @param [String] cert_pw_file
  #   File to use to store the certificate database password.
  #
  # @return [String]
  #
  # @api private
  attribute :cert_pw_file,
    kind_of: Proc,
    default: lazy { __cert_pw__ }

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
    
end
