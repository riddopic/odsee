# encoding: UTF-8
#
# Cookbook Name:: odsee
# Libraries:: helpers
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

require 'openssl'
require 'base64'
require 'securerandom'
require 'monitor'

module Odsee
  # A set of helper methods shared by all resources and providers.
  #
  module Helpers
    # Returns a salted PBKDF2 hash of the password.
    #
    def pwd_hash(password)
      salt = SecureRandom.base64(24)
      pbkdf2 = OpenSSL::PKCS5.pbkdf2_hmac_sha1(password, salt, 1000, 24)
      Base64.encode64(pbkdf2)
    end
  end

  # Generic Namespace for custom error errors and exceptions for the Cookbook
  #
  module Exceptions

    class UnsupportedAction < RuntimeError; end
    class ValidationError < RuntimeError; end
    class InvalidRegistryType < RuntimeError; end
    class InvalidStateType < RuntimeError; end
    class ResourceNotFound < RuntimeError; end

    # A custom exception class for registry methods
    #
    class InvalidPort < ValidationError
      # Construct a new Exception object, passing in any arguments
      #
      # @param [Integer] port
      # @param [Range<Integer>] range
      # @return [Odsee::Exceptions::InvalidPort]
      # @api private
      def initialize(port, range)
        super "`#{port}` is not within the valid range of `#{range}`"
      end
    end

    # A custom exception class for host? methods
    #
    class InvalidHost < ValidationError
      # Construct a new Exception object, passing in any arguments
      #
      # @param [String] host
      # @return [Odsee::Exceptions::InvalidHost]
      # @api private
      def initialize(host)
        super "unable to validate `#{host}` by IP address"
      end
    end

    # A custom exception class for file?? methods
    #
    class FileNotFound < ValidationError
      # Construct a new Exception object, passing in any arguments
      #
      # @param [String] file
      # @return [Odsee::Exceptions::FileNotFound]
      # @api private
      def initialize(path)
        super "No such file found `#{file}`"
      end
    end

    # A custom exception class for path? methods
    #
    class PathNotFound < ValidationError
      # Construct a new Exception object, passing in any arguments
      #
      # @param [String] path
      # @return [Odsee::Exceptions::PathNotFound]
      # @api private
      def initialize(path)
        super "Unable to validate if `#{path}` is a file or directory"
      end
    end
  end

  # Adds the methods in the Odsee::Helpers module.
  #
  unless Chef::Recipe.ancestors.include?(Odsee::Helpers)
    Chef::Recipe.send(:include,   Odsee::Helpers)
    Chef::Resource.send(:include, Odsee::Helpers)
    Chef::Provider.send(:include, Odsee::Helpers)
  end
end
