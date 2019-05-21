remote_file "/usr/local/bin/docker-compose" do
  source "https://github.com/docker/compose/releases/download/#{node['docker-compose']['version']}/docker-compose-Linux-x86_64"
  mode '0755'
end
