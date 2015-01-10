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
# The dsconf Chef Resource and Provider can be used to manage a Directory
# Server configuration. It enables you to modify the configuration entries in
# `cn=config`. The server must be running in order for dsconf to run.
#
class Chef::Resource::Dsconf < Chef::Resource::LWRPBase
  include Odsee

  identity_attr :suffix
  provides :dsconf, os: 'linux'
  self.resource_name = :dsconf

  actions :create_suffix, :delete_suffix, :import, :export
  default_action :nothing

  state_attrs :exists, :info
  provider_base Chef::Provider::Dsconf

  # @!attribute [rw] exists
  #   @return [TrueClass, FalseClass] Boolean, true if the BLANK BLANK BLANK
  #     BLANK BLANK, false otherwise.
  attr_writer :exists

  # Distinguished Name of the suffix to create.
  attribute :suffix, kind_of: String, name_attribute: true

  # A LDIF data file.
  attribute :ldif, kind_of: String, default: nil

end
