
payload[:generation][:members].each do |member|

  if member[:member_type] == 'default'

    execute "send diff data to new member" do
      command "rsync --delete -a /data/var/db/mysql/. #{member[:local_ip]}:/data/var/db/mysql/"
    end

  end
end
