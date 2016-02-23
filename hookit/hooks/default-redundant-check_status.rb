
root_user = []
payload[:users].each do |user|
  if user[:username] == "root"
    root_user = user
    break
  end
end

status = execute "check wsrep cluster status" do
  command <<-EOF
    /data/bin/mysql \
      -u root \
      --password=#{root_user[:password]} \
      -S /tmp/mysqld.sock \
      -e "SHOW STATUS LIKE 'wsrep_local_state_comment';"
    EOF
end

role = execute "check wsrep cluster role" do
  command <<-EOF
    /data/bin/mysql \
      -u root \
      --password=#{root_user[:password]} \
      -S /tmp/mysqld.sock \
      -e "SHOW STATUS LIKE 'wsrep_cluster_status';"
    EOF
end

if status =~ /Synced/
  synced = true
else
  synced = false
end

if role =~ /Primary/
  primary = true
else
  primary = false
end

if not synced or not primary
  # increment check
  registry("galera.replication.status", registry("galera.replication.status").to_i + 1)

  count = registry("galera.replication.status").to_i

  if count <= 10
    exit(count + 10)
  else
    $stderr.puts "ERROR: timed out waiting for galera cluster to get in sync"
    exit(Hooky::Exit::ERROR)
  end

end
