# encoding: UTF-8
#
# Author: Stefano Harding <sharding@trace3.com>
# Cookbook Name:: odsee
# Library:: dsccsetup
#

require_relative 'helpers'

# A Chef provider for the Oracle Directory Server Enterprise Edition
#
class Chef::Provider::DsccSetup < Chef::Provider::LWRPBase
  class NotImplementedError < StandardError; end

  include Chef::Mixin::ShellOut
  include Odsee::Helpers

  use_inline_resources if defined?(:use_inline_resources)

  # @return [TrueClass, FalseClass] WhyRun is supported by this provider.
  def whyrun_supported?
    true
  end

  # @return [Chef::Provider::DsccSetup] Load and return the current resource
  def load_current_resource
    @current_resource ||= Chef::Resource::DsccSetup.new new_resource.name
    @current_resource.exists = ads_created?
    @current_resource
  end

  action :ads_create do
    unless current_resource.exists?
      converge_by 'Creating the DSCC registry' do
        dsccsetup_cli("ads-create #{pwd_file} #{port} #{secure_port}")
      end
    else
      Chef::Log.info "#{new_resource} already exists - nothing to do"
    end
  end

  action :ads_delete do
    if current_resource.exists?
      converge_by 'Deleting the DSCC Registry' do
        dsccsetup_cli("ads-delete #{pwd_file} #{port} #{secure_port}")
      end
    else
      Chef::Log.info "#{new_resource} does not exists - nothing to do"
    end
  end

  # Register DSCC agent in Cacao.
  action :cacao_reg do
    dsccsetup_cli("cacao-reg #{pwd_file} #{port} #{secure_port}")
  end

  # Unregister DSCC agent from Cacao.
  action :cacao_unreg do
    dsccsetup_cli("cacao-unreg #{pwd_file} #{port} #{secure_port}")
  end

  # Performs actions required after applying a patch.
  action :complete_patch do
    dsccsetup_cli("complete-patch #{pwd_file} #{port} #{secure_port}")
  end

  # Disable Administrative Users feature.
  action :disable_admin_users do
    dsccsetup_cli("disable-admin-users #{pwd_file} #{port} #{secure_port}")
  end

  # Enable Administrative Users feature.
  action :enable_admin_users do
    dsccsetup_cli("enable-admin-users #{pwd_file} #{port} #{secure_port}")
  end

  # Register DS in JESMF.
  action :mfwk_reg do
    dsccsetup_cli("mfwk-reg #{pwd_file} #{port} #{secure_port}")
  end

  # Unregister DS from JESMF.
  action :mfwk_unreg do
    dsccsetup_cli("mfwk-unreg #{pwd_file} #{port} #{secure_port}")
  end

  # Performs actions required before applying patch.
  action :prepare_patch do
    dsccsetup_cli("prepare-patch #{pwd_file} #{port} #{secure_port}")
  end

  # Displays status of DSCC registration and initialization.
  action :status do
    dsccsetup_cli('status')
  end

  # Generate the WAR file for deploying DSCC in an application server.
  action :war_file_create do
    dsccsetup_cli('war-file-create')
  end

  # Delete the WAR file.
  action :war_file_delete do
    dsccsetup_cli('war-file-delete')
  end

  protected #      A T T E N Z I O N E   A R E A   P R O T E T T A

  # @return [TrueClass, FalseClass] if the DSCC Registry has been created.
  def ads_created?
    cmd = "#{dsccsetup} status"
    shell_out!(cmd).stdout.include?('DSCC Registry has been created')
  rescue
    'Unknown'
  end

  def pwd_file
    "-w #{new_resource.pwd_file} " if new_resource.pwd_file
  end

  def port
    "-p #{new_resource.port} " if new_resource.port
  end

  def secure_port
    "-P #{new_resource.secure_port} " if new_resource.secure_port
  end

  def dsccsetup_cli(*args)
    cmd = "#{dsccsetup} #{args.join(' ')}"
    Chef::Log.info shell_out!(cmd).stdout
  end

  def dsccsetup
    ::File.join(node[:odsee][:install_dir], 'dsee7/bin/dsccsetup')
  end
end
