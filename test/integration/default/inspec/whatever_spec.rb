control 'nginx-1' do
  title 'Nginx Setup'
  desc '
    Check that nginx is installed and listening to ports
  '
  describe package('nginx') do
    it { should be_installed }
  end

  describe service('nginx') do
    # it { should be_running }
  end

  describe port(80) do
    it { should be_listening }
    its('protocols') { should include 'tcp'}
    its('protocols') { should include 'tcp6'}
    its('processes') { should include 'nginx.conf' }
  end

  describe port(443) do
    it { should be_listening }
    its('protocols') { should include 'tcp'}
    its('protocols') { should include 'tcp6'}
    its('processes') { should include 'nginx.conf' }
  end

  nginx_config_options = {
    assignment_re: /^\s*([a-z_]+)\s+(.*?)\s*;\s*$/,
    multiple_values: true
  }
  describe parse_config_file('/etc/nginx/sites-enabled/review.typo3.org', nginx_config_options) do
    its('server_name') { should include 'review.typo3.org'}
    its('add_header') { should include 'Strict-Transport-Security "max-age=31536000; includeSubdomains; preload;"' }
  end
end

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