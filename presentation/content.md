# Title

---

# Agenda

1. Introduction
2. Deep-dive
3. ...

---

# Introduction

# Code

```ruby
def add(a,b)
  a + b
end
```

---

# Chef Concepts & Intro

* `chef-client` runs on the _node_.
* Talks to the Chef Server (https://chef.typo3.org)
* Authenticates using a _client_  key

* `knife client list` vs `knife node list`


* Workstation: your laptop


---

# Chef Attributes

* Per-node configuration
* Computed based on cookbooks, roles, environments,.. 
* Hierarchies `default`, `normal`, `override`, ... (in total: 16 levels)
* Always use `default`. .footnote[.red[*]That's correct in 99% of all cases]
* Attributes in `attributes/*.rb` of cookbooks loaded, when cookbook is loaded (e.g. when included via other cookbook's `metadata.rb`)

* `knife node show srv123.typo3.org -a mysql`


---

# Chef Roles

* Do not use them
* Maybe, use them for "tagging" (what's the node that has role `site-rsyslogtypo3org`)
* Would prever environments for poor man's service discovery


---

# Chef Environments


```ruby
name "production"
description "The production environment. All cookbooks in this environment are considered STABLE should have FIXED VERSIONS to ensure a certain (stable) state."

cookbook_versions({
  "monit"               => "= 0.7.3",
  "mysql"               => "<= 6.0.18",
  "php"                 => "= 1.1.2",
  "rsyslog"             => "= 1.4.5",
  "site-demotypo3org"   => "~> 1.4.0",
  "t3-apache2"          => "= 0.1.2",
  "t3-base"             => "~> 0.2.21",
  "t3-kvm"              => "~> 0.1.0",
})

default_attributes({
  "rabbitmq" => {
    "server" => "mq.typo3.org"
  },
  "t3-base" => {
    "flags" => {
      "production" => true
    }
  }
})
```

---

--- 

---

# Cookbook Stack

* Have _one_ (_one_!) top-level cookbook per node.  
* Include `t3-base` first


```ruby
# recipes/default.rb

include_recipe "t3-base"
```

```ruby
# metadata.rb
...
require "t3-base", "~> 0.2"

 
* Include other cookbooks afterwards

```ruby
# recipes/default.rb

include_recipe "t3-base"
include_recipe "t3-mysql"
include_recipe "#{cookbook_name}::_deploy"
include_recipe "#{cookbook_name}::_config"
include_recipe "#{cookbook_name}::logrotate"

```
 
---

# Top-Level Cookbook Template `site-skeletontypo3org`

* https://github.com/TYPO3-cookbooks/site-skeletontypo3org
* Also home of this presentation
* Includes 
  * monitoring
  * backup
  * logrotate 


# README (of top-level cookbooks)

* brief description of the application (is it for server, is it for the agent?)
* honest statement about the maturity level
  * save to deploy a new version?
  * do test-kitchen tests fail?
  * is this cookbook complete?
* were is data stored?
  * i.e. when we move to a new server, what to copy?
* how is configuration handled
  * configuration files overwritten via Chef?
  * 
  
---

# Workflow

* Create branch `feature-whatever`
* Make changes
* run `kitchen converge`
* Commit changes, merge branch back to `master`
* Release cookbook
  * Bump version number in `metadata.rb`
  * Run `berks install` (if it fails, run `berks update` or delete `Berksfile.lock`)
  * `git add Berksfile.lock` (<- under version control for top-level cookbooks)
  * `git commit -m "Bump version to 1.2.3"`
  * `git tag 1.2.3`
  * `git push origin master --tags`
  * `berks upload`
    * will try to upload _all_ cookbooks
    * will only upload new versions
    * can use `berks upload <cookbook-name>` to speed-up process

---

# ChefDK

* Bundles (almost) everything that we need
* Tools:
  * `chef-*`
  * `berks`
  * `test-kitchen` 
  * `foodcritic`
* Installs to `/opt/chefdk`
* Includes own ruby stack (use `chef gem install ...` to install ruby gems)

---

# Testing: `test-kitchen`

* Please, please, please use test-kitchen!
* Easy
* Reliable
* It gives us certainty
* Supports different _providers_ (vagrant, docker, digitalocean, etc..)
* Driven by the `.kitchen.yml` file

---

# TK: example setup

* `.kitchen.yml` file of `site-proxytypo3org`

```yaml
---
driver:
  name: vagrant

verifier:
  name: inspec

provisioner:
  name: chef_zero

platforms:
  - name: debian-7.8
  - name: debian-8.2

suites:
  - name: default
    run_list:
      - recipe[site-proxytypo3org::default]
    attributes:
      site-proxytypo3org:
        ssl_certificate: wildcard.vagrant
    driver_config:
      network:
        - ["private_network", {ip: "192.168.88.18"}]
        - ["forwarded_port", {guest: 22002, host: 22002, auto_correct: true}]
```

---

# TK: Workflow

* `kitchen list`

```
Instance           Driver   Provisioner  Verifier  Transport  Last Action
default-debian-78  Vagrant  ChefZero     Busser    Ssh        <Not Created>
default-debian-82  Vagrant  ChefZero     Busser    Ssh        <Not Created>
```
* `kitchen converge 82`
  * Creates new VM
  * Runs `chef-client`

* `kitchen list`

```
Instance           Driver   Provisioner  Verifier  Transport  Last Action
default-debian-78  Vagrant  ChefZero     Busser    Ssh        <Not Created>
default-debian-82  Vagrant  ChefZero     Busser    Ssh        Converged
```
* If it fails: `kitchen login 82`

* Tests? `kitchen verify`
  * Runs unit tests (chefspec) and integration tests (serverspec, inspec)
  * Personal opinion: We should at least have some basic integration tests

* Done? `kitchen destroy`


---

# TK: suites

* Allows testing of cookbook variants
  * different recipies
  * variation in attributs


---

# TK suites of `t3-base`

* Suites:
  * `default`: the humble VM, used for testing
  * `physical`: some extras that only physical servers need (NTP, .. )
  * `production`: we don't need Zabbix & friends for every test, right? But we need a way to also test _this_!

```
suites:
  - name: default
    run_list:
      - recipe[t3-base::default]
    attributes:
  - name: physical
    run_list:
      - recipe[t3-base::default]
      - recipe[t3-base::_physical]
  - name: production
    run_list:
    - recipe[t3-base::default]
    attributes:
      t3-base:
        flags:
          production: true
      virtualization:
        host: test.vagrant
      t3-base:
        prevent-t3-chef-client-inclusion-for-testing: true
```


```
Instance              Driver   Provisioner  Verifier  Transport  Last Action
default-debian-60     Vagrant  ChefZero     Inspec    Ssh        <Not Created>
default-debian-78     Vagrant  ChefZero     Inspec    Ssh        <Not Created>
default-debian-82     Vagrant  ChefZero     Inspec    Ssh        <Not Created>
physical-debian-60    Vagrant  ChefZero     Inspec    Ssh        <Not Created>
physical-debian-78    Vagrant  ChefZero     Inspec    Ssh        <Not Created>
physical-debian-82    Vagrant  ChefZero     Inspec    Ssh        <Not Created>
production-debian-60  Vagrant  ChefZero     Inspec    Ssh        <Not Created>
production-debian-78  Vagrant  ChefZero     Inspec    Ssh        <Not Created>
production-debian-82  Vagrant  ChefZero     Inspec    Ssh        <Not Created>
```

---

# TK: kitchen-docker

* Easy way to speed up machine creation
* `.kitchen.local.yml`:

```yaml
---
driver:
  name: docker
```

* Transparently translates platforms (`debian-8.2`) into docker images.
* Caveat: Docker images lack some packages (_cron_, _netutils_, ...)


---

# Misc: `knife search`

* Syntax ([Docs TODO](https://docs.chef.io)):
  * `knife search <index> <lucene-query>`
* What Containers are running on `ms03.typo3.org`?
  * `knife search node virtualization_host:ms03.typo3.org`
* What hosts are in the Hetzner data center?
  * `knife search node datacenter:hetzner`
* Who is one of us :-)
  * `knife search user groups:sysadmin`
* Who has access to that server?
  * `knife search user nodes:srv123.typo3.org`

# Misc: `knife ssh`

* `knife ssh virtualization_type:physical hostname`

* `knife ssh '*:*' cssh` launches Cluster-SSH (`brew install csshx` on MacOS)


---



# Conceptual: Split server and client cookbooks

* If server part is complex, separate it from client code (e.g. `zabbix-server` and `zabbix-agent`)
  * Imagine that the one `zabbix` cookbook requires a certain `mysql` cookbook version.
  * Instead, avoid side-effects / conflicting dependencies
  

---

# README Rendering

* `knife cookbook doc .` renders `README` based on `doc/` contents
* Comment attributes:

```ruby
#<> Number of workers to start
default['foo']['workers'] = 4
```


  
---

# pre-production for testing



---

# Attributes Antipattern

* DO NOT: Manually edit node attributes (`knife node edit`)
  * Congratulation: You now have a snowflake
  * All attributes have to be reproducible / computed

---


# Environment Antipattern

* DO NOT: pin non-toplevel cookbook versions in environments
  * Side-effect that cannot be tested with `test-kitchen`
  * Top-level cookbook must pin included cookbook version instead


---

# User Management (in `t3-base::_users`)

* Manage users through the users data bag




---

# 

---

# 

---

# 

---

# 

---

# 

---

# 



























