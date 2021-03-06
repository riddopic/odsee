# encoding: UTF-8
#
# Cookbook Name:: odsee
# Libraries:: cli_helpers
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

module Odsee
  # Instance methods that are added when you include Odsee::CliHelpers
  #
  module CliHelpers
    # Finds a command in $PATH
    #
    # @param [String] cmd
    #
    # @return [String, NilClass]
    #
    # @api public
    def which(cmd)
      if Pathname.new(cmd).absolute?
        ::File.executable?(cmd) ? cmd : nil
      else
        paths  = %w(/bin /usr/bin /sbin /usr/sbin)
        paths << ::File.join(node[:odsee][:install_dir], 'dsee7/bin')
        paths << ::File.join(node[:odsee][:install_dir], 'dsee7/dsrk/bin')
        paths << ENV.fetch('PATH').split(::File::PATH_SEPARATOR)
        paths.flatten.uniq.each do |path|
          possible = ::File.join(path, cmd)
          return possible if ::File.executable?(possible)
        end
        nil
      end
    end

    # Command line executioner for running provider commands
    #
    # @param [String] cmd
    #   With the main command line tool
    # @param [String, Symbol] subcmd
    #   With the subcommand
    # @param [String, Array] args
    #   Any additional arguments and/or operand
    # @return [Hash, self]
    #   `#stdout`, `#stderr`, `#status`, and `#exitstatus` will be populated
    #   with results of the command
    #
    # @raise [Errno::EACCES]
    #   When you are not privileged to execute the command
    # @raise [Errno::ENOENT]
    #   When the command is not available on the system (or in the $PATH)
    # @raise [Chef::Exceptions::CommandTimeout]
    #   When the command does not complete within timeout (default: 60s)
    #
    # @api private
    [:dsadm, :dsccagent, :dsccreg, :dsccsetup, :dsconf].each do |cmd|
      define_method(cmd) do |*args|
        subcmd = Hoodie::Inflections.dasherize(args.shift.to_s)
        (run ||= []) << which(cmd.to_s) << subcmd.to_s << args
        retrier(on: Errno::ENOENT, sleep: ->(n) { 4**n }) do
          Chef::Log.info shell_out!(run.flatten.join(' ')).stdout
        end
      end
    end

    # Boolean, true if the stat is running, false otherwise
    #
    # @return [TrueClass, FalseClass]
    #
    # @api private
    def running?
      info[:state] =~ /^running$/ ? true : false
    end
    alias_method :enabled?, :running?

    # Boolean, true if the instance has been created, false otherwise
    #
    # @return [TrueClass, FalseClass]
    #
    # @api private
    def created?
      info[:instance_path] == dscc_path
    end

    # Boolean to check if the suffix entry has been created LDAP DIT
    #
    # @return [TrueClass, FalseClass]
    #   True if the suffix entry has been created, otherwise false.
    #
    # @api public
    def suffix_created?
      @new_resource.admin_passwd.tmp do |passwd_file|
        info = info("-ic -w #{passwd_file}")
        info.key?(:suffixes) && info[:suffixes] == @new_resource.suffix[1..-2]
      end
    end

    # Boolean to check if the suffix has been populated with entries
    #
    # @return [TrueClass, FalseClass]
    #   True if the suffix has been populated, otherwise false.
    #
    # @api public
    def empty_suffix?
      @new_resource.admin_passwd.tmp do |passwd_file|
        info = info("-ic -w #{passwd_file}")
        info[:total_entries].to_i < 2
      end
    end

    # Boolean to check if the DSCC Registry has been created
    #
    # @return [TrueClass, FalseClass]
    #   True if the DSCC Registry instance has been created, otherwise false.
    #
    # @api public
    def ads_created?
      cmd = "#{__dsccsetup__} status"
      shell_out!(cmd).stdout.include?('DSCC Registry has been created')
    rescue
      false
    end

    # Displays information about server configuration such as port number,
    # suffix name, server mode and task states.
    #
    # @param [String] auth
    #   if a password is required for #info pass in the flag and password file
    #
    # @example info
    #   => { :bit_format       => "64-bit",
    #        :dscc_url         => "-",
    #        :instance_path    => "/opt/dsee7/var/dcc/ads",
    #        :instance_version => "D-A30",
    #        :non_secure_port  => "3998",
    #        :owner            => "root(root)",
    #        :secure_port      => "3997",
    #        :server_pid       => "781",
    #        :state            => "Running" }
    #
    # @return [Hash]
    #
    # @api public
    def info(auth = nil)
      resource = "__#{@current_resource.resource_name}__"
      cmd = "#{send(resource)} info #{info_opts} #{auth} #{dscc_path}"
      info ||= {}
      shell_out!(cmd, returns: [0, 125, 154]).stdout.split("\n").each do |line|
        next unless line.include?(':')
        key, value = line.to_s.split(':')
        info[key.strip.gsub(/(\s|-)/, '_').downcase.to_sym] = value.strip
      end
      info
    end

    # Returns a hash of the DSCC registroy entries for a server or agent
    # instance.
    #
    # @param [String, Symbol] instance
    #   The servers or agents to list entries for.
    #
    # @return [Hash]
    #
    # @api public
    def registry(instance)
      @new_resource.admin_passwd.tmp do |passwd_file|
        cmd = "#{__dsccreg__} list-#{instance} -w #{passwd_file}"
        lines = retrier(on: Errno::ENOENT, sleep: ->(n) { 4**n }) do
          shell_out!(cmd).stdout.split("\n").reverse
        end
        keys = lines.pop.split(' ').map { |line| line.downcase.to_sym }
        lines.delete_if do |line|
          line =~ /^--|(instance|agent)\(s\)\s(found|display)/
        end
        lines.map { |line| zip_hash(keys, line.split(' ')) }[0]
      end
    end

    # Boolean, true if the specified instance type has been added to DSCC
    # registry, otherwise false.
    #
    # @param [Symbol] instance
    #   Instance type to lookup, can be :servers or :agents
    # @param [String] path
    #   Path to the DSCC server instance.
    #
    # @return [TrueClass, FalseClass]
    #
    # @raise [Odsee::Exceptions::InvalidRegistryType]
    #
    # @api public
    def check_for(instance, path)
      if instance.to_sym == :agents || instance.to_sym == :servers
        reg = registry(instance.to_sym)
        reg.nil? ? false : reg[:ipath] == path
      else
        raise InvalidRegistryType, "Unknown instance type `#{instance}`"
      end
    end

    private #   P R O P R I E T À   P R I V A T A   Vietato L'accesso

    # Return the full path to the command
    #
    # @return [String]
    #
    # @api private
    [:__dsadm__, :__dsccagent__, :__dsccreg__, :__dsccsetup__, :__dsconf__
    ].each do |cmd|
      define_method(cmd) do
        which(cmd.to_s.tr!('_', ''))
      end
    end

    # Return a path to an agent or instance regardless of type
    # @return [String]
    # @api private
    def dscc_path
      if @new_resource.instance_variable_defined?(:@path)
        @new_resource.path
      else
        @new_resource.instance_path
      end
    end

    # Add any additional options to the info block, assigned with the IVAR
    # `@info_opts` in the respective providers
    # @return [String]
    # @api private
    def info_opts
      if @new_resource.instance_variable_defined?(:@info_opts)
        @new_resource.info_opts
      end
    end
  end
end
