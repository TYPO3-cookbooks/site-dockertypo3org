# Chef at *.typo.org

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
* Attributes in `attributes/*.rb` of cookbooks loaded, when cookbook is loaded (e.g. when included via other cookbook's `metadata.rb`)

* Hierarchies `default`, `normal`, `override`, ... (in total: 16 levels)
* Always use `default` .red[*]

* `knife node show srv123.typo3.org -a mysql`
```
srv123.typo3.org:
  mysql:
    allow_remote_root:        false
    auto-increment-increment: 1
    auto-increment-offset:    1
    ....
```

.footnote[.red.bold[*] correct in 99% of all cases]

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
  "monit"               => "= 0.7.3",   // FIXME remove!
  "mysql"               => "<= 6.0.18", // FIXME remove!
  "php"                 => "= 1.1.2",   // FIXME remove!
  "rsyslog"             => "= 1.4.5",   // FIXME remove!
  "site-demotypo3org"   => "~> 1.4.0",  // I would be okay here! 
  "t3-apache2"          => "= 0.1.2",   // FIXME remove!
  "t3-base"             => "~> 0.2.21", // FIXME remove!
  "t3-kvm"              => "~> 0.1.0",  // FIXME remove!
})

default_attributes({
  "rabbitmq" => {
    "server" => "mq.typo3.org"          // poor man's service discovery
  },
  "t3-base" => {
    "flags" => {
      "production" => true              // magic!
    }
  }
})
```

---


# Cookbook Stack

* Have _one_ (_one_!) top-level cookbook per node.  
  * it's name is `site-<younameit>typo3org`
  * everything derives from that
  * central "entry point" for testing

* Include `t3-base` first

```ruby
# recipes/default.rb

include_recipe "t3-base"
```
 
* Include other cookbooks afterwards

```ruby
include_recipe "t3-mysql"
include_recipe "#{cookbook_name}::_config"
include_recipe "#{cookbook_name}::_logrotate"

```
 
---

# Top-Level Cookbook Template `site-skeletontypo3org`

* https://github.com/TYPO3-cookbooks/site-skeletontypo3org
* Also home of this presentation
* Includes (FIXME)
  * monitoring
  * backup
  * logrotate 

 
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

# Repo Structure (aka. `chef-repo`)

* Usual suspectives:
  * `data_bags` 
  * `environments/`  
  * `roles/`  

* Config:
  * `.chef/` - contains knife config, private key, etc.
  * `support_files/` - test-kitchen customizations - not yet, but we should
    (vagrant cachier, custom APT mirror, more RAM, fixed Chef version!)
 
* `cookbooks/` - contains stand-alone Git repos of our cookbooks .red[*]
```shell
cd cookbooks/
git clone https://github.com/TYPO3-cookbooks/t3-base
 ```
  
  
.footnote[.red.bold[*] yes, maybe a way to get them all would be nice]

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
    driver_config:
      network:
        - ["private_network", {ip: "192.168.88.18"}]
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

---

# TK: suites

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

# TK: The _T_ is for _Testing_

* Good to know that a cookbook converges
  * Need data bags? -> put them into `test/integration/data_bags/<bag>/<item>.json`
  * Need nodes to search for? -> put them into `test/integration/nodes/<name>.json`


* `test/` should contain more tests
* `serverspec` vs. `inspec`
  * latter one is by Chef and pretty young
* `site-proxytypo3org` contains some inspec tests
  


---

# Inspec for nginx proxy

* `test/integration/default/inspec/nginx_spec.rb`

```ruby
control 'nginx-1' do
  title 'Nginx Setup'
  desc '
    Check that nginx is installed and listening to ports
  '
  describe package('nginx') do
    it { should be_installed }
  end

  describe service('nginx') do
    it { should be_running }
  end

  describe port(80) do
    it { should be_listening }
    its('protocols') { should include 'tcp'}
    its('protocols') { should include 'tcp6'}
    its('processes') { should include 'nginx.conf' }
  end
...
  describe parse_config_file('/etc/nginx/sites-enabled/review.typo3.org', nginx_config_options) do
    its('server_name') { should include 'review.typo3.org'}
    its('add_header') { should include 'Strict-Transport-Security "max-age=31536000; includeSubdomains; preload;"' }
  end
```

---

# Inspec for nginx proxy (cont'd)

```ruby
control 'nginx-proxy' do
  title 'Verify proxy functionality'
  desc 'Check that typo3.org config works'

  # redirect port 80
  describe command('curl --head --resolve "typo3.org:80:127.0.0.1" http://typo3.org') do
    its('exit_status') { should eq 0 }
    its('stdout') { should include '301 Moved Permanently' }
  end

  # port 443 to typo3.org works
  describe command('curl --insecure --resolve "typo3.org:443:127.0.0.1" https://typo3.org') do
    its('exit_status') { should eq 0 }
    its('stdout') { should include 'TYPO3 - The Enterprise Open Source CMS' }
  end

  # headers
  describe command('curl --head --insecure --resolve "typo3.org:443:127.0.0.1" https://typo3.org') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /Strict-Transport-Security: max-age=15768000; preload;/ }
    its('stdout') { should match /X-Content-Type-Options: nosniff/ }
    its('stdout') { should match /X-Frame-Options: SAMEORIGIN/ }
    its('stdout') { should match /XSS-Protection: 1; mode=block/ }
  end

  # do NOT set includeSubdomains flag for HSTS as this would break non-HTTPS subdomains
  describe command('curl --head --insecure --resolve "typo3.org:443:127.0.0.1" https://typo3.org') do
    its('exit_status') { should eq 0 }
    its('stdout') { should_not match /Strict-Transport-Security: .*includeSubdomains/m }
  end
end
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

* `chef gem install kitchen-docker`

* Transparently translates platforms (`debian-8.2`) into docker images.
* Caveat: Docker images lack some packages (_cron_, _netutils_, ...)

---

# README (of top-level cookbooks, )

* brief description of the application (is it for server, is it for the agent?)

* honest statement about the maturity level
  * save to deploy a new version?
  * do test-kitchen tests fail?
  * is this cookbook complete?

* were is data stored?
  * i.e. when we move to a new server, what to copy?

* how is configuration handled
  * configuration files overwritten via Chef?


---

# README Rendering

* `knife cookbook doc .` renders `README` based on `doc/` contents
* Comment attributes:

```ruby
#<> Number of workers to start
default['foo']['workers'] = 4
```

---



# Conceptual: Split server and client cookbooks

* If server part is complex, separate it from client code (e.g. `zabbix-server` and `zabbix-agent`)
  * Imagine that the one `zabbix` cookbook requires a certain `mysql` cookbook version.
  * Instead, avoid side-effects / conflicting dependencies
  


  
---

# Environment `pre-production` for Canary Release

* Bring _pre-production_ in sync with _production_
* Pin `site-xyztypo3org` to current version in _production_
* Upload new cookbook version
* Flip a node to _pre-production_
* Run `chef-client` on that node

* If all fine, remove constraint in _production_



---

# Attributes Antipattern

* DO NOT: Manually edit node attributes (`knife node edit`)
  * Congratulation: You now have a snowflake
  * All attributes have to be reproducible / computed

---


# Environment Antipattern

* DO NOT: pin **non-toplevel** cookbook versions in environments
  * Side-effect that cannot be tested with `test-kitchen`
  * Top-level cookbook must pin included cookbook version instead

* DO NOT: environment-specific code in cookbooks
  * detect production state based on `node[t3-base][flags][production]`

---

# Examples

* Data Bags for configuration (data center, users, proxy sites) 
* Ohai for magic

---

# Data Center Configuration 

* in `t3-base::_datacenter`

```json
$ cat data_bags/datacenters/punkt_de.json
{
  "id": "punkt_de",
  "servers": [
    "ms03.typo3.org",
    "ms04.typo3.org"
  ],
  "attributes": {
    "ntp": {
      "servers": [
        "chronos.pluspunkthosting.de"
      ]
    }
  }
}
```

* Every server.red[*] knows it's host (`node[virtualization][host]`)
  * So every node knows its data center
  * No need to specify it explicitly through run list

* DC stored in attribute `node[datacenter]`

.footnote[.red.bold[*] with OpenVZ]

---

# Platform-Specific Configuration

* in `t3-base::default`
* Ohai knows that we're on Debian
  * So let's include...
```ruby
include_if_available "t3-base::_platform_family_#{node[:platform_family]}"
include_if_available "t3-base::_platform_#{node[:platform]}"
```
  * `t3-base::_platform_debian` 
  * `t3-base::_platform_family_debian`

---

# Virtualization Anyone?

* Physical

```ruby
include_recipe "t3-base::_physical" if physical?
```

* Virtual

```ruby
if virtualization?
  Chef::Log.debug("Virtualization detected (using #{node[:virtualization][:system]})")
  # automatically include the cookbook for the used virtualization type (e.g. t3-openvz, t3-kvm, t3-vbox)
  include_if_available "t3-#{node[:virtualization][:system]}::default"
end
```


---

# User Management

* in `t3-base::_users`
* Manage users through the users data bag
* All users with `group: sysadmin` automatically assigned to all nodes with _sudo_ privileges
* Grant access to individual users:

```json
{
    "id": "a-srv123-admin",
    ...
    "nodes": {
            "srv123.typo3.org": {
                    "sudo": "true"
            }
    }
}
```



---

# Proxy `site-proxytypo3org`

* Multiple instances, one per host
* *Nginx* for HTTP and HTTPS
  * All HTTP redirected to HTTPS
  * HTTPS configured at central place

* *haproxy* for TCP (UDP?) forwarding
* Data bag driven

---

# `site-proxytypo3org` Data Bag


* Nginx setup based on [nginx_conf](https://github.com/tablexi/chef-nginx_conf) cookbook

* Simple:
```shell
$ knife data bag show proxy piwik.typo3.org
id:  piwik.typo3.org
nginx:
  backend: http://srv132.typo3.org:80
```

---

# `site-proxytypo3org` Data Bag: Nginx

* Complex:
```json
$ cat data_bags/proxy/typo3_org.json
 {
   "id": "typo3.org",
   "name": "typo3.org",
   "nginx": {
     "backend": "http://srv107.typo3.org:80",
     "options": {
       "add_header": {
         "Strict-Transport-Security": "\"max-age=15768000; preload;\"",
         "X-Content-Type-Options": "nosniff",
         "X-Frame-Options": "SAMEORIGIN",
         "X-XSS-Protection": "\"1; mode=block\"",
         "Content-Security-Policy-Report-Only": "\"script-src 'self' 'unsafe-inline' 'unsafe-eval' https://piwik.typo3.org https://maps.google.com https://*.googleapis.com https://cdn.jquerytools.org; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; report-uri https://report-uri.io/report/90234a82d771236e837f46bebcbe46a5/reportOnly\""
       },
       "locations": {
         "/api/typo3cms": {
           "proxy_pass":  "http://api.typo3.org/typo3cms/current/html",
           "proxy_set_header": "Host api.typo3.org"
         }
       }
     }
   }
 }
```

---

# `site-proxytypo3org` Data Bag: Haproxy

* Example: `review.typo3.org:29418`

```json
{
  "id": "review.typo3.org",
  "name": "review.typo3.org",
  "nginx": {
    "backend": "https://review.typo3.org:443"
  },
  "haproxy": {
    "review-29418": {
      "mode": "tcp",
      "bind": ":::29418 v4v6",
      "servers": [
        "srv151 srv151.typo3.org:29418 check"
      ]
    }
  }
}
```

---

# Misc: `knife search`

* Syntax ([Docs](https://docs.chef.io/chef_search.html)):
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


# Git Flow?

* It helps me