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
# will be randomly generate and assigned to the `node[:odsee][:dsm_password]`
# attribute (default: randomly generate password).
default[:odsee][:admin_password] = nil

# Uses DSCC agent password, if none is provided it will use the same password
# from `node[:odsee][:dsm_password]` (default: use `:dsm_password`).
default[:odsee][:agent_password] = nil

# Path of the DSCC Registry (default: `node[:odsee][:install_dir]/var/dcc/ads`).
default[:odsee][:registry_path] = ::File.join(node[:odsee][:install_dir], 'var/dcc/ads')

# Port of the DSCC Registry (default: 3998).
default[:odsee][:registry_port] = 3998

# Port of the DSCC Agent (default: 3997).
default[:odsee][:agent_port] = 3997

# Uses PORT for the LDAP port (default is 398).
default[:odsee][:port] = 389

# Uses PORT for the LDAPS port (default is 636).
default[:odsee][:secure_port] = 636

# Default DN as Directory Manager DN.
default[:odsee][:dn] = "'cn=Directory Manager'"

# Hostname or IP address of the DSCC registry to connect to. When nil it will
# connect to localhost (the default).
default[:odsee][:hostname] = nil

# Does not ask for confirmation before rejecting non-trusted server certificates.
default[:odsee][:reject_cert] = true

# Does not ask for confirmation before rejecting non-trusted server
# certificates.
default[:odsee][:reject_cert] = true

# Does not prompt for confirmation before performing the operation.
default[:odsee][:no_inter] = true

# Sets the server instance owner's group ID. The default is the user's current
# UNIX group.
default[:odsee][:dsadm][:username] = 'root'

# Sets the server instance owner user ID. The default is the current UNIX user
# name.
default[:odsee][:dsadm][:groupname] = 'root'

