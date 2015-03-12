# encoding: UTF-8
#
# Cookbook Name:: odsee
# Cookbook:: install
#
# Author:    Stefano Harding <riddopic@gmail.com>
# License:   Apache License, Version 2.0
# Copyright: (C) 2014-2015 Stefano Harding
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

single_include 'garcon::default'

concurrent 'ODSEE Prerequisite Packages' do
  block do
    monitor.synchronize do
      %w(gtk2-engines gtk2 libgcc glibc).each do |pkg|
        package pkg
      end

      %w(gtk2-engines.i686 gtk2.i686 libgcc.i686 glibc.i686 libXtst.i686
         libcanberra-gtk2.i686 PackageKit-gtk-module.i686).each do |pkg|
        package pkg
      end
    end
  end
end

with_tmp_dir do |tmp_dir|
  zip_file tmp_dir do
    source       uri_join(node[:odsee][:pkg][:url], node[:odsee][:pkg][:name])
    checksum     node[:odsee][:pkg][:checksum]
    overwrite    true
    remove_after true
    header      'Cookie: oraclelicense=accept-securebackup-cookie'
    not_if   { ::File.directory?(node[:odsee][:registry_path]) }
    not_if   { ::File.directory?(node[:odsee][:agent_path])    }
    notifies    :unzip, 'zip_file[inner_zip]', :immediately
    action      :unzip
  end
  #              Zip within-a-zip file distribution pattern.
  #              Brought to you by Oracle Engineering Special-Ed.
  #
  zip_file :inner_zip do
    source     ::File.join(tmp_dir, 'ODSEE_ZIP_Distribution', 'sun-dsee7.zip')
    path         node[:odsee][:install_dir]
    overwrite    true
    remove_after true
    action      :nothing
  end
end
