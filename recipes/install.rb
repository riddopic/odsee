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

chef_gem('net-ldap')  { action :nothing }.run_action(:install)
require 'net/ldap' unless defined?(Net::LDAP)

single_include 'garcon::default'

concurrent 'Odsee::Install' do
  block do
    monitor.synchronize do
      %w(gtk2-engines).each do |pkg|
        package pkg
      end

      %w(gtk2 libgcc glibc).each do |pkg|
        %w(x86_64 i686).each do |arch|
          yum_package pkg do
            arch arch
          end
        end
      end
    end
  end
end

zip_file node[:odsee][:install_dir] do
  checksum node[:odsee][:source][:checksum]
  source node[:odsee][:source][:filename]
  overwrite true
  remove_after true
  not_if { ::File.directory?(node[:odsee][:registry_path].call) }
  not_if { ::File.directory?(node[:odsee][:agent_path].call) }
  action :unzip
end
