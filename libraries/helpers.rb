# encoding: UTF-8
#
# Cookbook Name:: odsee
# Libraries:: helpers
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

  class LDAP

    # @!attribute [rw] ldap
    #   @return [Odsee::LDAP] authenticated Odsee::LDAP connection object
    attr_accessor :ldap

    # @!attribute [ro] base
    #   @return [String] the value of the attribute base
    attr_reader :base

    # @!attribute [ro] host
    #   @return [String] the value of the attribute host
    attr_reader :host

    # @!attribute [ro] port
    #   @return [Integer] the value of the attribute port
    attr_reader :port

    # Instantiate an object of type Odsee::LDAP to perform directory operations.
    # This constructor takes a Hash containing arguments, all of which are
    # either optional or may be specified later with other methods as described
    # below. The following arguments are supported:
    #
    # @example ldap = Odsee::LDAP.new auth: {
    #   method: :simple, username: 'ldapuser', password: 'secret'
    # }
    #
    # @param opts [Hash{Symbol => Value}]
    # @option opts [String] :host
    #   the ldap host to connect to, default is `localhost`
    # @option opts [Integer] :porbt
    #   the ldap port to connect to, default is `389`
    # @option opts [Hash] :auth
    #   hash containing authorization parameters, supported values include
    #   `:anonymous` and `:simple`, defautl is `:anonymous`, the password may be
    #   a Proc that returns a string
    # @option opts [String] :base
    #   default treebase parameter for searches performed against the server
    #
    # @return [Odsee::LDAP]
    #   authenticated Odsee::LDAP connection object
    #
    # @api public
    def initialize(options = {})
      @host = options.fetch(:host, 'localhost')
      @port = options.fetch(:port, 389)
      @auth = options.fetch(:auth, method: :anonymous)
      @base = options.fetch(:base, nil)

      @ldap ||= bind(@host, @port, @auth)
    end

    # Bind to the LDAP directory server and returns a Odsee::LDAP connection
    # object using the supplied authentication credentials
    #
    # @param [String] host
    #   the ldap host to connect to, default is `localhost`
    # @param [Integer] port
    #   the ldap port to connect to, default is `389`
    # @param [Hash] auth
    #   hash containing authorization parameters, supported values include
    #  `:anonymous` and `:simple`, defautl is `:anonymous`
    #
    # @return [Odsee::LDAP]
    #   authenticated Odsee::LDAP connection object
    #
    # @raise [Odsee::Exceptions::LDAPBindError]
    #
    # @api public
    def bind(host, port, auth)
      ldap = Net::LDAP.new(host: host, port: port, auth: auth)
      unless ldap.get_operation_result.message =~ /Success/i
        fail LDAPBindError.new ldap.get_operation_result.message
      end
      ldap
    end

    # Searches the LDAP directory for directory entries. `#search` against the
    # directory, involves specifying a treebase, a set of search filters, and a
    # list of attribute values. The filters specify ranges of possible values
    # for particular attributes. Multiple filters can be joined together with
    # AND, OR, and NOT operators. A server will respond to a `#search` by
    # returning a list of matching DNs together with a set of attribute values
    # for each entity, depending on what attributes the search requested
    #
    # @param [String] dn
    #   specifying the tree-base for the search
    # @param [String, Array] attributes
    #   a string or array specifying the LDAP attributes to return
    #
    # @return [Array<Odsee::LDAP::Entry>]
    #   a result set or nil if the requested `#search` fails with an error
    #
    # @api public
    def search(dn = @base, *attributes)
      (filter, scope, attrs) = attributes
      filter = filter.nil? ? Net::LDAP::Filter.eq('objectClass', '*') : filter

      scope = case
      when scope == 'base'
        Net::LDAP::SearchScope_BaseObject
      when scope == 'one'
        Net::LDAP::SearchScope_SingleLevel
      else
        Net::LDAP::SearchScope_WholeSubtree
      end

      scope = scope.nil? ? Net::LDAP::SearchScope_BaseObject : scope
      attrs = attrs.nil? ? ['*'] : attrs
      @ldap.search(base: dn, filter: filter, scope: scope, attributes: attrs)
    end

    # This method accepts a connection resource object. It is intended to be
    # used with Odsee::Ldap::LdapEntry objects that will also have a .dn
    # method indicating Distinguished Name to be retrieved. It returns a single
    # entry
    #
    # @param [String] dn
    #   specifying the tree-base for the search
    #
    # @return [Array<Odsee::LDAP::Entry>]
    #   a single result or nil if the requested `#search` fails with an error
    #
    # @api public
    def entry(dn = @base)
      entry = @ldap.search(
        base:   dn,
        filter: Net::LDAP::Filter.eq('objectClass', '*'),
        scope:  Net::LDAP::SearchScope_BaseObject,
        attributes: ['*']
      )
      entry ? entry.first : entry
    end

    # `#add` specifies a new dn and an initial set of attribute values. If the
    # operation succeeds, a new entity with the corresponding dn and attributes
    # is added to the directory
    #
    # @param [String] dn
    #   the full dn of the new entry
    # @param [Hash] attributes
    #   a hash of attributes of the new entry
    #
    # @return [undefined]
    #
    # @api public
    def add(dn = @base, attributes)
      relativedn = dn.split(',').first
      attributes.merge!(Hash[*relativedn.split('=').flatten])
      @ldap.add dn: dn, attributes: attributes
    end

    # `#modify` is used to change the attribute values stored in the directory
    # for a particular entity. `#modify` may add or delete attributes (which
    # are lists of values) or it change attributes by adding to or deleting
    # from their values
    #
    # @param [String] dn
    #   the full DN of the entry whose attributes are to be modified
    # @param [Array] operations
    #   each of the operations appearing in the Array must itself be an Array
    #   with exactly three elements; operator (must be `:add`, `:replace`, or
    #   `:delete`), attribute name (string or symbol) to modify, value:
    #   (string, symbol or an array of strings or symbols)
    #
    # @return [TrueClass, FalseClass]
    #   indicating whether the operation succeeded or failed
    #
    # @api public
    def modify(dn = @base, operations)
      @ldap.modify dn: dn, operations: operations
    end

    # `#delete` specifies an entity db, if it succeeds, the entity and all its
    # attributes are removed from the directory
    #
    # @param [String] dn
    #   the full DN of the entry to be deleted
    #
    # @return [TrueClass, FalseClass]
    #   indicating whether the operation succeeded or failed
    #
    # @api public
    def delete(dn = @base)
      @ldap.delete dn: dn
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
    class AuthenticationError < RuntimeError; end
    class LDAPBindError < RuntimeError; end

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
      def initialize(file)
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
