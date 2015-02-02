# encoding: UTF-8
#
# Cookbook Name:: odsee
# Provider:: ldap_entry
#
# Author:    Stefano Harding <riddopic@gmail.com>
# License:   Apache License, Version 2.0
# Copyright: (C) 2014-2015 Stefano Harding
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

# Creates a user for various kinds of identity management purposes. This is
# useful to create users who can bind (connect) and use the LDAP instance. It
# can also be used to create users with posix attributes on them for use with
# UNIX systems.
#
class Chef::Provider::LdapEntry < Chef::Provider::LWRPBase
  include Odsee

  use_inline_resources if defined?(:use_inline_resources)

  # Boolean indicating if WhyRun is supported by this provider
  #
  # @return [TrueClass, FalseClass]
  #
  # @api private
  def whyrun_supported?
    true
  end

  # Reload the resource state when something changes
  #
  # @return [undefined]
  #
  # @api private
  def load_new_resource_state
    if @new_resource.created.nil?
      @new_resource.created(@current_resource.created)
    end
  end

  # Load and return the current resource.
  #
  # @return [Chef::Resource::LdapEntry]
  #
  # @api private
  def load_current_resource
    @current_resource = Chef::Resource::LdapEntry.new(@new_resource.dn)
    @current_resource.dn(@new_resource.dn)
    @current_resource.created(dn?)
    @current_resource
  end

  def action_create
    if @new_resource.created
      Chef::Log.info "#{new_resource.dn} already created - nothing to do"
    else
      converge_by "Creating #{new_resource.dn} entry in directory" do

        Chef::Log.info "Entry created for #{new_resource.dn}"
      end
      new_resource.updated_by_last_action(true)
    end
    load_new_resource_state
    @current_resource.created(true)
  end

  def action_delete
    if @new_resource.created
      converge_by "Deleting #{new_resource.dn} entry from directory" do

        Chef::Log.info "Entry #{new_resource.dn} deleted"
      end
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.info "#{new_resource.dn} already deleted - nothing to do"
    end
    load_new_resource_state
    @current_resource.created(false)
  end
end
