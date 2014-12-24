# encoding: UTF-8
#
# Author: Stefano Harding <sharding@trace3.com>
# Cookbook Name:: odsee
# Library:: dsconf_provider
#

require_relative 'helpers'

# A Chef provider for the Oracle Directory Server Enterprise Edition
#
class Chef::Provider::Dsconf < Chef::Provider::LWRPBase
  class NotImplementedError < StandardError; end
  class LDIFNotFoundError < StandardError; end

  include Chef::Mixin::ShellOut
  include Odsee::Helpers

  use_inline_resources if defined?(:use_inline_resources)

  # @return [TrueClass, FalseClass] WhyRun is supported by this provider.
  def whyrun_supported?
    true
  end

  # @return [Chef::Provider::Dsconf] Load and return the current resource
  def load_current_resource
    @current_resource ||= Chef::Resource::Dsconf.new new_resource.name
    @current_resource.exists = exists?
    @current_resource
  end

  action :create_suffix do
    unless current_resource.exists?
      converge_by 'Creating an empty suffix' do
        dsconf_cli("create-suffix #{with_args} -e #{new_resource.suffix}")
      end
    else
      Chef::Log.info "#{new_resource} already exists - nothing to do"
    end
  end

  action :delete_suffix do
    if current_resource.exists?
      converge_by 'Deletes suffix configuration and data' do
        dsconf_cli("delete-suffix #{with_args} -e #{new_resource.suffix}")
      end
    else
      Chef::Log.info "#{new_resource} does not exists - nothing to do"
    end
  end

  action :import do
    if empty_suffix?
      fail FileNotFound,
        'Unable to locate LDIF file' unless ::File.exist?(new_resource.ldif)
      converge_by 'Populating suffix with LDIF data' do
        dsconf_cli("import #{with_args} -aei #{new_resource.ldif} #{new_resource.suffix}")
      end
    else
      Chef::Log.info "#{new_resource} already exists - nothing to do"
    end
  end

  protected #      A T T E N Z I O N E   A R E A   P R O T E T T A

  # @return [TrueClass, FalseClass] true if the Directory Server instance has
  # been created.
  def created?
    info.has_key?('Suffixes') && info['Suffixes'] == new_resource.suffix
  rescue
    false
  end
  alias_method :exists?, :created?

  # @return [TrueClass, FalseClass] true if more than 1 entry exists in the
  # directory Server.
  def empty_suffix?
    info['Total entries'].to_i < 2
  end

  # @return [Hash] with Directory Server instance status.
  # => {
  #      "Instance path" => "/opt/dsInst",
  #       "Global State" => "read-write",
  #          "Host Name" => "0edf0419bcea",
  #               "Port" => "389",
  #        "Secure port" => "636",
  #      "Total entries" => "1",
  #     "Server version" => "11.1.1.7.0",
  #           "Suffixes" => "dc=example,dc=com"
  # }
  def info
    instance = {}
    cmd = "#{dsconf} info -e #{pwd_file}"
    shell_out!(cmd).stdout.split("\n").each do |line|
      next unless line.include?(':')
      key,value = line.to_s.split(':')
      instance[key.strip] = value.strip
    end
    instance
  end

  def with_args
    args = []
    opts = [:rootDN, :pwd_file, :port, :ssl_port]
    opts.each { |arg| args << eval(arg.to_s) }
    args.join(' ')
  end

  def rootDN
    "-D #{new_resource.rootDN} " if new_resource.rootDN
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

  def dsconf_cli(*args)
    cmd = "#{dsconf} #{args.join(' ')}"
    Chef::Log.info shell_out!(cmd).stdout
  end

  def dsconf
    ::File.join(node[:odsee][:install_dir], 'dsee7/bin/dsconf')
  end
end
