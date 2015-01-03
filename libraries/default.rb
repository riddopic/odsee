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

require 'tmpdir'

module Odsee
  module Resource
  end

  module Provider
    # Monitor for thread safety
    # @api private
    def __lock__
      @@lock ||= Monitor.new
    end
  end

  # @param base [Class] to extend with class and instance methods.
  # @return [undefined]
  # @api private
  def self.included(base)
    super
    if base < Chef::Resource
      base.class_exec { include Garcon::Resource }
      base.class_exec { include Odsee::Resource }
    elsif base < Chef::Provider
      base.class_exec { include Chef::Mixin::ShellOut }
      base.class_exec { include Garcon::Provider }
      base.class_exec { include Odsee::Provider }

      [:admin_pwd, :agent_pwd].each do |ivar|
        base.send(:instance_variable_set, "@#{ivar}", false)
      end
    end
  end
  private_class_method :included
end
