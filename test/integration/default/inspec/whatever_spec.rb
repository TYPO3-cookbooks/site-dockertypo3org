control 'docker' do
  title 'Docker Tests'
  desc '
   test Docker package
  '
  describe package('docker-engine') do
    it { should be_installed }
  end
end
