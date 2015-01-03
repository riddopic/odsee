# encoding: UTF-8
#
# Cookbook Name:: odsee
# Libraries:: resource_methods
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

module Odsee::Resource
  class << self
    def included(base)
      base.class_eval do

        attribute :admin_tmp, kind_of: String,
                  default: Tempfile.new(rand(0x100000000).to_s(36)).path

        attribute :agent_tmp, kind_of: String,
                  default: Tempfile.new(rand(0x100000000).to_s(36)).path

        # @return [String] do not prompt for confirmation.
        # @api private
        attribute :no_inter, kind_of: [TrueClass, FalseClass],
                  default: lazy { node[:odsee][:no_inter] }

        # @return [Integer] port for LDAP.
        # @api private
        attribute :port, kind_of: Integer,
                  default: lazy { node[:odsee][:port] }

        # @return [Integer] port for LDAPS.
        # @api private
        attribute :secure_port, kind_of: Integer,
                  default: lazy { node[:odsee][:secure_port] }

        # @return [Integer] port for the DSCC Registry.
        # @api private
        attribute :registry_port, kind_of: Integer,
                  default: lazy { node[:odsee][:registry_port] }

        # @return [Integer] port for the DSCC Agent.
        # @api private
        attribute :agent_port, kind_of: Integer,
                  default: lazy { node[:odsee][:agent_port] }

        # @return [String] the Directory Manager DN.
        # @api private
        attribute :user_dn, kind_of: String,
                  default: lazy { node[:odsee][:dn] }

        # @return [String, Integer] the DSCC registry host name or IP address.
        # @api private
        attribute :hostname, kind_of: [Integer, String],
                  default: lazy { node[:odsee][:hostname] }

        # @return [TrueClass, FalseClass] ask for confirmation before rejecting
        # non-trusted server certificates.
        # @api private
        attribute :reject_cert, kind_of: [TrueClass, FalseClass],
                  default: lazy { node[:odsee][:reject_cert] }

        # @return [TrueClass, FalseClass] ask for confirmation before accepting
        # non-trusted server certificates.
        # @api private
        attribute :accept_cert, kind_of: [TrueClass, FalseClass],
                  default: lazy { node[:odsee][:accept_cert] }
      end
    end
  end
end
