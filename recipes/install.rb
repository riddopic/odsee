# encoding: UTF-8
#
# Author: Stefano Harding <sharding@trace3.com>
# Cookbook Name:: odsee
# Recipe:: default
#

single_include 'garcon::default'

pkgs = Concurrent::Promise.execute do
  %w(gtk2-engines lynx openldap openldap-devel).each { |pkg| package pkg }

  multiarch = %w(gtk2 libgcc glibc)

  archs = node[:platform_version].to_i >= 6 ? %w(x86_64 i686) : %w(x86_64 i386)

  multiarch.each do |pkg|
    archs.each do |arch|
      yum_package pkg do
        arch arch
      end
    end
  end
end

chef_gem('net-ldap') { action :nothing }.run_action(:install)
require 'net/ldap' unless defined?(Net::LDAP)

::Chef::Recipe.send(:include, Odsee::Helpers)

zip_file node[:odsee][:source] do
  destination node[:odsee][:install_dir]
  remove_after true
  not_if {
    ::File.exist?(::File.join(node[:odsee][:install_dir], 'dsee7/bin/ldif'))
  }
  action :unzip
end

timers_for([pkgs])
