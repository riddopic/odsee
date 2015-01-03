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

include Odsee

# The dsccagent command is used to create, delete, start, and stop DSCC agent
# instances on the local system. You can also use the dsccagent command to
# display status and DSCC agent information, and to enable and disable SNMP
# monitoring.

attr_writer :exists, :state, :snmp, :info

identity_attr :name
provides :odsee_dsccagent, os: 'linux'
actions :create, :delete, :disable_snmp, :enable_snmp, :info, :start, :stop
default_action :nothing
state_attrs :exists, :state, :snmp, :info

attribute :name, kind_of: String, name_attribute: true

# @return [TrueClass, FalseClass] true if the resource already exists.
def exists?
  !!@exists
end
