# encoding: UTF-8
#
# Cookbook Name:: odsee
# Libraries:: cli_helpers
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

module Odsee

  # Instance methods that are added when you include Odsee::CliHelpers.
  #
  module CliHelpers

    # Search a text file for a matching string.
    #
    # @param [String] file
    #   The file to search for the given string.
    #
    # @param [String] content
    #   String to search for in the given file.
    #
    # @return [TrueClass, FalseClass]
    #   True if match was found, false if file does not exist or does not
    #   contain a match.
    #
    def file_search(file, content)
      return false unless ::File.exist?(file)
      ::File.open(file, &:readlines).map! do |line|
        return true if line.match(content)
      end
      false
    end

    # Finds a command in $PATH.
    #
    # @param [String] cmd
    #
    # @return [String, NilClass]
    #
    def which(cmd)
      if Pathname.new(cmd).absolute?
        File.executable?(cmd) ? cmd : nil
      else
        paths = %w(/bin /usr/bin /sbin /usr/sbin)
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

    # Return the full path to the command.
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

    # Command line executioner for running provider commands. This is where all
    # the magic happens. ;-)
    #
    # @param [String] cmd
    #   With the main command line tool.
    #
    # @param [String, Symbol] subcmd
    #   With the subcommand.
    #
    # @param [String, Array] args
    #   Any additional arguments and/or operand.
    #
    # @return [Hash, self]
    #   `#stdout`, `#stderr`, `#status`, and `#exitstatus` will be populated
    #   with results of the command.
    #
    # @raise [Errno::EACCES]
    #   When you are not privileged to execute the command.
    #
    # @raise [Errno::ENOENT]
    #   When the command is not available on the system (or in the $PATH).
    #
    # @raise [Chef::Exceptions::CommandTimeout]
    #   When the command does not complete within timeout (default: 60s).
    #
    # @api private
    [:dsadm, :dsccagent, :dsccreg, :dsccsetup, :dsconf].each do |cmd|
      define_method(cmd) do |*args|
        subcmd = Hoodie::Inflections.dasherize(args.shift.to_s)
        (run ||= []) << which(cmd.to_s) << subcmd.to_s << args
        announce "Execute on node:::--> #{run}"
        Chef::Log.info shell_out!(run.flatten.join(' ')).stdout
      end
    end

    # Displays information about server configuration such as port number,
    # suffix name, server mode and task states.
    #
    # @example info
    #   => { "Instance Path"    => "/opt/dsee7/var/dcc/ads",
    #        "Owner"            => "root(root)",
    #        "Non-secure port"  => "3998",
    #        "Secure port"      => "3997",
    #        "Bit format"       => "64-bit",
    #        "State"            => "Running",
    #        "Server PID"       => "781",
    #        "DSCC url"         => "-",
    #        "Instance version" => "D-A30"}
    #
    # @return [Hash]
    #
    def info
      resource = "__#{@current_resource.resource_name.to_s}__"
      cmd = "#{self.send(resource)} info"
      instance = {}
      shell_out!(cmd, returns: [0, 125, 154]).stdout.split("\n").each do |line|
        next unless line.include?(":")
        key,value = line.to_s.split(':')
        instance[key.strip] = value.strip
      end
      instance
    end

    # Returns a hash of the DSCC registroy entries for a server or agent
    # instance.
    #
    # @param [String, Symbol] instance
    #   The servers or agents to list entries for.
    #
    # @param [String] admin_pwd
    #   Reads the DSCC agent password from `admin_pwd`.
    #
    # @return [Array]
    #
    def registry(instance, admin_pwd)
      cmd = "#{__dsccreg__} list-#{instance} #{admin_pwd}"
      registry = []
      lines = shell_out!(cmd).stdout.split("\n").reverse
      keys = lines.pop.split(' ').map { |line| line.downcase.to_sym }
      lines.delete_if { |line| line =~ /^--/ }
      lines.each { |line| registry << zip_hash(keys, line.split(' ')) }
      registry
    end

    # Boolean, true if the specified agent instance has been added to DSCC
    # registry, otherwise false.
    #
    # @param [String] path
    #   Path to the DSCC agent instance.
    #
    # @return [TrueClass, FalseClass]
    #
    def agent?(path)
      !registry('agents').select { |agent| agent[:ipath] == path }.empty?
    end

    # Boolean, true if the specified server instance has been added to DSCC
    # registry, otherwise false.
    #
    # @param [String] path
    #   Path to the DSCC server instance.
    #
    # @return [TrueClass, FalseClass]
    #
    def server?(path)
      !registry('servers').select { |server| server[:ipath] == path }.empty?
    end

    # Returns a hash using col1 as keys and col2 as values.
    #
    # @example zip_hash([:name, :age, :sex], ['Earl', 30, 'male'])
    #   => { :age => 30, :name => "Earl", :sex => "male" }
    #
    # @param [Array] col1
    #   Containing the keys.
    #
    # @param [Array] col2
    #   Values for hash.
    #
    # @return [Hash]
    #
    def zip_hash(col1, col2)
      col1.zip(col2).inject({}) { |r,i| r[i[0]] = i[1]; r }
    end

    # Boolean to check if the suffix entry has been created LDAP DIT.
    #
    # @return [TrueClass, FalseClass]
    #   True if the suffix entry has been created, otherwise false.
    #
    def suffix_created?
      @info.has_key?('Suffixes') && @info['Suffixes'] == new_resource.suffix
    rescue
      false
    end

    # Boolean to check if the suffix has been populated with entries.
    #
    # @return [TrueClass, FalseClass]
    #   True if the suffix has been populated, otherwise false.
    #
    def empty_suffix?
      @info['Total entries'].to_i < 2
    end

    # Boolean to check if the DSCC Registry has been created.
    #
    # @return [TrueClass, FalseClass]
    #   True if the DSCC Registry instance has been created, otherwise false.
    #
    def ads_created?
      cmd = "#{__dsccsetup__} status"
      shell_out!(cmd).stdout.include?('DSCC Registry has been created')
    rescue
      false
    end

    # Boolean to check if instance has been created.
    #
    # @param [String] instance
    #   Full path to the Directory Server instance.
    #
    # @return [TrueClass, FalseClass]
    #   True if the instance has been created, otherwise false.
    #
    def created?(instance = 'Instance Path')
      @info.has_key?('Instance Path')
    rescue
      false
    end
    alias_method :exists?, :created?

    # Boolean to check if the SNMP port is set.
    #
    # @return [TrueClass, FalseClass]
    #   True if the SNMP port has been set, otherwise false.
    #
    def snmp?
      @info['SNMP port'] =~ /^Disabled$/i ? false : true
    rescue
      'Unknown'
    end

    # Boolean to check if current instance is in the running state.
    #
    # @return [TrueClass, FalseClass]
    #   True if the current instance is in the running state, otherwise false.
    #
    def running?
      @info['State'] =~ /^Running$/i
    rescue
      false
    end

    # Boolean to check if current instance is in the stopped state.
    #
    # @return [TrueClass, FalseClass]
    #   True if the current instance is in the stopped state, otherwise false.
    #
    def stopped?
      @info['State'] =~ /^Stopped$/i
    rescue
      false
    end

    # Return the current instance state.
    #
    # @return [String]
    #   Running, Stoppend or Unknown.
    #
    def state
      @info['State']
    rescue
      'Unknown'
    end
  end
end
