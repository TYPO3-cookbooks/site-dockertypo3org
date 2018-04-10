name             "site-dockertypo3org"
maintainer       "TYPO3 Server Admin Team"
maintainer_email "cookbooks@typo3.org"
license          "Apache 2.0"
description      "Wrapper cookbook for Docker"
long_description IO.read(File.join(File.dirname(__FILE__), "README.md"))
version          IO.read(File.join(File.dirname(__FILE__), 'VERSION')) rescue '0.0.1'

supports         "debian"

# base cookbook
depends          "t3-base",     "~> 0.2.0"

# TYPO3-cookbooks, pin to minor (~> 1.1.0)
# depends          "zabbix-custom-checks", "~> 0.2.0"
# depends          "ssl_certificates",     "~> 0.2.0"

# community cookbooks, pin to patchlevel (= 1.1.1)
# depends          "haproxy",    "= 1.6.7"
depends          "openssl",    "= 8.1.2"
depends          "systemd",    "= 2.1.3"
