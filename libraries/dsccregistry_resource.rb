# encoding: UTF-8
#
# Author: Stefano Harding <sharding@trace3.com>
# Cookbook Name:: odsee
# Library:: dsccagent_resource
#

require_relative 'helpers'

# A Chef resource for the Oracle Directory Server Enterprise Edition
#
class Chef::Resource::DsccRegistry < Chef::Resource::LWRPBase
  # Chef attributes
  identity_attr :dsccreg
  provides :dsccreg

  # Set the resource name
  self.resource_name = :dsccreg

  # Actionss
  actions :add_agent, :add_server, :list_agents, :list_servers,
          :remove_agent, :remove_server
  default_action :nothing

  # Path to existing DSCC server or agent instance.
  attribute :path, kind_of: String, name_attribute: true

  # Reads DSCC administrator's password from FILE (default is prompt for pwd).
  attribute :pwd_file, kind_of: String, default: nil

  # Uses password from AGENT_PWD_FILE to access agent configuration (default is
  # to prompt for pwd).
  attribute :agent_pwd_file, kind_of: String, default: nil
end
