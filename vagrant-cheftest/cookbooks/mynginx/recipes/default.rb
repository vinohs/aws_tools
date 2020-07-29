execute 'security updates' do
  command 'apt-get upgrade -y'
end

execute 'apt-get update'

package ['nginx', 'curl']

cookbook_file '/etc/nginx/nginx.conf' do
  source 'nginx/nginx.conf'
  mode   00644
  action :create
end

service 'nginx' do
  action :restart
end
