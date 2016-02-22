
include Hooky::Mysql
boxfile = converge( BOXFILE_DEFAULTS, payload[:boxfile] )

if payload[:platform] == 'local'
  memcap = 128
else
  total_mem = `vmstat -s | grep 'total memory' | awk '{print $1}'`.to_i
  cgroup_mem = `cat /sys/fs/cgroup/memory/memory.limit_in_bytes`.to_i
  memcap = [ total_mem / 1024, cgroup_mem / 1024 / 1024 ].min
end

directory '/data/var/db/mysql' do
  recursive true
end

# chown data/var/db/mysql for gonano
execute 'chown /data/var/db/mysql' do
  command 'chown -R gonano:gonano /data/var/db/mysql'
end

directory '/var/log/mysql' do
  owner 'gonano'
  group 'gonano'
end

template '/data/etc/my.cnf' do
  mode 0644
  source 'my-prod.cnf.erb'
  owner 'gonano'
  group 'gonano'
  variables ({
    boxfile: boxfile,
    type:    'mysql',
    version: version(),
    memcap:  memcap,
    plugins: plugins(boxfile)
  })
end

execute 'mysql_install_db --basedir=/data --ldata=/data/var/db/mysql --user=gonano --defaults-file=/data/etc/my.cnf' do
  user 'gonano'
  not_if { ::Dir.exists? '/data/var/db/mysql/mysql' }
end

# Import service (and start)
directory '/etc/service/db' do
  recursive true
end

directory '/etc/service/db/log' do
  recursive true
end

template '/etc/service/db/log/run' do
  mode 0755
  source 'log-run.erb'
  variables ({ svc: "db" })
end

template '/etc/service/db/run' do
  mode 0755
  variables ({ exec: "mysqld --defaults-file=/data/etc/my.cnf --pid-file=/tmp/mysql.pid 2>&1" })
end

# Wait for server to start
until File.exists?( "/tmp/mysqld.sock" )
   sleep( 1 )
end

users = []
databases = []

if payload[:platform] == 'local'
  users = [
    {
      :username => "root",
      :password => "rootpassword",
      :meta => {
        :privileges => [
          {
            :privilege => "ALL PRIVILEGES",
            :on => "*.*",
            :with_grant => true
          }
        ]
      }
    },
    {
      :username => "gonano",
      :password => "password",
      :meta => {
        :privileges => [
          {
            :privilege => "ALL PRIVILEGES",
            :on => "gonano.*",
            :with_grant => true
          },
          {
            :privilege => "PROCESS",
            :on => "*.*",
            :with_grant => false
          },
          {
            :privilege => "SUPER",
            :on => "*.*",
            :with_grant => false
          }
        ]
      }
    }
  ]
  databases = ["gonano"]
else
  users = payload[:users]
  databases = payload[:databases]
end

# Create nanobox user and databases
template '/tmp/setup.sql' do
  variables ({
    hostname: `hostname`.to_s.strip[-59..-1],
    users: users,
    databases: databases
  })
  source 'setup.sql.erb'
end

execute 'setup user/permissions' do
  command <<-END
    /data/bin/mysql \
    -u root \
    -S /tmp/mysqld.sock \
      < /tmp/setup.sql
  END
end

# if payload[:platform] == 'local'

#   # Create nanobox user and databases
#   template '/tmp/setup.sql' do
#     variables ({
#       hostname: `hostname`.to_s.strip[-59..-1]
#     })
#     source 'setup.sql.erb'
#   end

#   execute 'setup user/permissions' do
#     command <<-END
#       /data/bin/mysql \
#       -u root \
#       -S /tmp/mysqld.sock \
#         < /tmp/setup.sql
#     END
#   end

# else

#   # Create nanobox user and databases
#   users = payload[:service][:users]

#   use_password = can_login?('root', users[:system][:password])

#   template '/tmp/setup.sql' do
#     variables ({
#       users:    payload[:service][:users],
#       hostname: `hostname`.to_s.strip[-59..-1]
#     })
#     source 'setup.sql.erb'
#   end

#   execute 'setup user/permissions' do
#     command <<-END
#       /opt/gonano/bin/mysql \
#       -u root \
#       #{(use_password) ? "--password=#{users[:system][:password]}" : '' } \
#       -S /tmp/mysqld.sock \
#         < /tmp/setup.sql
#     END
#   end

# end

file '/tmp/setup.sql' do
  action :delete
end

# Configure narc
template '/opt/gonano/etc/narc.conf' do
  variables ({ 
    uid: payload[:uid], 
    app: "nanobox", 
    logtap: payload[:logtap_host] 
  })
end

directory '/etc/service/narc'

file '/etc/service/narc/run' do
  mode 0755
  content <<-EOF
#!/bin/sh -e
export PATH="/opt/local/sbin:/opt/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/gonano/sbin:/opt/gonano/bin"

exec /opt/gonano/bin/narcd /opt/gonano/etc/narc.conf
  EOF
end

if payload[:platform] != 'local'

  # Setup root keys for data migrations
  directory '/root/.ssh' do
    recursive true
  end

  file '/root/.ssh/id_rsa' do
    content payload[:ssh][:admin_key][:private_key]
    mode 0600
  end

  file '/root/.ssh/id_rsa.pub' do
    content payload[:ssh][:admin_key][:public_key]
  end

  file '/root/.ssh/authorized_keys' do
    content payload[:ssh][:admin_key][:public_key]
  end

  # Create some ssh host keys
  execute "ssh-keygen -f /opt/gonano/etc/ssh/ssh_host_rsa_key -N '' -t rsa" do
    not_if { ::File.exists? '/opt/gonano/etc/ssh/ssh_host_rsa_key' }
  end

  execute "ssh-keygen -f /opt/gonano/etc/ssh/ssh_host_dsa_key -N '' -t dsa" do
    not_if { ::File.exists? '/opt/gonano/etc/ssh/ssh_host_dsa_key' }
  end

  execute "ssh-keygen -f /opt/gonano/etc/ssh/ssh_host_ecdsa_key -N '' -t ecdsa" do
    not_if { ::File.exists? '/opt/gonano/etc/ssh/ssh_host_ecdsa_key' }
  end

  execute "ssh-keygen -f /opt/gonano/etc/ssh/ssh_host_ed25519_key -N '' -t ed25519" do
    not_if { ::File.exists? '/opt/gonano/etc/ssh/ssh_host_ed25519_key' }
  end

end
