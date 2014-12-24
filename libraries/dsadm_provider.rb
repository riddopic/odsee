# encoding: UTF-8
#
# Author: Stefano Harding <sharding@trace3.com>
# Cookbook Name:: odsee
# Library:: dsadm_provider
#

require_relative 'helpers'

# A Chef provider for the Oracle Directory Server Enterprise Edition
#
class Chef::Provider::Dsadm < Chef::Provider::LWRPBase
  class NotImplementedError < StandardError; end

  include Chef::Mixin::ShellOut
  include Odsee::Helpers

  use_inline_resources if defined?(:use_inline_resources)

  # @return [TrueClass, FalseClass] WhyRun is supported by this provider.
  def whyrun_supported?
    true
  end

  # @return [Chef::Provider::Dsadm] Load and return the current resource
  def load_current_resource
    @current_resource ||= Chef::Resource::Dsadm.new new_resource.name
    @current_resource.exists = exists?
    @current_resource.state  = state
    @current_resource
  end

  action :create do
    unless current_resource.exists?
      converge_by 'Creating a Directory Server instance' do
        dsadm_cli("create #{with_args} #{new_resource.path}")
      end
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.info "#{new_resource} already exists - nothing to do"
    end
  end

  action :delete do
    if current_resource.exists?
      converge_by 'Deleting a Directory Server instance' do
        dsadm_cli("delete #{with_args} #{new_resource.path}")
      end
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.info "#{new_resource} does not exists - nothing to do"
    end
  end

  action :start do
    unless running?
      converge_by 'Starting the Directory Server instance' do
        dsadm_cli("start #{new_resource.path}")
      end
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.info "#{new_resource} is running - nothing to do"
    end
  end

  action :stop do
    unless stopped?
      converge_by 'Stopping the Directory Server instance' do
        dsadm_cli("stop #{new_resource.path}")
      end
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.info "#{new_resource} not running - nothing to do"
    end
  end

  protected #      A T T E N Z I O N E   A R E A   P R O T E T T A

  # @return [TrueClass, FalseClass] true if the Directory Server instance has
  # been created.
  def created?
    info.has_key?('Instance Path')
  rescue
    false
  end
  alias_method :exists?, :created?

  # @return [TrueClass, FalseClass] if the Directory Server instance is running.
  def running?
    info['State'] =~ /^Running$/i
  rescue
    false
  end

  # @return [TrueClass, FalseClass] if the Directory Server instance is stopped.
  def stopped?
    info['State'] =~ /^Stopped$/i
  rescue
    false
  end

  # @return [String] `Running`, `Stoppend` or `Unknown` for the state of the
  # Directory Server instance.
  def state
    info['State']
  rescue
    'Unknown'
  end

  # @return [TrueClass, FalseClass] true if the SNMP port is set.
  def snmp?
    info['SNMP port'] =~ /^Disabled$/i ? false : true
  rescue
    'Unknown'
  end

  # @return [Hash] with Directory Server instance status.
  def info
    instance = {}
    cmd = "#{dsadm} info #{new_resource.path}"
    shell_out!(cmd, returns: [0, 154]).stdout.split("\n").each do |line|
      key,value = line.to_s.split(':')
      instance[key.strip] = value.strip
    end
    instance
  end

  def with_args
    args = []
    opts = [:pwd_file, :port, :ssl_port, :user, :group, :rootDN]
    opts.each { |arg| args << eval(arg.to_s) }
    args.join(' ')
  end

  def rootDN
    "-D #{new_resource.rootDN} " if new_resource.rootDN
  end

  def user
    "-u #{new_resource.username} " if new_resource.username
  end

  def group
    "-g #{new_resource.groupname} " if new_resource.groupname
  end

  def pwd_file
    "-w #{new_resource.pwd_file} " if new_resource.pwd_file
  end

  def port
    "-p #{new_resource.port} " if new_resource.port
  end

  def ssl_port
    "-P #{new_resource.ssl_port} " if new_resource.ssl_port
  end

  def dsadm_cli(*args)
    cmd = "#{dsadm} #{args.join(' ')}"
    Chef::Log.info shell_out!(cmd).stdout
  end

  def dsadm
    ::File.join(node[:odsee][:install_dir], 'dsee7/bin/dsadm')
  end
end
