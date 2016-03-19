name             "site-skeletontypo3org"
maintainer       "TYPO3 Server Admin Team"
maintainer_email "cookbooks@typo3.org"
license          "Apache 2.0"
description      "Skeleton Cookbook for TYPO3 Site Cookbooks"
long_description IO.read(File.join(File.dirname(__FILE__), "README.md"))
version          "1.0.0"

supports         "debian"

# base cookbook
depends          "t3-base",     "~> 0.2.0"

# TYPO3-cookbooks, pin to minor (~> 1.1.0)
# depends          "zabbix-custom-checks", "~> 0.2.0"
# depends          "ssl_certificates",     "~> 0.2.0"

# community cookbooks, pin to patchlevel (= 1.1.1)
# depends          "haproxy",    "= 1.6.7"
# depends          "openssl",    "= 4.4.0"
