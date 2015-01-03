# encoding: UTF-8
#
# Cookbook Name:: odsee
# Libraries:: provider_methods
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

module Odsee::Provider
  class << self
    def included(base)
      base.class_eval do

        # Wraps shell_out in a monitor for thread safety.
        # @api private
        __shell_out__ = self.instance_method(:shell_out!)
        define_method(:shell_out!) do |*args, &block|
          __lock__.synchronize do
            begin
              __pwd_files__(:create)
              __shell_out__.bind(self).call(*args)
            ensure
              __pwd_files__(:delete)
            end
          end
        end

        def __pwd_files__(action = :nothing)
          __pwd_file_for__(new_resource.admin_tmp, :admin_password, action)
          __pwd_file_for__(new_resource.agent_tmp, :agent_password, action)
        end

        def __pwd_file_for__(file, key, action = :nothing)
          f ||= Chef::Resource::File.new(file, run_context)
          f.sensitive true
          f.backup false
          f.mode 00400
          f.content node[:odsee][key.to_sym]
          f.run_action action
        end

        # executioner
        #
        # @param subcmd [String]
        #   With the main command line tool.
        # @param subcmd [String]
        #   With the subcommand.
        # @param *args [String, Array]
        #   With any additional operand.
        #
        # @return [String]
        #   Result (STDOUT) of the execution of the command.
        #
        # @api private
        def run(cmd, subcmd, args, opts = {})
          subcmd = Hoodie::Inflections.dasherize subcmd.to_s
          (run ||= []) << cmd << subcmd.to_s << args << opts.values
          Chef::Log.info shell_out!(run.flatten.join(' ')).stdout
        end

        # @return [Hash] parse comand line output and return key/value pairs.
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
        def to_hash(from)
          instance = {}
          from.stdout.split("\n").each do |line|
            next unless line.include?(':')
            key,value = line.to_s.split(':')
            instance[key.strip] = value.strip
          end
          instance
        end

        # @return [String] do not prompt for confirmation.
        # @api private
        def no_inter
          '-i' if new_resource.no_inter
        end

        # @return [String] the Direcctory Service Manager password file.
        # @api private
        def admin_pwd
          "-w #{new_resource.admin_tmp}"
        end

        # @return [String] the Direcctory Service Agent password file.
        # @api private
        def agent_pwd
          "-G #{new_resource.agent_tmp}"
        end

        # @return [Integer] port for LDAP.
        # @api private
        def port
          "-p #{new_resource.port}" if new_resource.port
        end

        # @return [Integer] port for LDAPS.
        # @api private
        def secure_port
          "-P #{new_resource.secure_port}" if new_resource.secure_port
        end

        # @return [Integer] port for the DSCC Registry.
        # @api private
        def registry_port
          "-p #{new_resource.registry_port}" if new_resource.registry_port
        end

        # @return [Integer] port for the DSCC Agent.
        # @api private
        def agent_port
          "-P #{new_resource.agent_port}" if new_resource.agent_port
        end

        # @return [String] the Directory Manager DN.
        # @api private
        def user_dn
          "-D #{new_resource.user_dn}" if new_resource.user_dn
        end

        # @return [String, Integer] the DSCC registry host name or IP address.
        # @api private
        def hostname
          "-h #{new_resource.hostname}" if new_resource.hostname
        end

        # @return [TrueClass, FalseClass] ask for confirmation before rejecting
        # non-trusted server certificates.
        # @api private
        def reject_cert
          "-j #{new_resource.reject_cert}" if new_resource.reject_cert
        end

        # @return [TrueClass, FalseClass] ask for confirmation before accepting
        # non-trusted server certificates.
        # @api private
        def accept_cert
          "-c #{new_resource.accept_cert}" if new_resource.accept_cert
        end
      end
    end
  end
end
