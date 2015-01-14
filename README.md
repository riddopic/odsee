
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


## Class: Chef::Resource::Dsadm
|              |                              |
| -----------: | :----------------------------|
|    Inherits: |  LWRPBase                    |
|    Includes: |  Odsee                       |
|  Defined in: |  libraries/resource_dsadm.rb |

## Overview

The `dsadm` command is the local administration command for Directory Server
instances. The `dsadm` command must be run from the local machine where the
server instance is located. This command must be run by the username that is
the operating system owner of the server instance, or by root.

This cookbook comes with a Chef Resource and Provider that can be used in the
cookbook in-place of shelling out to run the `dsadm` CLI.

You use the `dsadm` resource to manage a Directory Server instance as you
would using the command line or with a shell script although as a native Chef
Resource.

### Instance Method Summary
- - -
  * [(String) `admin_pw_file`](#anchor1) __private__  
    a file containing the Direcctory Service Manager password.
  * [(String) `below`](#anchor1) __private__  
    creates the Directory Server instance in an existing directory, specified
    by the `instance_path`.
  * [(String) `cert_pw_file`](#anchor1) __private__  
    A file containing the certificate database password.
  * [(TrueClass, FalseClass) `created`](#anchor1) __private__  
    Boolean, returns true if the Directory Server instance has been created,
    otherwise false.
  * [(String) `dn`](#anchor1) __private__  
    Defines the Directory Manager DN.
  * [(TrueClass, FalseClass) `force`](#anchor1) __private__  
    If the instance should be forcibly shut down.
  * [(String) `group_name`](#anchor1) __private__  
    The server instance owner user ID.
  * [(String, NilClass) `hostname`](#anchor1) __private__  
    The DSCC registry host name.
  * [(Integer) `ldap_port`](#anchor1) __private__  
    The port number to use for LDAP communication.
  * [(Integer) `ldaps_port`](#anchor1) __private__  
    The port number to use for LDAPS communication.
  * [(TrueClass, FalseClass) `no_inter`](#anchor1) __private__  
    When true does not prompt for password and/or does not prompt for
    confirmation before performing the operation.
  * [(TrueClass, FalseClass) `safe_mode`](#anchor1) __private__  
    Starts Directory Server with the configuration used at the last successful
    startup.
  * [(TrueClass, FalseClass) `schema_push`](#anchor1) __private__  
    Ensures manually modified schema is replicated to consumers.
  * [(String) `user_name`](#anchor1) __private__  
    The server instance owner user ID.

### Instance Method Details
- - -
   - (String) __admin_pw_file__
    
            This method is part of a private API. You should avoid using
	        this method if possible, as it may be removed or be changed
	        in the future.
    
     A file containing the Directory Service Manager password.
    
     __Parameters:__
       * file (String) — File to use to store the Directory Service Manager
         password.
    
     __Returns:__
       * (String)
- - -
     
    
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

    dsadm '/opt/dsInst' do
      ldap_port 1234
      ldaps_port 1233
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
  * `cert_pw_file`: Reads certificate database password from `cert_pw_file`.

#### Examples

dsadm backup [-f FLAG] ... INSTANCE_PATH ARCHIVE_DIR
Creates a backup archive of the Directory Server instance.

dsadm import [-biK] [-x DN] ... [-f FLAG=VAL] ... [-y [-W CERT_PW_FILE]]
INSTANCE_PATH GZ_LDIF_FILE [GZ_LDIF_FILE...] SUFFIX_DN
Populates an existing suffix with LDIF data from a compressed or
uncompressed LDIF file.


### dsccagent


A Chef provider for the Oracle Directory Server dsccagent resource.

The `dsccagent` command is used to create, delete, start, and stop Directory 
Service Control Center agent instances on the local system. You can also use the `dsccagent` command to display status and DSCC agent information, and to enable and disable SNMP monitoring.



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

]For example:

    dsadm '/opt/dsInst' do
      ldap_port 1234
      ldaps_port 1233
      action [:create, :start]
    end

#### Actions:

  * `:create`: Creates a Directory Server instance.

#### Attribute Parameters:

  * `cert_pw_file`: Reads certificate database password from `cert_pw_file`.

#### [Examples](id:anchor1)


<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>
  Class: Chef::Resource::Dsccagent
  
    &mdash; Documentation by YARD 0.8.7.6
  
</title>

  <link rel="stylesheet" href="../../css/style.css" type="text/css" charset="utf-8" />

  <link rel="stylesheet" href="../../css/common.css" type="text/css" charset="utf-8" />

<script type="text/javascript" charset="utf-8">
  hasFrames = window.top.frames.main ? true : false;
  relpath = '../../';
  framesUrl = "../../frames.html#!Chef/Resource/Dsccagent.html";
</script>


  <script type="text/javascript" charset="utf-8" src="../../js/jquery.js"></script>

  <script type="text/javascript" charset="utf-8" src="../../js/app.js"></script>


  </head>
  <body>
    <div id="header">
      <div id="menu">
  
    <a href="../../_index.html">Index (D)</a> &raquo;
    <span class='title'>Chef</span> &raquo; <span class='title'>Resource</span>
     &raquo; 
    <span class="title">Dsccagent</span>
  

  <div class="noframes"><span class="title">(</span><a href="." target="_top">no frames</a><span class="title">)</span></div>
</div>

      <div id="search">
  
    <a class="full_list_link" id="class_list_link"
        href="../../class_list.html">
      Class List
    </a>
  
    <a class="full_list_link" id="method_list_link"
        href="../../method_list.html">
      Method List
    </a>
  
    <a class="full_list_link" id="file_list_link"
        href="../../file_list.html">
      File List
    </a>
  
</div>
      <div class="clear"></div>
    </div>

    <iframe id="search_frame"></iframe>

    <div id="content"><h1>Class: Chef::Resource::Dsccagent
  
  
  
</h1>

<dl class="box">
  
    <dt class="r1">Inherits:</dt>
    <dd class="r1">
      <span class="inheritName">LWRPBase</span>
      
        <ul class="fullTree">
          <li>Object</li>
          
            <li class="next">LWRPBase</li>
          
            <li class="next">Chef::Resource::Dsccagent</li>
          
        </ul>
        <a href="#" class="inheritanceTree">show all</a>
      
      </dd>
    
  
  
    
  
    
      <dt class="r2">Includes:</dt>
      <dd class="r2"><span class='object_link'><a href="../../Odsee.html" title="Odsee (module)">Odsee</a></span></dd>
      
    
  
  
  
    <dt class="r1 last">Defined in:</dt>
    <dd class="r1 last">libraries/resource_dsccagent.rb</dd>
  
</dl>
<div class="clear"></div>

<h2>Overview</h2><div class="docstring">
  <div class="discussion">
    
<p>A Chef resource for the Oracle Directory Server dsccagent command.</p>

<p>The dsccagent command is used to create, delete, start, and stop DSCC agent
instances on the local system. You can also use the dsccagent command to
display status and DSCC agent information, and to enable and disable SNMP
monitoring.</p>


  </div>
</div>
<div class="tags">
  

</div>






  
    <h2>
      Instance Method Summary
      <small>(<a href="#" class="summary_toggle">collapse</a>)</small>
    </h2>

    <ul class="summary">
      
        <li class="public ">
  <span class="summary_signature">
    
      <a href="#admin_pw_file-instance_method" title="#admin_pw_file (instance method)">- (String) <strong>admin_pw_file</strong> </a>
    

    
  </span>
  
  
  
  
  
  
  <span class="private note title">private</span>

  
    <span class="summary_desc"><div class='inline'>
<p>A file containing the Direcctory Service Manager password.</p>
</div></span>
  
</li>

      
        <li class="public ">
  <span class="summary_signature">
    
      <a href="#agent_path-instance_method" title="#agent_path (instance method)">- (String) <strong>agent_path</strong> </a>
    

    
  </span>
  
  
  
  
  
  
  <span class="private note title">private</span>

  
    <span class="summary_desc"><div class='inline'>
<p>Full path to the existing DSCC agent instance.</p>
</div></span>
  
</li>

      
        <li class="public ">
  <span class="summary_signature">
    
      <a href="#agent_port-instance_method" title="#agent_port (instance method)">- (Integer) <strong>agent_port</strong> </a>
    

    
  </span>
  
  
  
  
  
  
  <span class="private note title">private</span>

  
    <span class="summary_desc"><div class='inline'>
<p>Specifies the port for thr DSCC agent.</p>
</div></span>
  
</li>

      
        <li class="public ">
  <span class="summary_signature">
    
      <a href="#agent_pw_file-instance_method" title="#agent_pw_file (instance method)">- (String) <strong>agent_pw_file</strong> </a>
    

    
  </span>
  
  
  
  
  
  
  <span class="private note title">private</span>

  
    <span class="summary_desc"><div class='inline'>
<p>A file containing the DSCC agent password.</p>
</div></span>
  
</li>

      
        <li class="public ">
  <span class="summary_signature">
    
      <a href="#created-instance_method" title="#created (instance method)">- (TrueClass, FalseClass) <strong>created</strong> </a>
    

    
  </span>
  
  
  
  
  
  
  <span class="private note title">private</span>

  
    <span class="summary_desc"><div class='inline'>
<p>Boolean, true if a DSCC agent instance has been created, otherwise false.</p>
</div></span>
  
</li>

      
        <li class="public ">
  <span class="summary_signature">
    
      <a href="#ds_port-instance_method" title="#ds_port (instance method)">- (Integer) <strong>ds_port</strong> </a>
    

    
  </span>
  
  
  
  
  
  
  <span class="private note title">private</span>

  
    <span class="summary_desc"><div class='inline'>
<p>The port number to use for traffic from Directory Servers to agent.</p>
</div></span>
  
</li>

      
        <li class="public ">
  <span class="summary_signature">
    
      <a href="#enabled-instance_method" title="#enabled (instance method)">- (TrueClass, FalseClass) <strong>enabled</strong> </a>
    

    
  </span>
  
  
  
  
  
  
  <span class="private note title">private</span>

  
    <span class="summary_desc"><div class='inline'>
<p>Boolean, true if a DSCC agent instance has been configured as a SNMP agent,
otherwise false.</p>
</div></span>
  
</li>

      
        <li class="public ">
  <span class="summary_signature">
    
      <a href="#no_inter-instance_method" title="#no_inter (instance method)">- (TrueClass, FalseClass) <strong>no_inter</strong> </a>
    

    
  </span>
  
  
  
  
  
  
  <span class="private note title">private</span>

  
    <span class="summary_desc"><div class='inline'>
<p>When true does not prompt for password and/or does not prompt for
confirmation before performing the operation.</p>
</div></span>
  
</li>

      
        <li class="public ">
  <span class="summary_signature">
    
      <a href="#running-instance_method" title="#running (instance method)">- (TrueClass, FalseClass) <strong>running</strong> </a>
    

    
  </span>
  
  
  
  
  
  
  <span class="private note title">private</span>

  
    <span class="summary_desc"><div class='inline'>
<p>Boolean, true when the DSCC agent instance is running.</p>
</div></span>
  
</li>

      
        <li class="public ">
  <span class="summary_signature">
    
      <a href="#snmp_port-instance_method" title="#snmp_port (instance method)">- (Integer) <strong>snmp_port</strong> </a>
    

    
  </span>
  
  
  
  
  
  
  <span class="private note title">private</span>

  
    <span class="summary_desc"><div class='inline'>
<p>The port number to use for SNMP traffic.</p>
</div></span>
  
</li>

      
        <li class="public ">
  <span class="summary_signature">
    
      <a href="#snmp_v3-instance_method" title="#snmp_v3 (instance method)">- (TrueClass, FalseClass) <strong>snmp_v3</strong> </a>
    

    
  </span>
  
  
  
  
  
  
  <span class="private note title">private</span>

  
    <span class="summary_desc"><div class='inline'>
<p>Boolean, true if SNMP version 3 should be used, otherwise false.</p>
</div></span>
  
</li>

      
    </ul>
  


  
  
  
  
  
  
  

  <div id="instance_method_details" class="method_details_list">
    <h2>Instance Method Details</h2>

    
      <div class="method_details first">
  <h3 class="signature first" id="admin_pw_file-instance_method">
  
    - (<tt>String</tt>) <strong>admin_pw_file</strong> 
  

  

  
</h3><div class="docstring">
  <div class="discussion">
    <p class="note private">
  <strong>This method is part of a private API.</strong>
  You should avoid using this method if possible, as it may be removed or be changed in the future.
</p>

<p>A file containing the Direcctory Service Manager password.</p>


  </div>
</div>
<div class="tags">
  <p class="tag_title">Parameters:</p>
<ul class="param">
  
    <li>
      
        <span class='name'>file</span>
      
      
        <span class='type'>(<tt>String</tt>)</span>
      
      
      
        &mdash;
        <div class='inline'>
<p>File to use to store the Direcctory Service Manager password.</p>
</div>
      
    </li>
  
</ul>

<p class="tag_title">Returns:</p>
<ul class="return">
  
    <li>
      
      
        <span class='type'>(<tt>String</tt>)</span>
      
      
      
    </li>
  
</ul>

</div><table class="source_code">
  <tr>
    <td>
      <pre class="lines">


185
186
187</pre>
    </td>
    <td>
      <pre class="code"><span class="info file"># File 'libraries/resource_dsccagent.rb', line 185</span>

<span class='id identifier rubyid_attribute'>attribute</span> <span class='symbol'>:admin_pw_file</span><span class='comma'>,</span>
<span class='label'>kind_of:</span> <span class='const'>Proc</span><span class='comma'>,</span>
<span class='label'>default:</span> <span class='id identifier rubyid_lazy'>lazy</span> <span class='lbrace'>{</span> <span class='id identifier rubyid___admin_pw__'>__admin_pw__</span> <span class='rbrace'>}</span></pre>
    </td>
  </tr>
</table>
</div>
    
      <div class="method_details ">
  <h3 class="signature " id="agent_path-instance_method">
  
    - (<tt>String</tt>) <strong>agent_path</strong> 
  

  

  
</h3><div class="docstring">
  <div class="discussion">
    <p class="note private">
  <strong>This method is part of a private API.</strong>
  You should avoid using this method if possible, as it may be removed or be changed in the future.
</p>

<p>Full path to the existing DSCC agent instance. The default path is to use:
install-path/var/dcc/agent</p>


  </div>
</div>
<div class="tags">
  <p class="tag_title">Parameters:</p>
<ul class="param">
  
    <li>
      
        <span class='name'>path</span>
      
      
        <span class='type'>(<tt>String</tt>)</span>
      
      
      
        &mdash;
        <div class='inline'>
<p>Path to existing DSCC agent instance.</p>
</div>
      
    </li>
  
</ul>

<p class="tag_title">Returns:</p>
<ul class="return">
  
    <li>
      
      
        <span class='type'>(<tt>String</tt>)</span>
      
      
      
    </li>
  
</ul>

</div><table class="source_code">
  <tr>
    <td>
      <pre class="lines">


136
137
138</pre>
    </td>
    <td>
      <pre class="code"><span class="info file"># File 'libraries/resource_dsccagent.rb', line 136</span>

<span class='id identifier rubyid_attribute'>attribute</span> <span class='symbol'>:agent_path</span><span class='comma'>,</span>
<span class='label'>kind_of:</span> <span class='const'>String</span><span class='comma'>,</span>
<span class='label'>name_attribute:</span> <span class='kw'>true</span></pre>
    </td>
  </tr>
</table>
</div>
    
      <div class="method_details ">
  <h3 class="signature " id="agent_port-instance_method">
  
    - (<tt>Integer</tt>) <strong>agent_port</strong> 
  

  

  
</h3><div class="docstring">
  <div class="discussion">
    <p class="note private">
  <strong>This method is part of a private API.</strong>
  You should avoid using this method if possible, as it may be removed or be changed in the future.
</p>

<p>Specifies the port for thr DSCC agent. The default is 3997.</p>


  </div>
</div>
<div class="tags">
  <p class="tag_title">Parameters:</p>
<ul class="param">
  
    <li>
      
        <span class='name'>port</span>
      
      
        <span class='type'>(<tt>Integer</tt>)</span>
      
      
      
        &mdash;
        <div class='inline'>
<p>The DSCC agent port to use.</p>
</div>
      
    </li>
  
</ul>

<p class="tag_title">Returns:</p>
<ul class="return">
  
    <li>
      
      
        <span class='type'>(<tt>Integer</tt>)</span>
      
      
      
    </li>
  
</ul>

</div><table class="source_code">
  <tr>
    <td>
      <pre class="lines">


111
112
113</pre>
    </td>
    <td>
      <pre class="code"><span class="info file"># File 'libraries/resource_dsccagent.rb', line 111</span>

<span class='id identifier rubyid_attribute'>attribute</span> <span class='symbol'>:agent_port</span><span class='comma'>,</span>
<span class='label'>kind_of:</span> <span class='const'>String</span><span class='comma'>,</span>
<span class='label'>default:</span> <span class='id identifier rubyid_lazy'>lazy</span> <span class='lbrace'>{</span> <span class='id identifier rubyid_node'>node</span><span class='lbracket'>[</span><span class='symbol'>:odsee</span><span class='rbracket'>]</span><span class='lbracket'>[</span><span class='symbol'>:agent_port</span><span class='rbracket'>]</span> <span class='rbrace'>}</span></pre>
    </td>
  </tr>
</table>
</div>
    
      <div class="method_details ">
  <h3 class="signature " id="agent_pw_file-instance_method">
  
    - (<tt>String</tt>) <strong>agent_pw_file</strong> 
  

  

  
</h3><div class="docstring">
  <div class="discussion">
    <p class="note private">
  <strong>This method is part of a private API.</strong>
  You should avoid using this method if possible, as it may be removed or be changed in the future.
</p>

<p>A file containing the DSCC agent password.</p>


  </div>
</div>
<div class="tags">
  <p class="tag_title">Parameters:</p>
<ul class="param">
  
    <li>
      
        <span class='name'>file</span>
      
      
        <span class='type'>(<tt>String</tt>)</span>
      
      
      
        &mdash;
        <div class='inline'>
<p>File to use to store the DSCC agent password.</p>
</div>
      
    </li>
  
</ul>

<p class="tag_title">Returns:</p>
<ul class="return">
  
    <li>
      
      
        <span class='type'>(<tt>String</tt>)</span>
      
      
      
    </li>
  
</ul>

</div><table class="source_code">
  <tr>
    <td>
      <pre class="lines">


123
124
125</pre>
    </td>
    <td>
      <pre class="code"><span class="info file"># File 'libraries/resource_dsccagent.rb', line 123</span>

<span class='id identifier rubyid_attribute'>attribute</span> <span class='symbol'>:agent_pw_file</span><span class='comma'>,</span>
<span class='label'>kind_of:</span> <span class='const'>Proc</span><span class='comma'>,</span>
<span class='label'>default:</span> <span class='id identifier rubyid_lazy'>lazy</span> <span class='lbrace'>{</span> <span class='id identifier rubyid___agent_pw__'>__agent_pw__</span> <span class='rbrace'>}</span></pre>
    </td>
  </tr>
</table>
</div>
    
      <div class="method_details ">
  <h3 class="signature " id="created-instance_method">
  
    - (<tt>TrueClass</tt>, <tt>FalseClass</tt>) <strong>created</strong> 
  

  

  
</h3><div class="docstring">
  <div class="discussion">
    <p class="note private">
  <strong>This method is part of a private API.</strong>
  You should avoid using this method if possible, as it may be removed or be changed in the future.
</p>

<p>Boolean, true if a DSCC agent instance has been created, otherwise false</p>


  </div>
</div>
<div class="tags">
  <p class="tag_title">Parameters:</p>
<ul class="param">
  
    <li>
      
        <span class='name'></span>
      
      
        <span class='type'>(<tt>TrueClass</tt>, <tt>FalseClass</tt>)</span>
      
      
      
    </li>
  
</ul>

<p class="tag_title">Returns:</p>
<ul class="return">
  
    <li>
      
      
        <span class='type'>(<tt>TrueClass</tt>, <tt>FalseClass</tt>)</span>
      
      
      
    </li>
  
</ul>

</div><table class="source_code">
  <tr>
    <td>
      <pre class="lines">


59
60
61</pre>
    </td>
    <td>
      <pre class="code"><span class="info file"># File 'libraries/resource_dsccagent.rb', line 59</span>

<span class='id identifier rubyid_attribute'>attribute</span> <span class='symbol'>:created</span><span class='comma'>,</span>
<span class='label'>kind_of:</span> <span class='lbracket'>[</span><span class='const'>TrueClass</span><span class='comma'>,</span> <span class='const'>FalseClass</span><span class='rbracket'>]</span><span class='comma'>,</span>
<span class='label'>default:</span> <span class='kw'>nil</span></pre>
    </td>
  </tr>
</table>
</div>
    
      <div class="method_details ">
  <h3 class="signature " id="ds_port-instance_method">
  
    - (<tt>Integer</tt>) <strong>ds_port</strong> 
  

  

  
</h3><div class="docstring">
  <div class="discussion">
    <p class="note private">
  <strong>This method is part of a private API.</strong>
  You should avoid using this method if possible, as it may be removed or be changed in the future.
</p>

<p>The port number to use for traffic from Directory Servers to agent. The
default is 3995.</p>


  </div>
</div>
<div class="tags">
  <p class="tag_title">Parameters:</p>
<ul class="param">
  
    <li>
      
        <span class='name'>port</span>
      
      
        <span class='type'>(<tt>Integer</tt>)</span>
      
      
      
        &mdash;
        <div class='inline'>
<p>The Directory Servers agent port to use.</p>
</div>
      
    </li>
  
</ul>

<p class="tag_title">Returns:</p>
<ul class="return">
  
    <li>
      
      
        <span class='type'>(<tt>Integer</tt>)</span>
      
      
      
    </li>
  
</ul>

</div><table class="source_code">
  <tr>
    <td>
      <pre class="lines">


173
174
175</pre>
    </td>
    <td>
      <pre class="code"><span class="info file"># File 'libraries/resource_dsccagent.rb', line 173</span>

<span class='id identifier rubyid_attribute'>attribute</span> <span class='symbol'>:ds_port</span><span class='comma'>,</span>
<span class='label'>kind_of:</span> <span class='const'>Integer</span><span class='comma'>,</span>
<span class='label'>default:</span> <span class='id identifier rubyid_lazy'>lazy</span> <span class='lbrace'>{</span> <span class='id identifier rubyid_node'>node</span><span class='lbracket'>[</span><span class='symbol'>:odsee</span><span class='rbracket'>]</span><span class='lbracket'>[</span><span class='symbol'>:ds_port</span><span class='rbracket'>]</span> <span class='rbrace'>}</span></pre>
    </td>
  </tr>
</table>
</div>
    
      <div class="method_details ">
  <h3 class="signature " id="enabled-instance_method">
  
    - (<tt>TrueClass</tt>, <tt>FalseClass</tt>) <strong>enabled</strong> 
  

  

  
</h3><div class="docstring">
  <div class="discussion">
    <p class="note private">
  <strong>This method is part of a private API.</strong>
  You should avoid using this method if possible, as it may be removed or be changed in the future.
</p>

<p>Boolean, true if a DSCC agent instance has been configured as a SNMP agent,
otherwise false</p>


  </div>
</div>
<div class="tags">
  <p class="tag_title">Parameters:</p>
<ul class="param">
  
    <li>
      
        <span class='name'></span>
      
      
        <span class='type'>(<tt>TrueClass</tt>, <tt>FalseClass</tt>)</span>
      
      
      
    </li>
  
</ul>

<p class="tag_title">Returns:</p>
<ul class="return">
  
    <li>
      
      
        <span class='type'>(<tt>TrueClass</tt>, <tt>FalseClass</tt>)</span>
      
      
      
    </li>
  
</ul>

</div><table class="source_code">
  <tr>
    <td>
      <pre class="lines">


71
72
73</pre>
    </td>
    <td>
      <pre class="code"><span class="info file"># File 'libraries/resource_dsccagent.rb', line 71</span>

<span class='id identifier rubyid_attribute'>attribute</span> <span class='symbol'>:enabled</span><span class='comma'>,</span>
<span class='label'>kind_of:</span> <span class='lbracket'>[</span><span class='const'>TrueClass</span><span class='comma'>,</span> <span class='const'>FalseClass</span><span class='rbracket'>]</span><span class='comma'>,</span>
<span class='label'>default:</span> <span class='kw'>nil</span></pre>
    </td>
  </tr>
</table>
</div>
    
      <div class="method_details ">
  <h3 class="signature " id="no_inter-instance_method">
  
    - (<tt>TrueClass</tt>, <tt>FalseClass</tt>) <strong>no_inter</strong> 
  

  

  
</h3><div class="docstring">
  <div class="discussion">
    <p class="note private">
  <strong>This method is part of a private API.</strong>
  You should avoid using this method if possible, as it may be removed or be changed in the future.
</p>

  <div class="note notetag">
    <strong>Note:</strong>
    <div class='inline'>
<p>This should always return nil.</p>
</div>
  </div>


<p>When true does not prompt for password and/or does not prompt for
confirmation before performing the operation.</p>


  </div>
</div>
<div class="tags">
  <p class="tag_title">Parameters:</p>
<ul class="param">
  
    <li>
      
        <span class='name'>interupt</span>
      
      
        <span class='type'>(<tt>TrueClass</tt>, <tt>FalseClass</tt>)</span>
      
      
      
        &mdash;
        <div class='inline'>
<p>If you would like to be prompted to confirm actions.</p>
</div>
      
    </li>
  
</ul>

<p class="tag_title">Returns:</p>
<ul class="return">
  
    <li>
      
      
        <span class='type'>(<tt>TrueClass</tt>, <tt>FalseClass</tt>)</span>
      
      
      
    </li>
  
</ul>

</div><table class="source_code">
  <tr>
    <td>
      <pre class="lines">


99
100
101</pre>
    </td>
    <td>
      <pre class="code"><span class="info file"># File 'libraries/resource_dsccagent.rb', line 99</span>

<span class='id identifier rubyid_attribute'>attribute</span> <span class='symbol'>:no_inter</span><span class='comma'>,</span>
<span class='label'>kind_of:</span> <span class='lbracket'>[</span><span class='const'>TrueClass</span><span class='comma'>,</span> <span class='const'>FalseClass</span><span class='rbracket'>]</span><span class='comma'>,</span>
<span class='label'>default:</span> <span class='id identifier rubyid_lazy'>lazy</span> <span class='lbrace'>{</span> <span class='id identifier rubyid_node'>node</span><span class='lbracket'>[</span><span class='symbol'>:odsee</span><span class='rbracket'>]</span><span class='lbracket'>[</span><span class='symbol'>:no_inter</span><span class='rbracket'>]</span> <span class='rbrace'>}</span></pre>
    </td>
  </tr>
</table>
</div>
    
      <div class="method_details ">
  <h3 class="signature " id="running-instance_method">
  
    - (<tt>TrueClass</tt>, <tt>FalseClass</tt>) <strong>running</strong> 
  

  

  
</h3><div class="docstring">
  <div class="discussion">
    <p class="note private">
  <strong>This method is part of a private API.</strong>
  You should avoid using this method if possible, as it may be removed or be changed in the future.
</p>

<p>Boolean, true when the DSCC agent instance is running. The DSCC agent will
be able to start if it was registered in the DSCC registry, or if the SNMP
agent is enabled</p>


  </div>
</div>
<div class="tags">
  <p class="tag_title">Parameters:</p>
<ul class="param">
  
    <li>
      
        <span class='name'></span>
      
      
        <span class='type'>(<tt>TrueClass</tt>, <tt>FalseClass</tt>)</span>
      
      
      
    </li>
  
</ul>

<p class="tag_title">Returns:</p>
<ul class="return">
  
    <li>
      
      
        <span class='type'>(<tt>TrueClass</tt>, <tt>FalseClass</tt>)</span>
      
      
      
    </li>
  
</ul>

</div><table class="source_code">
  <tr>
    <td>
      <pre class="lines">


84
85
86</pre>
    </td>
    <td>
      <pre class="code"><span class="info file"># File 'libraries/resource_dsccagent.rb', line 84</span>

<span class='id identifier rubyid_attribute'>attribute</span> <span class='symbol'>:running</span><span class='comma'>,</span>
<span class='label'>kind_of:</span> <span class='lbracket'>[</span><span class='const'>TrueClass</span><span class='comma'>,</span> <span class='const'>FalseClass</span><span class='rbracket'>]</span><span class='comma'>,</span>
<span class='label'>default:</span> <span class='kw'>nil</span></pre>
    </td>
  </tr>
</table>
</div>
    
      <div class="method_details ">
  <h3 class="signature " id="snmp_port-instance_method">
  
    - (<tt>Integer</tt>) <strong>snmp_port</strong> 
  

  

  
</h3><div class="docstring">
  <div class="discussion">
    <p class="note private">
  <strong>This method is part of a private API.</strong>
  You should avoid using this method if possible, as it may be removed or be changed in the future.
</p>

<p>The port number to use for SNMP traffic. Default is 3996.</p>


  </div>
</div>
<div class="tags">
  <p class="tag_title">Parameters:</p>
<ul class="param">
  
    <li>
      
        <span class='name'>port</span>
      
      
        <span class='type'>(<tt>Integer</tt>)</span>
      
      
      
        &mdash;
        <div class='inline'>
<p>The SNMP traffic port to use.</p>
</div>
      
    </li>
  
</ul>

<p class="tag_title">Returns:</p>
<ul class="return">
  
    <li>
      
      
        <span class='type'>(<tt>Integer</tt>)</span>
      
      
      
    </li>
  
</ul>

</div><table class="source_code">
  <tr>
    <td>
      <pre class="lines">


160
161
162</pre>
    </td>
    <td>
      <pre class="code"><span class="info file"># File 'libraries/resource_dsccagent.rb', line 160</span>

<span class='id identifier rubyid_attribute'>attribute</span> <span class='symbol'>:snmp_port</span><span class='comma'>,</span>
<span class='label'>kind_of:</span> <span class='lbracket'>[</span><span class='const'>Integer</span><span class='rbracket'>]</span><span class='comma'>,</span>
<span class='label'>default:</span> <span class='id identifier rubyid_lazy'>lazy</span> <span class='lbrace'>{</span> <span class='id identifier rubyid_node'>node</span><span class='lbracket'>[</span><span class='symbol'>:odsee</span><span class='rbracket'>]</span><span class='lbracket'>[</span><span class='symbol'>:snmp_port</span><span class='rbracket'>]</span> <span class='rbrace'>}</span></pre>
    </td>
  </tr>
</table>
</div>
    
      <div class="method_details ">
  <h3 class="signature " id="snmp_v3-instance_method">
  
    - (<tt>TrueClass</tt>, <tt>FalseClass</tt>) <strong>snmp_v3</strong> 
  

  

  
</h3><div class="docstring">
  <div class="discussion">
    <p class="note private">
  <strong>This method is part of a private API.</strong>
  You should avoid using this method if possible, as it may be removed or be changed in the future.
</p>

<p>Boolean, true if SNMP version 3 should be used, otherwise false.</p>


  </div>
</div>
<div class="tags">
  <p class="tag_title">Parameters:</p>
<ul class="param">
  
    <li>
      
        <span class='name'>snmp_v3</span>
      
      
        <span class='type'>(<tt>TrueClass</tt>, <tt>FalseClass</tt>)</span>
      
      
      
        &mdash;
        <div class='inline'>
<p>True to use SNMP version 3, otherwise false.</p>
</div>
      
    </li>
  
</ul>

<p class="tag_title">Returns:</p>
<ul class="return">
  
    <li>
      
      
        <span class='type'>(<tt>TrueClass</tt>, <tt>FalseClass</tt>)</span>
      
      
      
    </li>
  
</ul>

</div><table class="source_code">
  <tr>
    <td>
      <pre class="lines">


148
149
150</pre>
    </td>
    <td>
      <pre class="code"><span class="info file"># File 'libraries/resource_dsccagent.rb', line 148</span>

<span class='id identifier rubyid_attribute'>attribute</span> <span class='symbol'>:snmp_v3</span><span class='comma'>,</span>
<span class='label'>kind_of:</span> <span class='lbracket'>[</span><span class='const'>TrueClass</span><span class='comma'>,</span> <span class='const'>FalseClass</span><span class='rbracket'>]</span><span class='comma'>,</span>
<span class='label'>default:</span> <span class='id identifier rubyid_lazy'>lazy</span> <span class='lbrace'>{</span> <span class='id identifier rubyid_node'>node</span><span class='lbracket'>[</span><span class='symbol'>:odsee</span><span class='rbracket'>]</span><span class='lbracket'>[</span><span class='symbol'>:snmp_v3</span><span class='rbracket'>]</span> <span class='rbrace'>}</span></pre>
    </td>
  </tr>
</table>
</div>
    
  </div>

</div>

    <div id="footer">
  Generated on Tue Jan 13 19:32:35 2015 by
  <a href="http://yardoc.org" title="Yay! A Ruby Documentation Tool" target="_parent">yard</a>
  0.8.7.6 (ruby-2.1.4).
</div>

  </body>
</html>




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
    rake all                         # Run all tasks
    rake chefspec                    # Run RSpec code examples
    rake doc                         # Build documentation
    rake foodcritic                  # Lint Chef cookbooks
    rake kitchen:all                 # Run all test instances
    rake kitchen:apps-dir-centos-65  # Run apps-dir-centos-65 test instance
    rake kitchen:default-centos-65   # Run default-centos-65 test instance
    rake kitchen:ihs-centos-65       # Run ihs-centos-65 test instance
    rake kitchen:was-centos-65       # Run was-centos-65 test instance
    rake kitchen:wps-centos-65       # Run wps-centos-65 test instance
    rake readme                      # Generate README.md from _README.md.erb
    rake rubocop                     # Run RuboCop
    rake rubocop:auto_correct        # Auto-correct RuboCop offenses
    rake test                        # Run all tests except `kitchen` / Run
                                     # kitchen integration tests
    rake yard                        # Generate YARD Documentation

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
