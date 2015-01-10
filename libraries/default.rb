# encoding: UTF-8
#
# Cookbook Name:: odsee
# Libraries:: default
#
# Author: Stefano Harding <riddopic@gmail.com>
#
# Copyright (C) 2014-2015 Stefano Harding
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

# Include hooks to extend with class and instance methods.
#
module Odsee

  # Include hooks to extend Resource with class and instance methods.
  #
  module Resource

    # @return [String] tmp_file
    # @api private
    def tmp_file
      Tempfile.new(rand(0x100000000).to_s(36)).path
    end

    # Creates a temp file for just the duration of the monitor.
    #
    # @return [Chef::Resource::File]
    #
    # @api private
    def secure_tmp_file
      file ||= Chef::Resource::File.new(tmp_file, run_context)
      file.sensitive true
      file.backup false
      file.mode 00400
      file
    end

    # @return [Chef::Resource::File] __admin_pw__
    # @api private
    def __admin_pw__
      @admin_pw ||= secure_tmp_file
      @admin_pw.content(node[:odsee][:admin_password])
      @admin_pw.run_action(:create)
      @admin_pw.path
    end

    # @return [Chef::Resource::File] __agent_pw__
    # @api private
    def __agent_pw__
      @agent_pw ||= secure_tmp_file
      @agent_pw.content(node[:odsee][:agent_password])
      @agent_pw.run_action(:create)
      @agent_pw.path
    end

    # @return [Chef::Resource::File] __cert_pw__
    # @api private
    def __cert_pw__
      @cert_pw ||= secure_tmp_file
      @cert_pw.content(node[:odsee][:cert_password])
      @cert_pw.run_action(:create)
      @cert_pw.path
    end
  end

  # Include hooks to extend Providers with class and instance methods.
  #
  module Provider
    include Chef::Mixin::ShellOut

    # Provide a common Monitor to all providers for locking.
    #
    # @return [Class<Monitor>]
    #
    # @api private
    def lock
      @@lock ||= Monitor.new
    end

    # Wraps shell_out in a monitor for thread safety.
    # @api private
    __shell_out__ = self.instance_method(:shell_out!)
    define_method(:shell_out!) do |*args, &block|
      lock.synchronize { __shell_out__.bind(self).call(*args) }
    end
  end

  # Extends a descendant with class and instance methods
  #
  # @param [Class] descendant
  #
  # @return [undefined]
  #
  # @api private
  def self.included(descendant)
    super

    if descendant < Chef::Resource
      descendant.class_exec { include Garcon::Resource }
      descendant.class_exec { include Odsee::Resource }

    elsif descendant < Chef::Provider
      descendant.class_exec { include Garcon::Provider }
      descendant.class_exec { include Odsee::Provider }
      descendant.class_exec { include Odsee::CliHelpers }
    end
  end
  private_class_method :included
end
