
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
      ldif ::File.join(node[:odsee][:install_dir], 'dsee7/resources/ldif/Example.ldif')
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

Copyright:: 2014, Stefano Harding

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
