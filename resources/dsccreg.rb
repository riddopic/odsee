# encoding: UTF-8
#
# Cookbook Name:: odsee
# Resources:: dsccreg
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

# The dsccreg command is used to register server instances on the local system
# with the Directory Service Control Center (DSCC) registry, which may be
# remote.

identity_attr :path
provides :odsee_dsccreg, os: 'linux'
actions :add_agent, :add_server, :remove_agent, :remove_server
default_action :nothing

# Path to existing DSCC server or agent instance.
attribute :path, kind_of: String, name_attribute: true
