# encoding: UTF-8
#
# Cookbook Name:: odsee
# Provider:: dsconf
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

# A Chef Resource and Provider that manages a Directory Server configuration.
#
# The dsconf Chef Resource and Provider can be used to manage a Directory
# Server configuration. It enables you to modify the configuration entries in
# `cn=config`. The server must be running in order for dsconf to run.
#
class Chef::Provider::Dsconf < Chef::Provider
  include Odsee

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
    @current_resource ||= Chef::Resource::Dsconf.new(new_resource.name)
    @current_resource.info = info
    @current_resource.exists = exists?('Instance Path')
    @current_resource.state = state
    @current_resource
  end

# Enables inline evaluation of resources in provider actions.
use_inline_resources if defined?(:use_inline_resources)

# @return [TrueClass, FalseClass]
#   If WhyRun is supported by this provider.
#
# @api private
def whyrun_supported?
  true
end

# Load and return the current resource.
#
# @return [<Chef::Provider::OdseeDsconf>]
#
# @api private
def load_current_resource
  @current_resource      ||= new(new_resource.name)
  @current_resource.exists = exists?
  @current_resource.info   = info
  @current_resource
end

# Creates a top level suffix entry in a LDAP DIT (Directory Information Tree).
#
# @param [String, Integer] hostname
#   Connects to the directory on specified host, this can be a host name or an
#   IP address. If no host is specified the default is to use the local host.
#
# @param [Integer] port
#   Port used to connects to the directory server, If none are specified are,
#    the default is to use port 636.
#
# @param [String] db_name
#   Specifies a database name.
#
# @param [String] db_path
#   Specifies database directory and path.
#
# @param [String] no_top_entry
#   Does not create a top entry for the suffix. By default, a top-level entry
#   is created when a new suffix is created (on the condition that the suffix
#   starts with dc=, c=, o= or ou=). This option changes the default behavior.
#
# @param [String] suffix
#   Suffix DN (Distinguished Name).
#
# @return [undefined]
#
# @api private
action :create_suffix do
  unless @current_resource.exists?
    converge_by 'Creating an empty suffix' do
      run dsconf :create_suffix, hostname, port, db_name, db_path,
                                 no_top_entry, new_resource.suffix
    end
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info "#{new_resource} already exists - nothing to do"
  end
end

# Deletes suffix configuration and data.
#
# @param [String, Integer] hostname
#   Connects to the directory on specified host, this can be a host name or an
#   IP address. If no host is specified the default is to use the local host.
#
# @param [Integer] port
#   Port used to connects to the directory server, If none are specified are,
#    the default is to use port 636.
#
# @param [String] suffix
#   Suffix DN (Distinguished Name).
#
# @return [undefined]
#
# @api private
action :delete_suffix do
  if @current_resource.exists?
    converge_by 'Deletes suffix configuration and data' do
      dsconf :delete_suffix, user_dn, port, unsecured, admin_pwd,
                             new_resource.suffix
    end
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info "#{new_resource} does not exists - nothing to do"
  end
end

# Populates an existing suffix with LDIF data from a compressed or uncompressed
# LDIF file.
#
# @param [String, Integer] hostname
#   Connects to the directory on specified host, this can be a host name or an
#   IP address. If no host is specified the default is to use the local host.
#
# @param [Integer] port
#   Port used to connects to the directory server, If none are specified are,
#    the default is to use port 636.
#
# @param [String] async
#   Launches a task and returns the command line accessible immediately.
#
# @param [incremental] async
#   Specifies that the contents of the imported LDIF file are appended to the
#   existing LDAP entries. If this option is not specified, the contents of the
#   imported file replace the existing entries.
#
# @param [Hash] flags
#   Customizes specific subcommand.
#   Import flags:
#   * chunk-size=INTEGER
#     Sets the merge chunk size. Overrides the detection of when to start a new
#     pass during import.
#   * incremental-output
#     Specifies whether an output file will be generated for later use in
#     importing to large replicated suffixes. Default is yes. Possible values
#     are yes and no. This flag can only be used when the -K option is used.
#     If this flag is not used, an output file will automatically be generated.
#   * incremental-output-file=PATH
#     Sets the path of the generated output file for an incremental (appended)
#     import. The output file is used for updating a replication topology. It
#     is an LDIF file containing the difference between the replicated suffix
#     and the LDIF file, and replication information.
#
#   Export flags:
#   * compression-level
#     Compression level to use when a GZ_LDIF_FILE is given as operand. Default
#     level is 3, level range is from 1 to 9.
#   * multiple-output-file
#     Exports each suffix to a separate file.
#   * use-main-db-file
#     Exports the main database file only.
#   * not-export-unique-id
#     Does not export unique id values.
#   * output-not-folded
#     Does not wrap long lines.
#   * not-print-entry-ids
#     Does not export entry IDs.
#
#   Backup flags:
#   * verify-db
#     Check integrity of the backed up database.
#
#   * no-recovery
#     Skip recovery of the backed up database.
#
#   Restore flags:
#   * move-archive
#     Performs restore by moving files in place of copying them.
#
#   Rewrite flags:
#   * purge-csn
#     Purge the Change Sequence Number (CSN). The purge-csn flag is set to off
#     by default. Setting purge-csn to on prevents old CSN data from being kept
#     by the operation. This reduces the size of entries by removing traces of
#     previous updates.
#
#   convert-pwp-opattr-to-DS6
#   * Converts DS5 mode password policy operational attributes to run in
#     D6-mode. The convert-pwp-opattr-to-DS6 flag is set to off by default.
#     When a server is DS6-migration-mode enabled, setting
#     convert-pwp-opattr-to-DS6 to on, permits DS5 mode password policy
#     operational attributes to be migrated using their ID (Internet Draft) and
#     to run in DS6-mode. DS6-migration-mode is the only mode in which you can
#     migrate operational attributes safely. When the migration has been
#     successfully performed, run the server in DS6-mode when you are ready.
#
#     Note that the dsconf rewrite -f convert-pwp-opattr-to-DS6=on subcommand
#     must be run on all servers in the topology that are in DS6-migration-mode
#     in order to migrate their DS5 mode password policy operational attributes.
#
# @param [String] dn
#   Does not import or export data contained under the specified dm.
#
# @param [String] ldif_file
#   Path and filename for file in LDIF format, can be gzip compressed.
#
# @param [String] suffix
#   Suffix DN (Distinguished Name).
#
# @return [undefined]
#
# @api private
action :import do
  if empty_suffix?
    converge_by 'Populating suffix with LDIF data' do
      if ::File.exist?(new_resource.ldif)
        dsconf :import, user_dn, port, unsecured, no_inter, async, admin_pwd,
                        new_resource.ldif, new_resource.suffix
      else
        fail Odsee::Exceptions::LDIFNotFoundError, new_resource.ldif
      end
    end
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info "#{new_resource} already exists - nothing to do"
  end
end

private #       P R O P R I E T À   P R I V A T A   Vietato L'accesso

# @return [String]
#   Path to executable.
#
# @api private
def dsconf
  ::File.join(node[:odsee][:install_dir], 'dsee7/bin/dsconf')
end

# The following options apply to the subcommands where they are specified:

# @return [String]
#   Connects over LDAP with no secure connection.
#
# @api private
def unsecured
  '-e'
end

# @return [String]
#   launches a task and returns the command line immediately.
#
# @api private
def async
  '-a'
end
