
# pipe the backup into mysql client to restore from backup
execute "restore from backup" do
  command <<-EOF
    bash -c 'ssh #{payload[:backup][:local_ip]} \
    'cat /data/var/db/mysql/#{payload[:backup][:backup_id]}.gz' \
      | gunzip \
        | /data/bin/mysql \
          -u root \
          --password=#{payload[:service][:users][:system][:password]} \
          -S /tmp/mysqld.sock
    for i in ${PIPESTATUS[@]}; do
      if [[ $i -ne 0 ]]; then
        exit $i
      fi
    done
    '
  EOF
end
