# encoding: UTF-8
#
# Cookbook Name:: odsee
# Libraries:: default
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

require_relative 'ldap'
require_relative 'secrets'

# Include hooks to extend with class and instance methods.
#
module Odsee
  # Include hooks to extend Resource with class and instance methods.
  #
  module Resource
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
      @lock ||= Monitor.new
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
      descendant.class_exec { include Odsee::SecretsResource }

    elsif descendant < Chef::Provider
      descendant.class_exec { include Garcon::Provider }
      descendant.class_exec { include Odsee::Provider }
      descendant.class_exec { include Odsee::CliHelpers }
    end
  end
  private_class_method :included
end
