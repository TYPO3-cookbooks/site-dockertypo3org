Cookbook site-skeletontypo3org
==============================

This cookbook provides a skeleton for TYPO3 site-cookbooks. The following sections describe the usage of the skeleton.

## Cookbook Structure

	├── Berksfile                       # Cookbook dependencies for Berkshelf
	├── Gemfile                         # Ruby Gems dependencies for Bundler
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



## Gemfile

The `Gemfile` describes the dependencies to Ruby Gems, which we need for some meta tasks (e.g. rendering the documentation or dependency management for cookbooks).

To resolve the Gem dependencies that you need to work with the cookbook, run

	bundle install

from the cookbook's root directory. Make sure to have Bundler installed with `gem install bundler`.



### Gem Dependencies

Here's a brief description of the dependencies defined in the Gemfile:

* `berkshelf` - the cookbook dependency manager, see [berkshelf.com](http://berkshelf.com)
* `chefspec` - the unit testing framework for Chef cookbooks, see [ChefSpec's Github page](https://github.com/sethvargo/chefspec)
* `knife-cookbook-doc` - a plugin for knife that let's you generate the README, see [knife-cookbook-doc's Github page](https://github.com/realityforge/knife-cookbook-doc)
* `foodcritic` - a linting tool for Chef cookbooks, see [foodcritic.io](http://foodcritic.io/)
* `serverspec` - an integration testing framework, see [serverspec.org](http://serverspec.org/)
* `guard` - a file watcher tool, see [Guard's Github page](https://github.com/guard/guard)
* `thor-scmversion` - a versioning utility handling the cookbook versions, see [thor-scmversion's Github page](https://github.com/RiotGamesMinions/thor-scmversion)

The usage of the tools is described below if necessary.



## Berkshelf

We use [Berkshelf](http://berkshelf.com) as a dependency manager for our cookbooks. Since most of our cookbooks have dependencies to other cookbooks (community cookbooks or other TYPO3 cookbooks) it is a requirement for the cookbook development to resolve those cookbooks in a consistent manner. Berkshelf does this job for us.



### The Berksfile

Within the `Berksfile` we can configure the dependencies of our cookbook. Therefore we create a `Berksfile` with the following content in the root directory of our cookbook:

````ruby
source 'https://supermarket.chef.io'

metadata

cookbook 'apache22'
cookbook 't3-zabbix', github: 'TYPO3-cookbooks/t3-zabbix'
cookbook 't3-megabook', path: '../cookbooks/t3-megabook'
````


Generally there are three different sources from where we get our cookbooks:

1. From the [Chef Supermarket](https://supermarket.chef.io/)
2. From (TYPO3's cookbook repositories on Github)[https://github.com/TYPO3-cookbooks]
3. From a local directory in our development environment

As you can see in the given example above, Berkshelf can handle all three of these locations for us.

The `metadata` keyword indicates that the dependencies of the cookbook should automatically be read from our `metadata.rb` file in which we have to declare the dependencies for Chef. Berkshelf will then automatically resolve those dependencies (from the Chef Supermarket unless an different location is given in the `Berksfile`).



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

Let us now take a look at the `metadata.rb` and `Berksfile`s of each of the cookbooks:

**typo3base** and **typo3lib** most likely have no dependencies, so their `metadata.rb` will be empty

````
name             'site-skeletontypo3org'
maintainer       'The TYPO3 DevOps Team'
maintainer_email 'cookbooks@typo3.de'
license          'All rights reserved'
# ...

# no `depends` entries
````

For **typo3base** and **typo3lib** the `Berksfile` only contains the following lines:

```` ruby
source 'https://supermarket.chef.io'

metadata
````

indicating that dependencies can be resolved from the `metadata.rb` file.






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





Requirements
============

Platform:
---------

* debian

Cookbooks:
----------

*No dependencies defined*



Attributes
==========


### `node['skeleton']['sample_attribute']`
Sample attribute for showing how documentation of attributes works

**Default Value:** `[ ... ]`
### `node['email_adress']`
email address for the TYPO3 cookbook maintainers

**Default Value:** `cookbooks@typo3.org`




Recipes
=======

* [site-skeletontypo3org::sample](#site-skeletontypo3orgsample) - Provides a sample recipe for the TYPO3 skeleton cookbook.

site-skeletontypo3org::sample
-----------------------------

Provides a sample recipe for the TYPO3 skeleton cookbook.



TODOs
=====

## Documentation

* email address and metadata information in `metadata.rb`
* agree upon which platforms we want to support



## Testing

* Add basic TestKitchen configuration
* Agree upon whether or not we want to use Chefspec



## Tools

* Discuss usage / implementation of our own CLI helper tool (Thor?)
* Introduce Guard





License and Maintainer
======================

Maintainer:: The TYPO3 DevOps Team (<cookbooks@typo3.de>)

License:: All rights reserved
