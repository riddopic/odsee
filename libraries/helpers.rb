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

    # @return [String] tmp_file
    # @api private
    def tmp_file
      Tempfile.new(rand(0x100000000).to_s(36)).path
    end

    # Creates a temp file for just the duration of the monitor.
    #
    # @return [Chef::Resource::File]
    # @api private
    def secure_tmp_file
      file ||= Chef::Resource::File.new(tmp_file, run_context)
      file.sensitive true
      file.backup false
      file.mode 00400
      file
    end
  end

  class Ldap
    # Configuration of the directory server is almost entirely via ldap objects.
    # This class enables LDAP connectivity to the directory server via the net-
    # ldap library.
    #
    # To make use of most methods in this library, you will need to pass in a
    # resource object for the connection that has the following methods:
    #
    # host:: the ldap host to connect to.
    # port:: the ldap port to connect to
    # auth:: either a hash with the bind_dn and password to use, or a
    # string that identifies the name of a databag item.
    #               see the documentation in the README.md for details.
    # databag:: the name of the databag in which to lookup the auth
    #
    # The main user of this library is the ldap_entry resource, which has
    # sensible defaults for these three items.
    attr_accessor :ldap

    # Chef libraries are evaluated before the recipe that places the chef_gem
    # that it needs is put into place.
    # This places two constraints on this library:
    #   1) A 'require' must be done in a method
    #   2) This class cannot use 'Subclass < Superclass'
    # As Net::LDAP is a class it cannot be included as a module

    def initialize
      require 'rubygems'
      require 'net-ldap'
      require 'cicphash'
    end

    # This method should not be used directly. It is used to bind to the
    # directory server.
    # The databag is the name of the databag that is used for looking up
    # connection auth.
    # It returns a connected ruby Net::LDAP object
    #
    def bind(host, port, auth, databag)
      auth = auth.is_a?(Hash) ? auth.to_hash : auth.to_s

      unless databag.is_a?(String) || databag.is_a?(Symbol)
        fail "Invalid databag: #{databag}"
      end

      if auth.is_a?(String) && auth.length > 0
        require 'chef/data_bag_item'
        require 'chef/encrypted_data_bag_item'

        secret = Chef::EncryptedDataBagItem.load_secret
        auth = Chef::EncryptedDataBagItem.load(
          databag.to_s, auth, secret
        ).to_hash
      end

      unless auth.is_a?(Hash) && auth.key?('bind_dn') && auth.key?('password')
        fail "Invalid auth: #{auth}"
      end

      @ldap = Net::LDAP.new host: host, port: port, auth: {
        method: :simple, username: auth['bind_dn'], password: auth['password']
      }

      unless @ldap.get_operation_result.message == 'Success'
        fail "Unable to bind: #{@ldap.get_operation_result.message}"
      end
      @ldap
    end

    # This method is used to search the directory server. It accepts the
    # connection resource object described above
    # along with the basedn to be searched. Optionally it also accepts an LDAP
    # filter and scope.
    # The default filter is objectClass=* and the default scope is 'base'
    # It returns a list of entries.
    #
    def search(c, basedn, *constraints)
      bind(c.host, c.port, c.auth, c.databag) unless @ldap
      fail 'Must specify base dn for search' unless basedn
      (filter, scope, attributes) = constraints
      filter = filter.nil? ? Net::LDAP::Filter.eq('objectClass', '*') : filter

      case scope
      when 'base'
        scope = Net::LDAP::SearchScope_BaseObject
      when 'one'
        scope = Net::LDAP::SearchScope_SingleLevel
      else
        scope = Net::LDAP::SearchScope_WholeSubtree
      end

      scope = scope.nil? ? Net::LDAP::SearchScope_BaseObject : scope
      attributes = attributes.nil? ? ['*'] : attributes

      entries = @ldap.search(
        base: basedn, filter: filter, scope: scope, attributes: attribute
      )

      unless @ldap.get_operation_result.message =~ /(Success|No Such Object)/
        fail "Error while searching: #{@ldap.get_operation_result.message}"
      end
      entries
    end

    # This method accepts a connection resource object. It is intended to be
    # used with Odsee::Ldap::LdapEntry objects that will also have a .dn
    # method indicating Distinguished Name to be retrieved. It returns a single
    # entry.
    #
    def get_entry(c, dn)
      bind(c.host, c.port, c.auth, c.databag) unless @ldap
      entry = @ldap.search(
        base:   dn,
        filter: Net::LDAP::Filter.eq('objectClass', '*'),
        scope:  Net::LDAP::SearchScope_BaseObject,
        attributes: ['*']
      )

      unless @ldap.get_operation_result.message =~ /(Success|No Such Object)/
        fail "Error while searching: #{@ldap.get_operation_result.message}"
      end
      entry ? entry.first : entry
    end

    # This method accepts a connection resource object, a distinguished name,
    # and the attributes for the entry to be added.
    #
    def add_entry(c, dn, attrs)
      bind(c.host, c.port, c.auth, c.databag) unless @ldap
      attrs = CICPHash.new.merge(attrs)
      relativedn = dn.split(',').first
      attrs.merge!(Hash[*relativedn.split('=').flatten])
      @ldap.add dn: dn, attributes: attrs
      unless @ldap.get_operation_result.message == 'Success'
        fail "Unable to add record: #{@ldap.get_operation_result.message}"
      end
    end

    # Accepts a connection resource object as the first argument, followed by an
    # Array of ldap operations. It is intended to be used with
    # Odsee::Ldap::LdapEntry objects that will also have a .dn method that
    # returns the DN of the entry to be modified.
    #
    # Each ldap operation in the ldap operations list is an Array object with
    # the following items:
    #   1) LDAP operation (e.g. :add, :delete, :replace)
    #   2) Attribute name (String or Symbol)
    #   3) Attribute Values (String or Symbol, or Array of Strings or Symbols)
    #
    # So an example of an operations list to be passed to this method might look
    # like this:
    # [[:add, 'attr1', 'value1'],
    # [:replace, :attr2, [:attr2a, 'attr2b', :attr2c]],
    # [:delete, 'attr3' ], [:delete, :attr4, 'value4']]
    #
    # Note that none of the values passed can be Integers. They must be STRINGS
    # ONLY! This is a limitation of the ruby net-ldap library.
    #
    def modify_entry(c, dn, ops)
      entry = get_entry(c, dn)
      @ldap.modify dn: dn, operations: ops
      unless @ldap.get_operation_result.message =~
             /(Success|Attribute or Value Exists)/
        fail "Unable to modify record: #{@ldap.get_operation_result.message}"
      end
    end

    # Expects a connection resource object, along with a .dn method that returns
    # the Distinguished Name of the entry to be deleted.
    #
    def delete_entry(c, dn)
      bind(c.host, c.port, c.auth, c.databag) unless @ldap
      @ldap.delete dn: dn
      unless @ldap.get_operation_result.message =~ /(Success|No Such Object)/
        fail "Unable to remove record: #{@ldap.get_operation_result.message}"
      end
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
      def initialize(_path)
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
    Odsee::Ldap.send(:include, Odsee::Helpers)
    Chef::Provider.send(:include, Odsee::Helpers)
  end
end
