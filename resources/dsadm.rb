# encoding: UTF-8
#
# Cookbook Name:: garcon
# Resource:: dsadm
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

include Odsee

# Manages a Directory Server instance. The dsadm command is the local
# administration command for Directory Server instances. The dsadm command must
# be run from the local machine where the server instance is located. This
# command must be run by the username that is the operating system owner of the
# server instance, or by root.

attr_writer :exists, :state, :info

identity_attr :path
provides :odsee_dsadm, os: 'linux'
actions :create, :delete, :start, :stop
default_action :nothing
state_attrs :exists, :state, :info

# Path of the Directory Server instance to create
attribute :path, kind_of: String, name_attribute: true

# Sets the instance owner user ID (Default: is root)
attribute :username, kind_of: String,
          default: lazy { node[:odsee][:dsadm][:username] }

# Sets the instance owner group ID (Default: root)
attribute :groupname, kind_of: String,
          default: lazy { node[:odsee][:dsadm][:groupname] }

# @return [TrueClass, FalseClass] true if the resource already exists.
def exists?
  !!@exists
end
