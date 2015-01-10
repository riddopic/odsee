# encoding: UTF-8
#
# Cookbook Name:: garcon
# HWRP:: dsadm
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

# A Chef Resource and Provider that manages a Directory Server instance.
#
# The dsadm Chef Resource and Provider can be used to manage a local Directory
# Server instance as a native Chef resource. With it you can create, delete,
# start, stop and backup local DSCC instances.
#
class Chef::Provider::Dsadm < Chef::Provider
  include Odsee

  use_inline_resources if defined?(:use_inline_resources)

  # Boolean indicating if WhyRun is supported by this provider.
  #
  # @return [TrueClass, FalseClass]
  #
  # @api private
  def whyrun_supported?
    true
  end

  # Load and return the current resource.
  #
  # @return [<Chef::Provider::Dsadm>]
  #
  # @api private
  def load_current_resource
    @current_resource ||= Chef::Resource::Dsadm.new(new_resource.name)
    @current_resource.info = info
    @current_resource.exists = exists?('Instance Path')
    @current_resource.state = state
    @current_resource
  end

  # Creates a Directory Server instance.
  #
  # @param [String] below
  #   Creates the Directory Server instance in an existing directory,
  #   specified by the `instance_path`. The existing directory must be
  #   empty. On UNIX machines, the user who runs this command must be root,
  #   or must be the owner of the existing directory. If the user is root,
  #   the instance will be owned by the owner of the existing directory.
  #
  # @param [TrueClass, FalseClass] no_inter
  #   When true does not prompt for password and/or does not prompt for
  #   confirmation before performing the operation.
  #
  # @param [String] user_name
  #   The server instance owner user ID.
  #
  # @param [String] group_name
  #   The server instance owner group ID.
  #
  # @param [String, Integer] hostname
  #   The DSCC registry host name or IP address.
  #
  # @param [Integer] ldap_port
  #   Specifies the port for LDAP traffic. The default is 389 if dsadm is
  #   run by the root user, or 1389 if dsadm is run by a non-root user.
  #
  # @param [Integer] ldaps_port
  #   Specifies the secure SSL port for LDAP traffic. The default is 636 if
  #   dsadm is run by the root user, or 1636 if dsadm is run by a non-root
  #   user.
  #
  # @param [String] dn
  #   Defines the Directory Manager DN. The default is cn=Directory Manager.
  #
  # @param [String] agent_pwd_file
  #   Reads the DSCC agent password from `pwd_file`.
  #
  # @param [String] instance_path
  #   Full path to the Directory Server instance.
  #
  # @return [undefined]
  #
  # @api private
  def action_create
    if exists?
      Chef::Log.info "#{new_resource} already created - nothing to do"
    else
      converge_by 'Creating a Directory Server instance' do
        begin
          dsadm :create, new_resource._?(:below,         '-B'),
                         new_resource._?(:no_inter,      '-i'),
                         new_resource._?(:user_name,     '-u'),
                         new_resource._?(:group_name,    '-g'),
                         new_resource._?(:hostname,      '-h'),
                         new_resource._?(:ldap_port,     '-p'),
                         new_resource._?(:ldaps_port,    '-P'),
                         new_resource._?(:dn,            '-D'),
                         new_resource._?(:admin_pw_file, '-w'),
                         new_resource.instance_path

          Chef::Log.info 'DSCC Directory Server instance initialized'
        ensure
          if ::File.exist?(new_resource.admin_pw_file.split.last)
            Chef::Log.debug "Removing Direcctory Service Admin password file"
            ::File.unlink new_resource.admin_pw_file.split.last
          end
        end
        new_resource.updated_by_last_action(true)
      end
    end
  end

  # Deletes a Directory Server instance.
  #
  # @param [String] instance_path
  #   Full path to the Directory Server instance.
  #
  # @return [undefined]
  #
  # @api private
  def action_delete
    if exists?
      converge_by "Deleting Directory Server instance for #{new_resource}" do
        dsadm :delete, new_resource.instance_path

        Chef::Log.info "Directory Server instance deleted for #{new_resource}"
      end
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.info "#{new_resource} does not exists - nothing to do"
    end
  end

  # Starts a Directory Server instance.
  #
  # @param [TrueClass, FalseClass] safe_mode
  #   Starts Directory Server with the configuration used at the last
  #   successful startup.
  #
  # @param [TrueClass, FalseClass] no_inter
  #   Does not prompt for password.
  #
  # @param [TrueClass, FalseClass] schema_push
  #   Ensures manually modified schema is replicated to consumers.
  #
  # @param [String] cert_pw_file
  #   Reads certificate database password from `cert_pw_file`.
  #
  # @param [String] instance_path
  #   Full path to the Directory Server instance.
  #
  # @return [undefined]
  #
  # @api private
  def action_start
    if exists?
      converge_by "Start the Directory Server instance for #{new_resource}" do
        dsadm :start, new_resource._?(:safe_mode,              '-E'),
                      new_resource._?(:no_inter,               '-i'),
                      new_resource._?(:schema_push, '--schema-push'),
                      new_resource._?(:cert_pw_file,           '-W'),
                      new_resource.instance_path

        Chef::Log.info "Directory Server instance started for #{new_resource}"
      end
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.info "#{new_resource} already enabled - nothing to do"
    end
  end

  # Stops a Directory Server instance.
  #
  # @param [TrueClass, FalseClass] force
  #   When used with stop-running-instances, the command forcibly shuts
  #   down all the running server instances that are created using the same
  #   dsadm installation. When used with stop, the command forcibly shuts
  #   down the instance even if the instance is not initiated by the
  #   current installation.
  #
  # @param [String] instance_path
  #   Full path to the Directory Server instance.
  #
  # @return [undefined]
  #
  # @api private
  def action_stop
    if stopped?
      Chef::Log.info "#{new_resource} not running - nothing to do"
    else
      converge_by "Stopping Directory Server instance for #{new_resource}" do
        dsadm :stop, new_resource._?(:force, '--force'),
                     new_resource.instance_path

        Chef::Log.info "Directory Server instance stopped for #{new_resource}"
      end
      new_resource.updated_by_last_action(true)
    end
  end

  # Restarts a Directory Server instance.
  #
  # @param [TrueClass, FalseClass] no_inter
  #   Does not prompt for password.
  #
  # @param [TrueClass, FalseClass] schema_push
  #   Ensures manually modified schema is replicated to consumers.
  #
  # @param [String] cert_pw_file
  #   Reads certificate database password from `cert_pw_file`.
  #
  # @param [String] instance_path
  #   Full path to the Directory Server instance.
  #
  # @return [undefined]
  #
  # @api private
  def action_stop
    converge_by "Restarting Directory Server instance for #{new_resource}" do
      dsadm :start, new_resource._?(:no_inter,               '-i'),
                    new_resource._?(:schema_push, '--schema-push'),
                    new_resource._?(:cert_pw_file,           '-W'),
                    new_resource.instance_path

      Chef::Log.info "Directory Server instance stopped for #{new_resource}"
    end
    new_resource.updated_by_last_action(true)
  end
end
