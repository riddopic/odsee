# encoding: UTF-8
#
# Author: Stefano Harding <sharding@trace3.com>
# Cookbook Name:: odsee
# Libraries:: helpers
#

require 'tmpdir'
require 'openssl'
require 'base64'

begin
  require 'net/ldap'
rescue LoadError
  Chef::Log.debug 'Missing `net/ldap` gem. Gets installed by recipe.'
end

module Odsee
  # A set of helper methods shared by all resources and providers.
  #
  module Helpers
    def self.included(base)
      include(ClassMethods)

      base.send(:include, ClassMethods)
    end
    private_class_method :included

    module ClassMethods
      # Returns a salted PBKDF2 hash of the password.
      def create_hash(password)
        salt = SecureRandom.base64(24)
        pbkdf2 = OpenSSL::PKCS5::pbkdf2_hmac_sha1(password, salt, 1000, 24)
        Base64.encode64(pbkdf2)
      end

      # Creates a temp directory executing the block provided. When done the
      # temp directory and all it's contents are garbage collected.
      #
      # @param block [Block]
      #
      def with_tmp_dir(&block)
        Dir.mktmpdir(SecureRandom.hex(3)) do |tmp_dir|
          Dir.chdir(tmp_dir, &block)
        end
      end

      def ldap_search(base, filter, attrs)
        Net::LDAP.open(host: 'localhost') do |ldap|
          query = {
            base: 'dc=example,dc=com',
            filter: Net::LDAP::Filter.eq('cn', 'Directory Administrators'),
            attrs: ['dn'],
            return_result: false
          }
          results = []
          ldap.search(query) { |entry| results << entry }
          code    = ldap.get_operation_result.code
          message = ldap.get_operation_result.message

          { result: result.length, code: code, message: message }
        end
      end
    end
  end

  unless Chef::Recipe.ancestors.include?(Odsee::Helpers)
    Chef::Recipe.send(:include, Odsee::Helpers)
    Chef::Resource.send(:include, Odsee::Helpers)
    Chef::Provider.send(:include, Odsee::Helpers)
  end
end
