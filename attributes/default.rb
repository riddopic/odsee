# encoding: UTF-8
#
# Author: Stefano Harding <sharding@trace3.com>
# Cookbook Name:: odsee
# Attributes:: default
#

# location where the sorce ZIP file distribution can be found.
default[:odsee][:source] = 'http://repo.mudbox.dev/oracle/oiam11g/sun-dsee7.zip'

# Path under which Directory Server is installed.
default[:odsee][:install_dir] = '/opt'

# ====================== Directory Service Control Center  =====================
#
# Password assigned to the Directory Service Manager, if none is provided one
# will be randomly generate and assigned to the `node[:odsee][:dsm_password]`
# attribute (default: randomly generate password).
default[:odsee][:dsm_password] = nil

# Uses DSCC agent password, if none is provided it will use the same password
# from `node[:odsee][:dsm_password]` (default: use `:dsm_password`).
default[:odsee][:agent_password] = nil

# Temporary location of the DSCC administrator's password. Used when a CLI tool
# takes the password file as an argument.
default[:odsee][:pwd_file] = '/root/.befuddle'
default[:odsee][:agent_pwd_file] = node[:odsee][:pwd_file]

# Path of the DSCC Registry (default: `node[:odsee][:install_dir]/var/dcc/ads`).
default[:odsee][:registry_path] = ::File.join(node[:odsee][:install_dir], 'var/dcc/ads')

# Port of the DSCC Registry (default: 3998).
default[:odsee][:registry_port] = 3998

# Port of the DSCC Agent (default: 3997).
default[:odsee][:agent_port] = 3997
