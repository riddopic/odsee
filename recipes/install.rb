# encoding: UTF-8
#
# Cookbook Name:: odsee
# Cookbook:: install
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

single_include 'garcon::default'

zip_file node[:odsee][:install_dir] do
  checksum node[:odsee][:source][:checksum]
  source node[:odsee][:source][:filename]
  overwrite true
  remove_after true
  not_if { ::File.directory?(node[:odsee][:registry_path].call) }
  not_if { ::File.directory?(node[:odsee][:agent_path].call) }
  not_if {
    ::File.exist?(::File.join(node[:odsee][:install_dir], 'dsee7/bin/dsconf'))
  }
  action :unzip
end
