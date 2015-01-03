# encoding: UTF-8
#
# Author: Stefano Harding <sharding@trace3.com>
# Cookbook Name:: odsee
# Recipe:: default
#

single_include 'garcon::default'

concurrent :threads do
  block do
    %w(gtk2-engines).each { |pkg| package pkg }
    multiarch = %w(gtk2 libgcc glibc)
    archs = %w(x86_64 i686)
    multiarch.each do |pkg|
      archs.each do |arch|
        yum_package pkg do
          arch arch
        end
      end
    end
  end
end

zip_file node[:odsee][:install_dir] do
  checksum node[:odsee][:source][:checksum]
  source node[:odsee][:source][:filename]
  overwrite true
  remove_after true
  not_if {
    ::File.exists?(::File.join(node[:odsee][:install_dir], 'dsee7/bin/dsconf'))
  }
  action :unzip
end

concurrent(:threads) { action :join }
