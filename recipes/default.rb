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
systemd_service 'docker' do
  description 'Docker Application Container Engine'
  documentation 'https://docs.docker.com'
  after 'network-online.target docker.socket firewalld.service'
  wants 'network-online.target'
  requires 'docker.socket'
  install do
    wanted_by 'multi-user.target'
  end
  service do
    type 'notify'
    exec_start '/usr/bin/dockerd --tlsverify=true --tlscacert=/etc/docker/tls.crt --tlscert=/etc/docker/tls.crt --tlskey=/etc/docker/tls.key -H=0.0.0.0:2376 --host=unix:///var/run/docker.sock'
    exec_reload '/bin/kill -s HUP $MAINPID'
    limit_nofile 1048576
    limit_nproc 'infinity'
    limit_core 'infinity'
    timeout_start_sec 0
    delegate true
    kill_mode 'process'
    restart 'on-failure'
    start_limit_burst 3
    start_limit_interval '60s'
  end
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
openssl_x509 '/etc/docker/tls.crt' do
  common_name node['hostname']
  org 'TYPO3 Association'
  org_unit 'Server Team'
  country 'CH'
  key_length 4096
  expire 3650
  notifies :restart, resources(:service => "docker")
end

