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

    # Boolean, true if port number is within range, otherwise raises a
    # Exceptions::InvalidPort.
    #
    # @param [Integer] port
    # @param [Range<Integer>] range
    #
    # @return [Trueclass]
    #
    # @raise [Exceptions::InvalidPort]
    #
    def valid_port?(port, range)
      (range === port) ? true : (fail Exceptions::InvalidPort, port, range)
    end

    # Validate the hostname, returns the IP address if valid, raises
    # Exceptions::InvalidHost if not
    #
    # @param [String] host
    #
    # @return [Integer]
    #
    # @raise [Exceptions::InvalidHost]
    #
    def valid_host?(host)
      IPSocket::getaddress(host)
    rescue
      fail Exceptions::InvalidHost, host
    end

    # Validate that the path specified is a file or directory, will raise
    # Exceptions::InvalidFilePath if not
    #
    # @param [String] path
    #
    # @return [TrueClass]
    #
    # @raise [Exceptions::InvalidFilePath]
    #
    def valid_path?(path)
      unless ::File.exist?(path) || ::File.directory?(path)
        fail Exceptions::InvalidPath, path
      end
    end

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

  # Generic Namespace Exceptions class
  #
  class Exceptions
    # A custom exception class for InvalidPort methods
    #
    class InvalidPort < ArgumentError

      # Construct a new Exception object, passing in any arguments
      # @param [Integer] port
      # @param [Range<Integer>] range
      # @return [Exceptions::InvalidPort]
      # @api private
      def initialize(port, range)
        super "`#{port}` is not within the valid range of `#{range}`"
      end
    end

    # A custom exception class for InvalidPort methods
    #
    class InvalidHost < ArgumentError

      # Construct a new Exception object, passing in any arguments
      # @param [String] host
      # @return [Exceptions::InvalidHost]
      # @api private
      def initialize(host)
        super "unable to validate `#{host}` by IP address"
      end
    end

    # A custom exception class for InvalidPort methods
    #
    class InvalidFilePath < ArgumentError

      # Construct a new Eption object, passing in any arguments
      # @param [String] path
      # @return [Exceptions::InvalidFilePath]
      # @api private
      def initialize(path)
        super "unable to validate if `#{path}` is a file or directory"
      end
    end
  end
end
