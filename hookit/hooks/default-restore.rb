
root_user = []
payload[:users].each do |user|
  if user[:username] == "root"
    root_user = user
    break
  end
end

# pipe the backup into mysql client to restore from backup
execute "restore from backup" do
  command <<-EOF
    bash -c 'ssh -o StrictHostKeyChecking=no #{payload[:backup][:local_ip]} \
    "cat /data/var/db/mysql/#{payload[:backup][:backup_id]}.gz" \
      | gunzip \
        | /data/bin/mysql \
          -u root \
          --password=#{root_user[:password]} \
          -S /tmp/mysqld.sock
    for i in ${PIPESTATUS[@]}; do
      if [[ $i -ne 0 ]]; then
        exit $i
      fi
    done
    '
  EOF
end
