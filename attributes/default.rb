# encoding: UTF-8
#
# Cookbook Name:: odsee
# Attributes:: default
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

# location where the sorce ZIP file distribution can be found.
default[:odsee][:source] = {
  filename: 'http://repo.mudbox.dev/oracle/oiam11g/sun-dsee7.zip',
  checksum: 'bd8451c8fa493206f79d0cf9141c1c15ed202f9288084208363a98de15b51137'
}

# Path under which Directory Server is installed.
default[:odsee][:install_dir] = '/opt'

# Password assigned to the Directory Service Manager, if none is provided one
# will be randomly generate and assigned to the `node[:odsee][:admin_password]`
# attribute (default: randomly generate password).
default[:odsee][:admin_password] = nil

# Password assigned to the Directory Service Agent, if none is provided one
# will be randomly generate and assigned to the `node[:odsee][:agent_password]`
# attribute (default: randomly generate password).
default[:odsee][:agent_password] = nil

# Password assigned to the certificate database, if none is provided one will
# be randomly generate and assigned to the `node[:odsee][:cert_password]`
# attribute (default: randomly generate password).
default[:odsee][:cert_password] = nil

# Uses PORT for the LDAP port, the default is 398.
default[:odsee][:ldap_port] = 389

# Uses PORT for the LDAPS port, the default is 636.
default[:odsee][:ldaps_port] = 636

# The PORT for traffic from Directory Servers to agent, the default is 3995.
default[:odsee][:ds_port] = 3995

# The PORT number for SNMP, the default is port 3996.
default[:odsee][:ds_port] = 3996

# Uses PORT for the agent port for the DSCC instance (default is 3997).
default[:odsee][:agent_port] = 3997

# Uses PORT for the LDAP port for the DSCC registry instance (default is 3998).
default[:odsee][:registry_ldap_port] = 3998

# Uses PORT for the LDAPS port for the DSCC registry instance (default is 3999).
default[:odsee][:registry_ldaps_port] = 3999

# Default DN as Directory Manager DN.
default[:odsee][:dn] = "'cn=Directory Manager'"

# Does not ask for confirmation before rejecting non-trusted server
# certificates.
default[:odsee][:reject_cert] = true

# Does not ask for confirmation before rejecting non-trusted server
# certificates.
default[:odsee][:reject_cert] = true

# Does not prompt for confirmation before performing the operation.
default[:odsee][:no_inter] = true

# Sets the server instance owner's group ID. The default is the user's current
# UNIX group.
default[:odsee][:dsadm][:user_name] = 'root'

# Sets the server instance owner user ID. The default is the current UNIX user
# name.
default[:odsee][:dsadm][:group_name] = 'root'

# Boolean, true if SNMP version 3 should be used, otherwise false.
default[:odsee][:snmp_v3] = false

# Path of the DSCC Registry.
default[:odsee][:registry_path] = ->{
  ::File.join(node[:odsee][:install_dir], 'dsee7/var/dcc/ads') }

# Full path to the existing DSCC agent instance. The default path is to use:
# install-path/var/dcc/agent
default[:odsee][:agent_path] = ->{
  ::File.join(node[:odsee][:install_dir], 'dsee7/var/dcc/agent') }

# Creates the Directory Server instance in an existing directory, specified by
# the `instance_path`. The existing directory must be empty. On UNIX machines,
# the user who runs this command must be root, or must be the owner of the
# existing directory. If the user is root, the instance will be owned by the
# owner of the existing directory.
default[:odsee][:instance_path] = '/opt/dsInst'

# When true starts Directory Server with the configuration used at the last
# successful startup.
default[:odsee][:safe_mode] = false

# When true ensures manually modified schema is replicated to consumers. Default
# is false.
default[:odsee][:schema_push] = false

# If the instance should be forcibly shut down. When used with
#`stop-running-instances`, the command forcibly shuts down all the running
# server instances that are created using the same dsadm installation. When
# used with stop, the command forcibly shuts down the instance even if the
# instance is not initiated by the current installation.
default[:odsee][:force] = false
