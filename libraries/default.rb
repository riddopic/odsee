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

require_relative 'secrets'

# Include hooks to extend with class and instance methods.
#
module Odsee
  # Include hooks to extend Resource with class and instance methods.
  #
  module Resource
    # Matches on a string.
    STRING_VALID_REGEX = /\A[^\\\/\:\*\?\<\>\|]+\z/

    # Matches on a file mode.
    FILE_MODE_VALID_REGEX = /^0?\d{3,4}$/

    # Matches on a MD5/SHA-1/256 checksum.
    CHECKSUM_VALID_REGEX = /^[0-9a-f]{32}$|^[a-zA-Z0-9]{40,64}$/

    # Matches on a URL/URI with a archive file link.
    URL_ARCH_VALID_REGEX = /^(file|http|https?):\/\/.*(gz|tar.gz|tgz|bin|zip)$/

    # Matches on a FQDN like name (does not validate FQDN).
    FQDN_VALID_REGEX = /^(?:(?:[0-9a-zA-Z_\-]+)\.){2,}(?:[0-9a-zA-Z_\-]+)$/

    # Matches on a valid IPV4 address.
    IPV4_VALID_REGEX = /\b(25[0-5]|2[0-4]\d|1\d\d|
                        [1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}\b/

    # Matches on port ranges 0 to 1023.
    VALID_PORTS_REGEX = /^(102[0-3]|10[0-1]\d|[1-9][0-9]{0,2}|0)$/

    # Matches on any port from 0 to 65_535.
    PORTS_ALL_VALID_REGEX = /^(6553[0-5]|655[0-2]\d|65[0-4]\d\d|6[0-4]\d{3}|
                             [1-5]\d{4}|[1-9]\d{0,3}|0)$/
    class << self
      # Helper method to validate port numbers
      #
      # @yield [Integer]
      # @return [Trueclass]
      # @raise [Odsee::Exceptions::InvalidPort]
      # @api private
      def port?
        ->(port) { validate_port(port) }
      end

      # Boolean, true if port number is within range, otherwise raises a
      # Exceptions::InvalidPort
      #
      # @param [Integer] port
      # @param [Range<Integer>] range
      # @return [Trueclass]
      # @raise [Odsee::Exceptions::InvalidPort]
      # @api private
      def valid_port?(port, range = 0..65_535)
        (range === port) ? true : (fail InvalidPort.new port, range)
      end

      # Helper method to validate host name
      #
      # @yield [Integer]
      # @return [Trueclass]
      # @raise [Odsee::Exceptions::InvalidHost]
      # @api private
      def host?
        ->(_host) { validate_host(name) }
      end

      # Validate the hostname, returns the IP address if valid, otherwise raises
      # Exceptions::InvalidHost
      #
      # @param [String] host
      # @return [Integer]
      # @raise [Odsee::Exceptions::InvalidHost]
      # @api private
      def validate_host(host)
        IPSocket.getaddress(host)
      rescue
        fail InvalidHost.new host
      end

      # Helper method to validate file
      #
      # @yield [Integer]
      # @return [Trueclass]
      # @raise [Odsee::Exceptions::InvalidFile]
      # @api private
      def file?
        ->(file) { validate_file(file) }
      end

      # Boolean, true if file exists, otherwise raises a Exceptions::InvalidFile
      #
      # @param [String] file
      # @return [Trueclass]
      # @raise [Odsee::Exceptions::InvalidFile]
      # @api private
      def valid_file?(file)
        ::File.exist?(file) ? true : (fail FileNotFound.new file)
      end

      # Helper method to validate file path
      #
      # @yield [Integer]
      # @return [Trueclass]
      # @raise [Odsee::Exceptions::InvalidFilePath]
      # @api private
      def path?
        ->(_path) { validate_filepath(file) }
      end

      # Validate that the path specified is a file or directory, will raise
      # Exceptions::InvalidFilePath if not
      #
      # @param [String] path
      # @return [TrueClass]
      # @raise [Odsee::Exceptions::InvalidFilePath]
      # @api private
      def validate_filepath?(path)
        unless ::File.exist?(path) || ::File.directory?(path)
          fail PathNotFound.new path
        end
      end
    end

    # A file containing the Direcctory Service Manager password.
    #
    # @param [String] admin_pw_file
    #   File to use to store the Direcctory Service Manager password.
    #
    # @return [Odsee::Secrets]
    #
    # @api private
    def admin_passwd
      set_or_return :admin_passwd,
      Odsee::Secrets.new(node[:odsee][:admin_password], run_context).freeze
    end

    # A file containing the DSCC agent password.
    #
    # @param [String] agent_pw_file
    #   File to use to store the DSCC agent password.
    #
    # @return [Odsee::Secrets]
    #
    # @api private
    def agent_passwd
      set_or_return :agent_passwd,
      Odsee::Secrets.new(node[:odsee][:agent_password], run_context).freeze
    end

    # A file containing the certificate database password.
    #
    # @param [String] cert_pw_file
    #   File to use to store the certificate database password.
    #
    # @return [Odsee::Secrets]
    #
    # @api private
    def cert_passwd
      set_or_return :cert_passwd,
      Odsee::Secrets.new(node[:odsee][:cert_password], run_context).freeze
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
    __shell_out__ = instance_method(:shell_out!)
    define_method(:shell_out!) do |*args, &_block|
      lock.synchronize { __shell_out__.bind(self).call(*args) }
    end
  end

  # Extends a descendant with class and instance methods
  #
  # @param [Class] descendant
  # @return [undefined]
  # @api private
  def self.included(descendant)
    super

    descendant.class_exec { include Odsee::Helpers }
    descendant.class_exec { include Odsee::Exceptions }

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
