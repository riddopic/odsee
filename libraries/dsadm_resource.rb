# encoding: UTF-8
#
# Author: Stefano Harding <sharding@trace3.com>
# Cookbook Name:: odsee
# Library:: dsadm_resource
#

require_relative 'helpers'

# A Chef resource for the Oracle Directory Server Enterprise Edition
#
class Chef::Resource::Dsadm < Chef::Resource::LWRPBase
  # Chef attributes
  identity_attr :dsadm
  provides :dsadm
  state_attrs :info

  # Set the resource name
  self.resource_name = :dsadm

  # Actionss
  actions :create, :delete, :start, :stop
  default_action :nothing

  # Path of the Directory Server instance to create
  attribute :path, kind_of: String, name_attribute: true

  # Reads DSCC administrator's password from FILE (default is prompt for pwd).
  attribute :pwd_file, kind_of: String, default: nil

  # Uses `port` for LDAP traffic (default is 389).
  attribute :port, kind_of: String, default: nil

  # Uses `ssl_port` for secure LDAP traffic (default is 636).
  attribute :ssl_port, kind_of: String, default: nil

  # Sets the instance owner user ID (Default: is root)
  attribute :username, kind_of: String, default: nil

  # Sets the instance owner group ID (Default: root)
  attribute :groupname, kind_of: String, default: nil

  # Uses DN as Directory Manager DN (Default: 'cn=Directory Manager')
  attribute :rootDN, kind_of: String, default: nil

  attr_writer :exists, :state

  # @return [TrueClass, FalseClass] true if the resource already exists.
  def exists?
    !!@exists
  end
end
