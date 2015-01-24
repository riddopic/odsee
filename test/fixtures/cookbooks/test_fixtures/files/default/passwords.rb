# encoding: UTF-8
#
# Cookbook Name:: garcon
# Handler:: threadpool
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

require 'chef/handler'

class PasswordPooper < Chef::Handler

  def initialize
    Chef::Log.debug "#{self.class.to_s} initialized."
  end

  def report
    if failed?
      # If something goes wrong in dev dump the password so you can debug
      Chef::Log.info ''
      Chef::Log.info '->>>---P-A-S-S-W-O-R-D-S---F-O-R---A-L-L---T-O---S-E-E---->>>>'
      Chef::Log.info ''
      Chef::Log.info "admin => '#{node[:odsee][:admin_password]}'"
      Chef::Log.info "agent => '#{node[:odsee][:agent_password]}'"
      Chef::Log.info "cert  => '#{node[:odsee][:cert_password]}'"
    end
  end
end
