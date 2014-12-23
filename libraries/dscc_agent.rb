# encoding: UTF-8
#
# Author: Stefano Harding <sharding@trace3.com>
# Cookbook Name:: odsee
# Library:: dscc_agent
#

require_relative 'helpers'

# A Chef resource for the Oracle Directory Server Enterprise Edition
#
class Chef::Resource::DsccAgent < Chef::Resource::LWRPBase
  # Chef attributes
  identity_attr :dscc_agent
  provides :dscc_agent
  state_attrs :info

  # Set the resource name
  self.resource_name = :dscc_agent

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

# A Chef provider for the Oracle Directory Server Enterprise Edition
#
class Chef::Provider::DsccAgent < Chef::Provider::LWRPBase
  class NotImplementedError < StandardError; end

  include Chef::Mixin::ShellOut
  include Odsee::Helpers

  use_inline_resources if defined?(:use_inline_resources)

  # @return [TrueClass, FalseClass] WhyRun is supported by this provider.
  def whyrun_supported?
    true
  end

  # @return [Chef::Provider::DsccAgent] Load and return the current resource
  def load_current_resource
    @current_resource ||= Chef::Resource::DsccAgent.new new_resource.name
    @current_resource.exists = exists?
    @current_resource.state  = state
    @current_resource.snmp   = snmp?
    @current_resource
  end

  action :info do
    if current_resource.exists?
      converge_by 'Display DSCC agent instance status and configuration' do
        dsccagent_cli('info')
      end
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.info "#{new_resource} does not exists - nothing to do"
    end
  end

  action :create do
    unless current_resource.exists?
      converge_by 'Creating the DSCC agent instance' do
        dsccagent_cli("create #{pwd_file} #{port}")
      end
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.info "#{new_resource} already exists - nothing to do"
    end
  end

  action :delete do
    if current_resource.exists?
      converge_by 'Deleting the DSCC agent instance' do
        dsccagent_cli("delete #{pwd_file} #{port}")
      end
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.info "#{new_resource} does not exists - nothing to do"
    end
  end

  action :disable_snmp do
    if current_resource.snmp?
      converge_by 'Unconfigure the SNMP agent for DSCC agent instance' do
        dsccagent_cli("disable-snmp #{pwd_file} #{port}")
      end
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.info "#{new_resource} not configured - nothing to do"
    end
  end

  action :enable_snmp do
    unless current_resource.snmp?
      converge_by 'Configure the SNMP agent for DSCC agent instance' do
        dsccagent_cli("enable-snmp #{pwd_file} #{port}")
      end
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.info "#{new_resource} already configured - nothing to do"
    end
  end

  action :start do
    unless running?
      converge_by 'Starting the DSCC agent instance' do
        dsccagent_cli('start')
      end
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.info "#{new_resource} is running - nothing to do"
    end
  end

  action :stop do
    unless stopped?
      converge_by 'Stopping the DSCC agent instance' do
        dsccagent_cli('stop')
      end
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.info "#{new_resource} not running - nothing to do"
    end
  end

  protected #      A T T E N Z I O N E   A R E A   P R O T E T T A

  # @return [TrueClass, FalseClass] if the DSCC Agent instance has been created.
  def created?
    agent.has_key?('Instance Path')
  rescue
    false
  end
  alias_method :exists?, :created?

  # @return [TrueClass, FalseClass] if the DSCC Agent instance is running.
  def running?
    agent['State'] =~ /^Running$/i
  rescue
    false
  end

  # @return [TrueClass, FalseClass] if the DSCC Agent instance is stopped.
  def stopped?
    agent['State'] =~ /^Stopped$/i
  rescue
    false
  end

  # @return [String] `Running`, `Stoppend` or `Unknown` for the DSCC Agent.
  def state
    agent['State']
  rescue
    'Unknown'
  end

  # @return [TrueClass, FalseClass] true if the SNMP port is set.
  def snmp?
    agent['SNMP port'] =~ /^Disabled$/i ? false : true
  rescue
    'Unknown'
  end

  # @return [Hash] with state of the running DSCC Agent.
  # => {
  #          "DSCC hostname" => "4e18e18e2d14",
  #   "DSCC non-secure port" => "3998",
  #       "DSCC secure port" => "3389",
  #          "Instance Path" => "/opt/dsee7/var/dcc/agent",
  #       "Instance version" => "A-A00",
  #               "JMX port" => "3997",
  #                  "Owner" => "root",
  #                    "PID" => "751",
  #              "SNMP port" => "Disabled",
  #                  "State" => "Running"
  # }
  def agent
    agent = {}
    cmd = "#{dsccagent} info"
    shell_out!(cmd, returns: [0, 125]).stdout.split("\n").each do |line|
      key,value = line.to_s.split(':')
      agent[key.strip] = value.strip
    end
    agent
  end

  def pwd_file
    "-w #{new_resource.pwd_file} " if new_resource.pwd_file
  end

  def port
    "-p #{new_resource.port} " if new_resource.port
  end

  def dsccagent_cli(*args)
    cmd = "#{dsccagent} #{args.join(' ')}"
    Chef::Log.info shell_out!(cmd).stdout
  end

  def dsccagent
    ::File.join(node[:odsee][:install_dir], 'dsee7/bin/dsccagent')
  end
end
