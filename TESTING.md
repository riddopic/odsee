
Ensure you have all the required prerequisite listed in the Development
Requirements section. You should have a working Vagrant installation with either
VirtualBox or VMware installed. From the parent directory of this cookbook begin
by running bundler to ensure you have all the required Gems:

    bundle install

A ruby environment with Bundler installed is a prerequisite for using the
testing harness shipped with this cookbook. At the time of this writing, it
works with Ruby 2.1.2 and Bundler 1.6.2. All programs involved, with the
exception of Vagrant and VirtualBox, can be installed by cd'ing into the parent
directory of this cookbook and running 'bundle install'.

#### Vagrant and VirtualBox

The installation of Vagrant and VirtualBox is extremely complex and involved.
Please be prepared to spend some time at your computer:

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

The Rakefile ships with a number of tasks, each of which can be ran
individually, or in groups. Typing `rake` by itself will perform style checks
with [Rubocop](https://github.com/bbatsov/rubocop) and
[Foodcritic](http://www.foodcritic.io),
[Chefspec](http://sethvargo.github.io/chefspec/) with rspec, and integration
with [Test Kitchen](http://kitchen.ci) using the Vagrant driver by default.
Alternatively, integration tests can be ran with Test Kitchen cloud drivers for
EC2 are provided.

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

Ruby style tests can be performed by Rubocop by issuing either the bundled
binary or with the Rake task:

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

Unit testing is done by running Rspec examples. Rspec will test any libraries,
then test recipes using ChefSpec. This works by compiling a recipe (but not
converging it), and allowing the user to make assertions about the
resource_collection.

#### Integration Testing

Integration testing is performed by Test Kitchen. Test Kitchen will use either
the Vagrant driver or EC2 cloud driver to instantiate machines and apply
cookbooks. After a successful converge, tests are uploaded and ran out of band
of Chef. Tests are be designed to
ensure that a recipe has accomplished its goal.

#### Integration Testing using Vagrant

Integration tests can be performed on a local workstation using Virtualbox or
VMWare. Detailed instructions for setting this up can be found at the
[Bento](https://github.com/opscode/bento) project web site. Integration tests
using Vagrant can be performed with either:

    $ bundle exec kitchen test
        or
    $ rake integration:vagrant

#### Integration Testing using EC2 Cloud provider

Integration tests can be performed on an EC2 providers using Test Kitchen
plugins. This cookbook references environmental variables present in the shell
that `kitchen test` is ran from. These must contain authentication tokens for
driving APIs, as well as the paths to ssh private keys needed for Test Kitchen
log into them after they've been created.

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
