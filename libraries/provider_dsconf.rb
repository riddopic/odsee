# encoding: UTF-8
#
# Cookbook Name:: odsee
# Provider:: dsconf
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

# A Chef Resource and Provider that manages a Directory Server configuration.
#
# The dsconf Chef Resource and Provider can be used to manage a Directory
# Server configuration. It enables you to modify the configuration entries in
# `cn=config`. The server must be running in order for dsconf to run.
#
class Chef::Provider::Dsconf < Chef::Provider::LWRPBase
  include Odsee

  def initialize(name, run_context = nil)
    super
    @auth_required = true
  end

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
    if @new_resource.empty.nil?
      @new_resource.empty(@current_resource.empty)
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
    @current_resource = Chef::Resource::Dsconf.new(@new_resource.name)
    @current_resource.name(@new_resource.name)

    unless ::File.exist?(which(@resource_name.to_s))
      fail Odsee::Exceptions::ResourceNotFound
    end

    @current_resource.created(suffix_created?)
    @current_resource.empty(empty_suffix?)
    @current_resource
  end

  # Creates a top level suffix entry in a LDAP DIT (Directory Information Tree)
  #
  # @param [String, NilClass] hostname
  #   Connects to the directory on specified host, By default it is nil, which
  #   sets it to localhost.
  # @param [Integer] ldap_port
  #   Port used to connects to the directory server. If none is specified the
  #   default is to use port 389.
  # @param [String] db_name
  #   Specifies a database name.
  # @param [String] db_path
  #   Specifies database directory and path.
  # @param [String] accept_cert
  #   Specifies to not ask for confirmation before accepting non-trusted server
  #   certificates.
  # @param [String] no_top_entry
  #   Boolean, used to specify if the `create_suffix` command should not create
  #   a top entry for the suffix. By default, a top-level entry is created when
  #   a new suffix is created (on the condition that the suffix starts with
  #   `dc=, c=, o= or ou=`). The default is false.
  # @param [String] admin_passwd
  #   Uses `password` from `admin_passwd` file to access agent configuration.
  #
  # @param [String] suffix
  #   Suffix DN (Distinguished Name)
  #
  # @return [Chef::Resource::Dsconf]
  #
  # @api private
  def action_create_suffix
    if @current_resource.created
      Chef::Log.info "#{new_resource} already created - nothing to do"
    else
      converge_by "Creating #{new_resource} suffix entry in the DIT" do
        new_resource.admin_passwd.tmp do |__p__|
          dsconf :create_suffix,
                 new_resource._?(:hostname,     '-h'),
                 new_resource._?(:ldap_port,    '-p'),
                 new_resource._?(:db_name,      '-B'),
                 new_resource._?(:db_path,      '-L'),
                 new_resource._?(:accept_cert,  '-c'),
                 new_resource._?(:no_top_entry, '-N'),
                 new_resource._?(:admin_passwd, '-w'),
                 new_resource.suffix
          Chef::Log.info "DIT entry created for #{new_resource} suffix"
        end
        new_resource.updated_by_last_action(true)
      end
    end
    load_new_resource_state
    @current_resource.created(true)
  end

  # Deletes suffix configuration and data
  #
  # @param [String, NilClass] hostname
  #   Connects to the directory on specified host, By default it is nil, which
  #   sets it to localhost
  # @param [Integer] ldap_port
  #   Port used to connects to the directory server. If none is specified the
  #   default is to use port 389
  # @param [String] suffix
  #   Suffix DN (Distinguished Name)
  #
  # @return [Chef::Resource::Dsconf]
  #
  # @api private
  def action_delete_suffix
    if @current_resource.created
      converge_by "Deleting #{new_resource} suffix entry from the DIT" do
        dsconf :delete_suffix,
               new_resource._?(:hostname,  '-h'),
               new_resource._?(:ldap_port, '-p'),
               new_resource.suffix
        Chef::Log.info "DIT entry deleted for #{new_resource} suffix"
      end
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.info "#{new_resource} does not exists - nothing to do"
    end
    load_new_resource_state
    @current_resource.created(false)
  end

  # Populates an existing suffix with LDIF data from a compressed or
  # uncompressed LDIF file
  #
  # @param [String, NilClass] hostname
  #   Connects to the directory on specified host, By default it is nil, which
  #   sets it to localhost.
  # @param [Integer] ldap_port
  #   Port used to connects to the directory server. If none is specified the
  #   default is to use port 389.
  # @param [String] async
  #   Launches a task and returns the command line accessible immediately.
  # @param [TrueClass, FalseClass] incremental
  #   Specifies that the contents of the imported LDIF file are appended to the
  #   existing LDAP entries. If this option is not specified, the contents of
  #   the imported file replace the existing entries.
  # @param [Hash] subcommand options.
  # Import flags:
  #   @option opts [Integer] `chunk-size`
  #     Sets the merge chunk size. Overrides the detection of when to start a
  #     new pass during import.
  #   @option opts [TrueClass, FalseClass] `incremental-output`
  #     Specifies whether an output file will be generated for later use in
  #     importing to large replicated suffixes. Default is `true`. This flag
  #     can only be used when the `incremental` option is also `true`. If this
  #     flag is not used, an output file will automatically be generated.
  #   @option opts [String] `incremental-output-file`
  #     Sets the path of the generated output file for an incremental (appended)
  #     import. The output file is used for updating a replication topology. It
  #     is an LDIF file containing the difference between the replicated suffix
  #     and the LDIF file, and replication information.
  # Export flags:
  #   @option opts [Integer] `compression-level`
  #     Compression level to use when a `GZ_LDIF_FILE` is given as operand.
  #     Default level is `3`, level range is from `1` to `9`.
  #   @option opts [TrueClass, FalseClass] `multiple-output-file`
  #     Exports each suffix to a separate file.
  #   @option opts [TrueClass, FalseClass] `use-main-db-file`
  #     Exports the main database file only.
  #   @option opts [TrueClass, FalseClass] `not-export-unique-id`
  #     Does not export unique id values.
  #   @option opts [TrueClass, FalseClass] `output-not-folded`
  #     Does not wrap long lines.
  #   @option opts [TrueClass, FalseClass] `not-print-entry-ids`
  #     Does not export entry IDs.
  # Backup flags:
  #   @option opts [TrueClass, FalseClass] `verify-db`
  #     Check integrity of the backed up database.
  #   @option opts [TrueClass, FalseClass] `no-recovery`
  #     Skip recovery of the backed up database.
  # Restore flags:
  #   @option opts [TrueClass, FalseClass] `move-archive`
  #     Performs restore by moving files in place of copying them.
  # Rewrite flags:
  #   @option opts [TrueClass, FalseClass] `purge-csn`
  #     Purge the Change Sequence Number (CSN). The purge-csn flag is set to off
  #     by default. Setting purge-csn to on prevents old CSN data from being
  #     kept by the operation. This reduces the size of entries by removing
  #     traces of previous updates.
  #   @option opts [TrueClass, FalseClass] `convert-pwp-opattr-to-DS6`
  #     Converts DS5 mode password policy operational attributes into D6-mode.
  #     The convert-pwp-opattr-to-DS6 flag is set to off by default. When a
  #     server is DS6-migration-mode enabled, setting convert-pwp-opattr-to-DS6
  #     to on, permits DS5 mode password policy operational attributes to be
  #     migrated using their ID (Internet Draft) and to run in DS6-mode.
  #     DS6-migration-mode is the only mode in which you can migrate
  #     operational attributes safely. When the migration has been successfully
  #     performed, run the server in DS6-mode when you are ready.
  #
  #     Note that the dsconf rewrite -f convert-pwp-opattr-to-DS6=on subcommand
  #     must be run on all servers in the topology that are in
  #     DS6-migration-mode in order to migrate their DS5 mode password policy
  #     operational attributes.
  # @param [String] exclude_dn
  #   Does not import or export data contained under the specified dm.
  # @param [String] ldif_file
  #   Path and filename for file in LDIF format, can be gzip compressed.
  # @param [String] suffix
  #   Suffix DN (Distinguished Name).
  #
  # @return [Chef::Resource::Dsconf]
  #
  # @api private
  def action_import
    if @current_resource.empty
      converge_by "Populating #{new_resource.suffix} with LDIF content from " \
                  "#{new_resource.ldif_file}" do
        new_resource.admin_passwd.tmp do |__p__|
          dsconf :import,
                 new_resource._?(:hostname,     '-H'),
                 new_resource._?(:port,         '-p'),
                 new_resource._?(:async,      '-aei'),
                 new_resource._?(:incremental,  '-K'),
                 new_resource._?(:opts,         '-f'),
                 new_resource._?(:exclude_dn,   '-x'),
                 new_resource._?(:admin_passwd, '-w'),
                 new_resource.ldif_file,
                 new_resource.suffix
          Chef::Log.info "#{new_resource.suffix} has been populated."
        end
      end
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.info "#{new_resource.suffix} already populated - nothing to do"
    end
    load_new_resource_state
    @new_resource.empty(false)
  end
end
