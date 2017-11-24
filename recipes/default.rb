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

# Service configuration
template '/lib/systemd/system/docker.service' do
  source "docker.service"
  mode 0644
end

# Service
service "docker"

# Configuration
directory "/etc/docker" do
  owner 'root'
  group 'root'
  mode 0700
end

# API TLS Key
execute 'generate API tls key' do
  command "openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj \"/C=CH/O=TYPO3 Association/CN=#{node['hostname']}\" -keyout /etc/docker/tls.key  -out /etc/docker/tls.crt"
  not_if 'test -f /etc/docker/tls.key && test -f /etc/docker/tls.crt'
  notifies :restart, resources(:service => "docker")
end

