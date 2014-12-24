# encoding: UTF-8
#
# Author: Stefano Harding <sharding@trace3.com>
# Cookbook Name:: odsee
# Library:: dsccsetup
#

require_relative 'helpers'

# A Chef resource for the Oracle Directory Server Enterprise Edition
#
class Chef::Resource::DsccSetup < Chef::Resource::LWRPBase
  # Chef attributes
  identity_attr :dsccsetup
  provides :dsccsetup
  state_attrs :status

  # Set the resource name
  self.resource_name = :dsccsetup

  # Actionss
  actions :ads_create, :ads_delete, :cacao_reg, :cacao_unreg, :complete_patch,
          :disable_admin_users, :enable_admin_users, :mfwk_reg, :mfwk_unreg,
          :prepare_patch, :status, :war_file_create, :war_file_delete
  default_action :nothing

  attribute :name, kind_of: String, name_attribute: true

  # Reads DSCC administrator's password from FILE (default is prompt for pwd).
  attribute :pwd_file, kind_of: String, default: nil

  # Uses PORT for the LDAP port (default is 3998).
  attribute :port, kind_of: String, default: 3998

  # Uses PORT for the LDAPS port (default is 3999).
  attribute :secure_port, kind_of: String, default: 3389

  attr_writer :exists

  # @return [Boolean] true if the DSCC Registry has been created.
  def exists?
    !!@exists
  end
end
