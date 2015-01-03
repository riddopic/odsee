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

module Odsee
  # A set of helper methods shared by all resources and providers.
  #
  module Helpers
    # Returns a salted PBKDF2 hash of the password.
    def pwd_hash(password)
      salt = SecureRandom.base64(24)
      pbkdf2 = OpenSSL::PKCS5::pbkdf2_hmac_sha1(password, salt, 1000, 24)
      Base64.encode64(pbkdf2)
    end
  end

  class Exceptions
    class LDIFNotFoundError < StandardError
      def initialize(ldif_file)
        super "Unable to locate the `#{ldif_file}` file specified."
      end
    end
  end

  unless Chef::Recipe.ancestors.include?(Odsee::Helpers)
    Chef::Recipe.send(:include,   Odsee::Helpers)
    Chef::Resource.send(:include, Odsee::Helpers)
    Chef::Provider.send(:include, Odsee::Helpers)
  end
end
