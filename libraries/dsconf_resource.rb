# encoding: UTF-8
#
# Author: Stefano Harding <sharding@trace3.com>
# Cookbook Name:: odsee
# Library:: dsconf_resource
#

require_relative 'helpers'

# A Chef resource for the Oracle Directory Server Enterprise Edition
#
class Chef::Resource::Dsconf < Chef::Resource::LWRPBase
  # Chef attributes
  identity_attr :dsconf
  provides :dsconf
  state_attrs :info

  # Set the resource name
  self.resource_name = :dsconf

  # Actionss
  actions :create_suffix, :delete_suffix, :import, :export
  default_action :nothing

  # Distinguished Name of the suffix to create.
  attribute :suffix, kind_of: String, name_attribute: true

  # Reads DSCC administrator's password from FILE (default is prompt for pwd).
  attribute :pwd_file, kind_of: String, default: nil

  # Uses `port` for LDAP traffic (default is 389).
  attribute :port, kind_of: String, default: nil

  # Uses `ssl_port` for secure LDAP traffic (default is 636).
  attribute :ssl_port, kind_of: String, default: nil

  # Uses DN as Directory Manager DN (Default: 'cn=Directory Manager')
  attribute :rootDN, kind_of: String, default: nil

  # A LDIF data file.
  attribute :ldif, kind_of: String, default: nil

  attr_writer :exists

  # @return [TrueClass, FalseClass] true if the resource already exists.
  def exists?
    !!@exists
  end
end
