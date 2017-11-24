control 'docker' do
  title 'Docker Tests'
  desc '
   test Docker package
  '

  # Package
  describe package('docker-engine') do
    it { should be_installed }
  end

  # Certificate exists
  describe file('/etc/docker/tls.crt') do
    it { should exist }
  end

  # Key exists
  describe file('/etc/docker/tls.key') do
    it { should exist }
  end

  # Certificate matches to key
  describe command('[ "$(openssl rsa -noout -modulus -in /etc/docker/tls.key | openssl md5)" = "$(openssl x509 -noout -modulus -in /etc/docker/tls.crt | openssl md5)" ]') do
    its('exit_status') { should eq 0 }
  end
  
  # Docker API listen
  describe port(2376) do
    it { should be_listening }
  end

  # Docker API ping
  describe command("curl --cacert /etc/docker/tls.crt --cert /etc/docker/tls.crt --key /etc/docker/tls.key https://$(hostname):2376/_ping") do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /^OK$/ }
  end
end
