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

include Odsee

# The dsccsetup command is used to deploy Directory Service Control Center
# (DSCC) in an application server, and to register local agents of the
# administration framework.

attr_writer :exists

identity_attr :name
provides :odsee_dsccsetup, os: 'linux'
actions :ads_create, :ads_delete
default_action :nothing
state_attrs :exists

attribute :name, kind_of: String, name_attribute: true

# @return [Boolean] true if the DSCC Registry has been created.
def exists?
  !!@exists
end
