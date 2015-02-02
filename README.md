
# Oracle Directory Server Enterprise Edition

## Requirements

Before trying to use the cookbook make sure you have a supported system. If you
are attempting to use the cookbook in a standalone manner to do testing and
development you will need a functioning Chef/Ruby environment, with the
following:

* Chef 11 or higher
* Ruby 1.9 (preferably from the Chef full-stack installer)

#### Chef

Chef Server version 11+ and Chef Client version 11.16.2+ and Ohai 7+ are
required. Clients older that 11.16.2 do not work.

#### Platforms

This cookbook uses Test Kitchen to do cross-platform convergence and post-
convergence tests. The tested platforms are considered supported. This cookbook
may work on other platforms or platform versions with or without modification.

* Red Hat Enterprise Linux (RHEL) Server 6 x86_64 (RedHat, CentOS, Oracle etc.)

#### Cookbooks

The following cookbooks are required as noted (check the metadata.rb file for
the specific version numbers):

* [chef_handler](https://supermarket.getchef.com/cookbooks/chef_handler) -
  Distribute and enable Chef Exception and Report handlers.
* [garcon](comming soon to a supermarket near you) - Provides handy hipster,
  hoodie ninja cool awesome methods and features.
* [ohai](https://supermarket.chef.io/cookbooks/ohai) - Creates a configured
  plugin path for distributing custom Ohai plugins, and reloads them via Ohai
  within the context of a Chef Client run during the compile phase (if needed)
* [sudo](https://supermarket.chef.io/cookbooks/sudo) - The Chef sudo cookbook
  installs the sudo package and configures the /etc/sudoers file. Require for
  local development only.

#### Limitations

### Development Requirements

In order to develop and test this Cookbook, you will need a handful of gems
installed.

* [Chef][]
* [Berkshelf][]
* [Test Kitchen][]
* [ChefSpec][]
* [Foodcritic][]

It is recommended for you to use the Chef Developer Kit (ChefDK). You can get
the [latest release of ChefDK from the downloads page][ChefDK].

On Mac OS X, you can also use [homebrew-cask](http://caskroom.io) to install
ChefDK.

Once you install the package, the `chef-client` suite, `berks`, `kitchen`, and
this application (`chef`) will be symlinked into your system bin directory,
ready to use.

You should then set your Ruby/Chef development environment to use ChefDK. You
can do so by initializing your shell with ChefDK's environment.

    eval "$(chef shell-init SHELL_NAME)"

where `SHELL_NAME` is the name of your shell, (bash or zsh). This modifies your
`PATH` and `GEM_*` environment variables to include ChefDK's paths (run without
the `eval` to see the generated code). Now your default `ruby` and associated
tools will be the ones from ChefDK:

    which ruby
    # => /opt/chefdk/embedded/bin/ruby

You will also need Vagrant 1.6+ installed and a Virtualization provider such as
VirtualBox or VMware.

## Usage

To install the Oracle Directory Server include the install recipe in your run
list:

    include_recipe 'odsee::install'

An example recipe that also configures the Directory Server using the included
providers

    # Sample example.com Directory Server configuration.
    single_include 'odsee::default'

    require 'tempfile'
    require 'securerandom' unless defined?(SecureRandom)

    node.set_unless[:odsee][:dsm_password] = pwd_hash(SecureRandom.hex)[0..12]
    node.set_unless[:odsee][:agent_password] = node[:odsee][:dsm_password]
    node.save unless Chef::Config[:solo]

    tmp_file = Tempfile.new(SecureRandom.hex(3))
    password_file = tmp_file.path

    template password_file do
      source 'password.erb'
      sensitive true
      owner 'root'
      group 'root'
      mode 00400
      action :create
      notifies :create, 'ruby_block[unlink]'
    end

    ruby_block :unlink do
      block { tmp_file.unlink }
      action :nothing
    end

    odsee_dsccsetup :ads_create do
      pwd_file password_file
      action :ads_create
    end

    odsee_dsccagent :create do
      pwd_file password_file
      action :create
    end

    odsee_dsccreg '/opt/dsee7/var/dcc/agent' do
      pwd_file password_file
      agent_pwd_file password_file
      action :add_agent
    end

    odsee_dsccagent :start do
      pwd_file password_file
      action :start
    end

    odsee_dsadm '/opt/dsInst' do
      pwd_file password_file
      action [:create, :start]
    end

    odsee_dsconf 'dc=example,dc=com' do
      pwd_file password_file
      ldif ::File.join(node[:odsee][:install_dir],
      'dsee7/resources/ldif/Example.ldif'
    )
      action [:create_suffix, :import]
    end

    odsee_dsccreg '/opt/dsInst' do
      pwd_file password_file
      agent_pwd_file password_file
      action :add_server
    end


## Attributes

### General attributes:

## Providers

This cookbook includes LWRPs for managing:

  * `Chef::Resource::Dsadm`: A Chef Resource and Provider that manages the
     administration command for Directory Server instances.
  * `Chef::Resource::Dsccagent`: A Chef Resource and Provider that help you
     create, delete, start, and stop DSCC agent instances.
  * `Chef::Resource::Dsccreg`: A Chef Resource and Provider used to register
     server instances with the Directory Service Control Center (DSCC) registry.
  * `Chef::Resource::Dsccsetup`: A Chef Resource and Provider used to deploy
     Directory Service Control Center (DSCC) in an application server, and to
     register local agents of the administration framework.
  * `Chef::Resource::Dsconf`: A Chef Resource and Provider that manages the
     Directory Server configuration. It enables you to modify the configuration
     entries in cn=config.


### dsadm

A Chef Resource and Provider that manages the administration command for Directory Server instances.

#### Overview

The `dsadm` command is the local administration command for Directory Server
instances. The `dsadm` command must be run from the local machine where the
server instance is located. This command must be run by the username that is
the operating system owner of the server instance, or by root.

This cookbook comes with a Chef Resource and Provider that can be used in the
cookbook in-place of shelling out to run the `dsadm` CLI.

You use the `dsadm` resource to manage a Directory Server instance as you
would using the command line or with a shell script although as a native Chef
Resource.     
    
#### Syntax

The syntax for using the `dsadm` resource in a recipe is as follows:

    dsadm 'name' do
      attribute 'value' # see attributes section below
      ...
      action :action # see actions section below
    end

Where:

  * `dsadm` tells the chef-client to use the `Chef::Provider::Dsadm` provider
     during the chef-client run;
  * `name` is the name of the resource block; when the `path` attribute is
     not specified as part of a recipe, `name` is also the path to the DSCC
     server instance;
  * `attribute` is zero (or more) of the attributes that are available for
     this resource;
  * `:action` identifies which steps the chef-client will take to bring the
     node into the desired state.

For example:

    dsadm node[:odsee][instance_path] do
      ldap_port node[:odsee][:ldap_port]
      ldaps_port node[:odsee][:ldaps_port]
      action [:create, :start]
    end

#### Actions:

  * `:create`: Creates a Directory Server instance.
  * `:delete`: Deletes a Directory Server instance.
  * `:start`: Starts a Directory Server instance.
  * `:stop`: Stops a Directory Server instance.
  * `:restart`: Restarts a Directory Server instance.
  * `:backup`: Creates a backup archive of the Directory Server instance.

#### Attribute Parameters:

  * `no_inter`: When true does not prompt for password and/or does not prompt
     for confirmation before performing the operation.
  * `user_name`: The server instance owner user ID. The default is root.
  * `group_name`: The server instance owner group ID. The default is root.
  * `hostname`: The DSCC registry host name. The default is `nil` or blank,
     which causes the local host name be returned by the operating system.
  * `ldap_port`: The port for LDAP traffic. The default is `389` if `dsadm` is
     run by the root user, or `1389` if `dsadm` is run by a non-root user.
  * `ldaps_port`: The secure SSL port for LDAP or LDAPS traffic. The default
     is `636` if `dsadm` is run by the root user, or `1636` if `dsadm` is run
     by a non-root user.
  * `dn`: Defines the Directory Manager. The default is `cn=Directory Manager`.
  * `agent_pwd_file`: Reads the DSCC agent password from `pwd_file`.
  * `instance_path`: Full path to the Directory Server instance.
  * `force`: When used with stop-running-instances, the command forcibly shuts
     down all the running server instances that are created using the same
    `dsadm` installation. When used with stop, the command forcibly shuts down
     the instance even if the instance is not initiated by the current
     installation.
  * `safe_mode`: Starts Directory Server with the configuration used at the
     last successful startup.
  * `schema_push`: Ensures manually modified schema is replicated to
     consumers.
  * `cert_passwd`: Reads certificate database password from `cert_passwd`.

#### Examples

dsadm backup [-f FLAG] ... INSTANCE_PATH ARCHIVE_DIR
Creates a backup archive of the Directory Server instance.

dsadm import [-biK] [-x DN] ... [-f FLAG=VAL] ... [-y [-W CERT_PW_FILE]]
INSTANCE_PATH GZ_LDIF_FILE [GZ_LDIF_FILE...] SUFFIX_DN
Populates an existing suffix with LDIF data from a compressed or
uncompressed LDIF file.

### dsccagent

A Chef Resource and Provider that help you create, delete, start, and stop DSCC agent instances.

#### Overview

The `dsccagent` command is used to create, delete, start, and stop DSCC agent
instances on the local system. You can also use the `dsccagent` command to
display status and DSCC agent information, and to enable and disable SNMP
monitoring.

This cookbook comes with a Chef Resource and Provider that can be used in the
cookbook in-place of shelling out to run the `dsccagent` CLI.

You use the `dsccagent` resource to manage a Directory Server instance as you
would using the command line or with a shell script although as a native Chef
Resource.     

#### Syntax

The syntax for using the `dsccagent` resource in a recipe is as follows:

    dsccagent 'name' do
      attribute 'value' # see attributes section below
      ...
      action :action # see actions section below
    end

Where:

  * `dsccagent` tells the chef-client to use the `Chef::Provider::Dsccagent`
     provider during the chef-client run;
  * `name` is the name of the resource block; when the `path` attribute is
     not specified as part of a recipe, `name` is also the path to the DSCC
     server instance;
  * `attribute` is zero (or more) of the attributes that are available for
     this resource;
  * `:action` identifies which steps the chef-client will take to bring the
     node into the desired state.

For example:

    dsccagent node[:odsee][:agent_path].call do
      action :create
    end

#### Actions:

  * `:create`: Creates a DSCC agent instance.
  * `:delete`: Deletes a DSCC agent instance.
  * `:enable_snmp`: Un-configures the SNMP agent of a DSCC agent instance.
  * `:disable_snmp`: Configures a DSCC agent instance as SNMP agent.
  * `:start`: Start a DSCC agent instance. The DSCC agent will be able to start
    if it was registered in the DSCC registry, or if the SNMP agent is enabled.
  * `:stop`: Stops a DSCC agent instance.

#### Attribute Parameters:

  * `no_inter`: When true does not prompt for password and/or does not prompt
     for confirmation before performing the operation.
  * `agent_port`: Specifies the port for the DSCC agent. The default is 3997.
  * `agent_passwd`: A file containing the DSCC agent password.
  * `agent_path`: Full path to the existing DSCC agent instance. The default
     path is to use: install-path/var/dcc/agentd.
  * `snmp_v3`: Boolean, true if SNMP version 3 should be used, otherwise false.
  * `snmp_port`: The port number to use for SNMP traffic. Default is 3996.
  * `ds_port`: The port number to use for traffic from Directory Servers to
     agent. The default is 3995.
  * `admin_passwd`: A file containing the Direcctory Service Manager password.

#### Examples

### dsccreg

A Chef provider for the Oracle Directory Server dsccreg resource.

#### Overview

The `dsccreg` command is used to register server instances on the local system with the Directory Service Control Center (DSCC) registry.

This cookbook comes with a Chef Resource and Provider that can be used in the
cookbook in-place of shelling out to run the `dsccreg` CLI.

You use the `dsccreg` resource to manage a Directory Server instance as you
would using the command line or with a shell script although as a native Chef
Resource.     

#### Syntax

The syntax for using the `dsccreg` resource in a recipe is as follows:

    dsccreg 'name' do
      attribute 'value' # see attributes section below
      ...
      action :action # see actions section below
    end

Where:

  * `dsccreg` tells the chef-client to use the `Chef::Provider::Dsccreg`
     provider during the chef-client run;
  * `name` is the name of the resource block; when the `path` attribute is
     not specified as part of a recipe, `name` is also the path to the DSCC
     server instance;
  * `attribute` is zero (or more) of the attributes that are available for
     this resource;
  * `:action` identifies which steps the chef-client will take to bring the
     node into the desired state.

For example:

    dsccreg node[:odsee][:agent_path].call do
      action :create
    end
    
#### Actions:

  * `:add-agent`: Add a DSCC agent instance to the DSCC registry.
  * `:add-server`: Add a server instance to the DSCC registry.
  * `:remove-agent`: Remove an agent instance from the DSCC registry.
  * `:remove-server`: Remove a server instance from the DSCC registry.

#### Attribute Parameters:

  * `description`: Used to provide an optional description for the agent
    instance.
  * `hostname`: The DSCC registry host name. By default, the `dsccreg` command
    uses the local host name returned by the operating system.
  * `agent_passwd`: A file containing the DSCC agent password.
  * `agent_path`: Full path to the existing DSCC agent instance. The default
    path is to use: install-path/var/dcc/agent.
  * `force`: If the instance should be forcibly shut down. When used with
    `stop-running-instances`, the command forcibly shuts down all the running
    server instances that are created using the same `dsadm` installation. When
    used with stop, the command forcibly shuts down the instance even if the
    instance is not initiated by the current installation.
  * `dn`: Defines the Directory Manager DN to use. The default Directory Manager
    DN is `cn=Directory Manager`.
  * `admin_passwd`: A file containing the Direcctory Service Manager password.
  * `agent_port`: Specifies port as the DSCC agent port to use for communicating
    with this server instance.

#### Examples

### ${provider_name}
#### Overview
#### Syntax
#### Actions:
#### Attribute Parameters:
#### Examples

### ${provider_name}
#### Overview
#### Syntax
#### Actions:
#### Attribute Parameters:
#### Examples

### ${provider_name}
#### Overview
#### Syntax
#### Actions:
#### Attribute Parameters:
#### Examples

## Testing

Ensure you have all the required prerequisite listed in the Development
Requirements section. You should have a working Vagrant installation with either VirtualBox or VMware installed. From the parent directory of this cookbook begin by running bundler to ensure you have all the required Gems:

    bundle install

A ruby environment with Bundler installed is a prerequisite for using the testing harness shipped with this cookbook. At the time of this writing, it works with Ruby 2.1.2 and Bundler 1.6.2. All programs involved, with the exception of Vagrant and VirtualBox, can be installed by cd'ing into the parent directory of this cookbook and running 'bundle install'.

#### Vagrant and VirtualBox

The installation of Vagrant and VirtualBox is extremely complex and involved. Please be prepared to spend some time at your computer:

If you have not yet installed Homebrew do so now:

    ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"

Next install Homebrew Cask:

    brew tap phinze/homebrew-cask && brew install brew-cask

Then, to get Vagrant installed run this command:

    brew cask install vagrant

Finally install VirtualBox:

    brew cask install virtualbox

You will also need to get the Berkshelf and Omnibus plugins for Vagrant:

    vagrant plugin install vagrant-berkshelf
    vagrant plugin install vagrant-omnibus

Try doing that on Windows.

#### Rakefile

The Rakefile ships with a number of tasks, each of which can be ran individually, or in groups. Typing `rake` by itself will perform style checks with [Rubocop](https://github.com/bbatsov/rubocop) and [Foodcritic](http://www.foodcritic.io), [Chefspec](http://sethvargo.github.io/chefspec/) with rspec, and integration with [Test Kitchen](http://kitchen.ci) using the Vagrant driver by default. Alternatively, integration tests can be ran with Test Kitchen cloud drivers for EC2 are provided.

    $ rake -T
    rake all                       # Run all tasks
    rake chefspec                  # Run RSpec code examples
    rake doc                       # Build documentation
    rake foodcritic                # Lint Chef cookbooks
    rake inch                      # Suggest objects to add documention to
    rake kitchen:all               # Run all test instances
    rake kitchen:default-centos-6  # Run default-centos-6 test instance
    rake readme                    # Generate README.md from _README.md.erb
    rake rubocop                   # Run RuboCop
    rake rubocop:auto_correct      # Auto-correct RuboCop offenses
    rake test                      # Run all tests except `kitchen` / Run
                                   # kitchen integration tests
    rake verify_measurements       # Verify that yardstick coverage is at
                                   # least 100%
    rake yard                      # Generate YARD Documentation
    rake yardstick_measure         # Measure docs in lib/**/*.rb with yardstick

#### Style Testing

Ruby style tests can be performed by Rubocop by issuing either the bundled binary or with the Rake task:

    $ bundle exec rubocop
        or
    $ rake style:ruby

Chef style tests can be performed with Foodcritic by issuing either:

    $ bundle exec foodcritic
        or
    $ rake style:chef

### Testing

This cookbook uses Test Kitchen to verify functionality.

1. Install [ChefDK](http://downloads.getchef.com/chef-dk/)
2. Activate ChefDK's copy of ruby: `eval "$(chef shell-init bash)"`
3. `bundle install`
4. `bundle exec kitchen test kitchen:default-centos-65`

#### Spec Testing

Unit testing is done by running Rspec examples. Rspec will test any libraries, then test recipes using ChefSpec. This works by compiling a recipe (but not converging it), and allowing the user to make assertions about the resource_collection.

#### Integration Testing

Integration testing is performed by Test Kitchen. Test Kitchen will use either the Vagrant driver or EC2 cloud driver to instantiate machines and apply cookbooks. After a successful converge, tests are uploaded and ran out of band of Chef. Tests are be designed to
ensure that a recipe has accomplished its goal.

#### Integration Testing using Vagrant

Integration tests can be performed on a local workstation using Virtualbox or VMWare. Detailed instructions for setting this up can be found at the [Bento](https://github.com/opscode/bento) project web site. Integration tests using Vagrant can be performed with either:

    $ bundle exec kitchen test
        or
    $ rake integration:vagrant

#### Integration Testing using EC2 Cloud provider

Integration tests can be performed on an EC2 providers using Test Kitchen plugins. This cookbook references environmental variables present in the shell that `kitchen test` is ran from. These must contain authentication tokens for driving APIs, as well as the paths to ssh private keys needed for Test Kitchen log into them after they've been created.

Examples of environment variables being set in `~/.bash_profile`:

    # aws
    export AWS_ACCESS_KEY_ID='your_bits_here'
    export AWS_SECRET_ACCESS_KEY='your_bits_here'
    export AWS_KEYPAIR_NAME='your_bits_here'

Integration tests using cloud drivers can be performed with either

    $ bundle exec kitchen test
        or
    $ rake integration:cloud

### Guard

Guard tasks have been separated into the following groups:

- `doc`
- `lint`
- `unit`
- `integration`

By default, Guard will generate documentation, lint, and run unit tests.
The integration group must be selected manually with `guard -g integration`.

## Contributing

Please see the [CONTRIBUTING.md](CONTRIBUTING.md).

## License and Authors

Author:: Stefano Harding <sharding@trace3.com>

Copyright:: 2014-2015, Stefano Harding

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

- - -

[Berkshelf]: http://berkshelf.com "Berkshelf"
[Chef]: https://www.getchef.com "Chef"
[ChefDK]: https://www.getchef.com/downloads/chef-dk "Chef Development Kit"
[Chef Documentation]: http://docs.opscode.com "Chef Documentation"
[ChefSpec]: http://chefspec.org "ChefSpec"
[Foodcritic]: http://foodcritic.io "Foodcritic"
[Learn Chef]: http://learn.getchef.com "Learn Chef"
[Test Kitchen]: http://kitchen.ci "Test Kitchen"
