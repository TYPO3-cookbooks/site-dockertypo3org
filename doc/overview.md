This cookbook provides a skeleton for TYPO3 site-cookbooks. The following sections describe the usage of the skeleton.

## Cookbook Structure

	├── Berksfile                       # Cookbook dependencies for Berkshelf
	├── README.md                       # The cookbook documentation - automatically generated, DO NOT TOUCH!
	├── attributes                      # Chef's attributes directory
	│   └── ...
	├── doc                             # Directory containing Markdown documents that will automatically be rendered into the README file
	│   └── ...
	├── files                           # Chef's files directory
	│   └── ...
	├── .kitchen.yml                    # Configuration for TestKitchen (integration testing)
	├── metadata.rb                     # The cookbook's metadata file
	├── recipes                         # The cookbook's recipes
	│   ├── _privat_cookbook.rb         # Private recipes start with a '_'
	│   ├── public_cookbook.rb          # Public recipes (reusable recipes, must be well documented)
	│   └── ...
	├── spec                            # Directory for ChefSpec tests (unit tests)
	│   └── ...
	└── templates                       # Chef's template directory
	    └── ...




# Chef Development Tooling


Install [ChefDK](https://downloads.chef.io), which brings already most tools.

Further, the follwing RubyGems have to be installed:

* `knife-cookbook-doc` - a plugin for knife that let's you generate the README, see [knife-cookbook-doc's Github page](https://github.com/realityforge/knife-cookbook-doc)
* `guard` - a file watcher tool, see [Guard's Github page](https://github.com/guard/guard)
* `thor-scmversion` - a versioning utility handling the cookbook versions, see [thor-scmversion's Github page](https://github.com/RiotGamesMinions/thor-scmversion)

We do not use Bundler/Gemfiles, to set those up on a per-repo basis, instead install these Gems into ChefDK's ruby:

	chef gem install knife-coobkook-doc
	chef gem install guard
	chef-gem install thor-scmversion

If executables are not available in `$PATH`, use `chef exec <whatever>` instead.


## Berkshelf

We use [Berkshelf](http://berkshelf.com) as a dependency manager for our cookbooks. Since most of our cookbooks have dependencies to other cookbooks (community cookbooks or other TYPO3 cookbooks) it is a requirement for the cookbook development to resolve those cookbooks in a consistent manner. Berkshelf does this job for us.



### The Berksfile

Within the `Berksfile` we can configure the dependencies of our cookbook. Therefore we create a `Berksfile` with the following content in the root directory of our cookbook:

````ruby
source 'http://chef.typo3.org:26200'
source 'https://supermarket.chef.io'

metadata
````

The commands `berks install` will download all cookbook dependencies (as specified in `metadata.rb`) from the defined source, which are:

1. The [Chef Supermarket](https://supermarket.chef.io/)
2. Our [Chef Server](https://chef.typo3.org), accessible through the Berksshelf API Server at `http://chef.typo3.org:26200`.

The `metadata` keyword indicates that the dependencies of the cookbook should automatically be read from our `metadata.rb` file in which we have to declare the dependencies for Chef. Berkshelf will then automatically resolve those dependencies.

*TODO: what about a description of `Berksfile.lock`?*

#### Berksfile During Development

Tha above specified sources require dependent cookbooks to be either available in the Supermarket or in our Chef Server.

While development of cookbooks, it is a frequent pattern that multiple cookbooks evolve together at the same time. To avoid uploading intermediate versions of dependent cookbooks, different sources can be specified in the `Berksfile`:

````ruby
source 'http://chef.typo3.org:26200'
source 'https://supermarket.chef.io'

metadata

cookbook 't3-zabbix', github: 'TYPO3-cookbooks/t3-zabbix'
cookbook 't3-foobar', github: 'TYPO3-cookbooks/t3-zabbix', ref: 'feature/new-feature'
cookbook 't3-megabook', path: '../cookbooks/t3-megabook'
````
As you can see in the given example above, Berkshelf can handle all three of these locations for us.


### Cookbook Dependencies and the Environment Pattern

We implement the so-called [Environment Cookbook Pattern](http://blog.vialstudios.com/the-environment-cookbook-pattern/). Within this pattern, you have the following types of cookbooks:

* **Base Cookbooks** doing basic things on your servers, e.g. setting the *message of the day* or creating system users and groups. Most likely there is basic set of packages that you want to install on all of your servers. This stuff belongs here.

* **Library Cookbooks** add basic functionality to your cookbooks, e.g. creating a database or cloning a Git repository to a given location. The goal is to abstract common things into re-usable building blocks.

* **Application Cookbooks** contain at least on recipe to install a piece of software, e.g. an Nginx server or a MySQL database server. Application cookbooks are always named after the application they provide (e.g. `apache` or `mysql`).

* **Wrapper Cookbooks** provide a thin layer for customizing other cookbooks (i.e. community cookbooks). What they do is essentially including recipes from other cookbooks and customizing the attributes of those included cookbooks. A `typo3-apache` cookbook might be a good example.

* **Environment Cookbooks** are the most high-level cookbooks. They are used to manage the release process of cookbooks. It's main goal is to define the exact versions of all the cookbooks that are used in a particular environment (i.e. development, staging, production). It's the only cookbook whose `Berksfile.lock` is checked into version control.

The following example of a fictitious cookbook dependency tree for the typo3.org server makes things clearer:

	└── site-typo3org-prod              # The toplevel environment coobook - provides www.typo3.org in a production environment
	    └── typo3org                    # An application cookbook - providing a typo3 server (with tunable attributes for the respective environments)
	        ├── typo3-apache            # TYPO3's wrapper cookbook for Apache - tunes the wrapped Apache community cookbook
	        │   └── apache              # Application cookbook for Apache - a community cookbook
	        ├── typo3-mysql             # TYPO3's wrapper cookbook for the MySQL server - tunes the wrapped MySQL community cookbook
	        │   └── mysql               # Application cookbook for MySQL - a community cookbook
	        ├── ...                     # Quite a few more of those wrapper / application cookbook pairs (e.g. PHP, Varnish, ...)
	        │   └── ...
	        ├── typo3lib                # A TYPO3 library cookbook - sets up a TYPO3 directory structure with source links...
	        └── typo3base               # A base cookbook that sets up the basic system users, packages...

Let us now take a look at the `metadata.rb` and `Berksfile` of each of the cookbooks:

**typo3base** and **typo3lib** most likely have no dependencies, so their `metadata.rb` will be empty

```` ruby
name             'typo3lib'
# 8< ... snip ... 8<

# no `depends` entries
````

The `Berksfile` only contains the following lines:

```` ruby
source 'https://supermarket.chef.io'

metadata
````

indicating that dependencies can be resolved from the `metadata.rb` file (not sure, whether it makes more sense to have no Berksfile at all or whether it may be empty - with this, we are on the safe side!).

**typo3mysql** will have a dependency to **mysql** which we can define in the `metadata.rb`

```` ruby
name             'typo3mysql'
# 8< ... snip ... 8<

depends 'mysql', '= 1.2.3'
````

When including a community cookbook, we agreed upon pinning the patchlevel - as you can never be sure that even a change in the patch level won't break things.

Here is the according `Berksfile`

````ruby
source 'https://supermarket.chef.io'

metadata
````

Noting special, since the cookbook can be taken from Chef's community cookbook supermarket and the version is pinned in the `metadata.rb` file.

In the **typo3org** application cookbook, things are slightly different, though. Here's the `metadata.rb`:

````ruby
name             'typo3org'
# 8< ... snip ... 8<

depends 'typo3apache', '~> 2.2.1'
depends 'typo3mysql',  '~> 1.4.3'
depends 'typo3lib',    '~> 2.1.0'
depends 'typo3base',   '~> 4.3.2'
````

When including our "own" cookbooks, we pin only the minor version and enable Chef to use a newer patch level version of the cookbooks.

Here is the according `Berksfile` that's again a little different:

````ruby
source 'https://supermarket.chef.io'

extension 't3github'

metadata

cookbook 'typo3apache', t3gitlab: 'typo3apache', tag: '2.2.1'
cookbook 'typo3mysql',  t3gitlab: 'typo3mysql',  tag: '1.4.3'
cookbook 'typo3lib',    t3gitlab: 'typo3lib',    tag: '2.1.0'
cookbook 'typo3mysql',  t3gitlab: 'typo3mysql',  tag: '4.3.2'
````

With the `extension 't3github'` line, we can register a plugin in Berkshelf that allows us to define our own cookbook locations. In this case we take the community cookbooks from our Github organization's repositories and can shorten things a lot by using a custom plugin to resolve the address for us. Since Berkshelf cannot (yet) resolve cookbook versions by Git tags, we need to provide a tag that satisfies the cookbook constraint in the `metadata.rb` which is done with the `tag:` parameter. All the other dependencies can be resolved from the Chef supermarket so they are covered with the `metadata` directive.

Last but not least the **site-typo3org-prod** cookbook's `metadata.rb`

```` ruby
name             'site-typo3org-prod'
# 8< ... snip ... 8<

depends 'typo3org', '~> 1.0.1'
````

since the environment cookbook only covers the "differences" between each of our environments (development, staging, production), this is a very thin "wrapper" around the `typo3org` application cookbook that does most of the work for us. It might come as a surprise, that the `Berksfile` holds some duplication though:

```` ruby
source 'https://supermarket.chef.io'

extension 't3github'

metadata

cookbook 'typo3org',    t3gitlab: 'typo3org',    tag: '1.0.1'
cookbook 'typo3apache', t3gitlab: 'typo3apache', tag: '2.2.1'
cookbook 'typo3mysql',  t3gitlab: 'typo3mysql',  tag: '1.4.3'
cookbook 'typo3lib',    t3gitlab: 'typo3lib',    tag: '2.1.0'
cookbook 'typo3mysql',  t3gitlab: 'typo3mysql',  tag: '4.3.2'
````

Berkshelf does not resolve locations of cookbooks recursively, which means that only the toplevel cookbook can provide a location for a cookbook other than the Chef Supermarket. Hence you need to provide the locations - that are already given in the `typo3org` application cookbook - again in the environment cookbook.



### Background and Consequences

* We do not use roles in Chef anymore. The reason is that roles in Chef cannot be versioned, hence we cannot have different versions of roles on different stages / servers. Instead, a Chef environment is created for each environment cookbook version that allows us to pin the cookbook versions on the Chef server.

* The environment cookbook itself (e.g. `site-typo3org-prod`) most likely cannot be tested (reasons can be, that hostnames for production won't work or that connected services are productive, hence end-to-end tests are not possible). This "un-testability" requires us to keep those cookbooks as thin as possible, namely: including the default recipe of the underlaying application cookbook and tuning some attributes (e.g. hostnames and credentials of production systems).

* The runlist of a Chef node consists of a single cookbook at the end: the environment cookbook.



## Rendering README Documentation

The README file for the cookbook is automatically generated by [knife-cookbook-doc](https://github.com/realityforge/knife-cookbook-doc). Here is a brief description of how it works.



### File and Directory Structure for Automated README Rendering

Regarding the following file / directory structure of a cookbook (files that are not relevant for the README rendering are not shown):

````
├── README.md                       # This file is generated automatically
├── attributes                      # Comments in attribute files are rendered as documentation
│   └── ...
├── doc                             # Every file in here is rendered into the README file
│   └── ...
├── metadata.rb                     # Certain content of `metadata.rb` is used for the README (e.g. authors and dependencies)
└── recipes                         # For each recipe in the `recipes` folder, a documentation section is rendered
    ├── _privat_cookbook.rb         # Documentation for prive recipes is NOT rendered into the README
    ├── public_cookbook.rb          # Public recipes should be well-annotated as there is a documentation section in the README for them
    └── ...
````

you will get a README rendered by running the following command from the cookbook root directory:

````
bundle exec knife cookbook doc . --template README.md.erb
````

If any error occurs, use the `-VV` switch to get some debug information.



### Template for README rendering

The template for the README rendering is currently part of this repository but should be put in a separate, global project since we want to re-use it in multiple cookbooks. It is planned to create a command line tool for common tasks concerning cookbook maintenance into which the template could be integrated later on.



### Documentation of Recipes

TODO



### Documentation of Attributes

TODO


