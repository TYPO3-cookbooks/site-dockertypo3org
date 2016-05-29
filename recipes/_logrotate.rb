# logrotate_app "nginx" do
#   path "#{node['nginx']['log_dir']}/*.log"
#   postrotate '[ ! -f /var/run/nginx.pid ] || kill -USR1 $(cat /var/run/nginx.pid)'
# end
#
# logrotate_app "haproxy" do
#   path "/var/log/haproxy"
# end


