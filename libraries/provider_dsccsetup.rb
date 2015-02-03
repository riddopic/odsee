# encoding: UTF-8
#
# Cookbook Name:: odsee
# HWRP:: dsccsetup
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

# A Chef resource for the Oracle Directory Server dsccsetup resource.
#
# The dsccsetup command is used to deploy Directory Service Control Center
# (DSCC) in an application server, and to register local agents of the
# administration framework.
#
class Chef::Provider::Dsccsetup < Chef::Provider::LWRPBase
  include Odsee

  # Boolean indicating if WhyRun is supported by this provider.
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
  # @return [Chef::Resource::Dsccsetup]
  #
  # @raise [Odsee::Exceptions::ResourceNotFound]
  #
  # @api private
  def load_current_resource
    @current_resource = Chef::Resource::Dsccsetup.new(@new_resource.name)
    @current_resource.name(@new_resource.name)

    unless ::File.exist?(which(@resource_name.to_s))
      fail Odsee::Exceptions::ResourceNotFound
    end

    @current_resource.created(ads_created?)
    @current_resource
  end

  # Initialize the DSCC registry, a local Directory Server instance for
  # private use by DSCC to store configuration information. DSCC requires
  # that this instance reside locally on the host where you run DSCC.
  # Therefore, if you replicate the data in the instance for high
  # availability, set up one DSCC per replica host.
  #
  # @note Please note the following when initialize the DSCC Registry:
  #       * The default port numbers used are 3998 for LDAP, and 3999
  #         for LDAPS.
  #       * The default instance path of DSCC registry is
  #         install-path/var/dcc/ads.
  #       * The base DN for the suffix containing configuration
  #         information is cn=dscc.
  #
  # @param [String] admin_passwd
  #   Use the Direcctory Service Manager password specified in file.
  # @param [Integer] registry_ldap_port
  #   The port number to use for LDAP. The default is 3998.
  # @param [Integer] registry_ldaps_port
  #   The port number to use for LDAPS. The default is 3999.
  #
  # @return [Chef::Resource::Dsccsetup]
  #
  # @api public
  def action_ads_create
    if @current_resource.created
      Chef::Log.info "#{new_resource} already exists - nothing to do"
    else
      converge_by "Initialize DSCC registry for #{new_resource}" do
        new_resource.admin_passwd.tmp do |__p__|
          lock.enter
          do_prerequisite
          dsccsetup :ads_create,
                    new_resource._?(:admin_passwd,        '-w'),
                    new_resource._?(:registry_ldap_port,  '-p'),
                    new_resource._?(:registry_ldaps_port, '-P')
          lock.exit
        end
        Chef::Log.info "DSCC registry initialized for #{new_resource}"
      end
    end
    load_new_resource_state
    @new_resource.created(true)
  end

  # Delete the Directory Server instance used by DSCC to store configuration
  # information. If you delete the DSCC registry, all the server
  # registrations are deleted but the Server instances remain unaffected.
  #
  # @param [TrueClass, FalseClass] no_inter
  #   Does not prompt for password and/or does not prompt for confirmation
  #   before performing the operation.
  #
  # @return [undefined]
  #
  # @return [Chef::Resource::Dsccsetup]
  #
  # @api public
  def action_ads_delete
    if @current_resource.created
      converge_by "Deleting DSCC registry for #{new_resource}" do
        dsccsetup :ads_delete, new_resource._?(:no_inter, '-i')
        Chef::Log.info "DSCC registry deleted for #{new_resource}"
      end
    else
      Chef::Log.info "#{new_resource} does not exists - nothing to do"
    end
    load_new_resource_state
    @new_resource.created(false)
  end

  private #   P R O P R I E T À   P R I V A T A   Vietato L'accesso

  # @api private
  def do_prerequisite
    lock.synchronize do
      %w(gtk2-engines).each do |pkg|
        package(pkg) { action :nothing }.run_action(:install)
      end

      %w(gtk2 libgcc glibc).each do |pkg|
        %w(x86_64 i686).each do |arch|
          yum_package pkg do
            arch arch
            action :nothing
          end.run_action(:install)
        end
      end
    end
  end
end
