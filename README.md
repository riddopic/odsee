
# Oracle Directory Server Enterprise Edition

## Requirements

Before trying to use the cookbook make sure you have a supported system. If you
are attempting to use the cookbook in a standalone manner to do testing and
development you will need a functioning Chef/Ruby environment, with the
following:

* Chef 11 or higher
* Ruby 1.9 (preferably from the Chef full-stack installer)

#### Chef

Chef Server version 11+ and Chef Client version 11.18+ and Ohai 7+ are
required. Clients older that 11.16 do not work.

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

The cookbook currently does not implement replication or LDAP directory backups.
Time permitting these features can be added or specifically requested.

The Directory Server Manager Web Console is not installed as part of this
cookbook nor should it be required. The resource/providers should expose the functionality with the advantage that changes using Chef and the providers are
self documenting and permanent once committed to the repository.

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

    #       T H I S   I S   A   E X A M P L E   R E C I P E   F O R
    #       D E M O N S T R A T I O N   P U R P O S E S   O N L Y !

    single_include 'odsee::default'

    # Generate passwords if none are provided, passwords are saved in the node
    # attributes, at the moment unencrypted although encrypting them does not
    # provide any level of protection because the machine must always be able
    # to decrypt the keys when required.
    #
    # There are different passwords for various components, they could all be
    # set the same for simplicity or each can be different.
    #
    require 'securerandom' unless defined?(SecureRandom)
    monitor.synchronize do
      node.set_unless[:odsee][:admin_passwd] = pwd_hash(SecureRandom.hex)[0..12]
      node.set_unless[:odsee][:agent_passwd] = pwd_hash(SecureRandom.hex)[0..12]
      node.set_unless[:odsee][:cert_passwd]  = pwd_hash(SecureRandom.hex)[0..12]
      node.save unless Chef::Config[:solo]
    end

    # This is an example of how you can use the providers in this cookbook to
    # create a LDAP directory tree. We create the dc=example,dc=com suffix and
    # use the supplied Example.ldif file to populate the directory.

    base_ldif = ::File.join(
      node[:odsee][:install_dir], 'dsee7/resources/ldif/Example.ldif'
    )

    dsccsetup :ads_create do
      action :ads_create
    end

    dsccagent node[:odsee][:agent_path] do
      action :create
    end

    dsccreg node[:odsee][:agent_path] do
      action :add_agent
    end

    dsccagent node[:odsee][:agent_path] do
      action :start
    end

    dsadm node[:odsee][:instance_path] do
      action [:create, :start]
    end

    dsconf node[:odsee][:suffix] do
      path node[:odsee][:instance_path]
      ldif_file base_ldif
      action [:create_suffix, :import]
    end

    dsccreg node[:odsee][:instance_path] do
      action :add_server
    end

## Attributes

Attributes are under the `odsee` namespace, the following attributes affect
the behavior of how the cookbook performs an installation, or are used in the
recipes for various settings that require flexibility. Attributes have default
values set, where possible or appropriate, the default values from Oracle have
been used.

### General attributes:

General attributes can be found in the `default.rb` file.

* `node[:odsee][:source][:filename]`: [String] The location to the install zip
  file containing the Oracle Directory Server, can be any valid file path or
  URL. Default value is `needs to be determined`.

* `node[:odsee][:source][:checksum]`: [String] The SHA-1 checksum of the zip
  file.

* `node[:odsee][:install_dir]`: [String] Path under which Directory Server is
  installed. Default value is `/opt`.

* `node[:odsee][:admin_passwd]`: [String] Password assigned to the Directory
  Service Manager, if none is provided one will be randomly generate and
  assigned to the `node[:odsee][:admin_passwd]` attribute. Optionally a data
  bag can be used in place of the node attribute. The default behavior is to
  randomly generate password.

* `node[:odsee][:agent_passwd]`: [String] Password assigned to the Directory
  Service Agent, if none is provided one will be randomly generate and
  assigned to the `node[:odsee][:agent_passwd]` attribute. Optionally a data
  bag can be used in place of the node attribute. The default behavior is to
  randomly generate password.

* `node[:odsee][:cert_passwd]`: [String] Password assigned to the certificate
  database, if none is provided one will be randomly generate and assigned to
  the `node[:odsee][:cert_passwd]` attribute. Optionally a data bag can be
  used in place of the node attribute. The default behavior is to randomly
  generate password.

* `node[:odsee][:ldap_port]`: [Integer] Assigns the LDAP port, default is 398.

* `node[:odsee][:ldaps_port]`: [Integer] Assigns the LDAPS port, default is 636.

* `node[:odsee][:ds_port]`: [Integer] Assigns the port for Directory Servers to
  agent communication, default is 3995.

* `node[:odsee][:ds_port]`: [Integer] Assigns the SNMP port, default is 3996.

* `node[:odsee][:agent_port]`: [Integer] Assigns the agent port for the DSCC
  instance, default is 3997.

* `node[:odsee][:registry_ldap_port]`: [Integer] Assigns the LDAP port for the
  DSCC registry instance, default is 3998.

* `node[:odsee][:registry_ldaps_port]`: [Integer] Assigns the LDAPS port for the
  DSCC registry instance, default is 3999.

* `node[:odsee][:dn]`: [String] Default DN as Directory Manager DN, default
  value is `cn=Directory Manager`

* `node[:odsee][:suffix]`: [String] Suffix for the directory, default value is
  `dc=example,dc=com`.

* `node[:odsee][:accept_cert]`: [TrueClass, FalseClass] Boolean, when true
  specifies to not ask for confirmation before accepting non-trusted server
  certificates. Default is `true`.

* `node[:odsee][:no_inter]`: [TrueClass, FalseClass] When true does not prompt
  for password and/or confirmation before performing the operation. Default is
  `true`.

* `node[:odsee][:dsadm][:user_name]`: [String] Sets the server instance owner
  user ID. Default is `root`.

* `node[:odsee][:dsadm][:group_name]`: [String] Sets the server instance owner
  group ID. Default is `root`.

* `node[:odsee][:snmp_v3]`: [TrueClass, FalseClass] Boolean, true if SNMP
  version 3 should be used, otherwise false. Default is `false`.

* `node[:odsee][:registry_path]`: [Proc] Path where the DSCC Registry will be
  installed, default is `/opt/dsee7/var/dcc/ads`.

* `node[:odsee][:agent_path]`: [Proc] Full path to the existing DSCC agent
  instance, default is `/opt/var/dcc/agent`.

* `node[:odsee][:instance_path]`: [String] The Directory Server instance, the
  destination directory must be empty, default is `/opt/dsInst`.

* `node[:odsee][:safe_mode]`: [TrueClass, FalseClass] Boolean, when true starts
  Directory Server with the configuration used at the last successful startup,
  default is `false`.

* `node[:odsee][:schema_push]`: [TrueClass, FalseClass] Boolean, when true
  ensures a manually modified schema is replicated to consumers, the default is
   `false`.

* `node[:odsee][:force]`: [TrueClass, FalseClass] Boolean, when set to true the
  the running instance will be forcibly shut down. When used with the option
  `stop-running-instances`, the command forcibly shuts down all the running
  server instances that are created using the same dsadm installation. When
  used with stop, the command forcibly shuts down the instance even if the
  instance is not initiated by the current installation. Default is `false`.

* `node[:odsee][:no_top_entry]`: [TrueClass, FalseClass] Boolean, used to
  specify if the `create_suffix` command should not create a top entry for the
  suffix. By default, a top-level entry is created when a new suffix is created
  (on the condition that the suffix starts with `dc=, c=, o= or ou=`). The
  default is false.

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
     entries in `cn=config`.
  * `Chef::Resource::LdapEntry`: A Chef Resource to manage generic LDAP entries.
    It makes use of the ruby net-ldap library, and can be used with any LDAP
    directory service.
  * `Chef::Resource::LdapUser`: A Chef Resource to create, manage or delete
    LDAP user objects.

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

    dsadm '/opt/dsee7/dsInst' do
      ldap_port 389
      ldaps_port 636
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
  * `agent_passwd`: Reads the DSCC agent password from supplied file.
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

The following examples demonstrate various approaches for using resources in
recipes. If you want to see examples of how Chef uses resources in recipes,
take a closer look at some of the cookbooks in the [supermarket]
(https://supermarket.chef.io/cookbooks?order=recently_updated)

##### Populate an existing suffix with LDIF data from a file

    dsadm 'dc=example,dc=com' do
      path '/opt/dsee7/dsInst'
      ldif_file '/opt/dsee7/example.com.LDIF
      action :import
    end

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

    dsccagent '/opt/dsee7/var/dcc/agent' do
      agent_passwd '/tmp/agent_passwd_file'
      action [:create, :start]
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
  * `admin_passwd`: A file containing the Directory Service Manager password.

#### Examples

The following examples demonstrate various approaches for using resources in
recipes. If you want to see examples of how Chef uses resources in recipes,
take a closer look at some of the cookbooks in the [supermarket]
(https://supermarket.chef.io/cookbooks?order=recently_updated)

##### Create an agent instance

    dsccagent '/opt/dsee7/var/dcc/agent' do
      agent_passwd '/tmp/agent_passwd_file'
      no_inter true
      ds_port 5150
      action [:create, :start]
    end

### dsccreg

A Chef provider for the Oracle Directory Server `dsccreg` resource.

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

    dsccreg '/opt/dsee7/var/dcc/agent' do
      action [:add_agent, :start]
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
  * `admin_passwd`: A file containing the Directory Service Manager password.
  * `agent_port`: Specifies port as the DSCC agent port to use for communicating
    with this server instance.

#### Examples

The following examples demonstrate various approaches for using resources in
recipes. If you want to see examples of how Chef uses resources in recipes,
take a closer look at some of the cookbooks in the [supermarket]
(https://supermarket.chef.io/cookbooks?order=recently_updated)

##### Create and start an agent instance

    dsccreg '/opt/dsee7/var/dcc/agent' do
      agent_passwd '/tmp/the_agent_password_file'
      action [:add_agent, :start]
    end

##### Create and start a server instance

    dsccreg '/opt/dsee7/var/dcc/agent' do
      description 'yo_dog_instance'
      action [:add_agent, :start]
    end

### dsccsetup

A Chef resource for the Oracle Directory Server `dsccsetup` resource.

#### Overview

The `dsccsetup` command is used to initialize the DSCC registry, a local
Directory Server instance for private use by DSCC to store configuration
information. DSCC requires that this instance reside locally on the host where
you run DSCC. Therefore, if you replicate the data in the instance for high
availability, set up one DSCC per replica host.

This cookbook comes with a Chef Resource and Provider that can be used in the
cookbook in-place of shelling out to run the `dsccsetup` CLI.

You use the `dsccsetup` resource to manage a Directory Server instance as you
would using the command line or with a shell script although as a native Chef
Resource.

#### Syntax

The syntax for using the `dsccsetup` resource in a recipe is as follows:

    dsccsetup 'name' do
      attribute 'value' # see attributes section below
      ...
      action :action # see actions section below
    end

Where:

  * `dsccsetup` tells the chef-client to use the `Chef::Provider::Dsccsetup`
    provider during the chef-client run;
  * `name` is the name of the resource block; **note** the `name` parameter is
    not used in this provider, it serves only to identify the block;
  * `attribute` is zero (or more) of the attributes that are available for
    this resource;
  * `:action` identifies which steps the chef-client will take to bring the
    node into the desired state.

For example:

    dsccsetup :create do
      action :ads_create
    end

#### Actions:

  * `:ads_create`: Initialize a local Directory Server registry instance for
    the DSCC to store configuration information.
  * `:ads_delete`: Delete the Directory Server registry instance.

#### Attribute Parameters:

  * `registry_ldap_port`: Specifies the LDAP port for the DSCC registry
    instance, default is 3998.
  * `registry_ldaps_port`: Specifies the LDAPS port for the DSCC registry
    instance, default is 3999.
  * `no_inter`: When true does not prompt for password and/or does not prompt
    for confirmation before performing the operation.

#### Examples

The following examples demonstrate various approaches for using resources in
recipes. If you want to see examples of how Chef uses resources in recipes,
take a closer look at some of the cookbooks in the [supermarket]
(https://supermarket.chef.io/cookbooks?order=recently_updated)

##### Create local Directory Server registry instance

    dsccsetup 'registry' do
      action :ads_create
    end

##### Delete the local Directory Server registry instance

    dsccsetup 'registry' do
      action :ads_delete
    end

### dsconf

A Chef Resource and Provider that manages a Directory Server configuration..

#### Overview

The `dsconf` Chef Resource and Provider can be used to manage a Directory
Server configuration. It enables you to modify the configuration entries in
`cn=config`. The server must be running in order for `dsconf` to run.

This cookbook comes with a Chef Resource and Provider that can be used in the
cookbook in-place of shelling out to run the `dsconf` CLI.

You use the `dsconf` resource to manage a Directory Server instance as you
would using the command line or with a shell script although as a native Chef
Resource.

#### Syntax

The syntax for using the `dsconf` resource in a recipe is as follows:

    dsconf 'name' do
      attribute 'value' # see attributes section below
      ...
      action :action # see actions section below
    end

Where:

  * `dsconf` tells the chef-client to use the `Chef::Provider::Dsconf`
    provider during the chef-client run;
  * `name` is the name of the resource block; when the `path` attribute is
    not specified as part of a recipe, `name` is also the path to the DSCC
    server instance;
  * `attribute` is zero (or more) of the attributes that are available for
    this resource;
  * `:action` identifies which steps the chef-client will take to bring the
    node into the desired state.

For example:

    dsconf :create do
      action :ads_create
    end

#### Actions:

  * `:create_suffix`: Creates a top level suffix entry in a LDAP DIT (Directory
    Information Tree).
  * `:delete_suffix`: Deletes suffix configuration and data.
  * `:import`: Populates an existing suffix with LDIF data from a compressed
    or uncompressed LDIF file.

#### Attribute Parameters:

  * `hostname`: The DSCC registry host name. The default is `nil` or blank,
    which causes the local host name be returned by the operating system.
  * `ldap_port`: The port for LDAP traffic. The default is `389` if `dsadm` is
    run by the root user, or `1389` if `dsadm` is run by a non-root user.
  * `db_name`: Specifies a database name.
  * `db_path`: Specifies database directory and path.
  * `db_path`: Specifies database directory and path.
  * `accept_cert`: Specifies whether or not to receive confirmation before
    accepting non-trusted server certificates. Default is `true`, and not
    require confirmation.
  * `no_top_entry`: Specifies if the `create_suffix` command should not create
    a top entry for the suffix. By default, a top-level entry is created when
    a new suffix is created (on the condition that the suffix starts with
    `dc=, c=, o= or ou=`). The default is `false`.
  * `admin_passwd`: Reads the DSCC agent password from supplied file.
  * `suffix`: Suffix for the directory.
  * `async`: Launches a task asynchronously, returns control immediately.
  * `incremental`: Boolean, specifies that the contents of the imported LDIF
    file are appended to the existing LDAP entries. If this option is not
    specified, the contents of the imported file replace the existing entries.
  * Import flags, Hash of the following key/pairs:
    * `chunk_size`: Sets the merge chunk size. Overrides the detection of when
      to start a new pass during import.
    * `incremental_output`: Specifies whether an output file will be generated
      for later use in importing to large replicated suffixes. Default is
      `true`. This flag can only be used when the `incremental` option is also
      `true`. If this flag is not used, an output file will automatically be
      generated.
    * `incremental_output_file`: Sets the path of the generated output file for
      an incremental (appended) import. The output file is used for updating a
      replication topology. It is an LDIF file containing the difference between
      the replicated suffix and the LDIF file, and replication information.
  * Export flags, Hash of the following key/pairs:
    * `compression_level`: Compression level when `GZ_LDIF_FILE` is given as
      operand. Default is `3`, range is from 1 to 9.
    * `multiple_output_file`: Boolean, when `true` each suffix is exported to
      separate file.
    * `use_main_db_file`: Boolean, `true` exports the main database file only.
    * `not_export_unique_id: [TrueClass, FalseClass]`: Boolean, true does not
      export unique id values.
    * `output_not_folded`: Boolean, `true` does not wrap long lines.
    * `not_print_entry_ids`: Boolean, `true` does not export entry IDs.
  * Backup flags, Hash of the following key/pairs:
    * `verify_db`: Boolean, when `true` the integrity of the backed up database
      will be checked.
    * `no_recovery`: Boolean, when `true` skips recovery of the database.
  * Restore flags, Hash of the following key/pairs:
    * `move_archive`: Boolean, when `true` performs a database restore by moving
      files in place of copying them.
  * Rewrite flags, Hash of the following key/pairs:
    * `purge_csn`: Boolean, when `true` the Change Sequence Number (CSN) are
      purged, preventing old CSN data from being kept by the operation. This
      reduces the size of the entries. Default is `false`.
    * `convert_pwp_opattr_to_DS6:`: Boolean, when `true` converts DS5 mode
      password policy operational attributes to run in D6-mode.
      `false` by default, when set to `true`, permits DS5 mode password policy
      operational attributes to be migrated using their ID (Internet Draft)
      and to run in DS6-mode. DS6-migration-mode is the only mode in which
      you can migrate operational attributes safely. When the migration has
      been successfully performed, run the server in DS6-mode when you are
      ready.
      **Note:** `convert_pwp_opattr_to_DS6: true` must be run on all servers in
      the topology that are in DS6-migration-mode in order to migrate their DS5
      mode password policy operational attributes.
  * `exclude_dn`: Does not import or export data contained in the specified dm.
  * `ldif_file`: Path to the file in LDIF format, can be gzip compressed.

#### Examples

The following examples demonstrate various approaches for using resources in
recipes. If you want to see examples of how Chef uses resources in recipes,
take a closer look at some of the cookbooks in the [supermarket]
(https://supermarket.chef.io/cookbooks?order=recently_updated)

##### Create a suffix and populate it with LDIF data from a file

    dsadm 'dc=example,dc=com' do
      path '/opt/dsee7/dsInst'
      ldif_file '/opt/dsee7/example.com.LDIF
      action [:create, :import]
    end

### ldap_entry

This resource is used to manage generic LDAP entries using the `net-ldap` Ruby
Gem, and can therefore be used with any LDAP directory service.

#### Overview

#### Syntax

The syntax for using the `ldap_entry` resource in a recipe is as follows:

    ldap_entry 'name' do
      attribute 'value' # see attributes section below
      ...
      action :action # see actions section below
    end

Where:

  * `ldap_entry` tells the chef-client to use the `Chef::Provider::LdapEntry`
    provider during the chef-client run;
  * `name` is the name of the resource block; when the Distinguished Name `dn`
    attribute is not specified as part of a recipe, `name` is also the `dn`;
  * `attribute` is zero (or more) of the attributes that are available for
    this resource;
  * `:action` identifies which steps the chef-client will take to bring the
    node into the desired state.

For example:

    ldap_entry 'ou=Company Servers,dc=example,dc=com' do
      attributes(
        objectClass: ['top', 'organizationalUnit'],
        ou:          'Quality-focused zero defect success Servers'
        description: 'Cross-group Multi-State Parallelism',
      )
      action :create
    end

#### Actions:

  * `:create`: Creates a new LDAP object or modifies and existing one.
  * `:delete`: Deletes an LDAP object.

#### Attribute Parameters:

  * `dn`: The Distinguished Name of the LDAP object.
  * `attributes`: A Hash of attributes to be set on the object. Existing
    attributes of the same name will be replaced with the new content.
  * `append_attributes`: A Hash of attributes whose values are to be appended
    to any existing values, if any.
  * `seed_attributes`: Attributes whose values are to be set once and not
    modified again.
  * `prune`: List (Array) of attributes to be removed, or a Hash of attributes
     with specific values to be removed.
  * `host`: The LDAP Server to connect to, defaults to `localhost`.
  * `port`: The LDAP Server port to connect to, default to `389`.
  * `auth`: A Hash containing a `bind_dn` and `password` to authenticate and
     bind to the LDAP Directory where:
     * `bind_dn`: The bind DN used to initialize the instance and create the
       initial set of LDAP entries. (example: 'cn=Directory Manager')
     * `password`: The password in plain text.

#### Examples

The following examples demonstrate various approaches for using resources in
recipes. If you want to see examples of how Chef uses resources in recipes,
take a closer look at some of the cookbooks in the [supermarket]
(https://supermarket.chef.io/cookbooks?order=recently_updated)

##### Create or update a Group object

    ldap_entry 'ou=Groups, dc=example,dc=com' do
      attributes(
        objectClass:  ['top', 'organizationalUnit'],
        cn:            'Disintermediate Seamless e-Commerce Tactics Engineer',
        description:   'Recontextualize Mission-Critical Convergence',
        uniquemember: ['uid=aliyah, ou=People, dc=example,dc=com',
                       'uid=garrett,ou=People, dc=example,dc=com'],
      )
      action :create
    end

### ldap_user

Creates a user object in the LDAP directory, can be used to bind (connect) to
the LDAP instance or with applied posix attributes used to authenticate on UNIX
systems.

#### Overview

#### Syntax

The syntax for using the `ldap_user` resource in a recipe is as follows:

    ldap_user 'name' do
      attribute 'value' # see attributes section below
      ...
      action :action # see actions section below
    end

Where:

  * `ldap_user` tells the chef-client to use the `Chef::Provider::LdapUser`
    provider during the chef-client run;
  * `name` is the name of the resource block; when the Common Name `cn`
    attribute is not specified as part of a recipe, `name` is also the `cn`;
  * `attribute` is zero (or more) of the attributes that are available for
    this resource;
  * `:action` identifies which steps the chef-client will take to bring the
    node into the desired state.

For example:

    ldap_user 'norberto' do
      basedn   'ou=People,o=ExampleOrg'
      home     '/home/norberto'
      shell    '/bin/zsh'
      password 'bjykehpxB/TIq'
      action :create
    end

#### Actions:

  * `:create`: Creates a new user object or modifies and existing one.
  * `:delete`: Deletes an user from the directory server.

#### Attribute Parameters:

  * `common_name`: The value to be set as both `uid` and `cn` attributes.
  * `surname`: The surname of the user.
  * `password`: Optional password should be specified in plaintext. Will be
     converted to a salted aes-256-cbc SHA Hash providing relatively no
     additional security but extra complexity and cool sounding words like
     cypher, before being sent to the directory.
  * `home`: The users home directory, required for posix accounts.
  * `shell`: The login shell, required for posix accounts.
  * `basedn`: The `dn` that will be the parent of the user account entry
    (example: 'ou=people,...').
  * `relativedn`: The relative distinguished name (RDN) attribute. This is will
    be used to name the `common_name` attribute from above. Given a common_name
    of `rosalia` and a `basedn` attribute of `ou=People,o=ExampleOrg,c=US` the
    distinguished name would be `uid=rosalia,ou=People,o=ExampleOrg,c=US`.
  * `uid_number`: Required for posix accounts. If not supplied, the `basedn`
    will be searched for the highest value and the next increment will be used.
  * `gid_number`: Required for posix accounts. If not supplied, the `basedn`
    will be searched for the highest value and the next increment will be used.
  * `is_person`: Will this be used by a person?
  * `is_posix`: Will this be used on a posix system?
  * `is_extensible`: Can the entry be extended using custom attributes?
  * `attrs`: Additional attributes to be added to the account.

#### Examples

The following examples demonstrate various approaches for using resources in
recipes. If you want to see examples of how Chef uses resources in recipes,
take a closer look at some of the cookbooks in the [supermarket]
(https://supermarket.chef.io/cookbooks?order=recently_updated)

##### Create a new user

    ldap_user 'yolanda' do
      basedn   'ou=People,o=ExampleOrg'
      home     '/home/yolanda'
      shell    '/bin/zsh'
      password 'bjykehpxB/TIq'
      action :create
    end

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

Author::    Stefano Harding <sharding@trace3.com>
License::   Apache License, Version 2.0
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

```
 .-.     .-.     .-.     .-.     .-.    .-.   .-.   .-.   .-.   .-.   .-.   .-.
Digit\al Pres\ence Gr\oup Aut\omation\ ( * ) ( : ) ('*.) (: :) (:-:) (:::) ((-))
'     `-'     `-'     `-'     `-'     ` `-'   `-'   `-'   `-'   `-'   `-'   `-'
```
[Berkshelf]: http://berkshelf.com "Berkshelf"
[Chef]: https://www.getchef.com "Chef"
[ChefDK]: https://www.getchef.com/downloads/chef-dk "Chef Development Kit"
[Chef Documentation]: http://docs.opscode.com "Chef Documentation"
[ChefSpec]: http://chefspec.org "ChefSpec"
[Foodcritic]: http://foodcritic.io "Foodcritic"
[Learn Chef]: http://learn.getchef.com "Learn Chef"
[Test Kitchen]: http://kitchen.ci "Test Kitchen"
