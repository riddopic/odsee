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
  # Creates a transient file with sensitive content, usefule when you have an
  # excecutable that reads a password from a file but you do not wish to leave
  # the password on the filesystem. When used in a block parameter the file is
  # written and deleted when the block returns
  #
  class Secrets

    # @!attribute [ro] path
    #   @return [String] path to the Odsee::Secrets file
    attr_reader :path

    # instantiate a Odsee::Secrets object, you need to call `#write` or use
    # use in a block with `#transient` for it to contain the secret
    #
    # @example
    #   admin = Odsee::Secrets.new(node[:odsee][:adminpasswd], run_context)
    #   # => <Odsee::Secrets:0x314fc3c>
    #          Instance variables:
    #            @run_context = #<Chef::RunContext:0x00000004e36e68>
    #            @secret = lsNKQLbrnKbmQ
    #            @file = file[/tmp/13seori20150131-4204-n6qmgm]
    #            @tmpfile = file[/tmp/13seori20150131-4204-n6qmgm]
    #            @path = /tmp/13seori20150131-4204-n6qmgm
    #            @lock = #<Monitor:0x0000000629e568>
    #
    # @param [String] secret
    #   the secret to write to the file
    # @param [Chef::RunContext] run_context
    #   the run context of chef run
    #
    # @return [Odsee::Secrets]
    #
    # @api public
    def initialize(secret, run_context = nil)
      @run_context = run_context
      @secret  = secret
      @tmpfile = secret_file
      @path = @tmpfile.path
      @lock = Monitor.new
    end

    # @return [String] string of instance
    # @api public
    def to_s
      @path
    end

    # Check if the file exists and contains the secret
    #
    # @example
    #   admin.exist? # => false
    #
    # @return [TrueClass, FalseClass]
    #   true when the file exists and contains the secret, otherwise false
    #
    # @api public
    def exist?
      @lock.synchronize { file_search(@path, @secret) }
    end

    # Creates the secrets file yields to the block, removes the secrets file
    # when the block returns
    #
    # @example
    #   admin.transient { |p| shell_out!("open_sesame --passwd-file #{p}") }
    #   # => Recipe: <Dynamically Defined Resource>
    #        * file[/tmp/13seori20150131-4204-n6qmgm] action create
    #          INFO: Processing file[/tmp/13seori20150131-4204-n6qmgm] action create (dynamically defined)
    #          INFO: file[/tmp/13seori20150131-4204-n6qmgm] created file /tmp/13seori20150131-4204-n6qmgm
    #          - create new file /tmp/13seori20150131-4204-n6qmgm
    #            INFO: file[/tmp/13seori20150131-4204-n6qmgm] updated file contents /tmp/13seori20150131-4204-n6qmgm
    #          - update content in file /tmp/13seori20150131-4204-n6qmgm from none to a88e1f
    #          - suppressed sensitive resource
    #            INFO: file[/tmp/13seori20150131-4204-n6qmgm] mode changed to 400
    #          - change mode from '' to '0400'
    #
    # @yield [Block]
    #   invokes the block
    #
    # @yieldreturn [Object]
    #   the result of evaluating the optional block
    #
    # @api public
    def transient(*args, &block)
      @lock.synchronize do
        unless exist?
          __zero__(@file, @path) if ::File.exist?(@path)
          @tmpfile.content(@secret)
          @tmpfile.run_action(:create)
        end
        yield @path if block_given?
      end
    ensure
      ::File.unlink(@path) if ::File.exist?(@path)
    end

    # Write the secrets file
    #
    # @return [String]
    #   the path to the file
    #
    # @api public
    def write
      @lock.synchronize do
        __zero__(@file, @path) if ::File.exist?(@path)
        @tmpfile.content(@secret)
        @tmpfile.run_action(:create)
        @path
      end
    end

    # Delete the secrets file
    #
    # @return [undefined]
    #
    # @api public
    def del
      @lock.synchronize { __zero__(@file, @path) if ::File.exist?(@path) }
    end

    # Define an inspect method
    #
    # @return [String] object inspection
    #
    # @api private
    def inspect
      instance_variables.inject([
        "\n#<#{self.class}:0x#{self.object_id.to_s(16)}>",
        "\tInstance variables:"
      ]) do |result, item|
        result << "\t\t#{item} = #{instance_variable_get(item)}"
        result
      end.join("\n")
    end

    # Search a text file for a matching string
    #
    # @param [String] file
    #   The file to search for the given string
    # @param [String] content
    #   String to search for in the given file
    #
    # @return [TrueClass, FalseClass]
    #   True if the file is present and a match was found, otherwise returns
    #   false if file does not exist and/or does not contain a match
    #
    # @api private
    def file_search(file, content)
      return false unless ::File.exist?(file)
      ::File.open(file, &:readlines).map! do |line|
        return true if line.match(content)
      end
      false
    end

    private #   P R O P R I E T À   P R I V A T A   Vietato L'accesso

    # @return [String] tmp_file
    # @api private
    def tmp_file
      Tempfile.new(rand(0x100000000).to_s(36)).path.freeze
    end

    # @api private
    def __zero__(what, where)
      ::File.unlink(where)
      what.checksum = nil
    end

    # Creates a temp file for just the duration of the monitor.
    #
    # @return [Chef::Resource::File]
    # @api private
    def secret_file
      @file ||= Chef::Resource::File.new(tmp_file, @run_context)
      @file.sensitive true
      @file.backup false
      @file.mode 00400
      @file
    end
  end
end
