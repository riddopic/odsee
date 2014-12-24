# encoding: UTF-8
#
# Author: Stefano Harding <sharding@trace3.com>
# Cookbook Name:: odsee
# Library:: dsccagent_resource
#

require_relative 'helpers'

# A Chef resource for the Oracle Directory Server Enterprise Edition
#
class Chef::Resource::DsccAgent < Chef::Resource::LWRPBase
  # Chef attributes
  identity_attr :dsccagent
  provides :dsccagent
  state_attrs :info

  # Set the resource name
  self.resource_name = :dsccagent

  # Actionss
  actions :create, :delete, :disable_snmp, :enable_snmp, :info, :start, :stop
  default_action :nothing

  attribute :name, kind_of: String, name_attribute: true

  # Reads DSCC administrator's password from FILE (default is prompt for pwd).
  attribute :pwd_file, kind_of: String, default: nil

  # Uses PORT for the LDAP port (default is 3997).
  attribute :port, kind_of: String, default: 3997

  attr_writer :exists, :state, :snmp

  # @return [TrueClass, FalseClass] true if the resource already exists.
  def exists?
    !!@exists
  end

  # @return [TrueClass, FalseClass] true if the resource already exists.
  def snmp?
    !!@snmp
  end
end
