
service 'db' do
  action :enable
  init :runit
end

ensure_socket 'db' do
  port '3306'
  action :listening
end
