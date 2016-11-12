=begin
#<
The default recipe
#>
=end

include_recipe "t3-base"

# continue with other stuff

# include_recipe "#{cookbook_name}::_logrotate"

# Repository
apt_repository 'docker' do
  uri          'https://apt.dockerproject.org/repo'
  distribution "#{node['platform']}-#{node['lsb']['codename']}"
  components   ['main']
  keyserver    'p80.pool.sks-keyservers.net'
  key          '58118E89F3A912897C070ADBF76221572C52609D'
end

# Package
package 'docker-engine'

