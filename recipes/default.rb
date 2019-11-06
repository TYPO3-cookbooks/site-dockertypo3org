=begin
#<
The default recipe
#>
=end

include_recipe "t3-base"

# continue with other stuff

# include_recipe "#{cookbook_name}::_logrotate"

directory '/root/.gnupg' do
  mode 0700
end

file '/root/.gnupg/dirmngr.conf' do
  content 'disable-ipv6'
end

bash "import apt repository key" do
  code <<-EOF
  curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
  EOF
  not_if "apt-key adv --list-public-keys --with-fingerprint --with-colons | grep -q \"9DC858229FC7DD38854AE2D88D81803C0EBFCD88\""
end

apt_repository 'docker' do
  uri          'https://download.docker.com/linux/debian'
  distribution node['lsb']['codename']
  components   ['stable']
end

# Package
package 'docker-ce'

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

    # this does not work in test-kitchen -> ignore failure
    ignore_failure true
  end
end

# Service
service "docker" do
  # this does not work in test-kitchen -> ignore failure
  ignore_failure true
end

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

##########################
# docker-compose
##########################
include_recipe 'site-dockertypo3org::docker_compose'
