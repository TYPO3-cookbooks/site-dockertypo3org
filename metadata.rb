name             'site-skeletontypo3org'
maintainer       'The TYPO3 DevOps Team'
maintainer_email 'cookbooks@typo3.de'
license          'All rights reserved'
description      'Skeleton Cookbook for TYPO3 Site Cookbooks'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          IO.read(File.join(File.dirname(__FILE__), 'VERSION')) rescue '0.1.0'

supports         'debian'
