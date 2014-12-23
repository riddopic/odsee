# encoding: UTF-8
#
# Author: Stefano Harding <sharding@trace3.com>
# Cookbook Name:: odsee
# Library:: dscc_agent
#

require_relative 'helpers'

# A Chef resource for the Oracle Directory Server Enterprise Edition
#
class Chef::Resource::DsccRegistry < Chef::Resource::LWRPBase
  # Chef attributes
  identity_attr :dscc_registry
  provides :dscc_registry

  # Set the resource name
  self.resource_name = :dscc_registry

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

# A Chef provider for the Oracle Directory Server Enterprise Edition
#
class Chef::Provider::DsccRegistry < Chef::Provider::LWRPBase
  class NotImplementedError < StandardError; end

  include Chef::Mixin::ShellOut
  include Odsee::Helpers

  use_inline_resources if defined?(:use_inline_resources)

  # @return [TrueClass, FalseClass] WhyRun is supported by this provider.
  def whyrun_supported?
    true
  end

  # @return [Chef::Provider::DsccRegistry] Load and return the current resource
  def load_current_resource
    @current_resource ||= Chef::Resource::DsccAgent.new new_resource.name
    @current_resource
  end

  # List server instances added to DSCC registry.
  action :list_servers do
    dsccreg_cli('list-servers')
  end

  action :add_agent do
    unless agent?(new_resource.path)
      converge_by 'Adding a DSCC agent instance to the DSCC registry' do
        dsccreg_cli("add-agent #{pwd_file} #{agent_pwd_file} #{new_resource.path}")
      end
    else
      Chef::Log.info "#{new_resource} already exists - nothing to do"
    end
  end

  action :remove_agent do
    if agent?(new_resource.path)
      converge_by 'Remove DSCC agent instance to the DSCC registry' do
        dsccreg_cli("remove-agent #{pwd_file} #{agent_pwd_file} #{new_resource.path}")
      end
    else
      Chef::Log.info "#{new_resource} does not exists - nothing to do"
    end
  end

  # List agents registered with DSCC registry.
  action :list_agents do
    dsccreg_cli('list-agents')
  end

  action :add_server do
    unless server?(new_resource.path)
      converge_by 'Adding server instance to the DSCC registry' do
        dsccreg_cli("add-server #{pwd_file} #{agent_pwd_file} -i #{new_resource.path}")
      end
    else
      Chef::Log.info "#{new_resource} already exists - nothing to do"
    end
  end

  action :remove_server do
    if server?(new_resource.path)
      converge_by 'Remove server instance instance to the DSCC registry' do
        dsccreg_cli("remove-server #{pwd_file} #{agent_pwd_file} #{new_resource.path}")
      end
    else
      Chef::Log.info "#{new_resource} does not exists - nothing to do"
    end
  end

  protected #      A T T E N Z I O N E   A R E A   P R O T E T T A

  # @return [TrueClass, FalseClass] if agent instance added to DSCC registry.
  def agent?(path)
    !registry('agents').select { |agent| agent[:ipath] == path }.empty?
  end

  # @return [TrueClass, FalseClass] if server instances added to DSCC registry.
  def server?(path)
    !registry('servers').select { |server| server[:ipath] == path }.empty?
  end

  # @param instance [String] servers or agents to list entries for.
  # @return [Array] of registry entries for given instance.
  def registry(instance)
    cmd = "#{dsccreg} list-#{instance} #{pwd_file}"
    registry = []
    lines = shell_out!(cmd).stdout.split("\n").reverse
    keys = lines.pop.split(' ').map { |line| line.downcase.to_sym }
    lines.delete_if { |line| line =~ /^--/ }
    lines.each { |line| registry << zip_hash(keys, line.split(' ')) }
    registry
  end

  # Returns a hash using col1 as keys and col2 as values:
  # @example zip_hash([:name, :age, :sex], ['Earl', 30, 'male'])
  #   => { :age => 30, :name => "Earl", :sex => "male" }
  #
  # @param col1 [Array] keys for hash.
  # @param col2 [Array] values for hash.
  # @return [Hash]
  def zip_hash(col1, col2)
    col1.zip(col2).inject({}) { |r,i| r[i[0]] = i[1]; r }
  end

  def pwd_file
    "-w #{new_resource.pwd_file} " if new_resource.pwd_file
  end

  def agent_pwd_file
    "-G #{new_resource.agent_pwd_file} " if new_resource.agent_pwd_file
  end

  def dsccreg_cli(*args)
    cmd = "#{dsccreg} #{args.join(' ')}"
    Chef::Log.info shell_out!(cmd).stdout
  end

  def dsccreg
    ::File.join(node[:odsee][:install_dir], 'dsee7/bin/dsccreg')
  end
end
